// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conflict.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Conflict {

 String get id; EntityType get entityType; String get entityId; Map<String, Object?> get localSnapshot; Map<String, Object?> get remoteSnapshot; int get remoteVersion; DateTime get createdAt; DateTime? get resolvedAt; ConflictResolution? get resolution;
/// Create a copy of Conflict
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConflictCopyWith<Conflict> get copyWith => _$ConflictCopyWithImpl<Conflict>(this as Conflict, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Conflict;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Conflict&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.entityType, _this.entityType) || other.entityType == _this.entityType)&&(identical(other.entityId, _this.entityId) || other.entityId == _this.entityId)&&const DeepCollectionEquality().equals(other.localSnapshot, _this.localSnapshot)&&const DeepCollectionEquality().equals(other.remoteSnapshot, _this.remoteSnapshot)&&(identical(other.remoteVersion, _this.remoteVersion) || other.remoteVersion == _this.remoteVersion)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.resolvedAt, _this.resolvedAt) || other.resolvedAt == _this.resolvedAt)&&(identical(other.resolution, _this.resolution) || other.resolution == _this.resolution));
}


@override
int get hashCode {
  final _this = this as Conflict;
  return Object.hash(runtimeType,_this.id,_this.entityType,_this.entityId,const DeepCollectionEquality().hash(_this.localSnapshot),const DeepCollectionEquality().hash(_this.remoteSnapshot),_this.remoteVersion,_this.createdAt,_this.resolvedAt,_this.resolution);
}

@override
String toString() {
  final _this = this as Conflict;
  return 'Conflict(id: ${_this.id}, entityType: ${_this.entityType}, entityId: ${_this.entityId}, localSnapshot: ${_this.localSnapshot}, remoteSnapshot: ${_this.remoteSnapshot}, remoteVersion: ${_this.remoteVersion}, createdAt: ${_this.createdAt}, resolvedAt: ${_this.resolvedAt}, resolution: ${_this.resolution})';
}


}

/// @nodoc
abstract mixin class $ConflictCopyWith<$Res>  {
  factory $ConflictCopyWith(Conflict value, $Res Function(Conflict) _then) = _$ConflictCopyWithImpl;
@useResult
$Res call({
 String id, EntityType entityType, String entityId, Map<String, Object?> localSnapshot, Map<String, Object?> remoteSnapshot, int remoteVersion, DateTime createdAt, DateTime? resolvedAt, ConflictResolution? resolution
});




}
/// @nodoc
class _$ConflictCopyWithImpl<$Res>
    implements $ConflictCopyWith<$Res> {
  _$ConflictCopyWithImpl(this._self, this._then);

  final Conflict _self;
  final $Res Function(Conflict) _then;

/// Create a copy of Conflict
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? entityType = null,Object? entityId = null,Object? localSnapshot = null,Object? remoteSnapshot = null,Object? remoteVersion = null,Object? createdAt = null,Object? resolvedAt = freezed,Object? resolution = freezed,}) {
  return _then(Conflict(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,localSnapshot: null == localSnapshot ? _self.localSnapshot : localSnapshot // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,remoteSnapshot: null == remoteSnapshot ? _self.remoteSnapshot : remoteSnapshot // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,remoteVersion: null == remoteVersion ? _self.remoteVersion : remoteVersion // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resolution: freezed == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as ConflictResolution?,
  ));
}

}


/// Adds pattern-matching-related methods to [Conflict].
extension ConflictPatterns on Conflict {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Conflict value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Conflict() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Conflict value)  $default,){
final _that = this;
switch (_that) {
case _Conflict():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Conflict value)?  $default,){
final _that = this;
switch (_that) {
case _Conflict() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  EntityType entityType,  String entityId,  Map<String, Object?> localSnapshot,  Map<String, Object?> remoteSnapshot,  int remoteVersion,  DateTime createdAt,  DateTime? resolvedAt,  ConflictResolution? resolution)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Conflict() when $default != null:
return $default(_that.id,_that.entityType,_that.entityId,_that.localSnapshot,_that.remoteSnapshot,_that.remoteVersion,_that.createdAt,_that.resolvedAt,_that.resolution);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  EntityType entityType,  String entityId,  Map<String, Object?> localSnapshot,  Map<String, Object?> remoteSnapshot,  int remoteVersion,  DateTime createdAt,  DateTime? resolvedAt,  ConflictResolution? resolution)  $default,) {final _that = this;
switch (_that) {
case _Conflict():
return $default(_that.id,_that.entityType,_that.entityId,_that.localSnapshot,_that.remoteSnapshot,_that.remoteVersion,_that.createdAt,_that.resolvedAt,_that.resolution);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  EntityType entityType,  String entityId,  Map<String, Object?> localSnapshot,  Map<String, Object?> remoteSnapshot,  int remoteVersion,  DateTime createdAt,  DateTime? resolvedAt,  ConflictResolution? resolution)?  $default,) {final _that = this;
switch (_that) {
case _Conflict() when $default != null:
return $default(_that.id,_that.entityType,_that.entityId,_that.localSnapshot,_that.remoteSnapshot,_that.remoteVersion,_that.createdAt,_that.resolvedAt,_that.resolution);case _:
  return null;

}
}

}

/// @nodoc


class _Conflict extends Conflict {
  const _Conflict({required this.id, required this.entityType, required this.entityId, required  Map<String, Object?> localSnapshot, required  Map<String, Object?> remoteSnapshot, required this.remoteVersion, required this.createdAt, this.resolvedAt, this.resolution}): _localSnapshot = localSnapshot,_remoteSnapshot = remoteSnapshot,super._();
  

@override final  String id;
@override final  EntityType entityType;
@override final  String entityId;
 final  Map<String, Object?> _localSnapshot;
@override Map<String, Object?> get localSnapshot {
  if (_localSnapshot is EqualUnmodifiableMapView) return _localSnapshot;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_localSnapshot);
}

 final  Map<String, Object?> _remoteSnapshot;
@override Map<String, Object?> get remoteSnapshot {
  if (_remoteSnapshot is EqualUnmodifiableMapView) return _remoteSnapshot;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_remoteSnapshot);
}

@override final  int remoteVersion;
@override final  DateTime createdAt;
@override final  DateTime? resolvedAt;
@override final  ConflictResolution? resolution;

/// Create a copy of Conflict
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConflictCopyWith<_Conflict> get copyWith => __$ConflictCopyWithImpl<_Conflict>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Conflict&&(identical(other.id, id) || other.id == id)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&const DeepCollectionEquality().equals(other.localSnapshot, _localSnapshot)&&const DeepCollectionEquality().equals(other.remoteSnapshot, _remoteSnapshot)&&(identical(other.remoteVersion, remoteVersion) || other.remoteVersion == remoteVersion)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.resolvedAt, resolvedAt) || other.resolvedAt == resolvedAt)&&(identical(other.resolution, resolution) || other.resolution == resolution));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,entityType,entityId,const DeepCollectionEquality().hash(_localSnapshot),const DeepCollectionEquality().hash(_remoteSnapshot),remoteVersion,createdAt,resolvedAt,resolution);
}

@override
String toString() {
    return 'Conflict(id: $id, entityType: $entityType, entityId: $entityId, localSnapshot: $localSnapshot, remoteSnapshot: $remoteSnapshot, remoteVersion: $remoteVersion, createdAt: $createdAt, resolvedAt: $resolvedAt, resolution: $resolution)';
}


}

/// @nodoc
abstract mixin class _$ConflictCopyWith<$Res> implements $ConflictCopyWith<$Res> {
  factory _$ConflictCopyWith(_Conflict value, $Res Function(_Conflict) _then) = __$ConflictCopyWithImpl;
@override @useResult
$Res call({
 String id, EntityType entityType, String entityId, Map<String, Object?> localSnapshot, Map<String, Object?> remoteSnapshot, int remoteVersion, DateTime createdAt, DateTime? resolvedAt, ConflictResolution? resolution
});




}
/// @nodoc
class __$ConflictCopyWithImpl<$Res>
    implements _$ConflictCopyWith<$Res> {
  __$ConflictCopyWithImpl(this._self, this._then);

  final _Conflict _self;
  final $Res Function(_Conflict) _then;

/// Create a copy of Conflict
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? entityType = null,Object? entityId = null,Object? localSnapshot = null,Object? remoteSnapshot = null,Object? remoteVersion = null,Object? createdAt = null,Object? resolvedAt = freezed,Object? resolution = freezed,}) {
  return _then(_Conflict(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,localSnapshot: null == localSnapshot ? _self._localSnapshot : localSnapshot // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,remoteSnapshot: null == remoteSnapshot ? _self._remoteSnapshot : remoteSnapshot // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,remoteVersion: null == remoteVersion ? _self.remoteVersion : remoteVersion // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resolution: freezed == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as ConflictResolution?,
  ));
}


}

// dart format on
