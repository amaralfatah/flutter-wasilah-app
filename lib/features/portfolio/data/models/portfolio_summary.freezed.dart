// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portfolio_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PortfolioSummary {

 double get totalValue; double get monthlyChangePercentage; double get targetProgressPercentage; List<Asset> get assets; DateTime get lastUpdatedAt;
/// Create a copy of PortfolioSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortfolioSummaryCopyWith<PortfolioSummary> get copyWith => _$PortfolioSummaryCopyWithImpl<PortfolioSummary>(this as PortfolioSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortfolioSummary&&(identical(other.totalValue, totalValue) || other.totalValue == totalValue)&&(identical(other.monthlyChangePercentage, monthlyChangePercentage) || other.monthlyChangePercentage == monthlyChangePercentage)&&(identical(other.targetProgressPercentage, targetProgressPercentage) || other.targetProgressPercentage == targetProgressPercentage)&&const DeepCollectionEquality().equals(other.assets, assets)&&(identical(other.lastUpdatedAt, lastUpdatedAt) || other.lastUpdatedAt == lastUpdatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,totalValue,monthlyChangePercentage,targetProgressPercentage,const DeepCollectionEquality().hash(assets),lastUpdatedAt);

@override
String toString() {
  return 'PortfolioSummary(totalValue: $totalValue, monthlyChangePercentage: $monthlyChangePercentage, targetProgressPercentage: $targetProgressPercentage, assets: $assets, lastUpdatedAt: $lastUpdatedAt)';
}


}

/// @nodoc
abstract mixin class $PortfolioSummaryCopyWith<$Res>  {
  factory $PortfolioSummaryCopyWith(PortfolioSummary value, $Res Function(PortfolioSummary) _then) = _$PortfolioSummaryCopyWithImpl;
@useResult
$Res call({
 double totalValue, double monthlyChangePercentage, double targetProgressPercentage, List<Asset> assets, DateTime lastUpdatedAt
});




}
/// @nodoc
class _$PortfolioSummaryCopyWithImpl<$Res>
    implements $PortfolioSummaryCopyWith<$Res> {
  _$PortfolioSummaryCopyWithImpl(this._self, this._then);

  final PortfolioSummary _self;
  final $Res Function(PortfolioSummary) _then;

/// Create a copy of PortfolioSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalValue = null,Object? monthlyChangePercentage = null,Object? targetProgressPercentage = null,Object? assets = null,Object? lastUpdatedAt = null,}) {
  return _then(_self.copyWith(
totalValue: null == totalValue ? _self.totalValue : totalValue // ignore: cast_nullable_to_non_nullable
as double,monthlyChangePercentage: null == monthlyChangePercentage ? _self.monthlyChangePercentage : monthlyChangePercentage // ignore: cast_nullable_to_non_nullable
as double,targetProgressPercentage: null == targetProgressPercentage ? _self.targetProgressPercentage : targetProgressPercentage // ignore: cast_nullable_to_non_nullable
as double,assets: null == assets ? _self.assets : assets // ignore: cast_nullable_to_non_nullable
as List<Asset>,lastUpdatedAt: null == lastUpdatedAt ? _self.lastUpdatedAt : lastUpdatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PortfolioSummary].
extension PortfolioSummaryPatterns on PortfolioSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortfolioSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortfolioSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortfolioSummary value)  $default,){
final _that = this;
switch (_that) {
case _PortfolioSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortfolioSummary value)?  $default,){
final _that = this;
switch (_that) {
case _PortfolioSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double totalValue,  double monthlyChangePercentage,  double targetProgressPercentage,  List<Asset> assets,  DateTime lastUpdatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortfolioSummary() when $default != null:
return $default(_that.totalValue,_that.monthlyChangePercentage,_that.targetProgressPercentage,_that.assets,_that.lastUpdatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double totalValue,  double monthlyChangePercentage,  double targetProgressPercentage,  List<Asset> assets,  DateTime lastUpdatedAt)  $default,) {final _that = this;
switch (_that) {
case _PortfolioSummary():
return $default(_that.totalValue,_that.monthlyChangePercentage,_that.targetProgressPercentage,_that.assets,_that.lastUpdatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double totalValue,  double monthlyChangePercentage,  double targetProgressPercentage,  List<Asset> assets,  DateTime lastUpdatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PortfolioSummary() when $default != null:
return $default(_that.totalValue,_that.monthlyChangePercentage,_that.targetProgressPercentage,_that.assets,_that.lastUpdatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _PortfolioSummary extends PortfolioSummary {
  const _PortfolioSummary({required this.totalValue, required this.monthlyChangePercentage, required this.targetProgressPercentage, required final  List<Asset> assets, required this.lastUpdatedAt}): _assets = assets,super._();
  

@override final  double totalValue;
@override final  double monthlyChangePercentage;
@override final  double targetProgressPercentage;
 final  List<Asset> _assets;
@override List<Asset> get assets {
  if (_assets is EqualUnmodifiableListView) return _assets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_assets);
}

@override final  DateTime lastUpdatedAt;

/// Create a copy of PortfolioSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortfolioSummaryCopyWith<_PortfolioSummary> get copyWith => __$PortfolioSummaryCopyWithImpl<_PortfolioSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortfolioSummary&&(identical(other.totalValue, totalValue) || other.totalValue == totalValue)&&(identical(other.monthlyChangePercentage, monthlyChangePercentage) || other.monthlyChangePercentage == monthlyChangePercentage)&&(identical(other.targetProgressPercentage, targetProgressPercentage) || other.targetProgressPercentage == targetProgressPercentage)&&const DeepCollectionEquality().equals(other._assets, _assets)&&(identical(other.lastUpdatedAt, lastUpdatedAt) || other.lastUpdatedAt == lastUpdatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,totalValue,monthlyChangePercentage,targetProgressPercentage,const DeepCollectionEquality().hash(_assets),lastUpdatedAt);

@override
String toString() {
  return 'PortfolioSummary(totalValue: $totalValue, monthlyChangePercentage: $monthlyChangePercentage, targetProgressPercentage: $targetProgressPercentage, assets: $assets, lastUpdatedAt: $lastUpdatedAt)';
}


}

/// @nodoc
abstract mixin class _$PortfolioSummaryCopyWith<$Res> implements $PortfolioSummaryCopyWith<$Res> {
  factory _$PortfolioSummaryCopyWith(_PortfolioSummary value, $Res Function(_PortfolioSummary) _then) = __$PortfolioSummaryCopyWithImpl;
@override @useResult
$Res call({
 double totalValue, double monthlyChangePercentage, double targetProgressPercentage, List<Asset> assets, DateTime lastUpdatedAt
});




}
/// @nodoc
class __$PortfolioSummaryCopyWithImpl<$Res>
    implements _$PortfolioSummaryCopyWith<$Res> {
  __$PortfolioSummaryCopyWithImpl(this._self, this._then);

  final _PortfolioSummary _self;
  final $Res Function(_PortfolioSummary) _then;

/// Create a copy of PortfolioSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalValue = null,Object? monthlyChangePercentage = null,Object? targetProgressPercentage = null,Object? assets = null,Object? lastUpdatedAt = null,}) {
  return _then(_PortfolioSummary(
totalValue: null == totalValue ? _self.totalValue : totalValue // ignore: cast_nullable_to_non_nullable
as double,monthlyChangePercentage: null == monthlyChangePercentage ? _self.monthlyChangePercentage : monthlyChangePercentage // ignore: cast_nullable_to_non_nullable
as double,targetProgressPercentage: null == targetProgressPercentage ? _self.targetProgressPercentage : targetProgressPercentage // ignore: cast_nullable_to_non_nullable
as double,assets: null == assets ? _self._assets : assets // ignore: cast_nullable_to_non_nullable
as List<Asset>,lastUpdatedAt: null == lastUpdatedAt ? _self.lastUpdatedAt : lastUpdatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
