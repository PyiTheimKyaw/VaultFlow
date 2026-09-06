// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'push_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SyncOpResult {

 String get clientOpId; SyncOpStatus get status;/// Set when [status] is [SyncOpStatus.applied].
 int? get newVersion;/// Server snapshot, set when [status] is [SyncOpStatus.conflict].
 Map<String, Object?>? get remote; int? get remoteVersion;/// Human-readable reason, set when [status] is [SyncOpStatus.rejected].
 String? get error;
/// Create a copy of SyncOpResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncOpResultCopyWith<SyncOpResult> get copyWith => _$SyncOpResultCopyWithImpl<SyncOpResult>(this as SyncOpResult, _$identity);

  /// Serializes this SyncOpResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SyncOpResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncOpResult&&(identical(other.clientOpId, _this.clientOpId) || other.clientOpId == _this.clientOpId)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.newVersion, _this.newVersion) || other.newVersion == _this.newVersion)&&const DeepCollectionEquality().equals(other.remote, _this.remote)&&(identical(other.remoteVersion, _this.remoteVersion) || other.remoteVersion == _this.remoteVersion)&&(identical(other.error, _this.error) || other.error == _this.error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SyncOpResult;
  return Object.hash(runtimeType,_this.clientOpId,_this.status,_this.newVersion,const DeepCollectionEquality().hash(_this.remote),_this.remoteVersion,_this.error);
}

@override
String toString() {
  final _this = this as SyncOpResult;
  return 'SyncOpResult(clientOpId: ${_this.clientOpId}, status: ${_this.status}, newVersion: ${_this.newVersion}, remote: ${_this.remote}, remoteVersion: ${_this.remoteVersion}, error: ${_this.error})';
}


}

/// @nodoc
abstract mixin class $SyncOpResultCopyWith<$Res>  {
  factory $SyncOpResultCopyWith(SyncOpResult value, $Res Function(SyncOpResult) _then) = _$SyncOpResultCopyWithImpl;
@useResult
$Res call({
 String clientOpId, SyncOpStatus status, int? newVersion, Map<String, Object?>? remote, int? remoteVersion, String? error
});




}
/// @nodoc
class _$SyncOpResultCopyWithImpl<$Res>
    implements $SyncOpResultCopyWith<$Res> {
  _$SyncOpResultCopyWithImpl(this._self, this._then);

  final SyncOpResult _self;
  final $Res Function(SyncOpResult) _then;

/// Create a copy of SyncOpResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clientOpId = null,Object? status = null,Object? newVersion = freezed,Object? remote = freezed,Object? remoteVersion = freezed,Object? error = freezed,}) {
  return _then(SyncOpResult(
clientOpId: null == clientOpId ? _self.clientOpId : clientOpId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SyncOpStatus,newVersion: freezed == newVersion ? _self.newVersion : newVersion // ignore: cast_nullable_to_non_nullable
as int?,remote: freezed == remote ? _self.remote : remote // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,remoteVersion: freezed == remoteVersion ? _self.remoteVersion : remoteVersion // ignore: cast_nullable_to_non_nullable
as int?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncOpResult].
extension SyncOpResultPatterns on SyncOpResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncOpResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncOpResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncOpResult value)  $default,){
final _that = this;
switch (_that) {
case _SyncOpResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncOpResult value)?  $default,){
final _that = this;
switch (_that) {
case _SyncOpResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String clientOpId,  SyncOpStatus status,  int? newVersion,  Map<String, Object?>? remote,  int? remoteVersion,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncOpResult() when $default != null:
return $default(_that.clientOpId,_that.status,_that.newVersion,_that.remote,_that.remoteVersion,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String clientOpId,  SyncOpStatus status,  int? newVersion,  Map<String, Object?>? remote,  int? remoteVersion,  String? error)  $default,) {final _that = this;
switch (_that) {
case _SyncOpResult():
return $default(_that.clientOpId,_that.status,_that.newVersion,_that.remote,_that.remoteVersion,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String clientOpId,  SyncOpStatus status,  int? newVersion,  Map<String, Object?>? remote,  int? remoteVersion,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _SyncOpResult() when $default != null:
return $default(_that.clientOpId,_that.status,_that.newVersion,_that.remote,_that.remoteVersion,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SyncOpResult implements SyncOpResult {
  const _SyncOpResult({required this.clientOpId, required this.status, this.newVersion,  Map<String, Object?>? remote, this.remoteVersion, this.error}): _remote = remote;
  factory _SyncOpResult.fromJson(Map<String, dynamic> json) => _$SyncOpResultFromJson(json);

@override final  String clientOpId;
@override final  SyncOpStatus status;
/// Set when [status] is [SyncOpStatus.applied].
@override final  int? newVersion;
/// Server snapshot, set when [status] is [SyncOpStatus.conflict].
 final  Map<String, Object?>? _remote;
/// Server snapshot, set when [status] is [SyncOpStatus.conflict].
@override Map<String, Object?>? get remote {
  final value = _remote;
  if (value == null) return null;
  if (_remote is EqualUnmodifiableMapView) return _remote;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  int? remoteVersion;
/// Human-readable reason, set when [status] is [SyncOpStatus.rejected].
@override final  String? error;

/// Create a copy of SyncOpResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncOpResultCopyWith<_SyncOpResult> get copyWith => __$SyncOpResultCopyWithImpl<_SyncOpResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SyncOpResultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncOpResult&&(identical(other.clientOpId, clientOpId) || other.clientOpId == clientOpId)&&(identical(other.status, status) || other.status == status)&&(identical(other.newVersion, newVersion) || other.newVersion == newVersion)&&const DeepCollectionEquality().equals(other.remote, _remote)&&(identical(other.remoteVersion, remoteVersion) || other.remoteVersion == remoteVersion)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,clientOpId,status,newVersion,const DeepCollectionEquality().hash(_remote),remoteVersion,error);
}

@override
String toString() {
    return 'SyncOpResult(clientOpId: $clientOpId, status: $status, newVersion: $newVersion, remote: $remote, remoteVersion: $remoteVersion, error: $error)';
}


}

/// @nodoc
abstract mixin class _$SyncOpResultCopyWith<$Res> implements $SyncOpResultCopyWith<$Res> {
  factory _$SyncOpResultCopyWith(_SyncOpResult value, $Res Function(_SyncOpResult) _then) = __$SyncOpResultCopyWithImpl;
@override @useResult
$Res call({
 String clientOpId, SyncOpStatus status, int? newVersion, Map<String, Object?>? remote, int? remoteVersion, String? error
});




}
/// @nodoc
class __$SyncOpResultCopyWithImpl<$Res>
    implements _$SyncOpResultCopyWith<$Res> {
  __$SyncOpResultCopyWithImpl(this._self, this._then);

  final _SyncOpResult _self;
  final $Res Function(_SyncOpResult) _then;

/// Create a copy of SyncOpResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clientOpId = null,Object? status = null,Object? newVersion = freezed,Object? remote = freezed,Object? remoteVersion = freezed,Object? error = freezed,}) {
  return _then(_SyncOpResult(
clientOpId: null == clientOpId ? _self.clientOpId : clientOpId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SyncOpStatus,newVersion: freezed == newVersion ? _self.newVersion : newVersion // ignore: cast_nullable_to_non_nullable
as int?,remote: freezed == remote ? _self._remote : remote // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,remoteVersion: freezed == remoteVersion ? _self.remoteVersion : remoteVersion // ignore: cast_nullable_to_non_nullable
as int?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PushResponse {

 List<SyncOpResult> get results;
/// Create a copy of PushResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PushResponseCopyWith<PushResponse> get copyWith => _$PushResponseCopyWithImpl<PushResponse>(this as PushResponse, _$identity);

  /// Serializes this PushResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PushResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PushResponse&&const DeepCollectionEquality().equals(other.results, _this.results));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PushResponse;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.results));
}

@override
String toString() {
  final _this = this as PushResponse;
  return 'PushResponse(results: ${_this.results})';
}


}

/// @nodoc
abstract mixin class $PushResponseCopyWith<$Res>  {
  factory $PushResponseCopyWith(PushResponse value, $Res Function(PushResponse) _then) = _$PushResponseCopyWithImpl;
@useResult
$Res call({
 List<SyncOpResult> results
});




}
/// @nodoc
class _$PushResponseCopyWithImpl<$Res>
    implements $PushResponseCopyWith<$Res> {
  _$PushResponseCopyWithImpl(this._self, this._then);

  final PushResponse _self;
  final $Res Function(PushResponse) _then;

/// Create a copy of PushResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? results = null,}) {
  return _then(PushResponse(
results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as List<SyncOpResult>,
  ));
}

}


/// Adds pattern-matching-related methods to [PushResponse].
extension PushResponsePatterns on PushResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PushResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PushResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PushResponse value)  $default,){
final _that = this;
switch (_that) {
case _PushResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PushResponse value)?  $default,){
final _that = this;
switch (_that) {
case _PushResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SyncOpResult> results)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PushResponse() when $default != null:
return $default(_that.results);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SyncOpResult> results)  $default,) {final _that = this;
switch (_that) {
case _PushResponse():
return $default(_that.results);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SyncOpResult> results)?  $default,) {final _that = this;
switch (_that) {
case _PushResponse() when $default != null:
return $default(_that.results);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PushResponse implements PushResponse {
  const _PushResponse({required  List<SyncOpResult> results}): _results = results;
  factory _PushResponse.fromJson(Map<String, dynamic> json) => _$PushResponseFromJson(json);

 final  List<SyncOpResult> _results;
@override List<SyncOpResult> get results {
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_results);
}


/// Create a copy of PushResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PushResponseCopyWith<_PushResponse> get copyWith => __$PushResponseCopyWithImpl<_PushResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PushResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PushResponse&&const DeepCollectionEquality().equals(other.results, _results));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_results));
}

@override
String toString() {
    return 'PushResponse(results: $results)';
}


}

/// @nodoc
abstract mixin class _$PushResponseCopyWith<$Res> implements $PushResponseCopyWith<$Res> {
  factory _$PushResponseCopyWith(_PushResponse value, $Res Function(_PushResponse) _then) = __$PushResponseCopyWithImpl;
@override @useResult
$Res call({
 List<SyncOpResult> results
});




}
/// @nodoc
class __$PushResponseCopyWithImpl<$Res>
    implements _$PushResponseCopyWith<$Res> {
  __$PushResponseCopyWithImpl(this._self, this._then);

  final _PushResponse _self;
  final $Res Function(_PushResponse) _then;

/// Create a copy of PushResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? results = null,}) {
  return _then(_PushResponse(
results: null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<SyncOpResult>,
  ));
}


}

// dart format on
