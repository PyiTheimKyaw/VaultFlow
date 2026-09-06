// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DocumentDto {

 String get id; String get folderId; String get name; String get mimeType; int get sizeBytes; String get sha256; int get version; DateTime get createdAt; DateTime get updatedAt;/// Object-storage key; `null` until the upload session completes.
 String? get storageKey; DateTime? get deletedAt;
/// Create a copy of DocumentDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentDtoCopyWith<DocumentDto> get copyWith => _$DocumentDtoCopyWithImpl<DocumentDto>(this as DocumentDto, _$identity);

  /// Serializes this DocumentDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DocumentDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.folderId, _this.folderId) || other.folderId == _this.folderId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.mimeType, _this.mimeType) || other.mimeType == _this.mimeType)&&(identical(other.sizeBytes, _this.sizeBytes) || other.sizeBytes == _this.sizeBytes)&&(identical(other.sha256, _this.sha256) || other.sha256 == _this.sha256)&&(identical(other.version, _this.version) || other.version == _this.version)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.storageKey, _this.storageKey) || other.storageKey == _this.storageKey)&&(identical(other.deletedAt, _this.deletedAt) || other.deletedAt == _this.deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DocumentDto;
  return Object.hash(runtimeType,_this.id,_this.folderId,_this.name,_this.mimeType,_this.sizeBytes,_this.sha256,_this.version,_this.createdAt,_this.updatedAt,_this.storageKey,_this.deletedAt);
}

@override
String toString() {
  final _this = this as DocumentDto;
  return 'DocumentDto(id: ${_this.id}, folderId: ${_this.folderId}, name: ${_this.name}, mimeType: ${_this.mimeType}, sizeBytes: ${_this.sizeBytes}, sha256: ${_this.sha256}, version: ${_this.version}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, storageKey: ${_this.storageKey}, deletedAt: ${_this.deletedAt})';
}


}

/// @nodoc
abstract mixin class $DocumentDtoCopyWith<$Res>  {
  factory $DocumentDtoCopyWith(DocumentDto value, $Res Function(DocumentDto) _then) = _$DocumentDtoCopyWithImpl;
@useResult
$Res call({
 String id, String folderId, String name, String mimeType, int sizeBytes, String sha256, int version, DateTime createdAt, DateTime updatedAt, String? storageKey, DateTime? deletedAt
});




}
/// @nodoc
class _$DocumentDtoCopyWithImpl<$Res>
    implements $DocumentDtoCopyWith<$Res> {
  _$DocumentDtoCopyWithImpl(this._self, this._then);

  final DocumentDto _self;
  final $Res Function(DocumentDto) _then;

/// Create a copy of DocumentDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? folderId = null,Object? name = null,Object? mimeType = null,Object? sizeBytes = null,Object? sha256 = null,Object? version = null,Object? createdAt = null,Object? updatedAt = null,Object? storageKey = freezed,Object? deletedAt = freezed,}) {
  return _then(DocumentDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,folderId: null == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,storageKey: freezed == storageKey ? _self.storageKey : storageKey // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentDto].
extension DocumentDtoPatterns on DocumentDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentDto value)  $default,){
final _that = this;
switch (_that) {
case _DocumentDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentDto value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String folderId,  String name,  String mimeType,  int sizeBytes,  String sha256,  int version,  DateTime createdAt,  DateTime updatedAt,  String? storageKey,  DateTime? deletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentDto() when $default != null:
return $default(_that.id,_that.folderId,_that.name,_that.mimeType,_that.sizeBytes,_that.sha256,_that.version,_that.createdAt,_that.updatedAt,_that.storageKey,_that.deletedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String folderId,  String name,  String mimeType,  int sizeBytes,  String sha256,  int version,  DateTime createdAt,  DateTime updatedAt,  String? storageKey,  DateTime? deletedAt)  $default,) {final _that = this;
switch (_that) {
case _DocumentDto():
return $default(_that.id,_that.folderId,_that.name,_that.mimeType,_that.sizeBytes,_that.sha256,_that.version,_that.createdAt,_that.updatedAt,_that.storageKey,_that.deletedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String folderId,  String name,  String mimeType,  int sizeBytes,  String sha256,  int version,  DateTime createdAt,  DateTime updatedAt,  String? storageKey,  DateTime? deletedAt)?  $default,) {final _that = this;
switch (_that) {
case _DocumentDto() when $default != null:
return $default(_that.id,_that.folderId,_that.name,_that.mimeType,_that.sizeBytes,_that.sha256,_that.version,_that.createdAt,_that.updatedAt,_that.storageKey,_that.deletedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DocumentDto implements DocumentDto {
  const _DocumentDto({required this.id, required this.folderId, required this.name, required this.mimeType, required this.sizeBytes, required this.sha256, required this.version, required this.createdAt, required this.updatedAt, this.storageKey, this.deletedAt});
  factory _DocumentDto.fromJson(Map<String, dynamic> json) => _$DocumentDtoFromJson(json);

@override final  String id;
@override final  String folderId;
@override final  String name;
@override final  String mimeType;
@override final  int sizeBytes;
@override final  String sha256;
@override final  int version;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
/// Object-storage key; `null` until the upload session completes.
@override final  String? storageKey;
@override final  DateTime? deletedAt;

/// Create a copy of DocumentDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentDtoCopyWith<_DocumentDto> get copyWith => __$DocumentDtoCopyWithImpl<_DocumentDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentDto&&(identical(other.id, id) || other.id == id)&&(identical(other.folderId, folderId) || other.folderId == folderId)&&(identical(other.name, name) || other.name == name)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.sha256, sha256) || other.sha256 == sha256)&&(identical(other.version, version) || other.version == version)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.storageKey, storageKey) || other.storageKey == storageKey)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,folderId,name,mimeType,sizeBytes,sha256,version,createdAt,updatedAt,storageKey,deletedAt);
}

@override
String toString() {
    return 'DocumentDto(id: $id, folderId: $folderId, name: $name, mimeType: $mimeType, sizeBytes: $sizeBytes, sha256: $sha256, version: $version, createdAt: $createdAt, updatedAt: $updatedAt, storageKey: $storageKey, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class _$DocumentDtoCopyWith<$Res> implements $DocumentDtoCopyWith<$Res> {
  factory _$DocumentDtoCopyWith(_DocumentDto value, $Res Function(_DocumentDto) _then) = __$DocumentDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String folderId, String name, String mimeType, int sizeBytes, String sha256, int version, DateTime createdAt, DateTime updatedAt, String? storageKey, DateTime? deletedAt
});




}
/// @nodoc
class __$DocumentDtoCopyWithImpl<$Res>
    implements _$DocumentDtoCopyWith<$Res> {
  __$DocumentDtoCopyWithImpl(this._self, this._then);

  final _DocumentDto _self;
  final $Res Function(_DocumentDto) _then;

/// Create a copy of DocumentDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? folderId = null,Object? name = null,Object? mimeType = null,Object? sizeBytes = null,Object? sha256 = null,Object? version = null,Object? createdAt = null,Object? updatedAt = null,Object? storageKey = freezed,Object? deletedAt = freezed,}) {
  return _then(_DocumentDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,folderId: null == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,storageKey: freezed == storageKey ? _self.storageKey : storageKey // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
