// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'download_url_dtos.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DownloadUrlResponse {

/// Path relative to the API origin, e.g. `/documents/x/content?token=…`.
 String get url; DateTime get expiresAt;
/// Create a copy of DownloadUrlResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadUrlResponseCopyWith<DownloadUrlResponse> get copyWith => _$DownloadUrlResponseCopyWithImpl<DownloadUrlResponse>(this as DownloadUrlResponse, _$identity);

  /// Serializes this DownloadUrlResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DownloadUrlResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadUrlResponse&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DownloadUrlResponse;
  return Object.hash(runtimeType,_this.url,_this.expiresAt);
}

@override
String toString() {
  final _this = this as DownloadUrlResponse;
  return 'DownloadUrlResponse(url: ${_this.url}, expiresAt: ${_this.expiresAt})';
}


}

/// @nodoc
abstract mixin class $DownloadUrlResponseCopyWith<$Res>  {
  factory $DownloadUrlResponseCopyWith(DownloadUrlResponse value, $Res Function(DownloadUrlResponse) _then) = _$DownloadUrlResponseCopyWithImpl;
@useResult
$Res call({
 String url, DateTime expiresAt
});




}
/// @nodoc
class _$DownloadUrlResponseCopyWithImpl<$Res>
    implements $DownloadUrlResponseCopyWith<$Res> {
  _$DownloadUrlResponseCopyWithImpl(this._self, this._then);

  final DownloadUrlResponse _self;
  final $Res Function(DownloadUrlResponse) _then;

/// Create a copy of DownloadUrlResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? expiresAt = null,}) {
  return _then(DownloadUrlResponse(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [DownloadUrlResponse].
extension DownloadUrlResponsePatterns on DownloadUrlResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DownloadUrlResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DownloadUrlResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DownloadUrlResponse value)  $default,){
final _that = this;
switch (_that) {
case _DownloadUrlResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DownloadUrlResponse value)?  $default,){
final _that = this;
switch (_that) {
case _DownloadUrlResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DownloadUrlResponse() when $default != null:
return $default(_that.url,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _DownloadUrlResponse():
return $default(_that.url,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _DownloadUrlResponse() when $default != null:
return $default(_that.url,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DownloadUrlResponse implements DownloadUrlResponse {
  const _DownloadUrlResponse({required this.url, required this.expiresAt});
  factory _DownloadUrlResponse.fromJson(Map<String, dynamic> json) => _$DownloadUrlResponseFromJson(json);

/// Path relative to the API origin, e.g. `/documents/x/content?token=…`.
@override final  String url;
@override final  DateTime expiresAt;

/// Create a copy of DownloadUrlResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DownloadUrlResponseCopyWith<_DownloadUrlResponse> get copyWith => __$DownloadUrlResponseCopyWithImpl<_DownloadUrlResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DownloadUrlResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadUrlResponse&&(identical(other.url, url) || other.url == url)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,url,expiresAt);
}

@override
String toString() {
    return 'DownloadUrlResponse(url: $url, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$DownloadUrlResponseCopyWith<$Res> implements $DownloadUrlResponseCopyWith<$Res> {
  factory _$DownloadUrlResponseCopyWith(_DownloadUrlResponse value, $Res Function(_DownloadUrlResponse) _then) = __$DownloadUrlResponseCopyWithImpl;
@override @useResult
$Res call({
 String url, DateTime expiresAt
});




}
/// @nodoc
class __$DownloadUrlResponseCopyWithImpl<$Res>
    implements _$DownloadUrlResponseCopyWith<$Res> {
  __$DownloadUrlResponseCopyWithImpl(this._self, this._then);

  final _DownloadUrlResponse _self;
  final $Res Function(_DownloadUrlResponse) _then;

/// Create a copy of DownloadUrlResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? expiresAt = null,}) {
  return _then(_DownloadUrlResponse(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$SyncEvent {

 int get seq;
/// Create a copy of SyncEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncEventCopyWith<SyncEvent> get copyWith => _$SyncEventCopyWithImpl<SyncEvent>(this as SyncEvent, _$identity);

  /// Serializes this SyncEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SyncEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncEvent&&(identical(other.seq, _this.seq) || other.seq == _this.seq));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SyncEvent;
  return Object.hash(runtimeType,_this.seq);
}

@override
String toString() {
  final _this = this as SyncEvent;
  return 'SyncEvent(seq: ${_this.seq})';
}


}

/// @nodoc
abstract mixin class $SyncEventCopyWith<$Res>  {
  factory $SyncEventCopyWith(SyncEvent value, $Res Function(SyncEvent) _then) = _$SyncEventCopyWithImpl;
@useResult
$Res call({
 int seq
});




}
/// @nodoc
class _$SyncEventCopyWithImpl<$Res>
    implements $SyncEventCopyWith<$Res> {
  _$SyncEventCopyWithImpl(this._self, this._then);

  final SyncEvent _self;
  final $Res Function(SyncEvent) _then;

/// Create a copy of SyncEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? seq = null,}) {
  return _then(SyncEvent(
seq: null == seq ? _self.seq : seq // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncEvent].
extension SyncEventPatterns on SyncEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncEvent value)  $default,){
final _that = this;
switch (_that) {
case _SyncEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncEvent value)?  $default,){
final _that = this;
switch (_that) {
case _SyncEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int seq)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncEvent() when $default != null:
return $default(_that.seq);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int seq)  $default,) {final _that = this;
switch (_that) {
case _SyncEvent():
return $default(_that.seq);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int seq)?  $default,) {final _that = this;
switch (_that) {
case _SyncEvent() when $default != null:
return $default(_that.seq);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SyncEvent implements SyncEvent {
  const _SyncEvent({required this.seq});
  factory _SyncEvent.fromJson(Map<String, dynamic> json) => _$SyncEventFromJson(json);

@override final  int seq;

/// Create a copy of SyncEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncEventCopyWith<_SyncEvent> get copyWith => __$SyncEventCopyWithImpl<_SyncEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SyncEventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncEvent&&(identical(other.seq, seq) || other.seq == seq));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,seq);
}

@override
String toString() {
    return 'SyncEvent(seq: $seq)';
}


}

/// @nodoc
abstract mixin class _$SyncEventCopyWith<$Res> implements $SyncEventCopyWith<$Res> {
  factory _$SyncEventCopyWith(_SyncEvent value, $Res Function(_SyncEvent) _then) = __$SyncEventCopyWithImpl;
@override @useResult
$Res call({
 int seq
});




}
/// @nodoc
class __$SyncEventCopyWithImpl<$Res>
    implements _$SyncEventCopyWith<$Res> {
  __$SyncEventCopyWithImpl(this._self, this._then);

  final _SyncEvent _self;
  final $Res Function(_SyncEvent) _then;

/// Create a copy of SyncEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? seq = null,}) {
  return _then(_SyncEvent(
seq: null == seq ? _self.seq : seq // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
