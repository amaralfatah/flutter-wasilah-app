// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'holding.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Holding {

 String get assetId; double get currentValue; DateTime get lastUpdatedAt;/// Total modal yang disetor ke aset ini; `null` bila belum diisi.
 double? get totalCost;/// Jumlah unit yang dimiliki (lot, lembar, koin, gram); `null` bila belum
/// diisi.
 double? get quantity;/// Harga rata-rata beli per unit, dalam [priceCurrency]. Nilai display
/// murni; tidak dipakai untuk menghitung PnL (PnL selalu IDR).
 double? get avgBuyPrice;/// Mata uang [avgBuyPrice] (mis. `IDR`, `USD`). `null` dianggap `IDR`.
/// Tidak ditebak dari kategori: BTC bisa dibeli dalam IDR atau USD.
 String? get priceCurrency;
/// Create a copy of Holding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HoldingCopyWith<Holding> get copyWith => _$HoldingCopyWithImpl<Holding>(this as Holding, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Holding&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.currentValue, currentValue) || other.currentValue == currentValue)&&(identical(other.lastUpdatedAt, lastUpdatedAt) || other.lastUpdatedAt == lastUpdatedAt)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.avgBuyPrice, avgBuyPrice) || other.avgBuyPrice == avgBuyPrice)&&(identical(other.priceCurrency, priceCurrency) || other.priceCurrency == priceCurrency));
}


@override
int get hashCode => Object.hash(runtimeType,assetId,currentValue,lastUpdatedAt,totalCost,quantity,avgBuyPrice,priceCurrency);

@override
String toString() {
  return 'Holding(assetId: $assetId, currentValue: $currentValue, lastUpdatedAt: $lastUpdatedAt, totalCost: $totalCost, quantity: $quantity, avgBuyPrice: $avgBuyPrice, priceCurrency: $priceCurrency)';
}


}

/// @nodoc
abstract mixin class $HoldingCopyWith<$Res>  {
  factory $HoldingCopyWith(Holding value, $Res Function(Holding) _then) = _$HoldingCopyWithImpl;
@useResult
$Res call({
 String assetId, double currentValue, DateTime lastUpdatedAt, double? totalCost, double? quantity, double? avgBuyPrice, String? priceCurrency
});




}
/// @nodoc
class _$HoldingCopyWithImpl<$Res>
    implements $HoldingCopyWith<$Res> {
  _$HoldingCopyWithImpl(this._self, this._then);

  final Holding _self;
  final $Res Function(Holding) _then;

/// Create a copy of Holding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? assetId = null,Object? currentValue = null,Object? lastUpdatedAt = null,Object? totalCost = freezed,Object? quantity = freezed,Object? avgBuyPrice = freezed,Object? priceCurrency = freezed,}) {
  return _then(_self.copyWith(
assetId: null == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as String,currentValue: null == currentValue ? _self.currentValue : currentValue // ignore: cast_nullable_to_non_nullable
as double,lastUpdatedAt: null == lastUpdatedAt ? _self.lastUpdatedAt : lastUpdatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,totalCost: freezed == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as double?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double?,avgBuyPrice: freezed == avgBuyPrice ? _self.avgBuyPrice : avgBuyPrice // ignore: cast_nullable_to_non_nullable
as double?,priceCurrency: freezed == priceCurrency ? _self.priceCurrency : priceCurrency // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Holding].
extension HoldingPatterns on Holding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Holding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Holding() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Holding value)  $default,){
final _that = this;
switch (_that) {
case _Holding():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Holding value)?  $default,){
final _that = this;
switch (_that) {
case _Holding() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String assetId,  double currentValue,  DateTime lastUpdatedAt,  double? totalCost,  double? quantity,  double? avgBuyPrice,  String? priceCurrency)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Holding() when $default != null:
return $default(_that.assetId,_that.currentValue,_that.lastUpdatedAt,_that.totalCost,_that.quantity,_that.avgBuyPrice,_that.priceCurrency);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String assetId,  double currentValue,  DateTime lastUpdatedAt,  double? totalCost,  double? quantity,  double? avgBuyPrice,  String? priceCurrency)  $default,) {final _that = this;
switch (_that) {
case _Holding():
return $default(_that.assetId,_that.currentValue,_that.lastUpdatedAt,_that.totalCost,_that.quantity,_that.avgBuyPrice,_that.priceCurrency);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String assetId,  double currentValue,  DateTime lastUpdatedAt,  double? totalCost,  double? quantity,  double? avgBuyPrice,  String? priceCurrency)?  $default,) {final _that = this;
switch (_that) {
case _Holding() when $default != null:
return $default(_that.assetId,_that.currentValue,_that.lastUpdatedAt,_that.totalCost,_that.quantity,_that.avgBuyPrice,_that.priceCurrency);case _:
  return null;

}
}

}

/// @nodoc


class _Holding extends Holding {
  const _Holding({required this.assetId, required this.currentValue, required this.lastUpdatedAt, this.totalCost, this.quantity, this.avgBuyPrice, this.priceCurrency}): super._();
  

@override final  String assetId;
@override final  double currentValue;
@override final  DateTime lastUpdatedAt;
/// Total modal yang disetor ke aset ini; `null` bila belum diisi.
@override final  double? totalCost;
/// Jumlah unit yang dimiliki (lot, lembar, koin, gram); `null` bila belum
/// diisi.
@override final  double? quantity;
/// Harga rata-rata beli per unit, dalam [priceCurrency]. Nilai display
/// murni; tidak dipakai untuk menghitung PnL (PnL selalu IDR).
@override final  double? avgBuyPrice;
/// Mata uang [avgBuyPrice] (mis. `IDR`, `USD`). `null` dianggap `IDR`.
/// Tidak ditebak dari kategori: BTC bisa dibeli dalam IDR atau USD.
@override final  String? priceCurrency;

/// Create a copy of Holding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HoldingCopyWith<_Holding> get copyWith => __$HoldingCopyWithImpl<_Holding>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Holding&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.currentValue, currentValue) || other.currentValue == currentValue)&&(identical(other.lastUpdatedAt, lastUpdatedAt) || other.lastUpdatedAt == lastUpdatedAt)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.avgBuyPrice, avgBuyPrice) || other.avgBuyPrice == avgBuyPrice)&&(identical(other.priceCurrency, priceCurrency) || other.priceCurrency == priceCurrency));
}


@override
int get hashCode => Object.hash(runtimeType,assetId,currentValue,lastUpdatedAt,totalCost,quantity,avgBuyPrice,priceCurrency);

@override
String toString() {
  return 'Holding(assetId: $assetId, currentValue: $currentValue, lastUpdatedAt: $lastUpdatedAt, totalCost: $totalCost, quantity: $quantity, avgBuyPrice: $avgBuyPrice, priceCurrency: $priceCurrency)';
}


}

/// @nodoc
abstract mixin class _$HoldingCopyWith<$Res> implements $HoldingCopyWith<$Res> {
  factory _$HoldingCopyWith(_Holding value, $Res Function(_Holding) _then) = __$HoldingCopyWithImpl;
@override @useResult
$Res call({
 String assetId, double currentValue, DateTime lastUpdatedAt, double? totalCost, double? quantity, double? avgBuyPrice, String? priceCurrency
});




}
/// @nodoc
class __$HoldingCopyWithImpl<$Res>
    implements _$HoldingCopyWith<$Res> {
  __$HoldingCopyWithImpl(this._self, this._then);

  final _Holding _self;
  final $Res Function(_Holding) _then;

/// Create a copy of Holding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? assetId = null,Object? currentValue = null,Object? lastUpdatedAt = null,Object? totalCost = freezed,Object? quantity = freezed,Object? avgBuyPrice = freezed,Object? priceCurrency = freezed,}) {
  return _then(_Holding(
assetId: null == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as String,currentValue: null == currentValue ? _self.currentValue : currentValue // ignore: cast_nullable_to_non_nullable
as double,lastUpdatedAt: null == lastUpdatedAt ? _self.lastUpdatedAt : lastUpdatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,totalCost: freezed == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as double?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double?,avgBuyPrice: freezed == avgBuyPrice ? _self.avgBuyPrice : avgBuyPrice // ignore: cast_nullable_to_non_nullable
as double?,priceCurrency: freezed == priceCurrency ? _self.priceCurrency : priceCurrency // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
