// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'changes_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChangeDto {

/// Monotonic sequence number; the pull cursor.
 int get seq; EntityType get entityType; String get entityId; SyncOp get op; int get version; String get deviceId; DateTime get createdAt;/// Entity snapshot after the change (empty for deletes).
 Map<String, Object?> get payload;
/// Create a copy of ChangeDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChangeDtoCopyWith<ChangeDto> get copyWith => _$ChangeDtoCopyWithImpl<ChangeDto>(this as ChangeDto, _$identity);

  /// Serializes this ChangeDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChangeDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangeDto&&(identical(other.seq, _this.seq) || other.seq == _this.seq)&&(identical(other.entityType, _this.entityType) || other.entityType == _this.entityType)&&(identical(other.entityId, _this.entityId) || other.entityId == _this.entityId)&&(identical(other.op, _this.op) || other.op == _this.op)&&(identical(other.version, _this.version) || other.version == _this.version)&&(identical(other.deviceId, _this.deviceId) || other.deviceId == _this.deviceId)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&const DeepCollectionEquality().equals(other.payload, _this.payload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChangeDto;
  return Object.hash(runtimeType,_this.seq,_this.entityType,_this.entityId,_this.op,_this.version,_this.deviceId,_this.createdAt,const DeepCollectionEquality().hash(_this.payload));
}

@override
String toString() {
  final _this = this as ChangeDto;
  return 'ChangeDto(seq: ${_this.seq}, entityType: ${_this.entityType}, entityId: ${_this.entityId}, op: ${_this.op}, version: ${_this.version}, deviceId: ${_this.deviceId}, createdAt: ${_this.createdAt}, payload: ${_this.payload})';
}


}

/// @nodoc
abstract mixin class $ChangeDtoCopyWith<$Res>  {
  factory $ChangeDtoCopyWith(ChangeDto value, $Res Function(ChangeDto) _then) = _$ChangeDtoCopyWithImpl;
@useResult
$Res call({
 int seq, EntityType entityType, String entityId, SyncOp op, int version, String deviceId, DateTime createdAt, Map<String, Object?> payload
});




}
/// @nodoc
class _$ChangeDtoCopyWithImpl<$Res>
    implements $ChangeDtoCopyWith<$Res> {
  _$ChangeDtoCopyWithImpl(this._self, this._then);

  final ChangeDto _self;
  final $Res Function(ChangeDto) _then;

/// Create a copy of ChangeDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? seq = null,Object? entityType = null,Object? entityId = null,Object? op = null,Object? version = null,Object? deviceId = null,Object? createdAt = null,Object? payload = null,}) {
  return _then(ChangeDto(
seq: null == seq ? _self.seq : seq // ignore: cast_nullable_to_non_nullable
as int,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,op: null == op ? _self.op : op // ignore: cast_nullable_to_non_nullable
as SyncOp,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [ChangeDto].
extension ChangeDtoPatterns on ChangeDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChangeDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChangeDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChangeDto value)  $default,){
final _that = this;
switch (_that) {
case _ChangeDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChangeDto value)?  $default,){
final _that = this;
switch (_that) {
case _ChangeDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int seq,  EntityType entityType,  String entityId,  SyncOp op,  int version,  String deviceId,  DateTime createdAt,  Map<String, Object?> payload)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChangeDto() when $default != null:
return $default(_that.seq,_that.entityType,_that.entityId,_that.op,_that.version,_that.deviceId,_that.createdAt,_that.payload);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int seq,  EntityType entityType,  String entityId,  SyncOp op,  int version,  String deviceId,  DateTime createdAt,  Map<String, Object?> payload)  $default,) {final _that = this;
switch (_that) {
case _ChangeDto():
return $default(_that.seq,_that.entityType,_that.entityId,_that.op,_that.version,_that.deviceId,_that.createdAt,_that.payload);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int seq,  EntityType entityType,  String entityId,  SyncOp op,  int version,  String deviceId,  DateTime createdAt,  Map<String, Object?> payload)?  $default,) {final _that = this;
switch (_that) {
case _ChangeDto() when $default != null:
return $default(_that.seq,_that.entityType,_that.entityId,_that.op,_that.version,_that.deviceId,_that.createdAt,_that.payload);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChangeDto implements ChangeDto {
  const _ChangeDto({required this.seq, required this.entityType, required this.entityId, required this.op, required this.version, required this.deviceId, required this.createdAt,  Map<String, Object?> payload = const <String, Object?>{}}): _payload = payload;
  factory _ChangeDto.fromJson(Map<String, dynamic> json) => _$ChangeDtoFromJson(json);

/// Monotonic sequence number; the pull cursor.
@override final  int seq;
@override final  EntityType entityType;
@override final  String entityId;
@override final  SyncOp op;
@override final  int version;
@override final  String deviceId;
@override final  DateTime createdAt;
/// Entity snapshot after the change (empty for deletes).
 final  Map<String, Object?> _payload;
/// Entity snapshot after the change (empty for deletes).
@override@JsonKey() Map<String, Object?> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}


/// Create a copy of ChangeDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChangeDtoCopyWith<_ChangeDto> get copyWith => __$ChangeDtoCopyWithImpl<_ChangeDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChangeDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChangeDto&&(identical(other.seq, seq) || other.seq == seq)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.op, op) || other.op == op)&&(identical(other.version, version) || other.version == version)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.payload, _payload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,seq,entityType,entityId,op,version,deviceId,createdAt,const DeepCollectionEquality().hash(_payload));
}

@override
String toString() {
    return 'ChangeDto(seq: $seq, entityType: $entityType, entityId: $entityId, op: $op, version: $version, deviceId: $deviceId, createdAt: $createdAt, payload: $payload)';
}


}

/// @nodoc
abstract mixin class _$ChangeDtoCopyWith<$Res> implements $ChangeDtoCopyWith<$Res> {
  factory _$ChangeDtoCopyWith(_ChangeDto value, $Res Function(_ChangeDto) _then) = __$ChangeDtoCopyWithImpl;
@override @useResult
$Res call({
 int seq, EntityType entityType, String entityId, SyncOp op, int version, String deviceId, DateTime createdAt, Map<String, Object?> payload
});




}
/// @nodoc
class __$ChangeDtoCopyWithImpl<$Res>
    implements _$ChangeDtoCopyWith<$Res> {
  __$ChangeDtoCopyWithImpl(this._self, this._then);

  final _ChangeDto _self;
  final $Res Function(_ChangeDto) _then;

/// Create a copy of ChangeDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? seq = null,Object? entityType = null,Object? entityId = null,Object? op = null,Object? version = null,Object? deviceId = null,Object? createdAt = null,Object? payload = null,}) {
  return _then(_ChangeDto(
seq: null == seq ? _self.seq : seq // ignore: cast_nullable_to_non_nullable
as int,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,op: null == op ? _self.op : op // ignore: cast_nullable_to_non_nullable
as SyncOp,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}


}


/// @nodoc
mixin _$ChangesResponse {

 List<ChangeDto> get changes;/// Pass as `since` on the next call.
 int get nextCursor; bool get hasMore;
/// Create a copy of ChangesResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChangesResponseCopyWith<ChangesResponse> get copyWith => _$ChangesResponseCopyWithImpl<ChangesResponse>(this as ChangesResponse, _$identity);

  /// Serializes this ChangesResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChangesResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangesResponse&&const DeepCollectionEquality().equals(other.changes, _this.changes)&&(identical(other.nextCursor, _this.nextCursor) || other.nextCursor == _this.nextCursor)&&(identical(other.hasMore, _this.hasMore) || other.hasMore == _this.hasMore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChangesResponse;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.changes),_this.nextCursor,_this.hasMore);
}

@override
String toString() {
  final _this = this as ChangesResponse;
  return 'ChangesResponse(changes: ${_this.changes}, nextCursor: ${_this.nextCursor}, hasMore: ${_this.hasMore})';
}


}

/// @nodoc
abstract mixin class $ChangesResponseCopyWith<$Res>  {
  factory $ChangesResponseCopyWith(ChangesResponse value, $Res Function(ChangesResponse) _then) = _$ChangesResponseCopyWithImpl;
@useResult
$Res call({
 List<ChangeDto> changes, int nextCursor, bool hasMore
});




}
/// @nodoc
class _$ChangesResponseCopyWithImpl<$Res>
    implements $ChangesResponseCopyWith<$Res> {
  _$ChangesResponseCopyWithImpl(this._self, this._then);

  final ChangesResponse _self;
  final $Res Function(ChangesResponse) _then;

/// Create a copy of ChangesResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? changes = null,Object? nextCursor = null,Object? hasMore = null,}) {
  return _then(ChangesResponse(
changes: null == changes ? _self.changes : changes // ignore: cast_nullable_to_non_nullable
as List<ChangeDto>,nextCursor: null == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ChangesResponse].
extension ChangesResponsePatterns on ChangesResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChangesResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChangesResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChangesResponse value)  $default,){
final _that = this;
switch (_that) {
case _ChangesResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChangesResponse value)?  $default,){
final _that = this;
switch (_that) {
case _ChangesResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ChangeDto> changes,  int nextCursor,  bool hasMore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChangesResponse() when $default != null:
return $default(_that.changes,_that.nextCursor,_that.hasMore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ChangeDto> changes,  int nextCursor,  bool hasMore)  $default,) {final _that = this;
switch (_that) {
case _ChangesResponse():
return $default(_that.changes,_that.nextCursor,_that.hasMore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ChangeDto> changes,  int nextCursor,  bool hasMore)?  $default,) {final _that = this;
switch (_that) {
case _ChangesResponse() when $default != null:
return $default(_that.changes,_that.nextCursor,_that.hasMore);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChangesResponse implements ChangesResponse {
  const _ChangesResponse({required  List<ChangeDto> changes, required this.nextCursor, required this.hasMore}): _changes = changes;
  factory _ChangesResponse.fromJson(Map<String, dynamic> json) => _$ChangesResponseFromJson(json);

 final  List<ChangeDto> _changes;
@override List<ChangeDto> get changes {
  if (_changes is EqualUnmodifiableListView) return _changes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_changes);
}

/// Pass as `since` on the next call.
@override final  int nextCursor;
@override final  bool hasMore;

/// Create a copy of ChangesResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChangesResponseCopyWith<_ChangesResponse> get copyWith => __$ChangesResponseCopyWithImpl<_ChangesResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChangesResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChangesResponse&&const DeepCollectionEquality().equals(other.changes, _changes)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_changes),nextCursor,hasMore);
}

@override
String toString() {
    return 'ChangesResponse(changes: $changes, nextCursor: $nextCursor, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class _$ChangesResponseCopyWith<$Res> implements $ChangesResponseCopyWith<$Res> {
  factory _$ChangesResponseCopyWith(_ChangesResponse value, $Res Function(_ChangesResponse) _then) = __$ChangesResponseCopyWithImpl;
@override @useResult
$Res call({
 List<ChangeDto> changes, int nextCursor, bool hasMore
});




}
/// @nodoc
class __$ChangesResponseCopyWithImpl<$Res>
    implements _$ChangesResponseCopyWith<$Res> {
  __$ChangesResponseCopyWithImpl(this._self, this._then);

  final _ChangesResponse _self;
  final $Res Function(_ChangesResponse) _then;

/// Create a copy of ChangesResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? changes = null,Object? nextCursor = null,Object? hasMore = null,}) {
  return _then(_ChangesResponse(
changes: null == changes ? _self._changes : changes // ignore: cast_nullable_to_non_nullable
as List<ChangeDto>,nextCursor: null == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
