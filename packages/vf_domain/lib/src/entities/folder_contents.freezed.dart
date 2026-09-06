// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'folder_contents.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FolderContents {

 String? get folderId; List<Folder> get folders; List<Document> get documents; List<Note> get notes;
/// Create a copy of FolderContents
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FolderContentsCopyWith<FolderContents> get copyWith => _$FolderContentsCopyWithImpl<FolderContents>(this as FolderContents, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FolderContents;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderContents&&(identical(other.folderId, _this.folderId) || other.folderId == _this.folderId)&&const DeepCollectionEquality().equals(other.folders, _this.folders)&&const DeepCollectionEquality().equals(other.documents, _this.documents)&&const DeepCollectionEquality().equals(other.notes, _this.notes));
}


@override
int get hashCode {
  final _this = this as FolderContents;
  return Object.hash(runtimeType,_this.folderId,const DeepCollectionEquality().hash(_this.folders),const DeepCollectionEquality().hash(_this.documents),const DeepCollectionEquality().hash(_this.notes));
}

@override
String toString() {
  final _this = this as FolderContents;
  return 'FolderContents(folderId: ${_this.folderId}, folders: ${_this.folders}, documents: ${_this.documents}, notes: ${_this.notes})';
}


}

/// @nodoc
abstract mixin class $FolderContentsCopyWith<$Res>  {
  factory $FolderContentsCopyWith(FolderContents value, $Res Function(FolderContents) _then) = _$FolderContentsCopyWithImpl;
@useResult
$Res call({
 String? folderId, List<Folder> folders, List<Document> documents, List<Note> notes
});




}
/// @nodoc
class _$FolderContentsCopyWithImpl<$Res>
    implements $FolderContentsCopyWith<$Res> {
  _$FolderContentsCopyWithImpl(this._self, this._then);

  final FolderContents _self;
  final $Res Function(FolderContents) _then;

/// Create a copy of FolderContents
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? folderId = freezed,Object? folders = null,Object? documents = null,Object? notes = null,}) {
  return _then(FolderContents(
folderId: freezed == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String?,folders: null == folders ? _self.folders : folders // ignore: cast_nullable_to_non_nullable
as List<Folder>,documents: null == documents ? _self.documents : documents // ignore: cast_nullable_to_non_nullable
as List<Document>,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as List<Note>,
  ));
}

}


/// Adds pattern-matching-related methods to [FolderContents].
extension FolderContentsPatterns on FolderContents {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FolderContents value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FolderContents() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FolderContents value)  $default,){
final _that = this;
switch (_that) {
case _FolderContents():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FolderContents value)?  $default,){
final _that = this;
switch (_that) {
case _FolderContents() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? folderId,  List<Folder> folders,  List<Document> documents,  List<Note> notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FolderContents() when $default != null:
return $default(_that.folderId,_that.folders,_that.documents,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? folderId,  List<Folder> folders,  List<Document> documents,  List<Note> notes)  $default,) {final _that = this;
switch (_that) {
case _FolderContents():
return $default(_that.folderId,_that.folders,_that.documents,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? folderId,  List<Folder> folders,  List<Document> documents,  List<Note> notes)?  $default,) {final _that = this;
switch (_that) {
case _FolderContents() when $default != null:
return $default(_that.folderId,_that.folders,_that.documents,_that.notes);case _:
  return null;

}
}

}

/// @nodoc


class _FolderContents extends FolderContents {
  const _FolderContents({required this.folderId,  List<Folder> folders = const <Folder>[],  List<Document> documents = const <Document>[],  List<Note> notes = const <Note>[]}): _folders = folders,_documents = documents,_notes = notes,super._();
  

@override final  String? folderId;
 final  List<Folder> _folders;
@override@JsonKey() List<Folder> get folders {
  if (_folders is EqualUnmodifiableListView) return _folders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_folders);
}

 final  List<Document> _documents;
@override@JsonKey() List<Document> get documents {
  if (_documents is EqualUnmodifiableListView) return _documents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_documents);
}

 final  List<Note> _notes;
@override@JsonKey() List<Note> get notes {
  if (_notes is EqualUnmodifiableListView) return _notes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_notes);
}


/// Create a copy of FolderContents
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FolderContentsCopyWith<_FolderContents> get copyWith => __$FolderContentsCopyWithImpl<_FolderContents>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FolderContents&&(identical(other.folderId, folderId) || other.folderId == folderId)&&const DeepCollectionEquality().equals(other.folders, _folders)&&const DeepCollectionEquality().equals(other.documents, _documents)&&const DeepCollectionEquality().equals(other.notes, _notes));
}


@override
int get hashCode {
    return Object.hash(runtimeType,folderId,const DeepCollectionEquality().hash(_folders),const DeepCollectionEquality().hash(_documents),const DeepCollectionEquality().hash(_notes));
}

@override
String toString() {
    return 'FolderContents(folderId: $folderId, folders: $folders, documents: $documents, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$FolderContentsCopyWith<$Res> implements $FolderContentsCopyWith<$Res> {
  factory _$FolderContentsCopyWith(_FolderContents value, $Res Function(_FolderContents) _then) = __$FolderContentsCopyWithImpl;
@override @useResult
$Res call({
 String? folderId, List<Folder> folders, List<Document> documents, List<Note> notes
});




}
/// @nodoc
class __$FolderContentsCopyWithImpl<$Res>
    implements _$FolderContentsCopyWith<$Res> {
  __$FolderContentsCopyWithImpl(this._self, this._then);

  final _FolderContents _self;
  final $Res Function(_FolderContents) _then;

/// Create a copy of FolderContents
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? folderId = freezed,Object? folders = null,Object? documents = null,Object? notes = null,}) {
  return _then(_FolderContents(
folderId: freezed == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String?,folders: null == folders ? _self._folders : folders // ignore: cast_nullable_to_non_nullable
as List<Folder>,documents: null == documents ? _self._documents : documents // ignore: cast_nullable_to_non_nullable
as List<Document>,notes: null == notes ? _self._notes : notes // ignore: cast_nullable_to_non_nullable
as List<Note>,
  ));
}


}

// dart format on
