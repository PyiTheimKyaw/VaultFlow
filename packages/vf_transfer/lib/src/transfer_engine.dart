import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_database/vf_database.dart';
import 'package:vf_domain/vf_domain.dart';
import 'package:vf_network/vf_network.dart';
import 'package:vf_protocol/vf_protocol.dart';
import 'package:vf_transfer/src/chunk_planner.dart';
import 'package:vf_transfer/src/download_worker.dart';
import 'package:vf_transfer/src/transfer_models.dart';
import 'package:vf_transfer/src/upload_worker.dart';

export 'package:vf_transfer/src/upload_worker.dart' show TransferException;

const _log = Logger('transfers');

/// Owns the transfer queue: a bounded pool of workers, pause/resume/cancel,
/// crash recovery, and live progress. Every state change is persisted in
/// `transfer_sessions`/`transfer_chunks`, so a killed app resumes exactly
/// where it stopped.
class TransferEngine {
  TransferEngine({
    required this.db,
    required this.api,
    required this.cacheRoot,
    this.clock = const SystemClock(),
    this.maxConcurrent = 2,
    this.chunkSize = vfDefaultChunkSize,
    this.parallelChunks = 3,
    this.maxAttempts = 8,
    this.retryDelay = const Duration(seconds: 2),
  });

  final VaultFlowDatabase db;
  final ApiClient api;

  /// Directory for downloaded files (content-addressed inside).
  final Future<String> Function() cacheRoot;
  final Clock clock;
  final int maxConcurrent;
  final int chunkSize;
  final int parallelChunks;
  final int maxAttempts;
  final Duration retryDelay;

  final ValueNotifier<Map<String, TransferProgress>> progress = ValueNotifier(
    const {},
  );
  final Map<String, CancelToken> _running = {};

  /// Upload content held in memory (web). Lost on reload: [recover] parks
  /// such sessions as failed so the user re-imports.
  final Map<String, Uint8List> _memory = {};

  /// Prefix of `localPath` for in-memory uploads.
  static const String memoryPathPrefix = 'memory:';
  final Map<String, Timer> _retryTimers = {};
  final Map<String, ({DateTime at, int bytes})> _lastSample = {};
  bool _disposed = false;
  bool _pumping = false;

  TransfersDao get _dao => db.transfersDao;

  Stream<List<TransferSessionRow>> watchSessions() => _dao.watchSessions();

  /// Call once at start-up: sessions left `running` by a crash are queued
  /// again and the pool starts.
  Future<void> recover() async {
    final recovered = await _dao.recoverRunning();
    if (recovered > 0) {
      _log.info('recovered running transfers', fields: {'count': recovered});
    }
    for (final s in await _dao.listSessions()) {
      if (!s.transferState.isTerminal &&
          s.localPath.startsWith(memoryPathPrefix) &&
          !_memory.containsKey(s.id)) {
        await _dao.setState(
          s.id,
          TransferState.failed.name,
          error: 'Content was lost when the page reloaded; import it again',
          now: clock.now(),
        );
      }
    }
    unawaited(_pump());
  }

  /// Queues an upload for a document whose bytes are at [localPath]. Returns
  /// the session id; the caller parks the document's outbox create on it.
  Future<String> enqueueUpload({
    required String documentId,
    required String localPath,
    required int totalBytes,
    required String sha256,
    String? sessionId,
    Uint8List? bytes,
  }) async {
    final id = sessionId ?? VfId.next();
    if (bytes != null) _memory[id] = bytes;
    final now = clock.now();
    final plans = planChunks(totalBytes, chunkSize);
    await db.transaction(() async {
      await _dao.insertSession(
        TransferSessionsCompanion.insert(
          id: id,
          kind: TransferKind.upload.name,
          documentId: documentId,
          localPath: localPath,
          totalBytes: totalBytes,
          chunkSize: chunkSize,
          sha256Expected: Value(sha256),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await _dao.insertChunks([
        for (final c in plans)
          TransferChunksCompanion.insert(
            sessionId: id,
            idx: c.index,
            offset: c.offset,
            length: c.length,
          ),
      ]);
    });
    unawaited(_pump());
    return id;
  }

  /// Queues a download into the content-addressed cache. Returns the
  /// existing session when one is already active for the document.
  Future<String> enqueueDownload(Document document) async {
    final existing = await _dao.findActiveFor(
      document.id,
      TransferKind.download.name,
    );
    if (existing != null) {
      if (existing.state == 'failed' || existing.state == 'paused') {
        await resume(existing.id);
      }
      return existing.id;
    }
    final id = VfId.next();
    final now = clock.now();
    final target = DownloadWorker.cachePathFor(await cacheRoot(), document);
    await _dao.insertSession(
      TransferSessionsCompanion.insert(
        id: id,
        kind: TransferKind.download.name,
        documentId: document.id,
        localPath: target,
        totalBytes: document.sizeBytes,
        chunkSize: chunkSize,
        sha256Expected: Value(document.sha256),
        createdAt: now,
        updatedAt: now,
      ),
    );
    unawaited(_pump());
    return id;
  }

  Future<void> pause(String id) async {
    _retryTimers.remove(id)?.cancel();
    _running[id]?.cancel('paused');
    final session = await _dao.getSession(id);
    if (session != null && !session.transferState.isTerminal) {
      await _dao.setState(id, TransferState.paused.name, now: clock.now());
    }
  }

  Future<void> resume(String id) async {
    final session = await _dao.getSession(id);
    if (session == null || session.transferState.isTerminal) return;
    await _dao.bumpAttempt(id, 0);
    await _dao.setState(id, TransferState.queued.name, now: clock.now());
    unawaited(_pump());
  }

  Future<void> retry(String id) => resume(id);

  Future<void> cancel(String id) async {
    _retryTimers.remove(id)?.cancel();
    _running[id]?.cancel('cancelled');
    final session = await _dao.getSession(id);
    if (session == null) return;
    await _dao.setState(id, TransferState.cancelled.name, now: clock.now());
    if (session.transferKind == TransferKind.download) {
      final part = File('${session.localPath}.part');
      if (part.existsSync()) await part.delete();
    }
    _clearProgress(id);
  }

  /// Removes finished or cancelled rows from the list.
  Future<void> clearFinished() async {
    for (final s in await _dao.listSessions()) {
      if (s.transferState.isTerminal) await _dao.deleteSession(s.id);
    }
  }

  Future<void> _pump() async {
    if (_disposed || _pumping) return;
    _pumping = true;
    try {
      while (_running.length < maxConcurrent) {
        final next =
            (await _dao.nextQueued(limit: maxConcurrent + _retryTimers.length))
                .where(
                  (s) =>
                      !_running.containsKey(s.id) &&
                      !_retryTimers.containsKey(s.id),
                )
                .firstOrNull;
        if (next == null) break;
        await _dao.setState(
          next.id,
          TransferState.running.name,
          now: clock.now(),
        );
        final token = CancelToken();
        _running[next.id] = token;
        unawaited(_run(next, token));
      }
    } finally {
      _pumping = false;
    }
  }

  Future<void> _run(TransferSessionRow session, CancelToken token) async {
    void report(int bytes) => _report(session, bytes);
    try {
      switch (session.transferKind) {
        case TransferKind.upload:
          await UploadWorker(
            db: db,
            api: api,
            session: session,
            cancelToken: token,
            onProgress: report,
            parallelChunks: parallelChunks,
            clock: clock,
            bytes: _memory[session.id],
          ).run();
          _memory.remove(session.id);
        case TransferKind.download:
          await DownloadWorker(
            db: db,
            api: api,
            session: session,
            cancelToken: token,
            onProgress: report,
            clock: clock,
          ).run();
      }
      if (!token.isCancelled) _clearProgress(session.id);
    } on TransferException catch (e) {
      await _handleFailure(session, e);
    } on Object catch (e, stackTrace) {
      _log.error('transfer crashed', error: e, stackTrace: stackTrace);
      await _handleFailure(
        session,
        TransferException(UnexpectedFailure('$e', cause: e), retryable: false),
      );
    } finally {
      _running.remove(session.id);
      if (!_disposed) unawaited(_pump());
    }
  }

  Future<void> _handleFailure(
    TransferSessionRow session,
    TransferException e,
  ) async {
    if (_disposed) return;
    final current = await _dao.getSession(session.id);
    if (current == null || current.transferState.isTerminal) return;
    if (current.state == 'paused') return;
    final attempt = current.attemptCount + 1;
    final giveUp = !e.retryable || attempt >= maxAttempts;
    await _dao.bumpAttempt(session.id, attempt);
    await _dao.setState(
      session.id,
      giveUp ? TransferState.failed.name : TransferState.queued.name,
      error: e.failure.message,
      now: clock.now(),
    );
    _log.warning(
      giveUp ? 'transfer failed' : 'transfer will retry',
      fields: {
        'id': session.id,
        'attempt': attempt,
        'error': e.failure.message,
      },
    );
    if (!giveUp) {
      // The row stays `queued` (visible as retrying in the UI) but the pool
      // skips it until the backoff elapses.
      _retryTimers[session.id]?.cancel();
      _retryTimers[session.id] = Timer(retryDelay * attempt, () {
        _retryTimers.remove(session.id);
        if (!_disposed) unawaited(_pump());
      });
    }
  }

  void _report(TransferSessionRow session, int bytes) {
    final now = clock.now();
    final last = _lastSample[session.id];
    var speed = progress.value[session.id]?.bytesPerSecond ?? 0;
    if (last != null) {
      final seconds = now.difference(last.at).inMilliseconds / 1000;
      if (seconds >= 0.5) {
        speed = (bytes - last.bytes) / seconds;
        _lastSample[session.id] = (at: now, bytes: bytes);
      }
    } else {
      _lastSample[session.id] = (at: now, bytes: bytes);
    }
    if (_disposed) return;
    progress.value = {
      ...progress.value,
      session.id: TransferProgress(
        sessionId: session.id,
        bytesDone: bytes,
        totalBytes: session.totalBytes,
        bytesPerSecond: speed,
      ),
    };
    unawaited(_dao.setProgress(session.id, bytes, now));
  }

  void _clearProgress(String id) {
    _lastSample.remove(id);
    if (_disposed) return;
    progress.value = {...progress.value}..remove(id);
  }

  /// Waits until no transfer is running or queued (tests and shutdown).
  Future<void> drain({Duration timeout = const Duration(seconds: 30)}) async {
    final deadline = clock.now().add(timeout);
    while (clock.now().isBefore(deadline)) {
      final active = (await _dao.listSessions()).where(
        (s) => s.state == 'queued' || s.state == 'running',
      );
      if (active.isEmpty && _running.isEmpty && _retryTimers.isEmpty) return;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final t in _retryTimers.values) {
      t.cancel();
    }
    _retryTimers.clear();
    for (final token in _running.values) {
      token.cancel('disposed');
    }
    progress.dispose();
  }
}
