// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'price_series.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PricePoint {

 DateTime get time; double get close;
/// Create a copy of PricePoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PricePointCopyWith<PricePoint> get copyWith => _$PricePointCopyWithImpl<PricePoint>(this as PricePoint, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PricePoint&&(identical(other.time, time) || other.time == time)&&(identical(other.close, close) || other.close == close));
}


@override
int get hashCode => Object.hash(runtimeType,time,close);

@override
String toString() {
  return 'PricePoint(time: $time, close: $close)';
}


}

/// @nodoc
abstract mixin class $PricePointCopyWith<$Res>  {
  factory $PricePointCopyWith(PricePoint value, $Res Function(PricePoint) _then) = _$PricePointCopyWithImpl;
@useResult
$Res call({
 DateTime time, double close
});




}
/// @nodoc
class _$PricePointCopyWithImpl<$Res>
    implements $PricePointCopyWith<$Res> {
  _$PricePointCopyWithImpl(this._self, this._then);

  final PricePoint _self;
  final $Res Function(PricePoint) _then;

/// Create a copy of PricePoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? time = null,Object? close = null,}) {
  return _then(_self.copyWith(
time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as DateTime,close: null == close ? _self.close : close // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [PricePoint].
extension PricePointPatterns on PricePoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PricePoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PricePoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PricePoint value)  $default,){
final _that = this;
switch (_that) {
case _PricePoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PricePoint value)?  $default,){
final _that = this;
switch (_that) {
case _PricePoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime time,  double close)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PricePoint() when $default != null:
return $default(_that.time,_that.close);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime time,  double close)  $default,) {final _that = this;
switch (_that) {
case _PricePoint():
return $default(_that.time,_that.close);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime time,  double close)?  $default,) {final _that = this;
switch (_that) {
case _PricePoint() when $default != null:
return $default(_that.time,_that.close);case _:
  return null;

}
}

}

/// @nodoc


class _PricePoint implements PricePoint {
  const _PricePoint({required this.time, required this.close});
  

@override final  DateTime time;
@override final  double close;

/// Create a copy of PricePoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PricePointCopyWith<_PricePoint> get copyWith => __$PricePointCopyWithImpl<_PricePoint>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PricePoint&&(identical(other.time, time) || other.time == time)&&(identical(other.close, close) || other.close == close));
}


@override
int get hashCode => Object.hash(runtimeType,time,close);

@override
String toString() {
  return 'PricePoint(time: $time, close: $close)';
}


}

/// @nodoc
abstract mixin class _$PricePointCopyWith<$Res> implements $PricePointCopyWith<$Res> {
  factory _$PricePointCopyWith(_PricePoint value, $Res Function(_PricePoint) _then) = __$PricePointCopyWithImpl;
@override @useResult
$Res call({
 DateTime time, double close
});




}
/// @nodoc
class __$PricePointCopyWithImpl<$Res>
    implements _$PricePointCopyWith<$Res> {
  __$PricePointCopyWithImpl(this._self, this._then);

  final _PricePoint _self;
  final $Res Function(_PricePoint) _then;

/// Create a copy of PricePoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? time = null,Object? close = null,}) {
  return _then(_PricePoint(
time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as DateTime,close: null == close ? _self.close : close // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$PriceSeries {

 String get symbol; String get currency; ChartRange get range; List<PricePoint> get points;/// Dari `meta.chartPreviousClose`; harga acuan untuk range
/// [ChartRange.oneDay].
 double? get previousClose;
/// Create a copy of PriceSeries
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PriceSeriesCopyWith<PriceSeries> get copyWith => _$PriceSeriesCopyWithImpl<PriceSeries>(this as PriceSeries, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PriceSeries&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.range, range) || other.range == range)&&const DeepCollectionEquality().equals(other.points, points)&&(identical(other.previousClose, previousClose) || other.previousClose == previousClose));
}


@override
int get hashCode => Object.hash(runtimeType,symbol,currency,range,const DeepCollectionEquality().hash(points),previousClose);

@override
String toString() {
  return 'PriceSeries(symbol: $symbol, currency: $currency, range: $range, points: $points, previousClose: $previousClose)';
}


}

/// @nodoc
abstract mixin class $PriceSeriesCopyWith<$Res>  {
  factory $PriceSeriesCopyWith(PriceSeries value, $Res Function(PriceSeries) _then) = _$PriceSeriesCopyWithImpl;
@useResult
$Res call({
 String symbol, String currency, ChartRange range, List<PricePoint> points, double? previousClose
});




}
/// @nodoc
class _$PriceSeriesCopyWithImpl<$Res>
    implements $PriceSeriesCopyWith<$Res> {
  _$PriceSeriesCopyWithImpl(this._self, this._then);

  final PriceSeries _self;
  final $Res Function(PriceSeries) _then;

/// Create a copy of PriceSeries
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? symbol = null,Object? currency = null,Object? range = null,Object? points = null,Object? previousClose = freezed,}) {
  return _then(_self.copyWith(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as ChartRange,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as List<PricePoint>,previousClose: freezed == previousClose ? _self.previousClose : previousClose // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [PriceSeries].
extension PriceSeriesPatterns on PriceSeries {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PriceSeries value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PriceSeries() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PriceSeries value)  $default,){
final _that = this;
switch (_that) {
case _PriceSeries():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PriceSeries value)?  $default,){
final _that = this;
switch (_that) {
case _PriceSeries() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String symbol,  String currency,  ChartRange range,  List<PricePoint> points,  double? previousClose)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PriceSeries() when $default != null:
return $default(_that.symbol,_that.currency,_that.range,_that.points,_that.previousClose);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String symbol,  String currency,  ChartRange range,  List<PricePoint> points,  double? previousClose)  $default,) {final _that = this;
switch (_that) {
case _PriceSeries():
return $default(_that.symbol,_that.currency,_that.range,_that.points,_that.previousClose);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String symbol,  String currency,  ChartRange range,  List<PricePoint> points,  double? previousClose)?  $default,) {final _that = this;
switch (_that) {
case _PriceSeries() when $default != null:
return $default(_that.symbol,_that.currency,_that.range,_that.points,_that.previousClose);case _:
  return null;

}
}

}

/// @nodoc


class _PriceSeries implements PriceSeries {
  const _PriceSeries({required this.symbol, required this.currency, required this.range, required final  List<PricePoint> points, this.previousClose}): _points = points;
  

@override final  String symbol;
@override final  String currency;
@override final  ChartRange range;
 final  List<PricePoint> _points;
@override List<PricePoint> get points {
  if (_points is EqualUnmodifiableListView) return _points;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_points);
}

/// Dari `meta.chartPreviousClose`; harga acuan untuk range
/// [ChartRange.oneDay].
@override final  double? previousClose;

/// Create a copy of PriceSeries
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PriceSeriesCopyWith<_PriceSeries> get copyWith => __$PriceSeriesCopyWithImpl<_PriceSeries>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PriceSeries&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.range, range) || other.range == range)&&const DeepCollectionEquality().equals(other._points, _points)&&(identical(other.previousClose, previousClose) || other.previousClose == previousClose));
}


@override
int get hashCode => Object.hash(runtimeType,symbol,currency,range,const DeepCollectionEquality().hash(_points),previousClose);

@override
String toString() {
  return 'PriceSeries(symbol: $symbol, currency: $currency, range: $range, points: $points, previousClose: $previousClose)';
}


}

/// @nodoc
abstract mixin class _$PriceSeriesCopyWith<$Res> implements $PriceSeriesCopyWith<$Res> {
  factory _$PriceSeriesCopyWith(_PriceSeries value, $Res Function(_PriceSeries) _then) = __$PriceSeriesCopyWithImpl;
@override @useResult
$Res call({
 String symbol, String currency, ChartRange range, List<PricePoint> points, double? previousClose
});




}
/// @nodoc
class __$PriceSeriesCopyWithImpl<$Res>
    implements _$PriceSeriesCopyWith<$Res> {
  __$PriceSeriesCopyWithImpl(this._self, this._then);

  final _PriceSeries _self;
  final $Res Function(_PriceSeries) _then;

/// Create a copy of PriceSeries
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? symbol = null,Object? currency = null,Object? range = null,Object? points = null,Object? previousClose = freezed,}) {
  return _then(_PriceSeries(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as ChartRange,points: null == points ? _self._points : points // ignore: cast_nullable_to_non_nullable
as List<PricePoint>,previousClose: freezed == previousClose ? _self.previousClose : previousClose // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
