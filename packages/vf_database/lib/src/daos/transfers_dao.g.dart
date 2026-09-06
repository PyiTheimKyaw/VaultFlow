// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfers_dao.dart';

// ignore_for_file: type=lint
mixin _$TransfersDaoMixin on DatabaseAccessor<VaultFlowDatabase> {
  $TransferSessionsTable get transferSessions =>
      attachedDatabase.transferSessions;
  $TransferChunksTable get transferChunks => attachedDatabase.transferChunks;
  TransfersDaoManager get managers => TransfersDaoManager(this);
}

class TransfersDaoManager {
  final _$TransfersDaoMixin _db;
  TransfersDaoManager(this._db);
  $$TransferSessionsTableTableManager get transferSessions =>
      $$TransferSessionsTableTableManager(
        _db.attachedDatabase,
        _db.transferSessions,
      );
  $$TransferChunksTableTableManager get transferChunks =>
      $$TransferChunksTableTableManager(
        _db.attachedDatabase,
        _db.transferChunks,
      );
}
