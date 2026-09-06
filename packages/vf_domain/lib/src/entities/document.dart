import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vf_domain/src/entities/sync_status.dart';

part 'document.freezed.dart';

/// A binary file. Bytes live in object storage (server) and optionally in the
/// local cache; this row only holds metadata.
@freezed
abstract class Document with _$Document {
  const factory Document({
    required String id,
    required String name,
    required String mimeType,
    required int sizeBytes,
    required String sha256,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? folderId,
    String? storageKey,
    String? localPath,
    @Default(CacheState.none) CacheState cacheState,
    @Default(0) int version,
    DateTime? deletedAt,
    @Default(SyncStatus.pending) SyncStatus syncStatus,
  }) = _Document;

  const Document._();

  bool get isDeleted => deletedAt != null;
  bool get isAvailableOffline => cacheState == CacheState.complete;
  bool get isUploaded => storageKey != null;
}
