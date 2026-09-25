// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'market_quote.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MarketQuote {

 String get symbol; String get currency; double get price; DateTime get marketTime; DateTime get fetchedAt;/// Penutupan sebelumnya; `null` bila Yahoo tidak mengirimkannya.
 double? get previousClose;/// Statistik perdagangan dari `meta` Yahoo. Semuanya `null` bila quote
/// datang dari cache (kolom ini tidak dipersist) atau Yahoo tidak
/// mengirimkannya. Bagian statistik di UI hanya tampil bila ada isinya.
 double? get dayHigh; double? get dayLow; double? get fiftyTwoWeekHigh; double? get fiftyTwoWeekLow; double? get volume;
/// Create a copy of MarketQuote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarketQuoteCopyWith<MarketQuote> get copyWith => _$MarketQuoteCopyWithImpl<MarketQuote>(this as MarketQuote, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarketQuote&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.price, price) || other.price == price)&&(identical(other.marketTime, marketTime) || other.marketTime == marketTime)&&(identical(other.fetchedAt, fetchedAt) || other.fetchedAt == fetchedAt)&&(identical(other.previousClose, previousClose) || other.previousClose == previousClose)&&(identical(other.dayHigh, dayHigh) || other.dayHigh == dayHigh)&&(identical(other.dayLow, dayLow) || other.dayLow == dayLow)&&(identical(other.fiftyTwoWeekHigh, fiftyTwoWeekHigh) || other.fiftyTwoWeekHigh == fiftyTwoWeekHigh)&&(identical(other.fiftyTwoWeekLow, fiftyTwoWeekLow) || other.fiftyTwoWeekLow == fiftyTwoWeekLow)&&(identical(other.volume, volume) || other.volume == volume));
}


@override
int get hashCode => Object.hash(runtimeType,symbol,currency,price,marketTime,fetchedAt,previousClose,dayHigh,dayLow,fiftyTwoWeekHigh,fiftyTwoWeekLow,volume);

@override
String toString() {
  return 'MarketQuote(symbol: $symbol, currency: $currency, price: $price, marketTime: $marketTime, fetchedAt: $fetchedAt, previousClose: $previousClose, dayHigh: $dayHigh, dayLow: $dayLow, fiftyTwoWeekHigh: $fiftyTwoWeekHigh, fiftyTwoWeekLow: $fiftyTwoWeekLow, volume: $volume)';
}


}

/// @nodoc
abstract mixin class $MarketQuoteCopyWith<$Res>  {
  factory $MarketQuoteCopyWith(MarketQuote value, $Res Function(MarketQuote) _then) = _$MarketQuoteCopyWithImpl;
@useResult
$Res call({
 String symbol, String currency, double price, DateTime marketTime, DateTime fetchedAt, double? previousClose, double? dayHigh, double? dayLow, double? fiftyTwoWeekHigh, double? fiftyTwoWeekLow, double? volume
});




}
/// @nodoc
class _$MarketQuoteCopyWithImpl<$Res>
    implements $MarketQuoteCopyWith<$Res> {
  _$MarketQuoteCopyWithImpl(this._self, this._then);

  final MarketQuote _self;
  final $Res Function(MarketQuote) _then;

/// Create a copy of MarketQuote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? symbol = null,Object? currency = null,Object? price = null,Object? marketTime = null,Object? fetchedAt = null,Object? previousClose = freezed,Object? dayHigh = freezed,Object? dayLow = freezed,Object? fiftyTwoWeekHigh = freezed,Object? fiftyTwoWeekLow = freezed,Object? volume = freezed,}) {
  return _then(_self.copyWith(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,marketTime: null == marketTime ? _self.marketTime : marketTime // ignore: cast_nullable_to_non_nullable
as DateTime,fetchedAt: null == fetchedAt ? _self.fetchedAt : fetchedAt // ignore: cast_nullable_to_non_nullable
as DateTime,previousClose: freezed == previousClose ? _self.previousClose : previousClose // ignore: cast_nullable_to_non_nullable
as double?,dayHigh: freezed == dayHigh ? _self.dayHigh : dayHigh // ignore: cast_nullable_to_non_nullable
as double?,dayLow: freezed == dayLow ? _self.dayLow : dayLow // ignore: cast_nullable_to_non_nullable
as double?,fiftyTwoWeekHigh: freezed == fiftyTwoWeekHigh ? _self.fiftyTwoWeekHigh : fiftyTwoWeekHigh // ignore: cast_nullable_to_non_nullable
as double?,fiftyTwoWeekLow: freezed == fiftyTwoWeekLow ? _self.fiftyTwoWeekLow : fiftyTwoWeekLow // ignore: cast_nullable_to_non_nullable
as double?,volume: freezed == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [MarketQuote].
extension MarketQuotePatterns on MarketQuote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MarketQuote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MarketQuote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MarketQuote value)  $default,){
final _that = this;
switch (_that) {
case _MarketQuote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MarketQuote value)?  $default,){
final _that = this;
switch (_that) {
case _MarketQuote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String symbol,  String currency,  double price,  DateTime marketTime,  DateTime fetchedAt,  double? previousClose,  double? dayHigh,  double? dayLow,  double? fiftyTwoWeekHigh,  double? fiftyTwoWeekLow,  double? volume)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MarketQuote() when $default != null:
return $default(_that.symbol,_that.currency,_that.price,_that.marketTime,_that.fetchedAt,_that.previousClose,_that.dayHigh,_that.dayLow,_that.fiftyTwoWeekHigh,_that.fiftyTwoWeekLow,_that.volume);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String symbol,  String currency,  double price,  DateTime marketTime,  DateTime fetchedAt,  double? previousClose,  double? dayHigh,  double? dayLow,  double? fiftyTwoWeekHigh,  double? fiftyTwoWeekLow,  double? volume)  $default,) {final _that = this;
switch (_that) {
case _MarketQuote():
return $default(_that.symbol,_that.currency,_that.price,_that.marketTime,_that.fetchedAt,_that.previousClose,_that.dayHigh,_that.dayLow,_that.fiftyTwoWeekHigh,_that.fiftyTwoWeekLow,_that.volume);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String symbol,  String currency,  double price,  DateTime marketTime,  DateTime fetchedAt,  double? previousClose,  double? dayHigh,  double? dayLow,  double? fiftyTwoWeekHigh,  double? fiftyTwoWeekLow,  double? volume)?  $default,) {final _that = this;
switch (_that) {
case _MarketQuote() when $default != null:
return $default(_that.symbol,_that.currency,_that.price,_that.marketTime,_that.fetchedAt,_that.previousClose,_that.dayHigh,_that.dayLow,_that.fiftyTwoWeekHigh,_that.fiftyTwoWeekLow,_that.volume);case _:
  return null;

}
}

}

/// @nodoc


class _MarketQuote extends MarketQuote {
  const _MarketQuote({required this.symbol, required this.currency, required this.price, required this.marketTime, required this.fetchedAt, this.previousClose, this.dayHigh, this.dayLow, this.fiftyTwoWeekHigh, this.fiftyTwoWeekLow, this.volume}): super._();
  

@override final  String symbol;
@override final  String currency;
@override final  double price;
@override final  DateTime marketTime;
@override final  DateTime fetchedAt;
/// Penutupan sebelumnya; `null` bila Yahoo tidak mengirimkannya.
@override final  double? previousClose;
/// Statistik perdagangan dari `meta` Yahoo. Semuanya `null` bila quote
/// datang dari cache (kolom ini tidak dipersist) atau Yahoo tidak
/// mengirimkannya. Bagian statistik di UI hanya tampil bila ada isinya.
@override final  double? dayHigh;
@override final  double? dayLow;
@override final  double? fiftyTwoWeekHigh;
@override final  double? fiftyTwoWeekLow;
@override final  double? volume;

/// Create a copy of MarketQuote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MarketQuoteCopyWith<_MarketQuote> get copyWith => __$MarketQuoteCopyWithImpl<_MarketQuote>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MarketQuote&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.price, price) || other.price == price)&&(identical(other.marketTime, marketTime) || other.marketTime == marketTime)&&(identical(other.fetchedAt, fetchedAt) || other.fetchedAt == fetchedAt)&&(identical(other.previousClose, previousClose) || other.previousClose == previousClose)&&(identical(other.dayHigh, dayHigh) || other.dayHigh == dayHigh)&&(identical(other.dayLow, dayLow) || other.dayLow == dayLow)&&(identical(other.fiftyTwoWeekHigh, fiftyTwoWeekHigh) || other.fiftyTwoWeekHigh == fiftyTwoWeekHigh)&&(identical(other.fiftyTwoWeekLow, fiftyTwoWeekLow) || other.fiftyTwoWeekLow == fiftyTwoWeekLow)&&(identical(other.volume, volume) || other.volume == volume));
}


@override
int get hashCode => Object.hash(runtimeType,symbol,currency,price,marketTime,fetchedAt,previousClose,dayHigh,dayLow,fiftyTwoWeekHigh,fiftyTwoWeekLow,volume);

@override
String toString() {
  return 'MarketQuote(symbol: $symbol, currency: $currency, price: $price, marketTime: $marketTime, fetchedAt: $fetchedAt, previousClose: $previousClose, dayHigh: $dayHigh, dayLow: $dayLow, fiftyTwoWeekHigh: $fiftyTwoWeekHigh, fiftyTwoWeekLow: $fiftyTwoWeekLow, volume: $volume)';
}


}

/// @nodoc
abstract mixin class _$MarketQuoteCopyWith<$Res> implements $MarketQuoteCopyWith<$Res> {
  factory _$MarketQuoteCopyWith(_MarketQuote value, $Res Function(_MarketQuote) _then) = __$MarketQuoteCopyWithImpl;
@override @useResult
$Res call({
 String symbol, String currency, double price, DateTime marketTime, DateTime fetchedAt, double? previousClose, double? dayHigh, double? dayLow, double? fiftyTwoWeekHigh, double? fiftyTwoWeekLow, double? volume
});




}
/// @nodoc
class __$MarketQuoteCopyWithImpl<$Res>
    implements _$MarketQuoteCopyWith<$Res> {
  __$MarketQuoteCopyWithImpl(this._self, this._then);

  final _MarketQuote _self;
  final $Res Function(_MarketQuote) _then;

/// Create a copy of MarketQuote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? symbol = null,Object? currency = null,Object? price = null,Object? marketTime = null,Object? fetchedAt = null,Object? previousClose = freezed,Object? dayHigh = freezed,Object? dayLow = freezed,Object? fiftyTwoWeekHigh = freezed,Object? fiftyTwoWeekLow = freezed,Object? volume = freezed,}) {
  return _then(_MarketQuote(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,marketTime: null == marketTime ? _self.marketTime : marketTime // ignore: cast_nullable_to_non_nullable
as DateTime,fetchedAt: null == fetchedAt ? _self.fetchedAt : fetchedAt // ignore: cast_nullable_to_non_nullable
as DateTime,previousClose: freezed == previousClose ? _self.previousClose : previousClose // ignore: cast_nullable_to_non_nullable
as double?,dayHigh: freezed == dayHigh ? _self.dayHigh : dayHigh // ignore: cast_nullable_to_non_nullable
as double?,dayLow: freezed == dayLow ? _self.dayLow : dayLow // ignore: cast_nullable_to_non_nullable
as double?,fiftyTwoWeekHigh: freezed == fiftyTwoWeekHigh ? _self.fiftyTwoWeekHigh : fiftyTwoWeekHigh // ignore: cast_nullable_to_non_nullable
as double?,fiftyTwoWeekLow: freezed == fiftyTwoWeekLow ? _self.fiftyTwoWeekLow : fiftyTwoWeekLow // ignore: cast_nullable_to_non_nullable
as double?,volume: freezed == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
