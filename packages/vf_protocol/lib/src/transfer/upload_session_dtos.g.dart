// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_session_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UploadSessionCreateRequest _$UploadSessionCreateRequestFromJson(
  Map<String, dynamic> json,
) => _UploadSessionCreateRequest(
  documentId: json['document_id'] as String,
  totalBytes: (json['total_bytes'] as num).toInt(),
  sha256: json['sha256'] as String,
  mimeType: json['mime_type'] as String,
  chunkSize: (json['chunk_size'] as num).toInt(),
);

Map<String, dynamic> _$UploadSessionCreateRequestToJson(
  _UploadSessionCreateRequest instance,
) => <String, dynamic>{
  'document_id': instance.documentId,
  'total_bytes': instance.totalBytes,
  'sha256': instance.sha256,
  'mime_type': instance.mimeType,
  'chunk_size': instance.chunkSize,
};

_UploadSessionResponse _$UploadSessionResponseFromJson(
  Map<String, dynamic> json,
) => _UploadSessionResponse(
  dedup: json['dedup'] as bool? ?? false,
  uploadId: json['upload_id'] as String?,
  chunkSize: (json['chunk_size'] as num?)?.toInt(),
  expiresAt: json['expires_at'] == null
      ? null
      : DateTime.parse(json['expires_at'] as String),
  storageKey: json['storage_key'] as String?,
);

Map<String, dynamic> _$UploadSessionResponseToJson(
  _UploadSessionResponse instance,
) => <String, dynamic>{
  'dedup': instance.dedup,
  'upload_id': ?instance.uploadId,
  'chunk_size': ?instance.chunkSize,
  'expires_at': ?instance.expiresAt?.toIso8601String(),
  'storage_key': ?instance.storageKey,
};

_UploadSessionStatus _$UploadSessionStatusFromJson(Map<String, dynamic> json) =>
    _UploadSessionStatus(
      uploadId: json['upload_id'] as String,
      state: $enumDecode(_$UploadSessionStateEnumMap, json['state']),
      totalBytes: (json['total_bytes'] as num).toInt(),
      chunkSize: (json['chunk_size'] as num).toInt(),
      receivedChunks: (json['received_chunks'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );

Map<String, dynamic> _$UploadSessionStatusToJson(
  _UploadSessionStatus instance,
) => <String, dynamic>{
  'upload_id': instance.uploadId,
  'state': _$UploadSessionStateEnumMap[instance.state]!,
  'total_bytes': instance.totalBytes,
  'chunk_size': instance.chunkSize,
  'received_chunks': instance.receivedChunks,
  'expires_at': instance.expiresAt.toIso8601String(),
};

const _$UploadSessionStateEnumMap = {
  UploadSessionState.active: 'active',
  UploadSessionState.completed: 'completed',
  UploadSessionState.expired: 'expired',
  UploadSessionState.aborted: 'aborted',
};

_UploadChunkResponse _$UploadChunkResponseFromJson(Map<String, dynamic> json) =>
    _UploadChunkResponse(
      index: (json['index'] as num).toInt(),
      receivedCount: (json['received_count'] as num).toInt(),
      etag: json['etag'] as String?,
    );

Map<String, dynamic> _$UploadChunkResponseToJson(
  _UploadChunkResponse instance,
) => <String, dynamic>{
  'index': instance.index,
  'received_count': instance.receivedCount,
  'etag': ?instance.etag,
};

_UploadCompleteResponse _$UploadCompleteResponseFromJson(
  Map<String, dynamic> json,
) => _UploadCompleteResponse(
  documentId: json['document_id'] as String,
  version: (json['version'] as num).toInt(),
  storageKey: json['storage_key'] as String,
);

Map<String, dynamic> _$UploadCompleteResponseToJson(
  _UploadCompleteResponse instance,
) => <String, dynamic>{
  'document_id': instance.documentId,
  'version': instance.version,
  'storage_key': instance.storageKey,
};
