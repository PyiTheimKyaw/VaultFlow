// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'folder.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Folder {

 String get id; String get name; DateTime get createdAt; DateTime get updatedAt; String? get parentId; int get version; DateTime? get deletedAt; SyncStatus get syncStatus;
/// Create a copy of Folder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FolderCopyWith<Folder> get copyWith => _$FolderCopyWithImpl<Folder>(this as Folder, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Folder;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Folder&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.parentId, _this.parentId) || other.parentId == _this.parentId)&&(identical(other.version, _this.version) || other.version == _this.version)&&(identical(other.deletedAt, _this.deletedAt) || other.deletedAt == _this.deletedAt)&&(identical(other.syncStatus, _this.syncStatus) || other.syncStatus == _this.syncStatus));
}


@override
int get hashCode {
  final _this = this as Folder;
  return Object.hash(runtimeType,_this.id,_this.name,_this.createdAt,_this.updatedAt,_this.parentId,_this.version,_this.deletedAt,_this.syncStatus);
}

@override
String toString() {
  final _this = this as Folder;
  return 'Folder(id: ${_this.id}, name: ${_this.name}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, parentId: ${_this.parentId}, version: ${_this.version}, deletedAt: ${_this.deletedAt}, syncStatus: ${_this.syncStatus})';
}


}

/// @nodoc
abstract mixin class $FolderCopyWith<$Res>  {
  factory $FolderCopyWith(Folder value, $Res Function(Folder) _then) = _$FolderCopyWithImpl;
@useResult
$Res call({
 String id, String name, DateTime createdAt, DateTime updatedAt, String? parentId, int version, DateTime? deletedAt, SyncStatus syncStatus
});




}
/// @nodoc
class _$FolderCopyWithImpl<$Res>
    implements $FolderCopyWith<$Res> {
  _$FolderCopyWithImpl(this._self, this._then);

  final Folder _self;
  final $Res Function(Folder) _then;

/// Create a copy of Folder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? createdAt = null,Object? updatedAt = null,Object? parentId = freezed,Object? version = null,Object? deletedAt = freezed,Object? syncStatus = null,}) {
  return _then(Folder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [Folder].
extension FolderPatterns on Folder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Folder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Folder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Folder value)  $default,){
final _that = this;
switch (_that) {
case _Folder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Folder value)?  $default,){
final _that = this;
switch (_that) {
case _Folder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  DateTime createdAt,  DateTime updatedAt,  String? parentId,  int version,  DateTime? deletedAt,  SyncStatus syncStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Folder() when $default != null:
return $default(_that.id,_that.name,_that.createdAt,_that.updatedAt,_that.parentId,_that.version,_that.deletedAt,_that.syncStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  DateTime createdAt,  DateTime updatedAt,  String? parentId,  int version,  DateTime? deletedAt,  SyncStatus syncStatus)  $default,) {final _that = this;
switch (_that) {
case _Folder():
return $default(_that.id,_that.name,_that.createdAt,_that.updatedAt,_that.parentId,_that.version,_that.deletedAt,_that.syncStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  DateTime createdAt,  DateTime updatedAt,  String? parentId,  int version,  DateTime? deletedAt,  SyncStatus syncStatus)?  $default,) {final _that = this;
switch (_that) {
case _Folder() when $default != null:
return $default(_that.id,_that.name,_that.createdAt,_that.updatedAt,_that.parentId,_that.version,_that.deletedAt,_that.syncStatus);case _:
  return null;

}
}

}

/// @nodoc


class _Folder extends Folder {
  const _Folder({required this.id, required this.name, required this.createdAt, required this.updatedAt, this.parentId, this.version = 0, this.deletedAt, this.syncStatus = SyncStatus.pending}): super._();
  

@override final  String id;
@override final  String name;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  String? parentId;
@override@JsonKey() final  int version;
@override final  DateTime? deletedAt;
@override@JsonKey() final  SyncStatus syncStatus;

/// Create a copy of Folder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FolderCopyWith<_Folder> get copyWith => __$FolderCopyWithImpl<_Folder>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Folder&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.version, version) || other.version == version)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,createdAt,updatedAt,parentId,version,deletedAt,syncStatus);
}

@override
String toString() {
    return 'Folder(id: $id, name: $name, createdAt: $createdAt, updatedAt: $updatedAt, parentId: $parentId, version: $version, deletedAt: $deletedAt, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class _$FolderCopyWith<$Res> implements $FolderCopyWith<$Res> {
  factory _$FolderCopyWith(_Folder value, $Res Function(_Folder) _then) = __$FolderCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, DateTime createdAt, DateTime updatedAt, String? parentId, int version, DateTime? deletedAt, SyncStatus syncStatus
});




}
/// @nodoc
class __$FolderCopyWithImpl<$Res>
    implements _$FolderCopyWith<$Res> {
  __$FolderCopyWithImpl(this._self, this._then);

  final _Folder _self;
  final $Res Function(_Folder) _then;

/// Create a copy of Folder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? createdAt = null,Object? updatedAt = null,Object? parentId = freezed,Object? version = null,Object? deletedAt = freezed,Object? syncStatus = null,}) {
  return _then(_Folder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as SyncStatus,
  ));
}


}

// dart format on
