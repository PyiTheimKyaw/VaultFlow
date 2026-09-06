// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SyncOpRequest _$SyncOpRequestFromJson(Map<String, dynamic> json) =>
    _SyncOpRequest(
      clientOpId: json['client_op_id'] as String,
      entityType: $enumDecode(_$EntityTypeEnumMap, json['entity_type']),
      entityId: json['entity_id'] as String,
      op: $enumDecode(_$SyncOpEnumMap, json['op']),
      baseVersion: (json['base_version'] as num).toInt(),
      payload:
          json['payload'] as Map<String, dynamic>? ?? const <String, Object?>{},
    );

Map<String, dynamic> _$SyncOpRequestToJson(_SyncOpRequest instance) =>
    <String, dynamic>{
      'client_op_id': instance.clientOpId,
      'entity_type': _$EntityTypeEnumMap[instance.entityType]!,
      'entity_id': instance.entityId,
      'op': _$SyncOpEnumMap[instance.op]!,
      'base_version': instance.baseVersion,
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

_PushRequest _$PushRequestFromJson(Map<String, dynamic> json) => _PushRequest(
  deviceId: json['device_id'] as String,
  ops: (json['ops'] as List<dynamic>)
      .map((e) => SyncOpRequest.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PushRequestToJson(_PushRequest instance) =>
    <String, dynamic>{
      'device_id': instance.deviceId,
      'ops': instance.ops.map((e) => e.toJson()).toList(),
    };
