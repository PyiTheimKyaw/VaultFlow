// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NoteDto _$NoteDtoFromJson(Map<String, dynamic> json) => _NoteDto(
  id: json['id'] as String,
  title: json['title'] as String,
  body: json['body'] as String,
  version: (json['version'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  folderId: json['folder_id'] as String?,
  deletedAt: json['deleted_at'] == null
      ? null
      : DateTime.parse(json['deleted_at'] as String),
);

Map<String, dynamic> _$NoteDtoToJson(_NoteDto instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'body': instance.body,
  'version': instance.version,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'folder_id': ?instance.folderId,
  'deleted_at': ?instance.deletedAt?.toIso8601String(),
};
