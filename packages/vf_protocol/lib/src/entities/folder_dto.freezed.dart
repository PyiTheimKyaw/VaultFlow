// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'folder_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FolderDto {

 String get id; String get name; int get version; DateTime get createdAt; DateTime get updatedAt; String? get parentId; DateTime? get deletedAt;
/// Create a copy of FolderDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FolderDtoCopyWith<FolderDto> get copyWith => _$FolderDtoCopyWithImpl<FolderDto>(this as FolderDto, _$identity);

  /// Serializes this FolderDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as FolderDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.version, _this.version) || other.version == _this.version)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.parentId, _this.parentId) || other.parentId == _this.parentId)&&(identical(other.deletedAt, _this.deletedAt) || other.deletedAt == _this.deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FolderDto;
  return Object.hash(runtimeType,_this.id,_this.name,_this.version,_this.createdAt,_this.updatedAt,_this.parentId,_this.deletedAt);
}

@override
String toString() {
  final _this = this as FolderDto;
  return 'FolderDto(id: ${_this.id}, name: ${_this.name}, version: ${_this.version}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, parentId: ${_this.parentId}, deletedAt: ${_this.deletedAt})';
}


}

/// @nodoc
abstract mixin class $FolderDtoCopyWith<$Res>  {
  factory $FolderDtoCopyWith(FolderDto value, $Res Function(FolderDto) _then) = _$FolderDtoCopyWithImpl;
@useResult
$Res call({
 String id, String name, int version, DateTime createdAt, DateTime updatedAt, String? parentId, DateTime? deletedAt
});




}
/// @nodoc
class _$FolderDtoCopyWithImpl<$Res>
    implements $FolderDtoCopyWith<$Res> {
  _$FolderDtoCopyWithImpl(this._self, this._then);

  final FolderDto _self;
  final $Res Function(FolderDto) _then;

/// Create a copy of FolderDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? version = null,Object? createdAt = null,Object? updatedAt = null,Object? parentId = freezed,Object? deletedAt = freezed,}) {
  return _then(FolderDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [FolderDto].
extension FolderDtoPatterns on FolderDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FolderDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FolderDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FolderDto value)  $default,){
final _that = this;
switch (_that) {
case _FolderDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FolderDto value)?  $default,){
final _that = this;
switch (_that) {
case _FolderDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int version,  DateTime createdAt,  DateTime updatedAt,  String? parentId,  DateTime? deletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FolderDto() when $default != null:
return $default(_that.id,_that.name,_that.version,_that.createdAt,_that.updatedAt,_that.parentId,_that.deletedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int version,  DateTime createdAt,  DateTime updatedAt,  String? parentId,  DateTime? deletedAt)  $default,) {final _that = this;
switch (_that) {
case _FolderDto():
return $default(_that.id,_that.name,_that.version,_that.createdAt,_that.updatedAt,_that.parentId,_that.deletedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int version,  DateTime createdAt,  DateTime updatedAt,  String? parentId,  DateTime? deletedAt)?  $default,) {final _that = this;
switch (_that) {
case _FolderDto() when $default != null:
return $default(_that.id,_that.name,_that.version,_that.createdAt,_that.updatedAt,_that.parentId,_that.deletedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FolderDto implements FolderDto {
  const _FolderDto({required this.id, required this.name, required this.version, required this.createdAt, required this.updatedAt, this.parentId, this.deletedAt});
  factory _FolderDto.fromJson(Map<String, dynamic> json) => _$FolderDtoFromJson(json);

@override final  String id;
@override final  String name;
@override final  int version;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  String? parentId;
@override final  DateTime? deletedAt;

/// Create a copy of FolderDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FolderDtoCopyWith<_FolderDto> get copyWith => __$FolderDtoCopyWithImpl<_FolderDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FolderDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FolderDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.version, version) || other.version == version)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,version,createdAt,updatedAt,parentId,deletedAt);
}

@override
String toString() {
    return 'FolderDto(id: $id, name: $name, version: $version, createdAt: $createdAt, updatedAt: $updatedAt, parentId: $parentId, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class _$FolderDtoCopyWith<$Res> implements $FolderDtoCopyWith<$Res> {
  factory _$FolderDtoCopyWith(_FolderDto value, $Res Function(_FolderDto) _then) = __$FolderDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int version, DateTime createdAt, DateTime updatedAt, String? parentId, DateTime? deletedAt
});




}
/// @nodoc
class __$FolderDtoCopyWithImpl<$Res>
    implements _$FolderDtoCopyWith<$Res> {
  __$FolderDtoCopyWithImpl(this._self, this._then);

  final _FolderDto _self;
  final $Res Function(_FolderDto) _then;

/// Create a copy of FolderDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? version = null,Object? createdAt = null,Object? updatedAt = null,Object? parentId = freezed,Object? deletedAt = freezed,}) {
  return _then(_FolderDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
