// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portfolio_position.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PortfolioPosition {

 Asset get asset; Holding get holding; double get allocationPercentage;
/// Create a copy of PortfolioPosition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortfolioPositionCopyWith<PortfolioPosition> get copyWith => _$PortfolioPositionCopyWithImpl<PortfolioPosition>(this as PortfolioPosition, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortfolioPosition&&(identical(other.asset, asset) || other.asset == asset)&&(identical(other.holding, holding) || other.holding == holding)&&(identical(other.allocationPercentage, allocationPercentage) || other.allocationPercentage == allocationPercentage));
}


@override
int get hashCode => Object.hash(runtimeType,asset,holding,allocationPercentage);

@override
String toString() {
  return 'PortfolioPosition(asset: $asset, holding: $holding, allocationPercentage: $allocationPercentage)';
}


}

/// @nodoc
abstract mixin class $PortfolioPositionCopyWith<$Res>  {
  factory $PortfolioPositionCopyWith(PortfolioPosition value, $Res Function(PortfolioPosition) _then) = _$PortfolioPositionCopyWithImpl;
@useResult
$Res call({
 Asset asset, Holding holding, double allocationPercentage
});


$AssetCopyWith<$Res> get asset;$HoldingCopyWith<$Res> get holding;

}
/// @nodoc
class _$PortfolioPositionCopyWithImpl<$Res>
    implements $PortfolioPositionCopyWith<$Res> {
  _$PortfolioPositionCopyWithImpl(this._self, this._then);

  final PortfolioPosition _self;
  final $Res Function(PortfolioPosition) _then;

/// Create a copy of PortfolioPosition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? asset = null,Object? holding = null,Object? allocationPercentage = null,}) {
  return _then(_self.copyWith(
asset: null == asset ? _self.asset : asset // ignore: cast_nullable_to_non_nullable
as Asset,holding: null == holding ? _self.holding : holding // ignore: cast_nullable_to_non_nullable
as Holding,allocationPercentage: null == allocationPercentage ? _self.allocationPercentage : allocationPercentage // ignore: cast_nullable_to_non_nullable
as double,
  ));
}
/// Create a copy of PortfolioPosition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AssetCopyWith<$Res> get asset {
  
  return $AssetCopyWith<$Res>(_self.asset, (value) {
    return _then(_self.copyWith(asset: value));
  });
}/// Create a copy of PortfolioPosition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HoldingCopyWith<$Res> get holding {
  
  return $HoldingCopyWith<$Res>(_self.holding, (value) {
    return _then(_self.copyWith(holding: value));
  });
}
}


/// Adds pattern-matching-related methods to [PortfolioPosition].
extension PortfolioPositionPatterns on PortfolioPosition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortfolioPosition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortfolioPosition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortfolioPosition value)  $default,){
final _that = this;
switch (_that) {
case _PortfolioPosition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortfolioPosition value)?  $default,){
final _that = this;
switch (_that) {
case _PortfolioPosition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Asset asset,  Holding holding,  double allocationPercentage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortfolioPosition() when $default != null:
return $default(_that.asset,_that.holding,_that.allocationPercentage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Asset asset,  Holding holding,  double allocationPercentage)  $default,) {final _that = this;
switch (_that) {
case _PortfolioPosition():
return $default(_that.asset,_that.holding,_that.allocationPercentage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Asset asset,  Holding holding,  double allocationPercentage)?  $default,) {final _that = this;
switch (_that) {
case _PortfolioPosition() when $default != null:
return $default(_that.asset,_that.holding,_that.allocationPercentage);case _:
  return null;

}
}

}

/// @nodoc


class _PortfolioPosition extends PortfolioPosition {
  const _PortfolioPosition({required this.asset, required this.holding, required this.allocationPercentage}): super._();
  

@override final  Asset asset;
@override final  Holding holding;
@override final  double allocationPercentage;

/// Create a copy of PortfolioPosition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortfolioPositionCopyWith<_PortfolioPosition> get copyWith => __$PortfolioPositionCopyWithImpl<_PortfolioPosition>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortfolioPosition&&(identical(other.asset, asset) || other.asset == asset)&&(identical(other.holding, holding) || other.holding == holding)&&(identical(other.allocationPercentage, allocationPercentage) || other.allocationPercentage == allocationPercentage));
}


@override
int get hashCode => Object.hash(runtimeType,asset,holding,allocationPercentage);

@override
String toString() {
  return 'PortfolioPosition(asset: $asset, holding: $holding, allocationPercentage: $allocationPercentage)';
}


}

/// @nodoc
abstract mixin class _$PortfolioPositionCopyWith<$Res> implements $PortfolioPositionCopyWith<$Res> {
  factory _$PortfolioPositionCopyWith(_PortfolioPosition value, $Res Function(_PortfolioPosition) _then) = __$PortfolioPositionCopyWithImpl;
@override @useResult
$Res call({
 Asset asset, Holding holding, double allocationPercentage
});


@override $AssetCopyWith<$Res> get asset;@override $HoldingCopyWith<$Res> get holding;

}
/// @nodoc
class __$PortfolioPositionCopyWithImpl<$Res>
    implements _$PortfolioPositionCopyWith<$Res> {
  __$PortfolioPositionCopyWithImpl(this._self, this._then);

  final _PortfolioPosition _self;
  final $Res Function(_PortfolioPosition) _then;

/// Create a copy of PortfolioPosition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? asset = null,Object? holding = null,Object? allocationPercentage = null,}) {
  return _then(_PortfolioPosition(
asset: null == asset ? _self.asset : asset // ignore: cast_nullable_to_non_nullable
as Asset,holding: null == holding ? _self.holding : holding // ignore: cast_nullable_to_non_nullable
as Holding,allocationPercentage: null == allocationPercentage ? _self.allocationPercentage : allocationPercentage // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

/// Create a copy of PortfolioPosition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AssetCopyWith<$Res> get asset {
  
  return $AssetCopyWith<$Res>(_self.asset, (value) {
    return _then(_self.copyWith(asset: value));
  });
}/// Create a copy of PortfolioPosition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HoldingCopyWith<$Res> get holding {
  
  return $HoldingCopyWith<$Res>(_self.holding, (value) {
    return _then(_self.copyWith(holding: value));
  });
}
}

// dart format on
