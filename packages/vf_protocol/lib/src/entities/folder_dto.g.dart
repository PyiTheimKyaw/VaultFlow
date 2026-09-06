// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FolderDto _$FolderDtoFromJson(Map<String, dynamic> json) => _FolderDto(
  id: json['id'] as String,
  name: json['name'] as String,
  version: (json['version'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  parentId: json['parent_id'] as String?,
  deletedAt: json['deleted_at'] == null
      ? null
      : DateTime.parse(json['deleted_at'] as String),
);

Map<String, dynamic> _$FolderDtoToJson(_FolderDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'version': instance.version,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'parent_id': ?instance.parentId,
      'deleted_at': ?instance.deletedAt?.toIso8601String(),
    };
