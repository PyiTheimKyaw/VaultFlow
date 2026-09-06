import 'package:vf_domain/src/entities/outbox_entry.dart';

/// Read-only view of the sync queue for status badges and the debug screen.
/// The sync engine (Phase 4) gets a richer DAO-level API.
abstract interface class OutboxRepository {
  Stream<List<OutboxEntry>> watchAll();

  /// Number of rows that still need to reach the server.
  Stream<int> watchPendingCount();
}
