import 'package:vf_database/src/database.dart';
import 'package:vf_database/src/repositories/mappers.dart';
import 'package:vf_domain/vf_domain.dart';

class DriftOutboxRepository implements OutboxRepository {
  DriftOutboxRepository(this._db);

  final VaultFlowDatabase _db;

  @override
  Stream<List<OutboxEntry>> watchAll() =>
      _db.outboxDao.watchAll().map((rows) => rows.map(Mappers.outbox).toList());

  @override
  Stream<int> watchPendingCount() => _db.outboxDao.watchCount();
}
