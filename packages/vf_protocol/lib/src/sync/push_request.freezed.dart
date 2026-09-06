// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'push_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SyncOpRequest {

/// Idempotency key; the server stores the result per `(device, op id)`.
 String get clientOpId; EntityType get entityType; String get entityId; SyncOp get op;/// Version the client edited against; `0` for creates.
 int get baseVersion;/// Full entity snapshot for create/update, `{folder_id}` for move,
/// empty for delete.
 Map<String, Object?> get payload;
/// Create a copy of SyncOpRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncOpRequestCopyWith<SyncOpRequest> get copyWith => _$SyncOpRequestCopyWithImpl<SyncOpRequest>(this as SyncOpRequest, _$identity);

  /// Serializes this SyncOpRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SyncOpRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncOpRequest&&(identical(other.clientOpId, _this.clientOpId) || other.clientOpId == _this.clientOpId)&&(identical(other.entityType, _this.entityType) || other.entityType == _this.entityType)&&(identical(other.entityId, _this.entityId) || other.entityId == _this.entityId)&&(identical(other.op, _this.op) || other.op == _this.op)&&(identical(other.baseVersion, _this.baseVersion) || other.baseVersion == _this.baseVersion)&&const DeepCollectionEquality().equals(other.payload, _this.payload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SyncOpRequest;
  return Object.hash(runtimeType,_this.clientOpId,_this.entityType,_this.entityId,_this.op,_this.baseVersion,const DeepCollectionEquality().hash(_this.payload));
}

@override
String toString() {
  final _this = this as SyncOpRequest;
  return 'SyncOpRequest(clientOpId: ${_this.clientOpId}, entityType: ${_this.entityType}, entityId: ${_this.entityId}, op: ${_this.op}, baseVersion: ${_this.baseVersion}, payload: ${_this.payload})';
}


}

/// @nodoc
abstract mixin class $SyncOpRequestCopyWith<$Res>  {
  factory $SyncOpRequestCopyWith(SyncOpRequest value, $Res Function(SyncOpRequest) _then) = _$SyncOpRequestCopyWithImpl;
@useResult
$Res call({
 String clientOpId, EntityType entityType, String entityId, SyncOp op, int baseVersion, Map<String, Object?> payload
});




}
/// @nodoc
class _$SyncOpRequestCopyWithImpl<$Res>
    implements $SyncOpRequestCopyWith<$Res> {
  _$SyncOpRequestCopyWithImpl(this._self, this._then);

  final SyncOpRequest _self;
  final $Res Function(SyncOpRequest) _then;

/// Create a copy of SyncOpRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clientOpId = null,Object? entityType = null,Object? entityId = null,Object? op = null,Object? baseVersion = null,Object? payload = null,}) {
  return _then(SyncOpRequest(
clientOpId: null == clientOpId ? _self.clientOpId : clientOpId // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,op: null == op ? _self.op : op // ignore: cast_nullable_to_non_nullable
as SyncOp,baseVersion: null == baseVersion ? _self.baseVersion : baseVersion // ignore: cast_nullable_to_non_nullable
as int,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncOpRequest].
extension SyncOpRequestPatterns on SyncOpRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncOpRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncOpRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncOpRequest value)  $default,){
final _that = this;
switch (_that) {
case _SyncOpRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncOpRequest value)?  $default,){
final _that = this;
switch (_that) {
case _SyncOpRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String clientOpId,  EntityType entityType,  String entityId,  SyncOp op,  int baseVersion,  Map<String, Object?> payload)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncOpRequest() when $default != null:
return $default(_that.clientOpId,_that.entityType,_that.entityId,_that.op,_that.baseVersion,_that.payload);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String clientOpId,  EntityType entityType,  String entityId,  SyncOp op,  int baseVersion,  Map<String, Object?> payload)  $default,) {final _that = this;
switch (_that) {
case _SyncOpRequest():
return $default(_that.clientOpId,_that.entityType,_that.entityId,_that.op,_that.baseVersion,_that.payload);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String clientOpId,  EntityType entityType,  String entityId,  SyncOp op,  int baseVersion,  Map<String, Object?> payload)?  $default,) {final _that = this;
switch (_that) {
case _SyncOpRequest() when $default != null:
return $default(_that.clientOpId,_that.entityType,_that.entityId,_that.op,_that.baseVersion,_that.payload);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SyncOpRequest implements SyncOpRequest {
  const _SyncOpRequest({required this.clientOpId, required this.entityType, required this.entityId, required this.op, required this.baseVersion,  Map<String, Object?> payload = const <String, Object?>{}}): _payload = payload;
  factory _SyncOpRequest.fromJson(Map<String, dynamic> json) => _$SyncOpRequestFromJson(json);

/// Idempotency key; the server stores the result per `(device, op id)`.
@override final  String clientOpId;
@override final  EntityType entityType;
@override final  String entityId;
@override final  SyncOp op;
/// Version the client edited against; `0` for creates.
@override final  int baseVersion;
/// Full entity snapshot for create/update, `{folder_id}` for move,
/// empty for delete.
 final  Map<String, Object?> _payload;
/// Full entity snapshot for create/update, `{folder_id}` for move,
/// empty for delete.
@override@JsonKey() Map<String, Object?> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}


/// Create a copy of SyncOpRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncOpRequestCopyWith<_SyncOpRequest> get copyWith => __$SyncOpRequestCopyWithImpl<_SyncOpRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SyncOpRequestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncOpRequest&&(identical(other.clientOpId, clientOpId) || other.clientOpId == clientOpId)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.op, op) || other.op == op)&&(identical(other.baseVersion, baseVersion) || other.baseVersion == baseVersion)&&const DeepCollectionEquality().equals(other.payload, _payload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,clientOpId,entityType,entityId,op,baseVersion,const DeepCollectionEquality().hash(_payload));
}

@override
String toString() {
    return 'SyncOpRequest(clientOpId: $clientOpId, entityType: $entityType, entityId: $entityId, op: $op, baseVersion: $baseVersion, payload: $payload)';
}


}

/// @nodoc
abstract mixin class _$SyncOpRequestCopyWith<$Res> implements $SyncOpRequestCopyWith<$Res> {
  factory _$SyncOpRequestCopyWith(_SyncOpRequest value, $Res Function(_SyncOpRequest) _then) = __$SyncOpRequestCopyWithImpl;
@override @useResult
$Res call({
 String clientOpId, EntityType entityType, String entityId, SyncOp op, int baseVersion, Map<String, Object?> payload
});




}
/// @nodoc
class __$SyncOpRequestCopyWithImpl<$Res>
    implements _$SyncOpRequestCopyWith<$Res> {
  __$SyncOpRequestCopyWithImpl(this._self, this._then);

  final _SyncOpRequest _self;
  final $Res Function(_SyncOpRequest) _then;

/// Create a copy of SyncOpRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clientOpId = null,Object? entityType = null,Object? entityId = null,Object? op = null,Object? baseVersion = null,Object? payload = null,}) {
  return _then(_SyncOpRequest(
clientOpId: null == clientOpId ? _self.clientOpId : clientOpId // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,op: null == op ? _self.op : op // ignore: cast_nullable_to_non_nullable
as SyncOp,baseVersion: null == baseVersion ? _self.baseVersion : baseVersion // ignore: cast_nullable_to_non_nullable
as int,payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}


}


/// @nodoc
mixin _$PushRequest {

 String get deviceId; List<SyncOpRequest> get ops;
/// Create a copy of PushRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PushRequestCopyWith<PushRequest> get copyWith => _$PushRequestCopyWithImpl<PushRequest>(this as PushRequest, _$identity);

  /// Serializes this PushRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PushRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PushRequest&&(identical(other.deviceId, _this.deviceId) || other.deviceId == _this.deviceId)&&const DeepCollectionEquality().equals(other.ops, _this.ops));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PushRequest;
  return Object.hash(runtimeType,_this.deviceId,const DeepCollectionEquality().hash(_this.ops));
}

@override
String toString() {
  final _this = this as PushRequest;
  return 'PushRequest(deviceId: ${_this.deviceId}, ops: ${_this.ops})';
}


}

/// @nodoc
abstract mixin class $PushRequestCopyWith<$Res>  {
  factory $PushRequestCopyWith(PushRequest value, $Res Function(PushRequest) _then) = _$PushRequestCopyWithImpl;
@useResult
$Res call({
 String deviceId, List<SyncOpRequest> ops
});




}
/// @nodoc
class _$PushRequestCopyWithImpl<$Res>
    implements $PushRequestCopyWith<$Res> {
  _$PushRequestCopyWithImpl(this._self, this._then);

  final PushRequest _self;
  final $Res Function(PushRequest) _then;

/// Create a copy of PushRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceId = null,Object? ops = null,}) {
  return _then(PushRequest(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,ops: null == ops ? _self.ops : ops // ignore: cast_nullable_to_non_nullable
as List<SyncOpRequest>,
  ));
}

}


/// Adds pattern-matching-related methods to [PushRequest].
extension PushRequestPatterns on PushRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PushRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PushRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PushRequest value)  $default,){
final _that = this;
switch (_that) {
case _PushRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PushRequest value)?  $default,){
final _that = this;
switch (_that) {
case _PushRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String deviceId,  List<SyncOpRequest> ops)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PushRequest() when $default != null:
return $default(_that.deviceId,_that.ops);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String deviceId,  List<SyncOpRequest> ops)  $default,) {final _that = this;
switch (_that) {
case _PushRequest():
return $default(_that.deviceId,_that.ops);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String deviceId,  List<SyncOpRequest> ops)?  $default,) {final _that = this;
switch (_that) {
case _PushRequest() when $default != null:
return $default(_that.deviceId,_that.ops);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PushRequest implements PushRequest {
  const _PushRequest({required this.deviceId, required  List<SyncOpRequest> ops}): _ops = ops;
  factory _PushRequest.fromJson(Map<String, dynamic> json) => _$PushRequestFromJson(json);

@override final  String deviceId;
 final  List<SyncOpRequest> _ops;
@override List<SyncOpRequest> get ops {
  if (_ops is EqualUnmodifiableListView) return _ops;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ops);
}


/// Create a copy of PushRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PushRequestCopyWith<_PushRequest> get copyWith => __$PushRequestCopyWithImpl<_PushRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PushRequestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PushRequest&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&const DeepCollectionEquality().equals(other.ops, _ops));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,deviceId,const DeepCollectionEquality().hash(_ops));
}

@override
String toString() {
    return 'PushRequest(deviceId: $deviceId, ops: $ops)';
}


}

/// @nodoc
abstract mixin class _$PushRequestCopyWith<$Res> implements $PushRequestCopyWith<$Res> {
  factory _$PushRequestCopyWith(_PushRequest value, $Res Function(_PushRequest) _then) = __$PushRequestCopyWithImpl;
@override @useResult
$Res call({
 String deviceId, List<SyncOpRequest> ops
});




}
/// @nodoc
class __$PushRequestCopyWithImpl<$Res>
    implements _$PushRequestCopyWith<$Res> {
  __$PushRequestCopyWithImpl(this._self, this._then);

  final _PushRequest _self;
  final $Res Function(_PushRequest) _then;

/// Create a copy of PushRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceId = null,Object? ops = null,}) {
  return _then(_PushRequest(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,ops: null == ops ? _self._ops : ops // ignore: cast_nullable_to_non_nullable
as List<SyncOpRequest>,
  ));
}


}

// dart format on
