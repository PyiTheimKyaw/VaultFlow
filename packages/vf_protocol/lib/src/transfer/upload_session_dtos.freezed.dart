// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'upload_session_dtos.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UploadSessionCreateRequest {

 String get documentId; int get totalBytes; String get sha256; String get mimeType; int get chunkSize;
/// Create a copy of UploadSessionCreateRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UploadSessionCreateRequestCopyWith<UploadSessionCreateRequest> get copyWith => _$UploadSessionCreateRequestCopyWithImpl<UploadSessionCreateRequest>(this as UploadSessionCreateRequest, _$identity);

  /// Serializes this UploadSessionCreateRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as UploadSessionCreateRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UploadSessionCreateRequest&&(identical(other.documentId, _this.documentId) || other.documentId == _this.documentId)&&(identical(other.totalBytes, _this.totalBytes) || other.totalBytes == _this.totalBytes)&&(identical(other.sha256, _this.sha256) || other.sha256 == _this.sha256)&&(identical(other.mimeType, _this.mimeType) || other.mimeType == _this.mimeType)&&(identical(other.chunkSize, _this.chunkSize) || other.chunkSize == _this.chunkSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UploadSessionCreateRequest;
  return Object.hash(runtimeType,_this.documentId,_this.totalBytes,_this.sha256,_this.mimeType,_this.chunkSize);
}

@override
String toString() {
  final _this = this as UploadSessionCreateRequest;
  return 'UploadSessionCreateRequest(documentId: ${_this.documentId}, totalBytes: ${_this.totalBytes}, sha256: ${_this.sha256}, mimeType: ${_this.mimeType}, chunkSize: ${_this.chunkSize})';
}


}

/// @nodoc
abstract mixin class $UploadSessionCreateRequestCopyWith<$Res>  {
  factory $UploadSessionCreateRequestCopyWith(UploadSessionCreateRequest value, $Res Function(UploadSessionCreateRequest) _then) = _$UploadSessionCreateRequestCopyWithImpl;
@useResult
$Res call({
 String documentId, int totalBytes, String sha256, String mimeType, int chunkSize
});




}
/// @nodoc
class _$UploadSessionCreateRequestCopyWithImpl<$Res>
    implements $UploadSessionCreateRequestCopyWith<$Res> {
  _$UploadSessionCreateRequestCopyWithImpl(this._self, this._then);

  final UploadSessionCreateRequest _self;
  final $Res Function(UploadSessionCreateRequest) _then;

/// Create a copy of UploadSessionCreateRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? documentId = null,Object? totalBytes = null,Object? sha256 = null,Object? mimeType = null,Object? chunkSize = null,}) {
  return _then(UploadSessionCreateRequest(
documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,totalBytes: null == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,chunkSize: null == chunkSize ? _self.chunkSize : chunkSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [UploadSessionCreateRequest].
extension UploadSessionCreateRequestPatterns on UploadSessionCreateRequest {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UploadSessionCreateRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UploadSessionCreateRequest() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UploadSessionCreateRequest value)  $default,){
final _that = this;
switch (_that) {
case _UploadSessionCreateRequest():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UploadSessionCreateRequest value)?  $default,){
final _that = this;
switch (_that) {
case _UploadSessionCreateRequest() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String documentId,  int totalBytes,  String sha256,  String mimeType,  int chunkSize)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UploadSessionCreateRequest() when $default != null:
return $default(_that.documentId,_that.totalBytes,_that.sha256,_that.mimeType,_that.chunkSize);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String documentId,  int totalBytes,  String sha256,  String mimeType,  int chunkSize)  $default,) {final _that = this;
switch (_that) {
case _UploadSessionCreateRequest():
return $default(_that.documentId,_that.totalBytes,_that.sha256,_that.mimeType,_that.chunkSize);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String documentId,  int totalBytes,  String sha256,  String mimeType,  int chunkSize)?  $default,) {final _that = this;
switch (_that) {
case _UploadSessionCreateRequest() when $default != null:
return $default(_that.documentId,_that.totalBytes,_that.sha256,_that.mimeType,_that.chunkSize);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UploadSessionCreateRequest implements UploadSessionCreateRequest {
  const _UploadSessionCreateRequest({required this.documentId, required this.totalBytes, required this.sha256, required this.mimeType, required this.chunkSize});
  factory _UploadSessionCreateRequest.fromJson(Map<String, dynamic> json) => _$UploadSessionCreateRequestFromJson(json);

@override final  String documentId;
@override final  int totalBytes;
@override final  String sha256;
@override final  String mimeType;
@override final  int chunkSize;

/// Create a copy of UploadSessionCreateRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UploadSessionCreateRequestCopyWith<_UploadSessionCreateRequest> get copyWith => __$UploadSessionCreateRequestCopyWithImpl<_UploadSessionCreateRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UploadSessionCreateRequestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UploadSessionCreateRequest&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.totalBytes, totalBytes) || other.totalBytes == totalBytes)&&(identical(other.sha256, sha256) || other.sha256 == sha256)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.chunkSize, chunkSize) || other.chunkSize == chunkSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,documentId,totalBytes,sha256,mimeType,chunkSize);
}

@override
String toString() {
    return 'UploadSessionCreateRequest(documentId: $documentId, totalBytes: $totalBytes, sha256: $sha256, mimeType: $mimeType, chunkSize: $chunkSize)';
}


}

/// @nodoc
abstract mixin class _$UploadSessionCreateRequestCopyWith<$Res> implements $UploadSessionCreateRequestCopyWith<$Res> {
  factory _$UploadSessionCreateRequestCopyWith(_UploadSessionCreateRequest value, $Res Function(_UploadSessionCreateRequest) _then) = __$UploadSessionCreateRequestCopyWithImpl;
@override @useResult
$Res call({
 String documentId, int totalBytes, String sha256, String mimeType, int chunkSize
});




}
/// @nodoc
class __$UploadSessionCreateRequestCopyWithImpl<$Res>
    implements _$UploadSessionCreateRequestCopyWith<$Res> {
  __$UploadSessionCreateRequestCopyWithImpl(this._self, this._then);

  final _UploadSessionCreateRequest _self;
  final $Res Function(_UploadSessionCreateRequest) _then;

/// Create a copy of UploadSessionCreateRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? documentId = null,Object? totalBytes = null,Object? sha256 = null,Object? mimeType = null,Object? chunkSize = null,}) {
  return _then(_UploadSessionCreateRequest(
documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,totalBytes: null == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,chunkSize: null == chunkSize ? _self.chunkSize : chunkSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$UploadSessionResponse {

 bool get dedup; String? get uploadId; int? get chunkSize; DateTime? get expiresAt; String? get storageKey;
/// Create a copy of UploadSessionResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UploadSessionResponseCopyWith<UploadSessionResponse> get copyWith => _$UploadSessionResponseCopyWithImpl<UploadSessionResponse>(this as UploadSessionResponse, _$identity);

  /// Serializes this UploadSessionResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as UploadSessionResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UploadSessionResponse&&(identical(other.dedup, _this.dedup) || other.dedup == _this.dedup)&&(identical(other.uploadId, _this.uploadId) || other.uploadId == _this.uploadId)&&(identical(other.chunkSize, _this.chunkSize) || other.chunkSize == _this.chunkSize)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.storageKey, _this.storageKey) || other.storageKey == _this.storageKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UploadSessionResponse;
  return Object.hash(runtimeType,_this.dedup,_this.uploadId,_this.chunkSize,_this.expiresAt,_this.storageKey);
}

@override
String toString() {
  final _this = this as UploadSessionResponse;
  return 'UploadSessionResponse(dedup: ${_this.dedup}, uploadId: ${_this.uploadId}, chunkSize: ${_this.chunkSize}, expiresAt: ${_this.expiresAt}, storageKey: ${_this.storageKey})';
}


}

/// @nodoc
abstract mixin class $UploadSessionResponseCopyWith<$Res>  {
  factory $UploadSessionResponseCopyWith(UploadSessionResponse value, $Res Function(UploadSessionResponse) _then) = _$UploadSessionResponseCopyWithImpl;
@useResult
$Res call({
 bool dedup, String? uploadId, int? chunkSize, DateTime? expiresAt, String? storageKey
});




}
/// @nodoc
class _$UploadSessionResponseCopyWithImpl<$Res>
    implements $UploadSessionResponseCopyWith<$Res> {
  _$UploadSessionResponseCopyWithImpl(this._self, this._then);

  final UploadSessionResponse _self;
  final $Res Function(UploadSessionResponse) _then;

/// Create a copy of UploadSessionResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dedup = null,Object? uploadId = freezed,Object? chunkSize = freezed,Object? expiresAt = freezed,Object? storageKey = freezed,}) {
  return _then(UploadSessionResponse(
dedup: null == dedup ? _self.dedup : dedup // ignore: cast_nullable_to_non_nullable
as bool,uploadId: freezed == uploadId ? _self.uploadId : uploadId // ignore: cast_nullable_to_non_nullable
as String?,chunkSize: freezed == chunkSize ? _self.chunkSize : chunkSize // ignore: cast_nullable_to_non_nullable
as int?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,storageKey: freezed == storageKey ? _self.storageKey : storageKey // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UploadSessionResponse].
extension UploadSessionResponsePatterns on UploadSessionResponse {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UploadSessionResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UploadSessionResponse() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UploadSessionResponse value)  $default,){
final _that = this;
switch (_that) {
case _UploadSessionResponse():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UploadSessionResponse value)?  $default,){
final _that = this;
switch (_that) {
case _UploadSessionResponse() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool dedup,  String? uploadId,  int? chunkSize,  DateTime? expiresAt,  String? storageKey)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UploadSessionResponse() when $default != null:
return $default(_that.dedup,_that.uploadId,_that.chunkSize,_that.expiresAt,_that.storageKey);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool dedup,  String? uploadId,  int? chunkSize,  DateTime? expiresAt,  String? storageKey)  $default,) {final _that = this;
switch (_that) {
case _UploadSessionResponse():
return $default(_that.dedup,_that.uploadId,_that.chunkSize,_that.expiresAt,_that.storageKey);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool dedup,  String? uploadId,  int? chunkSize,  DateTime? expiresAt,  String? storageKey)?  $default,) {final _that = this;
switch (_that) {
case _UploadSessionResponse() when $default != null:
return $default(_that.dedup,_that.uploadId,_that.chunkSize,_that.expiresAt,_that.storageKey);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UploadSessionResponse implements UploadSessionResponse {
  const _UploadSessionResponse({this.dedup = false, this.uploadId, this.chunkSize, this.expiresAt, this.storageKey});
  factory _UploadSessionResponse.fromJson(Map<String, dynamic> json) => _$UploadSessionResponseFromJson(json);

@override@JsonKey() final  bool dedup;
@override final  String? uploadId;
@override final  int? chunkSize;
@override final  DateTime? expiresAt;
@override final  String? storageKey;

/// Create a copy of UploadSessionResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UploadSessionResponseCopyWith<_UploadSessionResponse> get copyWith => __$UploadSessionResponseCopyWithImpl<_UploadSessionResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UploadSessionResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UploadSessionResponse&&(identical(other.dedup, dedup) || other.dedup == dedup)&&(identical(other.uploadId, uploadId) || other.uploadId == uploadId)&&(identical(other.chunkSize, chunkSize) || other.chunkSize == chunkSize)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.storageKey, storageKey) || other.storageKey == storageKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,dedup,uploadId,chunkSize,expiresAt,storageKey);
}

@override
String toString() {
    return 'UploadSessionResponse(dedup: $dedup, uploadId: $uploadId, chunkSize: $chunkSize, expiresAt: $expiresAt, storageKey: $storageKey)';
}


}

/// @nodoc
abstract mixin class _$UploadSessionResponseCopyWith<$Res> implements $UploadSessionResponseCopyWith<$Res> {
  factory _$UploadSessionResponseCopyWith(_UploadSessionResponse value, $Res Function(_UploadSessionResponse) _then) = __$UploadSessionResponseCopyWithImpl;
@override @useResult
$Res call({
 bool dedup, String? uploadId, int? chunkSize, DateTime? expiresAt, String? storageKey
});




}
/// @nodoc
class __$UploadSessionResponseCopyWithImpl<$Res>
    implements _$UploadSessionResponseCopyWith<$Res> {
  __$UploadSessionResponseCopyWithImpl(this._self, this._then);

  final _UploadSessionResponse _self;
  final $Res Function(_UploadSessionResponse) _then;

/// Create a copy of UploadSessionResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dedup = null,Object? uploadId = freezed,Object? chunkSize = freezed,Object? expiresAt = freezed,Object? storageKey = freezed,}) {
  return _then(_UploadSessionResponse(
dedup: null == dedup ? _self.dedup : dedup // ignore: cast_nullable_to_non_nullable
as bool,uploadId: freezed == uploadId ? _self.uploadId : uploadId // ignore: cast_nullable_to_non_nullable
as String?,chunkSize: freezed == chunkSize ? _self.chunkSize : chunkSize // ignore: cast_nullable_to_non_nullable
as int?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,storageKey: freezed == storageKey ? _self.storageKey : storageKey // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$UploadSessionStatus {

 String get uploadId; UploadSessionState get state; int get totalBytes; int get chunkSize; List<int> get receivedChunks; DateTime get expiresAt;
/// Create a copy of UploadSessionStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UploadSessionStatusCopyWith<UploadSessionStatus> get copyWith => _$UploadSessionStatusCopyWithImpl<UploadSessionStatus>(this as UploadSessionStatus, _$identity);

  /// Serializes this UploadSessionStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as UploadSessionStatus;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UploadSessionStatus&&(identical(other.uploadId, _this.uploadId) || other.uploadId == _this.uploadId)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.totalBytes, _this.totalBytes) || other.totalBytes == _this.totalBytes)&&(identical(other.chunkSize, _this.chunkSize) || other.chunkSize == _this.chunkSize)&&const DeepCollectionEquality().equals(other.receivedChunks, _this.receivedChunks)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UploadSessionStatus;
  return Object.hash(runtimeType,_this.uploadId,_this.state,_this.totalBytes,_this.chunkSize,const DeepCollectionEquality().hash(_this.receivedChunks),_this.expiresAt);
}

@override
String toString() {
  final _this = this as UploadSessionStatus;
  return 'UploadSessionStatus(uploadId: ${_this.uploadId}, state: ${_this.state}, totalBytes: ${_this.totalBytes}, chunkSize: ${_this.chunkSize}, receivedChunks: ${_this.receivedChunks}, expiresAt: ${_this.expiresAt})';
}


}

/// @nodoc
abstract mixin class $UploadSessionStatusCopyWith<$Res>  {
  factory $UploadSessionStatusCopyWith(UploadSessionStatus value, $Res Function(UploadSessionStatus) _then) = _$UploadSessionStatusCopyWithImpl;
@useResult
$Res call({
 String uploadId, UploadSessionState state, int totalBytes, int chunkSize, List<int> receivedChunks, DateTime expiresAt
});




}
/// @nodoc
class _$UploadSessionStatusCopyWithImpl<$Res>
    implements $UploadSessionStatusCopyWith<$Res> {
  _$UploadSessionStatusCopyWithImpl(this._self, this._then);

  final UploadSessionStatus _self;
  final $Res Function(UploadSessionStatus) _then;

/// Create a copy of UploadSessionStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uploadId = null,Object? state = null,Object? totalBytes = null,Object? chunkSize = null,Object? receivedChunks = null,Object? expiresAt = null,}) {
  return _then(UploadSessionStatus(
uploadId: null == uploadId ? _self.uploadId : uploadId // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as UploadSessionState,totalBytes: null == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int,chunkSize: null == chunkSize ? _self.chunkSize : chunkSize // ignore: cast_nullable_to_non_nullable
as int,receivedChunks: null == receivedChunks ? _self.receivedChunks : receivedChunks // ignore: cast_nullable_to_non_nullable
as List<int>,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [UploadSessionStatus].
extension UploadSessionStatusPatterns on UploadSessionStatus {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UploadSessionStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UploadSessionStatus() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UploadSessionStatus value)  $default,){
final _that = this;
switch (_that) {
case _UploadSessionStatus():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UploadSessionStatus value)?  $default,){
final _that = this;
switch (_that) {
case _UploadSessionStatus() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uploadId,  UploadSessionState state,  int totalBytes,  int chunkSize,  List<int> receivedChunks,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UploadSessionStatus() when $default != null:
return $default(_that.uploadId,_that.state,_that.totalBytes,_that.chunkSize,_that.receivedChunks,_that.expiresAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uploadId,  UploadSessionState state,  int totalBytes,  int chunkSize,  List<int> receivedChunks,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _UploadSessionStatus():
return $default(_that.uploadId,_that.state,_that.totalBytes,_that.chunkSize,_that.receivedChunks,_that.expiresAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uploadId,  UploadSessionState state,  int totalBytes,  int chunkSize,  List<int> receivedChunks,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _UploadSessionStatus() when $default != null:
return $default(_that.uploadId,_that.state,_that.totalBytes,_that.chunkSize,_that.receivedChunks,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UploadSessionStatus implements UploadSessionStatus {
  const _UploadSessionStatus({required this.uploadId, required this.state, required this.totalBytes, required this.chunkSize, required  List<int> receivedChunks, required this.expiresAt}): _receivedChunks = receivedChunks;
  factory _UploadSessionStatus.fromJson(Map<String, dynamic> json) => _$UploadSessionStatusFromJson(json);

@override final  String uploadId;
@override final  UploadSessionState state;
@override final  int totalBytes;
@override final  int chunkSize;
 final  List<int> _receivedChunks;
@override List<int> get receivedChunks {
  if (_receivedChunks is EqualUnmodifiableListView) return _receivedChunks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_receivedChunks);
}

@override final  DateTime expiresAt;

/// Create a copy of UploadSessionStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UploadSessionStatusCopyWith<_UploadSessionStatus> get copyWith => __$UploadSessionStatusCopyWithImpl<_UploadSessionStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UploadSessionStatusToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UploadSessionStatus&&(identical(other.uploadId, uploadId) || other.uploadId == uploadId)&&(identical(other.state, state) || other.state == state)&&(identical(other.totalBytes, totalBytes) || other.totalBytes == totalBytes)&&(identical(other.chunkSize, chunkSize) || other.chunkSize == chunkSize)&&const DeepCollectionEquality().equals(other.receivedChunks, _receivedChunks)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,uploadId,state,totalBytes,chunkSize,const DeepCollectionEquality().hash(_receivedChunks),expiresAt);
}

@override
String toString() {
    return 'UploadSessionStatus(uploadId: $uploadId, state: $state, totalBytes: $totalBytes, chunkSize: $chunkSize, receivedChunks: $receivedChunks, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$UploadSessionStatusCopyWith<$Res> implements $UploadSessionStatusCopyWith<$Res> {
  factory _$UploadSessionStatusCopyWith(_UploadSessionStatus value, $Res Function(_UploadSessionStatus) _then) = __$UploadSessionStatusCopyWithImpl;
@override @useResult
$Res call({
 String uploadId, UploadSessionState state, int totalBytes, int chunkSize, List<int> receivedChunks, DateTime expiresAt
});




}
/// @nodoc
class __$UploadSessionStatusCopyWithImpl<$Res>
    implements _$UploadSessionStatusCopyWith<$Res> {
  __$UploadSessionStatusCopyWithImpl(this._self, this._then);

  final _UploadSessionStatus _self;
  final $Res Function(_UploadSessionStatus) _then;

/// Create a copy of UploadSessionStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uploadId = null,Object? state = null,Object? totalBytes = null,Object? chunkSize = null,Object? receivedChunks = null,Object? expiresAt = null,}) {
  return _then(_UploadSessionStatus(
uploadId: null == uploadId ? _self.uploadId : uploadId // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as UploadSessionState,totalBytes: null == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int,chunkSize: null == chunkSize ? _self.chunkSize : chunkSize // ignore: cast_nullable_to_non_nullable
as int,receivedChunks: null == receivedChunks ? _self._receivedChunks : receivedChunks // ignore: cast_nullable_to_non_nullable
as List<int>,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$UploadChunkResponse {

 int get index; int get receivedCount; String? get etag;
/// Create a copy of UploadChunkResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UploadChunkResponseCopyWith<UploadChunkResponse> get copyWith => _$UploadChunkResponseCopyWithImpl<UploadChunkResponse>(this as UploadChunkResponse, _$identity);

  /// Serializes this UploadChunkResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as UploadChunkResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UploadChunkResponse&&(identical(other.index, _this.index) || other.index == _this.index)&&(identical(other.receivedCount, _this.receivedCount) || other.receivedCount == _this.receivedCount)&&(identical(other.etag, _this.etag) || other.etag == _this.etag));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UploadChunkResponse;
  return Object.hash(runtimeType,_this.index,_this.receivedCount,_this.etag);
}

@override
String toString() {
  final _this = this as UploadChunkResponse;
  return 'UploadChunkResponse(index: ${_this.index}, receivedCount: ${_this.receivedCount}, etag: ${_this.etag})';
}


}

/// @nodoc
abstract mixin class $UploadChunkResponseCopyWith<$Res>  {
  factory $UploadChunkResponseCopyWith(UploadChunkResponse value, $Res Function(UploadChunkResponse) _then) = _$UploadChunkResponseCopyWithImpl;
@useResult
$Res call({
 int index, int receivedCount, String? etag
});




}
/// @nodoc
class _$UploadChunkResponseCopyWithImpl<$Res>
    implements $UploadChunkResponseCopyWith<$Res> {
  _$UploadChunkResponseCopyWithImpl(this._self, this._then);

  final UploadChunkResponse _self;
  final $Res Function(UploadChunkResponse) _then;

/// Create a copy of UploadChunkResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? receivedCount = null,Object? etag = freezed,}) {
  return _then(UploadChunkResponse(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,receivedCount: null == receivedCount ? _self.receivedCount : receivedCount // ignore: cast_nullable_to_non_nullable
as int,etag: freezed == etag ? _self.etag : etag // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UploadChunkResponse].
extension UploadChunkResponsePatterns on UploadChunkResponse {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UploadChunkResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UploadChunkResponse() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UploadChunkResponse value)  $default,){
final _that = this;
switch (_that) {
case _UploadChunkResponse():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UploadChunkResponse value)?  $default,){
final _that = this;
switch (_that) {
case _UploadChunkResponse() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int index,  int receivedCount,  String? etag)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UploadChunkResponse() when $default != null:
return $default(_that.index,_that.receivedCount,_that.etag);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int index,  int receivedCount,  String? etag)  $default,) {final _that = this;
switch (_that) {
case _UploadChunkResponse():
return $default(_that.index,_that.receivedCount,_that.etag);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int index,  int receivedCount,  String? etag)?  $default,) {final _that = this;
switch (_that) {
case _UploadChunkResponse() when $default != null:
return $default(_that.index,_that.receivedCount,_that.etag);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UploadChunkResponse implements UploadChunkResponse {
  const _UploadChunkResponse({required this.index, required this.receivedCount, this.etag});
  factory _UploadChunkResponse.fromJson(Map<String, dynamic> json) => _$UploadChunkResponseFromJson(json);

@override final  int index;
@override final  int receivedCount;
@override final  String? etag;

/// Create a copy of UploadChunkResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UploadChunkResponseCopyWith<_UploadChunkResponse> get copyWith => __$UploadChunkResponseCopyWithImpl<_UploadChunkResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UploadChunkResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UploadChunkResponse&&(identical(other.index, index) || other.index == index)&&(identical(other.receivedCount, receivedCount) || other.receivedCount == receivedCount)&&(identical(other.etag, etag) || other.etag == etag));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,index,receivedCount,etag);
}

@override
String toString() {
    return 'UploadChunkResponse(index: $index, receivedCount: $receivedCount, etag: $etag)';
}


}

/// @nodoc
abstract mixin class _$UploadChunkResponseCopyWith<$Res> implements $UploadChunkResponseCopyWith<$Res> {
  factory _$UploadChunkResponseCopyWith(_UploadChunkResponse value, $Res Function(_UploadChunkResponse) _then) = __$UploadChunkResponseCopyWithImpl;
@override @useResult
$Res call({
 int index, int receivedCount, String? etag
});




}
/// @nodoc
class __$UploadChunkResponseCopyWithImpl<$Res>
    implements _$UploadChunkResponseCopyWith<$Res> {
  __$UploadChunkResponseCopyWithImpl(this._self, this._then);

  final _UploadChunkResponse _self;
  final $Res Function(_UploadChunkResponse) _then;

/// Create a copy of UploadChunkResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? index = null,Object? receivedCount = null,Object? etag = freezed,}) {
  return _then(_UploadChunkResponse(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,receivedCount: null == receivedCount ? _self.receivedCount : receivedCount // ignore: cast_nullable_to_non_nullable
as int,etag: freezed == etag ? _self.etag : etag // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$UploadCompleteResponse {

 String get documentId; int get version; String get storageKey;
/// Create a copy of UploadCompleteResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UploadCompleteResponseCopyWith<UploadCompleteResponse> get copyWith => _$UploadCompleteResponseCopyWithImpl<UploadCompleteResponse>(this as UploadCompleteResponse, _$identity);

  /// Serializes this UploadCompleteResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as UploadCompleteResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UploadCompleteResponse&&(identical(other.documentId, _this.documentId) || other.documentId == _this.documentId)&&(identical(other.version, _this.version) || other.version == _this.version)&&(identical(other.storageKey, _this.storageKey) || other.storageKey == _this.storageKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UploadCompleteResponse;
  return Object.hash(runtimeType,_this.documentId,_this.version,_this.storageKey);
}

@override
String toString() {
  final _this = this as UploadCompleteResponse;
  return 'UploadCompleteResponse(documentId: ${_this.documentId}, version: ${_this.version}, storageKey: ${_this.storageKey})';
}


}

/// @nodoc
abstract mixin class $UploadCompleteResponseCopyWith<$Res>  {
  factory $UploadCompleteResponseCopyWith(UploadCompleteResponse value, $Res Function(UploadCompleteResponse) _then) = _$UploadCompleteResponseCopyWithImpl;
@useResult
$Res call({
 String documentId, int version, String storageKey
});




}
/// @nodoc
class _$UploadCompleteResponseCopyWithImpl<$Res>
    implements $UploadCompleteResponseCopyWith<$Res> {
  _$UploadCompleteResponseCopyWithImpl(this._self, this._then);

  final UploadCompleteResponse _self;
  final $Res Function(UploadCompleteResponse) _then;

/// Create a copy of UploadCompleteResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? documentId = null,Object? version = null,Object? storageKey = null,}) {
  return _then(UploadCompleteResponse(
documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,storageKey: null == storageKey ? _self.storageKey : storageKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UploadCompleteResponse].
extension UploadCompleteResponsePatterns on UploadCompleteResponse {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UploadCompleteResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UploadCompleteResponse() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UploadCompleteResponse value)  $default,){
final _that = this;
switch (_that) {
case _UploadCompleteResponse():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UploadCompleteResponse value)?  $default,){
final _that = this;
switch (_that) {
case _UploadCompleteResponse() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String documentId,  int version,  String storageKey)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UploadCompleteResponse() when $default != null:
return $default(_that.documentId,_that.version,_that.storageKey);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String documentId,  int version,  String storageKey)  $default,) {final _that = this;
switch (_that) {
case _UploadCompleteResponse():
return $default(_that.documentId,_that.version,_that.storageKey);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String documentId,  int version,  String storageKey)?  $default,) {final _that = this;
switch (_that) {
case _UploadCompleteResponse() when $default != null:
return $default(_that.documentId,_that.version,_that.storageKey);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UploadCompleteResponse implements UploadCompleteResponse {
  const _UploadCompleteResponse({required this.documentId, required this.version, required this.storageKey});
  factory _UploadCompleteResponse.fromJson(Map<String, dynamic> json) => _$UploadCompleteResponseFromJson(json);

@override final  String documentId;
@override final  int version;
@override final  String storageKey;

/// Create a copy of UploadCompleteResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UploadCompleteResponseCopyWith<_UploadCompleteResponse> get copyWith => __$UploadCompleteResponseCopyWithImpl<_UploadCompleteResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UploadCompleteResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UploadCompleteResponse&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.version, version) || other.version == version)&&(identical(other.storageKey, storageKey) || other.storageKey == storageKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,documentId,version,storageKey);
}

@override
String toString() {
    return 'UploadCompleteResponse(documentId: $documentId, version: $version, storageKey: $storageKey)';
}


}

/// @nodoc
abstract mixin class _$UploadCompleteResponseCopyWith<$Res> implements $UploadCompleteResponseCopyWith<$Res> {
  factory _$UploadCompleteResponseCopyWith(_UploadCompleteResponse value, $Res Function(_UploadCompleteResponse) _then) = __$UploadCompleteResponseCopyWithImpl;
@override @useResult
$Res call({
 String documentId, int version, String storageKey
});




}
/// @nodoc
class __$UploadCompleteResponseCopyWithImpl<$Res>
    implements _$UploadCompleteResponseCopyWith<$Res> {
  __$UploadCompleteResponseCopyWithImpl(this._self, this._then);

  final _UploadCompleteResponse _self;
  final $Res Function(_UploadCompleteResponse) _then;

/// Create a copy of UploadCompleteResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? documentId = null,Object? version = null,Object? storageKey = null,}) {
  return _then(_UploadCompleteResponse(
documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,storageKey: null == storageKey ? _self.storageKey : storageKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
