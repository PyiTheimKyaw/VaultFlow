// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'outbox_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OutboxEntry {

 int get id; String get clientOpId; EntityType get entityType; String get entityId; SyncOp get op; Map<String, Object?> get payload; int get baseVersion; OutboxState get state; DateTime get createdAt; String? get dependsOnTransfer; int get attemptCount; DateTime? get nextAttemptAt; String? get lastError;
/// Create a copy of OutboxEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutboxEntryCopyWith<OutboxEntry> get copyWith => _$OutboxEntryCopyWithImpl<OutboxEntry>(this as OutboxEntry, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OutboxEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutboxEntry&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.clientOpId, _this.clientOpId) || other.clientOpId == _this.clientOpId)&&(identical(other.entityType, _this.entityType) || other.entityType == _this.entityType)&&(identical(other.entityId, _this.entityId) || other.entityId == _this.entityId)&&(identical(other.op, _this.op) || other.op == _this.op)&&const DeepCollectionEquality().equals(other.payload, _this.payload)&&(identical(other.baseVersion, _this.baseVersion) || other.baseVersion == _this.baseVersion)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.dependsOnTransfer, _this.dependsOnTransfer) || other.dependsOnTransfer == _this.dependsOnTransfer)&&(identical(other.attemptCount, _this.attemptCount) || other.attemptCount == _this.attemptCount)&&(identical(other.nextAttemptAt, _this.nextAttemptAt) || other.nextAttemptAt == _this.nextAttemptAt)&&(identical(other.lastError, _this.lastError) || other.lastError == _this.lastError));
}


@override
int get hashCode {
  final _this = this as OutboxEntry;
  return Object.hash(runtimeType,_this.id,_this.clientOpId,_this.entityType,_this.entityId,_this.op,const DeepCollectionEquality().hash(_this.payload),_this.baseVersion,_this.state,_this.createdAt,_this.dependsOnTransfer,_this.attemptCount,_this.nextAttemptAt,_this.lastError);
}

@override
String toString() {
  final _this = this as OutboxEntry;
  return 'OutboxEntry(id: ${_this.id}, clientOpId: ${_this.clientOpId}, entityType: ${_this.entityType}, entityId: ${_this.entityId}, op: ${_this.op}, payload: ${_this.payload}, baseVersion: ${_this.baseVersion}, state: ${_this.state}, createdAt: ${_this.createdAt}, dependsOnTransfer: ${_this.dependsOnTransfer}, attemptCount: ${_this.attemptCount}, nextAttemptAt: ${_this.nextAttemptAt}, lastError: ${_this.lastError})';
}


}

/// @nodoc
abstract mixin class $OutboxEntryCopyWith<$Res>  {
  factory $OutboxEntryCopyWith(OutboxEntry value, $Res Function(OutboxEntry) _then) = _$OutboxEntryCopyWithImpl;
@useResult
$Res call({
 int id, String clientOpId, EntityType entityType, String entityId, SyncOp op, Map<String, Object?> payload, int baseVersion, OutboxState state, DateTime createdAt, String? dependsOnTransfer, int attemptCount, DateTime? nextAttemptAt, String? lastError
});




}
/// @nodoc
class _$OutboxEntryCopyWithImpl<$Res>
    implements $OutboxEntryCopyWith<$Res> {
  _$OutboxEntryCopyWithImpl(this._self, this._then);

  final OutboxEntry _self;
  final $Res Function(OutboxEntry) _then;

/// Create a copy of OutboxEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? clientOpId = null,Object? entityType = null,Object? entityId = null,Object? op = null,Object? payload = null,Object? baseVersion = null,Object? state = null,Object? createdAt = null,Object? dependsOnTransfer = freezed,Object? attemptCount = null,Object? nextAttemptAt = freezed,Object? lastError = freezed,}) {
  return _then(OutboxEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,clientOpId: null == clientOpId ? _self.clientOpId : clientOpId // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,op: null == op ? _self.op : op // ignore: cast_nullable_to_non_nullable
as SyncOp,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,baseVersion: null == baseVersion ? _self.baseVersion : baseVersion // ignore: cast_nullable_to_non_nullable
as int,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as OutboxState,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,dependsOnTransfer: freezed == dependsOnTransfer ? _self.dependsOnTransfer : dependsOnTransfer // ignore: cast_nullable_to_non_nullable
as String?,attemptCount: null == attemptCount ? _self.attemptCount : attemptCount // ignore: cast_nullable_to_non_nullable
as int,nextAttemptAt: freezed == nextAttemptAt ? _self.nextAttemptAt : nextAttemptAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OutboxEntry].
extension OutboxEntryPatterns on OutboxEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OutboxEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OutboxEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OutboxEntry value)  $default,){
final _that = this;
switch (_that) {
case _OutboxEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OutboxEntry value)?  $default,){
final _that = this;
switch (_that) {
case _OutboxEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String clientOpId,  EntityType entityType,  String entityId,  SyncOp op,  Map<String, Object?> payload,  int baseVersion,  OutboxState state,  DateTime createdAt,  String? dependsOnTransfer,  int attemptCount,  DateTime? nextAttemptAt,  String? lastError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OutboxEntry() when $default != null:
return $default(_that.id,_that.clientOpId,_that.entityType,_that.entityId,_that.op,_that.payload,_that.baseVersion,_that.state,_that.createdAt,_that.dependsOnTransfer,_that.attemptCount,_that.nextAttemptAt,_that.lastError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String clientOpId,  EntityType entityType,  String entityId,  SyncOp op,  Map<String, Object?> payload,  int baseVersion,  OutboxState state,  DateTime createdAt,  String? dependsOnTransfer,  int attemptCount,  DateTime? nextAttemptAt,  String? lastError)  $default,) {final _that = this;
switch (_that) {
case _OutboxEntry():
return $default(_that.id,_that.clientOpId,_that.entityType,_that.entityId,_that.op,_that.payload,_that.baseVersion,_that.state,_that.createdAt,_that.dependsOnTransfer,_that.attemptCount,_that.nextAttemptAt,_that.lastError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String clientOpId,  EntityType entityType,  String entityId,  SyncOp op,  Map<String, Object?> payload,  int baseVersion,  OutboxState state,  DateTime createdAt,  String? dependsOnTransfer,  int attemptCount,  DateTime? nextAttemptAt,  String? lastError)?  $default,) {final _that = this;
switch (_that) {
case _OutboxEntry() when $default != null:
return $default(_that.id,_that.clientOpId,_that.entityType,_that.entityId,_that.op,_that.payload,_that.baseVersion,_that.state,_that.createdAt,_that.dependsOnTransfer,_that.attemptCount,_that.nextAttemptAt,_that.lastError);case _:
  return null;

}
}

}

/// @nodoc


class _OutboxEntry extends OutboxEntry {
  const _OutboxEntry({required this.id, required this.clientOpId, required this.entityType, required this.entityId, required this.op, required  Map<String, Object?> payload, required this.baseVersion, required this.state, required this.createdAt, this.dependsOnTransfer, this.attemptCount = 0, this.nextAttemptAt, this.lastError}): _payload = payload,super._();
  

@override final  int id;
@override final  String clientOpId;
@override final  EntityType entityType;
@override final  String entityId;
@override final  SyncOp op;
 final  Map<String, Object?> _payload;
@override Map<String, Object?> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}

@override final  int baseVersion;
@override final  OutboxState state;
@override final  DateTime createdAt;
@override final  String? dependsOnTransfer;
@override@JsonKey() final  int attemptCount;
@override final  DateTime? nextAttemptAt;
@override final  String? lastError;

/// Create a copy of OutboxEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutboxEntryCopyWith<_OutboxEntry> get copyWith => __$OutboxEntryCopyWithImpl<_OutboxEntry>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OutboxEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.clientOpId, clientOpId) || other.clientOpId == clientOpId)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.op, op) || other.op == op)&&const DeepCollectionEquality().equals(other.payload, _payload)&&(identical(other.baseVersion, baseVersion) || other.baseVersion == baseVersion)&&(identical(other.state, state) || other.state == state)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.dependsOnTransfer, dependsOnTransfer) || other.dependsOnTransfer == dependsOnTransfer)&&(identical(other.attemptCount, attemptCount) || other.attemptCount == attemptCount)&&(identical(other.nextAttemptAt, nextAttemptAt) || other.nextAttemptAt == nextAttemptAt)&&(identical(other.lastError, lastError) || other.lastError == lastError));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,clientOpId,entityType,entityId,op,const DeepCollectionEquality().hash(_payload),baseVersion,state,createdAt,dependsOnTransfer,attemptCount,nextAttemptAt,lastError);
}

@override
String toString() {
    return 'OutboxEntry(id: $id, clientOpId: $clientOpId, entityType: $entityType, entityId: $entityId, op: $op, payload: $payload, baseVersion: $baseVersion, state: $state, createdAt: $createdAt, dependsOnTransfer: $dependsOnTransfer, attemptCount: $attemptCount, nextAttemptAt: $nextAttemptAt, lastError: $lastError)';
}


}

/// @nodoc
abstract mixin class _$OutboxEntryCopyWith<$Res> implements $OutboxEntryCopyWith<$Res> {
  factory _$OutboxEntryCopyWith(_OutboxEntry value, $Res Function(_OutboxEntry) _then) = __$OutboxEntryCopyWithImpl;
@override @useResult
$Res call({
 int id, String clientOpId, EntityType entityType, String entityId, SyncOp op, Map<String, Object?> payload, int baseVersion, OutboxState state, DateTime createdAt, String? dependsOnTransfer, int attemptCount, DateTime? nextAttemptAt, String? lastError
});




}
/// @nodoc
class __$OutboxEntryCopyWithImpl<$Res>
    implements _$OutboxEntryCopyWith<$Res> {
  __$OutboxEntryCopyWithImpl(this._self, this._then);

  final _OutboxEntry _self;
  final $Res Function(_OutboxEntry) _then;

/// Create a copy of OutboxEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? clientOpId = null,Object? entityType = null,Object? entityId = null,Object? op = null,Object? payload = null,Object? baseVersion = null,Object? state = null,Object? createdAt = null,Object? dependsOnTransfer = freezed,Object? attemptCount = null,Object? nextAttemptAt = freezed,Object? lastError = freezed,}) {
  return _then(_OutboxEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,clientOpId: null == clientOpId ? _self.clientOpId : clientOpId // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,op: null == op ? _self.op : op // ignore: cast_nullable_to_non_nullable
as SyncOp,payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,baseVersion: null == baseVersion ? _self.baseVersion : baseVersion // ignore: cast_nullable_to_non_nullable
as int,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as OutboxState,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,dependsOnTransfer: freezed == dependsOnTransfer ? _self.dependsOnTransfer : dependsOnTransfer // ignore: cast_nullable_to_non_nullable
as String?,attemptCount: null == attemptCount ? _self.attemptCount : attemptCount // ignore: cast_nullable_to_non_nullable
as int,nextAttemptAt: freezed == nextAttemptAt ? _self.nextAttemptAt : nextAttemptAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
