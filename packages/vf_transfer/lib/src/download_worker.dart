import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:path/path.dart' as p;
import 'package:vf_core/vf_core.dart';
import 'package:vf_database/vf_database.dart';
import 'package:vf_domain/vf_domain.dart';
import 'package:vf_network/vf_network.dart';
import 'package:vf_transfer/src/hasher.dart';
import 'package:vf_transfer/src/upload_worker.dart' show TransferException;

const _log = Logger('download');

/// Downloads one document into `<localPath>.part` with `Range` resume, then
/// verifies the hash and moves it into place.
class DownloadWorker {
  DownloadWorker({
    required this.db,
    required this.api,
    required this.session,
    required this.cancelToken,
    required this.onProgress,
    this.progressEvery = 1024 * 1024,
    this.clock = const SystemClock(),
  });

  final VaultFlowDatabase db;
  final ApiClient api;
  final TransferSessionRow session;
  final CancelToken cancelToken;
  final void Function(int bytesDone) onProgress;
  final int progressEvery;
  final Clock clock;

  File get _part => File('${session.localPath}.part');

  Future<void> run() async {
    final expected = session.sha256Expected;
    if (expected == null) {
      throw const TransferException(
        ValidationFailure('Download session has no expected hash'),
        retryable: false,
      );
    }
    await _part.parent.create(recursive: true);
    var done = _part.existsSync() ? await _part.length() : 0;
    if (done > session.totalBytes) {
      await _part.delete();
      done = 0;
    }
    onProgress(done);

    if (done < session.totalBytes) {
      final opened = await api.downloadContent(
        session.documentId,
        offset: done,
        cancelToken: cancelToken,
      );
      final ContentDownload download;
      switch (opened) {
        case Err(:final failure):
          if (failure is CancelledFailure) return;
          throw TransferException(
            failure,
            retryable: failure is NetworkFailure,
          );
        case Ok(:final value):
          download = value;
      }
      if (download.etag.isNotEmpty && download.etag != expected) {
        // Content changed on the server since this session was planned.
        if (_part.existsSync()) await _part.delete();
        throw const TransferException(
          ConflictFailure(
            'File changed on the server; download it again',
            remoteVersion: 0,
          ),
          retryable: false,
        );
      }
      if (download.startsAt == 0 && done > 0) {
        // Server ignored the range: start over.
        await _part.writeAsBytes(const []);
        done = 0;
        onProgress(0);
      }
      final sink = _part.openWrite(mode: FileMode.append);
      var sinceReport = 0;
      try {
        await for (final chunk in download.stream) {
          if (cancelToken.isCancelled) return;
          sink.add(chunk);
          done += chunk.length;
          sinceReport += chunk.length;
          if (sinceReport >= progressEvery) {
            await sink.flush();
            sinceReport = 0;
            onProgress(done);
          }
        }
      } on DioException catch (e) {
        throw TransferException(ApiClient.mapDioException(e));
      } on Object catch (e) {
        throw TransferException(
          NetworkFailure('Download interrupted: $e', cause: e),
        );
      } finally {
        await sink.close();
      }
      onProgress(done);
    }
    if (cancelToken.isCancelled) return;

    if (done != session.totalBytes) {
      throw TransferException(
        NetworkFailure(
          'Connection closed after $done of ${session.totalBytes} bytes',
        ),
      );
    }
    final actual = await Hasher.ofFile(_part.path);
    if (actual != expected) {
      await _part.delete();
      _log.warning(
        'download hash mismatch; discarded',
        fields: {'doc': session.documentId},
      );
      throw const TransferException(
        StorageFailure('Downloaded file failed verification'),
      );
    }
    final target = File(session.localPath);
    await target.parent.create(recursive: true);
    if (target.existsSync()) await target.delete();
    await _part.rename(target.path);
    await DriftVaultRepository(db).updateDocumentCache(
      session.documentId,
      cacheState: CacheState.complete,
      localPath: target.path,
    );
    await db.transfersDao.updateSession(
      session.id,
      TransferSessionsCompanion(
        state: const Value('completed'),
        bytesDone: Value(session.totalBytes),
        updatedAt: Value(clock.now()),
      ),
    );
  }

  /// Content-addressed cache location for a document.
  static String cachePathFor(String cacheRoot, Document document) => p.join(
    cacheRoot,
    document.sha256.substring(0, 2),
    document.sha256,
    document.name,
  );
}
