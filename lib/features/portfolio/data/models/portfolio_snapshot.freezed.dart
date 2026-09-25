// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portfolio_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PortfolioSnapshot {

 String get id; double get totalValue; DateTime get recordedAt; String? get note;/// Total modal gabungan per tanggal pencatatan; `null` bila belum ada
/// satu aset pun yang punya modal.
 double? get totalCost;
/// Create a copy of PortfolioSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortfolioSnapshotCopyWith<PortfolioSnapshot> get copyWith => _$PortfolioSnapshotCopyWithImpl<PortfolioSnapshot>(this as PortfolioSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortfolioSnapshot&&(identical(other.id, id) || other.id == id)&&(identical(other.totalValue, totalValue) || other.totalValue == totalValue)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&(identical(other.note, note) || other.note == note)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost));
}


@override
int get hashCode => Object.hash(runtimeType,id,totalValue,recordedAt,note,totalCost);

@override
String toString() {
  return 'PortfolioSnapshot(id: $id, totalValue: $totalValue, recordedAt: $recordedAt, note: $note, totalCost: $totalCost)';
}


}

/// @nodoc
abstract mixin class $PortfolioSnapshotCopyWith<$Res>  {
  factory $PortfolioSnapshotCopyWith(PortfolioSnapshot value, $Res Function(PortfolioSnapshot) _then) = _$PortfolioSnapshotCopyWithImpl;
@useResult
$Res call({
 String id, double totalValue, DateTime recordedAt, String? note, double? totalCost
});




}
/// @nodoc
class _$PortfolioSnapshotCopyWithImpl<$Res>
    implements $PortfolioSnapshotCopyWith<$Res> {
  _$PortfolioSnapshotCopyWithImpl(this._self, this._then);

  final PortfolioSnapshot _self;
  final $Res Function(PortfolioSnapshot) _then;

/// Create a copy of PortfolioSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? totalValue = null,Object? recordedAt = null,Object? note = freezed,Object? totalCost = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,totalValue: null == totalValue ? _self.totalValue : totalValue // ignore: cast_nullable_to_non_nullable
as double,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,totalCost: freezed == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [PortfolioSnapshot].
extension PortfolioSnapshotPatterns on PortfolioSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortfolioSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortfolioSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortfolioSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _PortfolioSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortfolioSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _PortfolioSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  double totalValue,  DateTime recordedAt,  String? note,  double? totalCost)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortfolioSnapshot() when $default != null:
return $default(_that.id,_that.totalValue,_that.recordedAt,_that.note,_that.totalCost);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  double totalValue,  DateTime recordedAt,  String? note,  double? totalCost)  $default,) {final _that = this;
switch (_that) {
case _PortfolioSnapshot():
return $default(_that.id,_that.totalValue,_that.recordedAt,_that.note,_that.totalCost);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  double totalValue,  DateTime recordedAt,  String? note,  double? totalCost)?  $default,) {final _that = this;
switch (_that) {
case _PortfolioSnapshot() when $default != null:
return $default(_that.id,_that.totalValue,_that.recordedAt,_that.note,_that.totalCost);case _:
  return null;

}
}

}

/// @nodoc


class _PortfolioSnapshot extends PortfolioSnapshot {
  const _PortfolioSnapshot({required this.id, required this.totalValue, required this.recordedAt, this.note, this.totalCost}): super._();
  

@override final  String id;
@override final  double totalValue;
@override final  DateTime recordedAt;
@override final  String? note;
/// Total modal gabungan per tanggal pencatatan; `null` bila belum ada
/// satu aset pun yang punya modal.
@override final  double? totalCost;

/// Create a copy of PortfolioSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortfolioSnapshotCopyWith<_PortfolioSnapshot> get copyWith => __$PortfolioSnapshotCopyWithImpl<_PortfolioSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortfolioSnapshot&&(identical(other.id, id) || other.id == id)&&(identical(other.totalValue, totalValue) || other.totalValue == totalValue)&&(identical(other.recordedAt, recordedAt) || other.recordedAt == recordedAt)&&(identical(other.note, note) || other.note == note)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost));
}


@override
int get hashCode => Object.hash(runtimeType,id,totalValue,recordedAt,note,totalCost);

@override
String toString() {
  return 'PortfolioSnapshot(id: $id, totalValue: $totalValue, recordedAt: $recordedAt, note: $note, totalCost: $totalCost)';
}


}

/// @nodoc
abstract mixin class _$PortfolioSnapshotCopyWith<$Res> implements $PortfolioSnapshotCopyWith<$Res> {
  factory _$PortfolioSnapshotCopyWith(_PortfolioSnapshot value, $Res Function(_PortfolioSnapshot) _then) = __$PortfolioSnapshotCopyWithImpl;
@override @useResult
$Res call({
 String id, double totalValue, DateTime recordedAt, String? note, double? totalCost
});




}
/// @nodoc
class __$PortfolioSnapshotCopyWithImpl<$Res>
    implements _$PortfolioSnapshotCopyWith<$Res> {
  __$PortfolioSnapshotCopyWithImpl(this._self, this._then);

  final _PortfolioSnapshot _self;
  final $Res Function(_PortfolioSnapshot) _then;

/// Create a copy of PortfolioSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? totalValue = null,Object? recordedAt = null,Object? note = freezed,Object? totalCost = freezed,}) {
  return _then(_PortfolioSnapshot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,totalValue: null == totalValue ? _self.totalValue : totalValue // ignore: cast_nullable_to_non_nullable
as double,recordedAt: null == recordedAt ? _self.recordedAt : recordedAt // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,totalCost: freezed == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
