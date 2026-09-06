// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DocumentDto _$DocumentDtoFromJson(Map<String, dynamic> json) => _DocumentDto(
  id: json['id'] as String,
  folderId: json['folder_id'] as String,
  name: json['name'] as String,
  mimeType: json['mime_type'] as String,
  sizeBytes: (json['size_bytes'] as num).toInt(),
  sha256: json['sha256'] as String,
  version: (json['version'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  storageKey: json['storage_key'] as String?,
  deletedAt: json['deleted_at'] == null
      ? null
      : DateTime.parse(json['deleted_at'] as String),
);

Map<String, dynamic> _$DocumentDtoToJson(_DocumentDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'folder_id': instance.folderId,
      'name': instance.name,
      'mime_type': instance.mimeType,
      'size_bytes': instance.sizeBytes,
      'sha256': instance.sha256,
      'version': instance.version,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'storage_key': ?instance.storageKey,
      'deleted_at': ?instance.deletedAt?.toIso8601String(),
    };
