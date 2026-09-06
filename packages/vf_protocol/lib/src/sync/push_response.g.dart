// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SyncOpResult _$SyncOpResultFromJson(Map<String, dynamic> json) =>
    _SyncOpResult(
      clientOpId: json['client_op_id'] as String,
      status: $enumDecode(_$SyncOpStatusEnumMap, json['status']),
      newVersion: (json['new_version'] as num?)?.toInt(),
      remote: json['remote'] as Map<String, dynamic>?,
      remoteVersion: (json['remote_version'] as num?)?.toInt(),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$SyncOpResultToJson(_SyncOpResult instance) =>
    <String, dynamic>{
      'client_op_id': instance.clientOpId,
      'status': _$SyncOpStatusEnumMap[instance.status]!,
      'new_version': ?instance.newVersion,
      'remote': ?instance.remote,
      'remote_version': ?instance.remoteVersion,
      'error': ?instance.error,
    };

const _$SyncOpStatusEnumMap = {
  SyncOpStatus.applied: 'applied',
  SyncOpStatus.conflict: 'conflict',
  SyncOpStatus.rejected: 'rejected',
};

_PushResponse _$PushResponseFromJson(Map<String, dynamic> json) =>
    _PushResponse(
      results: (json['results'] as List<dynamic>)
          .map((e) => SyncOpResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PushResponseToJson(_PushResponse instance) =>
    <String, dynamic>{
      'results': instance.results.map((e) => e.toJson()).toList(),
    };
