// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'allocation_target.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AllocationTarget {

 String get id; AssetCategory get category; double get targetPercentage;
/// Create a copy of AllocationTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AllocationTargetCopyWith<AllocationTarget> get copyWith => _$AllocationTargetCopyWithImpl<AllocationTarget>(this as AllocationTarget, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AllocationTarget&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&(identical(other.targetPercentage, targetPercentage) || other.targetPercentage == targetPercentage));
}


@override
int get hashCode => Object.hash(runtimeType,id,category,targetPercentage);

@override
String toString() {
  return 'AllocationTarget(id: $id, category: $category, targetPercentage: $targetPercentage)';
}


}

/// @nodoc
abstract mixin class $AllocationTargetCopyWith<$Res>  {
  factory $AllocationTargetCopyWith(AllocationTarget value, $Res Function(AllocationTarget) _then) = _$AllocationTargetCopyWithImpl;
@useResult
$Res call({
 String id, AssetCategory category, double targetPercentage
});




}
/// @nodoc
class _$AllocationTargetCopyWithImpl<$Res>
    implements $AllocationTargetCopyWith<$Res> {
  _$AllocationTargetCopyWithImpl(this._self, this._then);

  final AllocationTarget _self;
  final $Res Function(AllocationTarget) _then;

/// Create a copy of AllocationTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? category = null,Object? targetPercentage = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as AssetCategory,targetPercentage: null == targetPercentage ? _self.targetPercentage : targetPercentage // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [AllocationTarget].
extension AllocationTargetPatterns on AllocationTarget {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AllocationTarget value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AllocationTarget() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AllocationTarget value)  $default,){
final _that = this;
switch (_that) {
case _AllocationTarget():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AllocationTarget value)?  $default,){
final _that = this;
switch (_that) {
case _AllocationTarget() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  AssetCategory category,  double targetPercentage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AllocationTarget() when $default != null:
return $default(_that.id,_that.category,_that.targetPercentage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  AssetCategory category,  double targetPercentage)  $default,) {final _that = this;
switch (_that) {
case _AllocationTarget():
return $default(_that.id,_that.category,_that.targetPercentage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  AssetCategory category,  double targetPercentage)?  $default,) {final _that = this;
switch (_that) {
case _AllocationTarget() when $default != null:
return $default(_that.id,_that.category,_that.targetPercentage);case _:
  return null;

}
}

}

/// @nodoc


class _AllocationTarget extends AllocationTarget {
  const _AllocationTarget({required this.id, required this.category, required this.targetPercentage}): super._();
  

@override final  String id;
@override final  AssetCategory category;
@override final  double targetPercentage;

/// Create a copy of AllocationTarget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AllocationTargetCopyWith<_AllocationTarget> get copyWith => __$AllocationTargetCopyWithImpl<_AllocationTarget>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AllocationTarget&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&(identical(other.targetPercentage, targetPercentage) || other.targetPercentage == targetPercentage));
}


@override
int get hashCode => Object.hash(runtimeType,id,category,targetPercentage);

@override
String toString() {
  return 'AllocationTarget(id: $id, category: $category, targetPercentage: $targetPercentage)';
}


}

/// @nodoc
abstract mixin class _$AllocationTargetCopyWith<$Res> implements $AllocationTargetCopyWith<$Res> {
  factory _$AllocationTargetCopyWith(_AllocationTarget value, $Res Function(_AllocationTarget) _then) = __$AllocationTargetCopyWithImpl;
@override @useResult
$Res call({
 String id, AssetCategory category, double targetPercentage
});




}
/// @nodoc
class __$AllocationTargetCopyWithImpl<$Res>
    implements _$AllocationTargetCopyWith<$Res> {
  __$AllocationTargetCopyWithImpl(this._self, this._then);

  final _AllocationTarget _self;
  final $Res Function(_AllocationTarget) _then;

/// Create a copy of AllocationTarget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? category = null,Object? targetPercentage = null,}) {
  return _then(_AllocationTarget(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as AssetCategory,targetPercentage: null == targetPercentage ? _self.targetPercentage : targetPercentage // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
