// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_url_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DownloadUrlResponse _$DownloadUrlResponseFromJson(Map<String, dynamic> json) =>
    _DownloadUrlResponse(
      url: json['url'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );

Map<String, dynamic> _$DownloadUrlResponseToJson(
  _DownloadUrlResponse instance,
) => <String, dynamic>{
  'url': instance.url,
  'expires_at': instance.expiresAt.toIso8601String(),
};

_SyncEvent _$SyncEventFromJson(Map<String, dynamic> json) =>
    _SyncEvent(seq: (json['seq'] as num).toInt());

Map<String, dynamic> _$SyncEventToJson(_SyncEvent instance) =>
    <String, dynamic>{'seq': instance.seq};
