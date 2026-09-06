// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CredentialsRequest _$CredentialsRequestFromJson(Map<String, dynamic> json) =>
    _CredentialsRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      deviceName: json['device_name'] as String,
      platform: json['platform'] as String,
      deviceId: json['device_id'] as String?,
    );

Map<String, dynamic> _$CredentialsRequestToJson(_CredentialsRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'device_name': instance.deviceName,
      'platform': instance.platform,
      'device_id': ?instance.deviceId,
    };

_RefreshRequest _$RefreshRequestFromJson(Map<String, dynamic> json) =>
    _RefreshRequest(
      refreshToken: json['refresh_token'] as String,
      deviceId: json['device_id'] as String,
    );

Map<String, dynamic> _$RefreshRequestToJson(_RefreshRequest instance) =>
    <String, dynamic>{
      'refresh_token': instance.refreshToken,
      'device_id': instance.deviceId,
    };

_AuthTokens _$AuthTokensFromJson(Map<String, dynamic> json) => _AuthTokens(
  accessToken: json['access_token'] as String,
  refreshToken: json['refresh_token'] as String,
  deviceId: json['device_id'] as String,
  userId: json['user_id'] as String,
  expiresIn: (json['expires_in'] as num).toInt(),
);

Map<String, dynamic> _$AuthTokensToJson(_AuthTokens instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'device_id': instance.deviceId,
      'user_id': instance.userId,
      'expires_in': instance.expiresIn,
    };
