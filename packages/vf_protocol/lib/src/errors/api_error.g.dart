// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ApiError _$ApiErrorFromJson(Map<String, dynamic> json) => _ApiError(
  code: $enumDecode(_$ApiErrorCodeEnumMap, json['code']),
  message: json['message'] as String,
  details: json['details'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ApiErrorToJson(_ApiError instance) => <String, dynamic>{
  'code': _$ApiErrorCodeEnumMap[instance.code]!,
  'message': instance.message,
  'details': ?instance.details,
};

const _$ApiErrorCodeEnumMap = {
  ApiErrorCode.badRequest: 'bad_request',
  ApiErrorCode.validationFailed: 'validation_failed',
  ApiErrorCode.unauthorized: 'unauthorized',
  ApiErrorCode.tokenExpired: 'token_expired',
  ApiErrorCode.tokenRevoked: 'token_revoked',
  ApiErrorCode.forbidden: 'forbidden',
  ApiErrorCode.notFound: 'not_found',
  ApiErrorCode.conflict: 'conflict',
  ApiErrorCode.emailTaken: 'email_taken',
  ApiErrorCode.payloadTooLarge: 'payload_too_large',
  ApiErrorCode.uploadExpired: 'upload_expired',
  ApiErrorCode.chunkMismatch: 'chunk_mismatch',
  ApiErrorCode.hashMismatch: 'hash_mismatch',
  ApiErrorCode.rateLimited: 'rate_limited',
  ApiErrorCode.protocolUnsupported: 'protocol_unsupported',
  ApiErrorCode.internal: 'internal',
};
