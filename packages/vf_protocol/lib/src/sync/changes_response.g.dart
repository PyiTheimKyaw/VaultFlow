// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'changes_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChangeDto _$ChangeDtoFromJson(Map<String, dynamic> json) => _ChangeDto(
  seq: (json['seq'] as num).toInt(),
  entityType: $enumDecode(_$EntityTypeEnumMap, json['entity_type']),
  entityId: json['entity_id'] as String,
  op: $enumDecode(_$SyncOpEnumMap, json['op']),
  version: (json['version'] as num).toInt(),
  deviceId: json['device_id'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  payload:
      json['payload'] as Map<String, dynamic>? ?? const <String, Object?>{},
);

Map<String, dynamic> _$ChangeDtoToJson(_ChangeDto instance) =>
    <String, dynamic>{
      'seq': instance.seq,
      'entity_type': _$EntityTypeEnumMap[instance.entityType]!,
      'entity_id': instance.entityId,
      'op': _$SyncOpEnumMap[instance.op]!,
      'version': instance.version,
      'device_id': instance.deviceId,
      'created_at': instance.createdAt.toIso8601String(),
      'payload': instance.payload,
    };

const _$EntityTypeEnumMap = {
  EntityType.folder: 'folder',
  EntityType.document: 'document',
  EntityType.note: 'note',
};

const _$SyncOpEnumMap = {
  SyncOp.create: 'create',
  SyncOp.update: 'update',
  SyncOp.delete: 'delete',
  SyncOp.move: 'move',
};

_ChangesResponse _$ChangesResponseFromJson(Map<String, dynamic> json) =>
    _ChangesResponse(
      changes: (json['changes'] as List<dynamic>)
          .map((e) => ChangeDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: (json['next_cursor'] as num).toInt(),
      hasMore: json['has_more'] as bool,
    );

Map<String, dynamic> _$ChangesResponseToJson(_ChangesResponse instance) =>
    <String, dynamic>{
      'changes': instance.changes.map((e) => e.toJson()).toList(),
      'next_cursor': instance.nextCursor,
      'has_more': instance.hasMore,
    };
