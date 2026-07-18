// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'asset_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AssetSnapshot {

 String get id; String get assetId; double get totalValue; DateTime get recordedAt; String? get note;
/// Create a copy of AssetSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssetSnapshotCopyWith<AssetSnapshot> get copyWith => _$AssetSnapshotCopyWithImpl<AssetSnapshot>(this as AssetSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssetSnapshot&&(identical(other.id, id) || other.id == id)&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.totalValue, totalValue) || other.totalValue == totalValue)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hash(runtimeType,id,assetId,totalValue,recordedAt,note);

@override
String toString() {
  return 'AssetSnapshot(id: $id, assetId: $assetId, totalValue: $totalValue, recordedAt: $recordedAt, note: $note)';
}


}

/// @nodoc
abstract mixin class $AssetSnapshotCopyWith<$Res>  {
  factory $AssetSnapshotCopyWith(AssetSnapshot value, $Res Function(AssetSnapshot) _then) = _$AssetSnapshotCopyWithImpl;
@useResult
$Res call({
 String id, String assetId, double totalValue, DateTime recordedAt, String? note
});




}
/// @nodoc
class _$AssetSnapshotCopyWithImpl<$Res>
    implements $AssetSnapshotCopyWith<$Res> {
  _$AssetSnapshotCopyWithImpl(this._self, this._then);

  final AssetSnapshot _self;
  final $Res Function(AssetSnapshot) _then;

/// Create a copy of AssetSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? assetId = null,Object? totalValue = null,Object? recordedAt = null,Object? note = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,assetId: null == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as String,totalValue: null == totalValue ? _self.totalValue : totalValue // ignore: cast_nullable_to_non_nullable
as double,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AssetSnapshot].
extension AssetSnapshotPatterns on AssetSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssetSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssetSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssetSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _AssetSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssetSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _AssetSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String assetId,  double totalValue,  DateTime recordedAt,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssetSnapshot() when $default != null:
return $default(_that.id,_that.assetId,_that.totalValue,_that.recordedAt,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String assetId,  double totalValue,  DateTime recordedAt,  String? note)  $default,) {final _that = this;
switch (_that) {
case _AssetSnapshot():
return $default(_that.id,_that.assetId,_that.totalValue,_that.recordedAt,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String assetId,  double totalValue,  DateTime recordedAt,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _AssetSnapshot() when $default != null:
return $default(_that.id,_that.assetId,_that.totalValue,_that.recordedAt,_that.note);case _:
  return null;

}
}

}

/// @nodoc


class _AssetSnapshot extends AssetSnapshot {
  const _AssetSnapshot({required this.id, required this.assetId, required this.totalValue, required this.recordedAt, this.note}): super._();
  

@override final  String id;
@override final  String assetId;
@override final  double totalValue;
@override final  DateTime recordedAt;
@override final  String? note;

/// Create a copy of AssetSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssetSnapshotCopyWith<_AssetSnapshot> get copyWith => __$AssetSnapshotCopyWithImpl<_AssetSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssetSnapshot&&(identical(other.id, id) || other.id == id)&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.totalValue, totalValue) || other.totalValue == totalValue)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hash(runtimeType,id,assetId,totalValue,recordedAt,note);

@override
String toString() {
  return 'AssetSnapshot(id: $id, assetId: $assetId, totalValue: $totalValue, recordedAt: $recordedAt, note: $note)';
}


}

/// @nodoc
abstract mixin class _$AssetSnapshotCopyWith<$Res> implements $AssetSnapshotCopyWith<$Res> {
  factory _$AssetSnapshotCopyWith(_AssetSnapshot value, $Res Function(_AssetSnapshot) _then) = __$AssetSnapshotCopyWithImpl;
@override @useResult
$Res call({
 String id, String assetId, double totalValue, DateTime recordedAt, String? note
});




}
/// @nodoc
class __$AssetSnapshotCopyWithImpl<$Res>
    implements _$AssetSnapshotCopyWith<$Res> {
  __$AssetSnapshotCopyWithImpl(this._self, this._then);

  final _AssetSnapshot _self;
  final $Res Function(_AssetSnapshot) _then;

/// Create a copy of AssetSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? assetId = null,Object? totalValue = null,Object? recordedAt = null,Object? note = freezed,}) {
  return _then(_AssetSnapshot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,assetId: null == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as String,totalValue: null == totalValue ? _self.totalValue : totalValue // ignore: cast_nullable_to_non_nullable
as double,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
