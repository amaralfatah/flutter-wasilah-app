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
 double? get previousClose;
/// Create a copy of MarketQuote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarketQuoteCopyWith<MarketQuote> get copyWith => _$MarketQuoteCopyWithImpl<MarketQuote>(this as MarketQuote, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarketQuote&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.price, price) || other.price == price)&&(identical(other.marketTime, marketTime) || other.marketTime == marketTime)&&(identical(other.fetchedAt, fetchedAt) || other.fetchedAt == fetchedAt)&&(identical(other.previousClose, previousClose) || other.previousClose == previousClose));
}


@override
int get hashCode => Object.hash(runtimeType,symbol,currency,price,marketTime,fetchedAt,previousClose);

@override
String toString() {
  return 'MarketQuote(symbol: $symbol, currency: $currency, price: $price, marketTime: $marketTime, fetchedAt: $fetchedAt, previousClose: $previousClose)';
}


}

/// @nodoc
abstract mixin class $MarketQuoteCopyWith<$Res>  {
  factory $MarketQuoteCopyWith(MarketQuote value, $Res Function(MarketQuote) _then) = _$MarketQuoteCopyWithImpl;
@useResult
$Res call({
 String symbol, String currency, double price, DateTime marketTime, DateTime fetchedAt, double? previousClose
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
@pragma('vm:prefer-inline') @override $Res call({Object? symbol = null,Object? currency = null,Object? price = null,Object? marketTime = null,Object? fetchedAt = null,Object? previousClose = freezed,}) {
  return _then(_self.copyWith(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,marketTime: null == marketTime ? _self.marketTime : marketTime // ignore: cast_nullable_to_non_nullable
as DateTime,fetchedAt: null == fetchedAt ? _self.fetchedAt : fetchedAt // ignore: cast_nullable_to_non_nullable
as DateTime,previousClose: freezed == previousClose ? _self.previousClose : previousClose // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String symbol,  String currency,  double price,  DateTime marketTime,  DateTime fetchedAt,  double? previousClose)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MarketQuote() when $default != null:
return $default(_that.symbol,_that.currency,_that.price,_that.marketTime,_that.fetchedAt,_that.previousClose);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String symbol,  String currency,  double price,  DateTime marketTime,  DateTime fetchedAt,  double? previousClose)  $default,) {final _that = this;
switch (_that) {
case _MarketQuote():
return $default(_that.symbol,_that.currency,_that.price,_that.marketTime,_that.fetchedAt,_that.previousClose);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String symbol,  String currency,  double price,  DateTime marketTime,  DateTime fetchedAt,  double? previousClose)?  $default,) {final _that = this;
switch (_that) {
case _MarketQuote() when $default != null:
return $default(_that.symbol,_that.currency,_that.price,_that.marketTime,_that.fetchedAt,_that.previousClose);case _:
  return null;

}
}

}

/// @nodoc


class _MarketQuote extends MarketQuote {
  const _MarketQuote({required this.symbol, required this.currency, required this.price, required this.marketTime, required this.fetchedAt, this.previousClose}): super._();
  

@override final  String symbol;
@override final  String currency;
@override final  double price;
@override final  DateTime marketTime;
@override final  DateTime fetchedAt;
/// Penutupan sebelumnya; `null` bila Yahoo tidak mengirimkannya.
@override final  double? previousClose;

/// Create a copy of MarketQuote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MarketQuoteCopyWith<_MarketQuote> get copyWith => __$MarketQuoteCopyWithImpl<_MarketQuote>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MarketQuote&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.price, price) || other.price == price)&&(identical(other.marketTime, marketTime) || other.marketTime == marketTime)&&(identical(other.fetchedAt, fetchedAt) || other.fetchedAt == fetchedAt)&&(identical(other.previousClose, previousClose) || other.previousClose == previousClose));
}


@override
int get hashCode => Object.hash(runtimeType,symbol,currency,price,marketTime,fetchedAt,previousClose);

@override
String toString() {
  return 'MarketQuote(symbol: $symbol, currency: $currency, price: $price, marketTime: $marketTime, fetchedAt: $fetchedAt, previousClose: $previousClose)';
}


}

/// @nodoc
abstract mixin class _$MarketQuoteCopyWith<$Res> implements $MarketQuoteCopyWith<$Res> {
  factory _$MarketQuoteCopyWith(_MarketQuote value, $Res Function(_MarketQuote) _then) = __$MarketQuoteCopyWithImpl;
@override @useResult
$Res call({
 String symbol, String currency, double price, DateTime marketTime, DateTime fetchedAt, double? previousClose
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
@override @pragma('vm:prefer-inline') $Res call({Object? symbol = null,Object? currency = null,Object? price = null,Object? marketTime = null,Object? fetchedAt = null,Object? previousClose = freezed,}) {
  return _then(_MarketQuote(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,marketTime: null == marketTime ? _self.marketTime : marketTime // ignore: cast_nullable_to_non_nullable
as DateTime,fetchedAt: null == fetchedAt ? _self.fetchedAt : fetchedAt // ignore: cast_nullable_to_non_nullable
as DateTime,previousClose: freezed == previousClose ? _self.previousClose : previousClose // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
