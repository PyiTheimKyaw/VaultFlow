import 'package:drift/drift.dart';
import 'package:vf_database/src/converters.dart';
import 'package:vf_domain/vf_domain.dart';

/// Columns shared by every synced entity.
mixin SyncedEntityColumns on Table {
  TextColumn get id => text()();

  /// Server-authoritative version; `0` until first synced.
  IntColumn get version => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus =>
      textEnum<SyncStatus>().withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('FolderRow')
class Folders extends Table with SyncedEntityColumns {
  TextColumn get parentId => text().nullable()();
  TextColumn get name => text()();
}

@DataClassName('DocumentRow')
class Documents extends Table with SyncedEntityColumns {
  TextColumn get folderId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get mimeType => text()();
  IntColumn get sizeBytes => integer()();
  TextColumn get sha256 => text()();
  TextColumn get storageKey => text().nullable()();
  TextColumn get localPath => text().nullable()();
  TextColumn get cacheState =>
      textEnum<CacheState>().withDefault(const Constant('none'))();
}

@DataClassName('NoteRow')
class Notes extends Table with SyncedEntityColumns {
  TextColumn get folderId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get body => text()();
}

@DataClassName('ConflictRow')
class Conflicts extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => textEnum<EntityType>()();
  TextColumn get entityId => text()();
  TextColumn get localSnapshot => text().map(const JsonMapConverter())();
  TextColumn get remoteSnapshot => text().map(const JsonMapConverter())();
  IntColumn get remoteVersion => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get resolvedAt => dateTime().nullable()();
  TextColumn get resolution => textEnum<ConflictResolution>().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// FIFO queue of local mutations waiting to be pushed.
@DataClassName('OutboxRow')
class SyncOutbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientOpId => text().unique()();
  TextColumn get entityType => textEnum<EntityType>()();
  TextColumn get entityId => text()();
  TextColumn get op => textEnum<SyncOp>()();
  TextColumn get payload => text().map(const JsonMapConverter())();
  IntColumn get baseVersion => integer()();
  TextColumn get state =>
      textEnum<OutboxState>().withDefault(const Constant('pending'))();
  TextColumn get dependsOnTransfer => text().nullable()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Key/value sync bookkeeping: pull cursor, device id, last sync time.
@DataClassName('SyncStateRow')
class SyncState extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DataClassName('TransferSessionRow')
class TransferSessions extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()();
  TextColumn get documentId => text()();
  TextColumn get remoteSessionId => text().nullable()();
  TextColumn get localPath => text()();
  IntColumn get totalBytes => integer()();
  IntColumn get chunkSize => integer()();
  TextColumn get sha256Expected => text().nullable()();
  TextColumn get state => text().withDefault(const Constant('queued'))();
  IntColumn get bytesDone => integer().withDefault(const Constant(0))();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TransferChunkRow')
class TransferChunks extends Table {
  TextColumn get sessionId =>
      text().references(TransferSessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get idx => integer()();
  IntColumn get offset => integer()();
  IntColumn get length => integer()();
  TextColumn get state => text().withDefault(const Constant('pending'))();
  TextColumn get etag => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {sessionId, idx};
}

@DataClassName('AppSettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
