import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vf_protocol/vf_protocol.dart';

part 'conflict.freezed.dart';

/// How the user resolved a conflict.
enum ConflictResolution { keepLocal, keepRemote, keepBoth }

/// A push that the server rejected because its version moved on. Both
/// snapshots are kept so the resolver UI can show a diff.
@freezed
abstract class Conflict with _$Conflict {
  const factory Conflict({
    required String id,
    required EntityType entityType,
    required String entityId,
    required Map<String, Object?> localSnapshot,
    required Map<String, Object?> remoteSnapshot,
    required int remoteVersion,
    required DateTime createdAt,
    DateTime? resolvedAt,
    ConflictResolution? resolution,
  }) = _Conflict;

  const Conflict._();

  bool get isResolved => resolvedAt != null;
}
