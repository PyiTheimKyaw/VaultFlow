// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Document {

 String get id; String get name; String get mimeType; int get sizeBytes; String get sha256; DateTime get createdAt; DateTime get updatedAt; String? get folderId; String? get storageKey; String? get localPath; CacheState get cacheState; int get version; DateTime? get deletedAt; SyncStatus get syncStatus;
/// Create a copy of Document
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentCopyWith<Document> get copyWith => _$DocumentCopyWithImpl<Document>(this as Document, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Document;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Document&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.mimeType, _this.mimeType) || other.mimeType == _this.mimeType)&&(identical(other.sizeBytes, _this.sizeBytes) || other.sizeBytes == _this.sizeBytes)&&(identical(other.sha256, _this.sha256) || other.sha256 == _this.sha256)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.folderId, _this.folderId) || other.folderId == _this.folderId)&&(identical(other.storageKey, _this.storageKey) || other.storageKey == _this.storageKey)&&(identical(other.localPath, _this.localPath) || other.localPath == _this.localPath)&&(identical(other.cacheState, _this.cacheState) || other.cacheState == _this.cacheState)&&(identical(other.version, _this.version) || other.version == _this.version)&&(identical(other.deletedAt, _this.deletedAt) || other.deletedAt == _this.deletedAt)&&(identical(other.syncStatus, _this.syncStatus) || other.syncStatus == _this.syncStatus));
}


@override
int get hashCode {
  final _this = this as Document;
  return Object.hash(runtimeType,_this.id,_this.name,_this.mimeType,_this.sizeBytes,_this.sha256,_this.createdAt,_this.updatedAt,_this.folderId,_this.storageKey,_this.localPath,_this.cacheState,_this.version,_this.deletedAt,_this.syncStatus);
}

@override
String toString() {
  final _this = this as Document;
  return 'Document(id: ${_this.id}, name: ${_this.name}, mimeType: ${_this.mimeType}, sizeBytes: ${_this.sizeBytes}, sha256: ${_this.sha256}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, folderId: ${_this.folderId}, storageKey: ${_this.storageKey}, localPath: ${_this.localPath}, cacheState: ${_this.cacheState}, version: ${_this.version}, deletedAt: ${_this.deletedAt}, syncStatus: ${_this.syncStatus})';
}


}

/// @nodoc
abstract mixin class $DocumentCopyWith<$Res>  {
  factory $DocumentCopyWith(Document value, $Res Function(Document) _then) = _$DocumentCopyWithImpl;
@useResult
$Res call({
 String id, String name, String mimeType, int sizeBytes, String sha256, DateTime createdAt, DateTime updatedAt, String? folderId, String? storageKey, String? localPath, CacheState cacheState, int version, DateTime? deletedAt, SyncStatus syncStatus
});




}
/// @nodoc
class _$DocumentCopyWithImpl<$Res>
    implements $DocumentCopyWith<$Res> {
  _$DocumentCopyWithImpl(this._self, this._then);

  final Document _self;
  final $Res Function(Document) _then;

/// Create a copy of Document
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? mimeType = null,Object? sizeBytes = null,Object? sha256 = null,Object? createdAt = null,Object? updatedAt = null,Object? folderId = freezed,Object? storageKey = freezed,Object? localPath = freezed,Object? cacheState = null,Object? version = null,Object? deletedAt = freezed,Object? syncStatus = null,}) {
  return _then(Document(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,folderId: freezed == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String?,storageKey: freezed == storageKey ? _self.storageKey : storageKey // ignore: cast_nullable_to_non_nullable
as String?,localPath: freezed == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String?,cacheState: null == cacheState ? _self.cacheState : cacheState // ignore: cast_nullable_to_non_nullable
as CacheState,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [Document].
extension DocumentPatterns on Document {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Document value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Document() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Document value)  $default,){
final _that = this;
switch (_that) {
case _Document():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Document value)?  $default,){
final _that = this;
switch (_that) {
case _Document() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String mimeType,  int sizeBytes,  String sha256,  DateTime createdAt,  DateTime updatedAt,  String? folderId,  String? storageKey,  String? localPath,  CacheState cacheState,  int version,  DateTime? deletedAt,  SyncStatus syncStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Document() when $default != null:
return $default(_that.id,_that.name,_that.mimeType,_that.sizeBytes,_that.sha256,_that.createdAt,_that.updatedAt,_that.folderId,_that.storageKey,_that.localPath,_that.cacheState,_that.version,_that.deletedAt,_that.syncStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String mimeType,  int sizeBytes,  String sha256,  DateTime createdAt,  DateTime updatedAt,  String? folderId,  String? storageKey,  String? localPath,  CacheState cacheState,  int version,  DateTime? deletedAt,  SyncStatus syncStatus)  $default,) {final _that = this;
switch (_that) {
case _Document():
return $default(_that.id,_that.name,_that.mimeType,_that.sizeBytes,_that.sha256,_that.createdAt,_that.updatedAt,_that.folderId,_that.storageKey,_that.localPath,_that.cacheState,_that.version,_that.deletedAt,_that.syncStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String mimeType,  int sizeBytes,  String sha256,  DateTime createdAt,  DateTime updatedAt,  String? folderId,  String? storageKey,  String? localPath,  CacheState cacheState,  int version,  DateTime? deletedAt,  SyncStatus syncStatus)?  $default,) {final _that = this;
switch (_that) {
case _Document() when $default != null:
return $default(_that.id,_that.name,_that.mimeType,_that.sizeBytes,_that.sha256,_that.createdAt,_that.updatedAt,_that.folderId,_that.storageKey,_that.localPath,_that.cacheState,_that.version,_that.deletedAt,_that.syncStatus);case _:
  return null;

}
}

}

/// @nodoc


class _Document extends Document {
  const _Document({required this.id, required this.name, required this.mimeType, required this.sizeBytes, required this.sha256, required this.createdAt, required this.updatedAt, this.folderId, this.storageKey, this.localPath, this.cacheState = CacheState.none, this.version = 0, this.deletedAt, this.syncStatus = SyncStatus.pending}): super._();
  

@override final  String id;
@override final  String name;
@override final  String mimeType;
@override final  int sizeBytes;
@override final  String sha256;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  String? folderId;
@override final  String? storageKey;
@override final  String? localPath;
@override@JsonKey() final  CacheState cacheState;
@override@JsonKey() final  int version;
@override final  DateTime? deletedAt;
@override@JsonKey() final  SyncStatus syncStatus;

/// Create a copy of Document
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentCopyWith<_Document> get copyWith => __$DocumentCopyWithImpl<_Document>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Document&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.sha256, sha256) || other.sha256 == sha256)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.folderId, folderId) || other.folderId == folderId)&&(identical(other.storageKey, storageKey) || other.storageKey == storageKey)&&(identical(other.localPath, localPath) || other.localPath == localPath)&&(identical(other.cacheState, cacheState) || other.cacheState == cacheState)&&(identical(other.version, version) || other.version == version)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,mimeType,sizeBytes,sha256,createdAt,updatedAt,folderId,storageKey,localPath,cacheState,version,deletedAt,syncStatus);
}

@override
String toString() {
    return 'Document(id: $id, name: $name, mimeType: $mimeType, sizeBytes: $sizeBytes, sha256: $sha256, createdAt: $createdAt, updatedAt: $updatedAt, folderId: $folderId, storageKey: $storageKey, localPath: $localPath, cacheState: $cacheState, version: $version, deletedAt: $deletedAt, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class _$DocumentCopyWith<$Res> implements $DocumentCopyWith<$Res> {
  factory _$DocumentCopyWith(_Document value, $Res Function(_Document) _then) = __$DocumentCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String mimeType, int sizeBytes, String sha256, DateTime createdAt, DateTime updatedAt, String? folderId, String? storageKey, String? localPath, CacheState cacheState, int version, DateTime? deletedAt, SyncStatus syncStatus
});




}
/// @nodoc
class __$DocumentCopyWithImpl<$Res>
    implements _$DocumentCopyWith<$Res> {
  __$DocumentCopyWithImpl(this._self, this._then);

  final _Document _self;
  final $Res Function(_Document) _then;

/// Create a copy of Document
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? mimeType = null,Object? sizeBytes = null,Object? sha256 = null,Object? createdAt = null,Object? updatedAt = null,Object? folderId = freezed,Object? storageKey = freezed,Object? localPath = freezed,Object? cacheState = null,Object? version = null,Object? deletedAt = freezed,Object? syncStatus = null,}) {
  return _then(_Document(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,folderId: freezed == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String?,storageKey: freezed == storageKey ? _self.storageKey : storageKey // ignore: cast_nullable_to_non_nullable
as String?,localPath: freezed == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String?,cacheState: null == cacheState ? _self.cacheState : cacheState // ignore: cast_nullable_to_non_nullable
as CacheState,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,
  ));
}


}

// dart format on
