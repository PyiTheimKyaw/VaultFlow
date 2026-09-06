// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'note_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NoteDto {

 String get id; String get folderId; String get title; String get body; int get version; DateTime get createdAt; DateTime get updatedAt; DateTime? get deletedAt;
/// Create a copy of NoteDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NoteDtoCopyWith<NoteDto> get copyWith => _$NoteDtoCopyWithImpl<NoteDto>(this as NoteDto, _$identity);

  /// Serializes this NoteDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NoteDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NoteDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.folderId, _this.folderId) || other.folderId == _this.folderId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.body, _this.body) || other.body == _this.body)&&(identical(other.version, _this.version) || other.version == _this.version)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.deletedAt, _this.deletedAt) || other.deletedAt == _this.deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NoteDto;
  return Object.hash(runtimeType,_this.id,_this.folderId,_this.title,_this.body,_this.version,_this.createdAt,_this.updatedAt,_this.deletedAt);
}

@override
String toString() {
  final _this = this as NoteDto;
  return 'NoteDto(id: ${_this.id}, folderId: ${_this.folderId}, title: ${_this.title}, body: ${_this.body}, version: ${_this.version}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, deletedAt: ${_this.deletedAt})';
}


}

/// @nodoc
abstract mixin class $NoteDtoCopyWith<$Res>  {
  factory $NoteDtoCopyWith(NoteDto value, $Res Function(NoteDto) _then) = _$NoteDtoCopyWithImpl;
@useResult
$Res call({
 String id, String folderId, String title, String body, int version, DateTime createdAt, DateTime updatedAt, DateTime? deletedAt
});




}
/// @nodoc
class _$NoteDtoCopyWithImpl<$Res>
    implements $NoteDtoCopyWith<$Res> {
  _$NoteDtoCopyWithImpl(this._self, this._then);

  final NoteDto _self;
  final $Res Function(NoteDto) _then;

/// Create a copy of NoteDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? folderId = null,Object? title = null,Object? body = null,Object? version = null,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,}) {
  return _then(NoteDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,folderId: null == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [NoteDto].
extension NoteDtoPatterns on NoteDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NoteDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NoteDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NoteDto value)  $default,){
final _that = this;
switch (_that) {
case _NoteDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NoteDto value)?  $default,){
final _that = this;
switch (_that) {
case _NoteDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String folderId,  String title,  String body,  int version,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NoteDto() when $default != null:
return $default(_that.id,_that.folderId,_that.title,_that.body,_that.version,_that.createdAt,_that.updatedAt,_that.deletedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String folderId,  String title,  String body,  int version,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt)  $default,) {final _that = this;
switch (_that) {
case _NoteDto():
return $default(_that.id,_that.folderId,_that.title,_that.body,_that.version,_that.createdAt,_that.updatedAt,_that.deletedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String folderId,  String title,  String body,  int version,  DateTime createdAt,  DateTime updatedAt,  DateTime? deletedAt)?  $default,) {final _that = this;
switch (_that) {
case _NoteDto() when $default != null:
return $default(_that.id,_that.folderId,_that.title,_that.body,_that.version,_that.createdAt,_that.updatedAt,_that.deletedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NoteDto implements NoteDto {
  const _NoteDto({required this.id, required this.folderId, required this.title, required this.body, required this.version, required this.createdAt, required this.updatedAt, this.deletedAt});
  factory _NoteDto.fromJson(Map<String, dynamic> json) => _$NoteDtoFromJson(json);

@override final  String id;
@override final  String folderId;
@override final  String title;
@override final  String body;
@override final  int version;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  DateTime? deletedAt;

/// Create a copy of NoteDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NoteDtoCopyWith<_NoteDto> get copyWith => __$NoteDtoCopyWithImpl<_NoteDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NoteDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NoteDto&&(identical(other.id, id) || other.id == id)&&(identical(other.folderId, folderId) || other.folderId == folderId)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.version, version) || other.version == version)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,folderId,title,body,version,createdAt,updatedAt,deletedAt);
}

@override
String toString() {
    return 'NoteDto(id: $id, folderId: $folderId, title: $title, body: $body, version: $version, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class _$NoteDtoCopyWith<$Res> implements $NoteDtoCopyWith<$Res> {
  factory _$NoteDtoCopyWith(_NoteDto value, $Res Function(_NoteDto) _then) = __$NoteDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String folderId, String title, String body, int version, DateTime createdAt, DateTime updatedAt, DateTime? deletedAt
});




}
/// @nodoc
class __$NoteDtoCopyWithImpl<$Res>
    implements _$NoteDtoCopyWith<$Res> {
  __$NoteDtoCopyWithImpl(this._self, this._then);

  final _NoteDto _self;
  final $Res Function(_NoteDto) _then;

/// Create a copy of NoteDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? folderId = null,Object? title = null,Object? body = null,Object? version = null,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,}) {
  return _then(_NoteDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,folderId: null == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
