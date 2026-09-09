import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:vf_core/vf_core.dart';
import 'package:vf_database/vf_database.dart';
import 'package:vf_network/vf_network.dart';
import 'package:vf_protocol/vf_protocol.dart';
import 'package:vf_transfer/src/hasher.dart';

const _log = Logger('upload');

/// Thrown by workers; the engine maps it to a session state.
class TransferException implements Exception {
  const TransferException(this.failure, {this.retryable = true});
  final Failure failure;
  final bool retryable;

  @override
  String toString() => 'TransferException(${failure.message})';
}

/// Uploads one session: reconciles with the server, sends the missing
/// chunks with bounded parallelism, completes, and stamps the document.
class UploadWorker {
  UploadWorker({
    required this.db,
    required this.api,
    required this.session,
    required this.cancelToken,
    required this.onProgress,
    this.parallelChunks = 3,
    this.chunkAttempts = 5,
    this.clock = const SystemClock(),
  });

  final VaultFlowDatabase db;
  final ApiClient api;
  final TransferSessionRow session;
  final CancelToken cancelToken;
  final void Function(int bytesDone) onProgress;
  final int parallelChunks;
  final int chunkAttempts;
  final Clock clock;

  TransfersDao get _dao => db.transfersDao;

  Future<void> run() async {
    final doc = await db.documentsDao.getById(session.documentId);
    if (doc == null) {
      throw const TransferException(
        NotFoundFailure('Document was deleted'),
        retryable: false,
      );
    }
    final remoteId = await _reconcile();
    if (remoteId == null) return; // dedup finished everything

    final chunks = await _dao.getChunks(session.id);
    var bytesDone = chunks
        .where((c) => c.state == 'done')
        .fold<int>(0, (sum, c) => sum + c.length);
    onProgress(bytesDone);

    final pending = chunks.where((c) => c.state != 'done').toList();
    final queue = List.of(pending);
    TransferException? firstError;
    Future<void> lane() async {
      while (queue.isNotEmpty &&
          firstError == null &&
          !cancelToken.isCancelled) {
        final chunk = queue.removeAt(0);
        try {
          await _sendChunk(remoteId, chunk);
          bytesDone += chunk.length;
          onProgress(bytesDone);
        } on TransferException catch (e) {
          firstError ??= e;
        } on Object catch (e) {
          firstError ??= TransferException(
            UnexpectedFailure('$e', cause: e),
            retryable: false,
          );
        }
      }
    }

    await Future.wait(List.generate(parallelChunks, (_) => lane()));
    if (cancelToken.isCancelled) return;
    final error = firstError;
    if (error != null) throw error;

    final completed = await api.completeUpload(remoteId);
    switch (completed) {
      case Err(:final failure):
        throw TransferException(failure, retryable: failure is NetworkFailure);
      case Ok(:final value):
        await _finish(value.storageKey, version: value.version);
    }
  }

  /// Creates the server session on first run, or asks which chunks the
  /// server already has and marks them done locally. Returns `null` when
  /// the server deduplicated the content (nothing left to send).
  Future<String?> _reconcile() async {
    var remoteId = session.remoteSessionId;
    if (remoteId != null) {
      final status = await api.uploadStatus(remoteId);
      switch (status) {
        case Ok(:final value):
          for (final index in value.receivedChunks) {
            await _dao.markChunkDone(session.id, index);
          }
          return remoteId;
        case Err(:final failure):
          if (failure is NetworkFailure) {
            throw TransferException(failure);
          }
          // Expired or unknown on the server: start over from zero.
          _log.info(
            'upload session gone on server; restarting',
            fields: {'id': remoteId},
          );
          await _dao.resetChunks(session.id);
          remoteId = null;
      }
    }
    final created = await api.createUpload(
      UploadSessionCreateRequest(
        documentId: session.documentId,
        totalBytes: session.totalBytes,
        sha256: session.sha256Expected!,
        mimeType:
            (await db.documentsDao.getById(session.documentId))?.mimeType ??
            'application/octet-stream',
        chunkSize: session.chunkSize,
      ),
    );
    switch (created) {
      case Err(:final failure):
        throw TransferException(failure, retryable: failure is NetworkFailure);
      case Ok(:final value):
        if (value.dedup) {
          _log.info(
            'dedup: nothing to upload',
            fields: {'doc': session.documentId},
          );
          await db.settingsDao.setSyncState(
            'dedupe_saved_bytes',
            '${(int.tryParse(await db.settingsDao.getSyncState('dedupe_saved_bytes') ?? '') ?? 0) + session.totalBytes}',
          );
          onProgress(session.totalBytes);
          await _finish(value.storageKey!, version: 0);
          return null;
        }
        await _dao.updateSession(
          session.id,
          TransferSessionsCompanion(remoteSessionId: Value(value.uploadId)),
        );
        return value.uploadId!;
    }
  }

  Future<void> _sendChunk(String remoteId, TransferChunkRow chunk) async {
    final bytes = await _readChunk(chunk.offset, chunk.length);
    final hash = Hasher.ofBytes(bytes);
    Failure? last;
    for (var attempt = 1; attempt <= chunkAttempts; attempt++) {
      if (cancelToken.isCancelled) return;
      final result = await api.putChunk(
        remoteId,
        chunk.idx,
        bytes,
        sha256: hash,
        cancelToken: cancelToken,
      );
      switch (result) {
        case Ok(:final value):
          await _dao.markChunkDone(session.id, chunk.idx, etag: value.etag);
          return;
        case Err(:final failure):
          if (failure is CancelledFailure) return;
          if (failure is! NetworkFailure) {
            throw TransferException(failure, retryable: false);
          }
          last = failure;
          await Future<void>.delayed(Duration(milliseconds: 200 * attempt));
      }
    }
    throw TransferException(last!);
  }

  Future<List<int>> _readChunk(int offset, int length) async {
    if (length == 0) return const [];
    final file = File(session.localPath);
    return await file
        .openRead(offset, offset + length)
        .fold<List<int>>(<int>[], (acc, part) => acc..addAll(part));
  }

  Future<void> _finish(String storageKey, {required int version}) async {
    final hasLocalEdits = await db.outboxDao.hasUnsynced(
      EntityType.document,
      session.documentId,
    );
    await DriftVaultRepository(db).attachStorageKey(
      session.documentId,
      storageKey: storageKey,
      transferId: session.id,
      // Only adopt the server version when nothing local is still queued.
      version: version > 0 && !hasLocalEdits ? version : null,
    );
    await _dao.updateSession(
      session.id,
      TransferSessionsCompanion(
        state: const Value('completed'),
        bytesDone: Value(session.totalBytes),
        updatedAt: Value(clock.now()),
      ),
    );
  }
}
