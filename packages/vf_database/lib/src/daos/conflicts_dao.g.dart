// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conflicts_dao.dart';

// ignore_for_file: type=lint
mixin _$ConflictsDaoMixin on DatabaseAccessor<VaultFlowDatabase> {
  $ConflictsTable get conflicts => attachedDatabase.conflicts;
  ConflictsDaoManager get managers => ConflictsDaoManager(this);
}

class ConflictsDaoManager {
  final _$ConflictsDaoMixin _db;
  ConflictsDaoManager(this._db);
  $$ConflictsTableTableManager get conflicts =>
      $$ConflictsTableTableManager(_db.attachedDatabase, _db.conflicts);
}
