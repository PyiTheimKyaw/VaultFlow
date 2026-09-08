import 'package:meta/meta.dart';
import 'package:vf_core/vf_core.dart';
import 'package:vf_database/vf_database.dart';
import 'package:vf_network/vf_network.dart';
import 'package:vf_protocol/vf_protocol.dart';

const _log = Logger('puller');

@immutable
class PullReport {
  const PullReport({
    this.applied = 0,
    this.skipped = 0,
    this.pages = 0,
    this.cursor = 0,
    this.failure,
  });

  final int applied;

  /// Changes ignored because the entity has unsynced local edits or an open
  /// conflict; the push will settle them authoritatively.
  final int skipped;
  final int pages;
  final int cursor;
  final Failure? failure;

  bool get isOk => failure == null;
}

/// Pulls the change feed from the persisted cursor and applies snapshots.
class ChangePuller {
  ChangePuller({
    required VaultFlowDatabase db,
    required this.api,
    required this.deviceId,
    this.pageSize = vfMaxChangesPageSize,
    this.maxPages = 50,
  }) : _db = db,
       _repo = DriftSyncRepository(db);

  final VaultFlowDatabase _db;
  final DriftSyncRepository _repo;
  final ApiClient api;
  final String deviceId;

  /// Changes per request; mutable so tests can exercise paging.
  int pageSize;

  /// Safety valve per round; the next round continues from the cursor.
  final int maxPages;

  Future<PullReport> pullOnce() async {
    var cursor = await _db.settingsDao.getPullCursor();
    var applied = 0;
    var skipped = 0;
    var pages = 0;

    while (pages < maxPages) {
      final result = await api.changes(
        since: cursor,
        limit: pageSize,
        excludeDeviceId: deviceId,
      );
      final ChangesResponse page;
      switch (result) {
        case Err(:final failure):
          return PullReport(
            applied: applied,
            skipped: skipped,
            pages: pages,
            cursor: cursor,
            failure: failure,
          );
        case Ok(:final value):
          page = value;
      }
      pages++;
      for (final change in page.changes) {
        if (await _shouldSkip(change)) {
          _log.info('pull skipped', fields: {'entity': change.entityId});
          skipped++;
          continue;
        }
        await _repo.applyRemoteSnapshot(
          change.entityType,
          change.payload,
          version: change.version,
        );
        applied++;
      }
      if (page.nextCursor > cursor) {
        cursor = page.nextCursor;
        await _db.settingsDao.setPullCursor(cursor);
      }
      if (!page.hasMore) break;
    }
    _log.info('pull done', fields: {'applied': applied, 'skipped': skipped});
    return PullReport(
      applied: applied,
      skipped: skipped,
      pages: pages,
      cursor: cursor,
    );
  }

  Future<bool> _shouldSkip(ChangeDto change) async {
    if (await _db.outboxDao.hasUnsynced(change.entityType, change.entityId)) {
      return true;
    }
    final conflict = await _db.conflictsDao.findUnresolvedFor(
      change.entityType,
      change.entityId,
    );
    return conflict != null;
  }
}
