// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'asset.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Asset {

 String get id; String get name; String get code; AssetCategory get category; double get currentValue; double get allocationPercentage; DateTime get lastUpdatedAt;/// Total modal yang disetor ke aset ini; `null` bila belum diisi.
 double? get totalCost;/// Simbol Yahoo Finance (mis. `BMRI.JK`, `BTC-USD`); `null` bila aset
/// tidak punya harga pasar.
 String? get marketSymbol;/// Jumlah unit yang dimiliki (lot, lembar, koin, gram); `null` bila belum
/// diisi.
 double? get quantity;/// Harga rata-rata beli per unit, dalam [priceCurrency]. Nilai display
/// murni; tidak dipakai untuk menghitung PnL (PnL selalu IDR).
 double? get avgBuyPrice;/// Mata uang [avgBuyPrice] (mis. `IDR`, `USD`). `null` dianggap `IDR`.
/// Tidak ditebak dari kategori: BTC bisa dibeli dalam IDR atau USD.
 String? get priceCurrency;
/// Create a copy of Asset
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssetCopyWith<Asset> get copyWith => _$AssetCopyWithImpl<Asset>(this as Asset, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Asset&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code)&&(identical(other.category, category) || other.category == category)&&(identical(other.currentValue, currentValue) || other.currentValue == currentValue)&&(identical(other.allocationPercentage, allocationPercentage) || other.allocationPercentage == allocationPercentage)&&(identical(other.lastUpdatedAt, lastUpdatedAt) || other.lastUpdatedAt == lastUpdatedAt)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.marketSymbol, marketSymbol) || other.marketSymbol == marketSymbol)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.avgBuyPrice, avgBuyPrice) || other.avgBuyPrice == avgBuyPrice)&&(identical(other.priceCurrency, priceCurrency) || other.priceCurrency == priceCurrency));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,code,category,currentValue,allocationPercentage,lastUpdatedAt,totalCost,marketSymbol,quantity,avgBuyPrice,priceCurrency);

@override
String toString() {
  return 'Asset(id: $id, name: $name, code: $code, category: $category, currentValue: $currentValue, allocationPercentage: $allocationPercentage, lastUpdatedAt: $lastUpdatedAt, totalCost: $totalCost, marketSymbol: $marketSymbol, quantity: $quantity, avgBuyPrice: $avgBuyPrice, priceCurrency: $priceCurrency)';
}


}

/// @nodoc
abstract mixin class $AssetCopyWith<$Res>  {
  factory $AssetCopyWith(Asset value, $Res Function(Asset) _then) = _$AssetCopyWithImpl;
@useResult
$Res call({
 String id, String name, String code, AssetCategory category, double currentValue, double allocationPercentage, DateTime lastUpdatedAt, double? totalCost, String? marketSymbol, double? quantity, double? avgBuyPrice, String? priceCurrency
});




}
/// @nodoc
class _$AssetCopyWithImpl<$Res>
    implements $AssetCopyWith<$Res> {
  _$AssetCopyWithImpl(this._self, this._then);

  final Asset _self;
  final $Res Function(Asset) _then;

/// Create a copy of Asset
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? code = null,Object? category = null,Object? currentValue = null,Object? allocationPercentage = null,Object? lastUpdatedAt = null,Object? totalCost = freezed,Object? marketSymbol = freezed,Object? quantity = freezed,Object? avgBuyPrice = freezed,Object? priceCurrency = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as AssetCategory,currentValue: null == currentValue ? _self.currentValue : currentValue // ignore: cast_nullable_to_non_nullable
as double,allocationPercentage: null == allocationPercentage ? _self.allocationPercentage : allocationPercentage // ignore: cast_nullable_to_non_nullable
as double,lastUpdatedAt: null == lastUpdatedAt ? _self.lastUpdatedAt : lastUpdatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,totalCost: freezed == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as double?,marketSymbol: freezed == marketSymbol ? _self.marketSymbol : marketSymbol // ignore: cast_nullable_to_non_nullable
as String?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double?,avgBuyPrice: freezed == avgBuyPrice ? _self.avgBuyPrice : avgBuyPrice // ignore: cast_nullable_to_non_nullable
as double?,priceCurrency: freezed == priceCurrency ? _self.priceCurrency : priceCurrency // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Asset].
extension AssetPatterns on Asset {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Asset value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Asset() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Asset value)  $default,){
final _that = this;
switch (_that) {
case _Asset():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Asset value)?  $default,){
final _that = this;
switch (_that) {
case _Asset() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String code,  AssetCategory category,  double currentValue,  double allocationPercentage,  DateTime lastUpdatedAt,  double? totalCost,  String? marketSymbol,  double? quantity,  double? avgBuyPrice,  String? priceCurrency)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Asset() when $default != null:
return $default(_that.id,_that.name,_that.code,_that.category,_that.currentValue,_that.allocationPercentage,_that.lastUpdatedAt,_that.totalCost,_that.marketSymbol,_that.quantity,_that.avgBuyPrice,_that.priceCurrency);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String code,  AssetCategory category,  double currentValue,  double allocationPercentage,  DateTime lastUpdatedAt,  double? totalCost,  String? marketSymbol,  double? quantity,  double? avgBuyPrice,  String? priceCurrency)  $default,) {final _that = this;
switch (_that) {
case _Asset():
return $default(_that.id,_that.name,_that.code,_that.category,_that.currentValue,_that.allocationPercentage,_that.lastUpdatedAt,_that.totalCost,_that.marketSymbol,_that.quantity,_that.avgBuyPrice,_that.priceCurrency);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String code,  AssetCategory category,  double currentValue,  double allocationPercentage,  DateTime lastUpdatedAt,  double? totalCost,  String? marketSymbol,  double? quantity,  double? avgBuyPrice,  String? priceCurrency)?  $default,) {final _that = this;
switch (_that) {
case _Asset() when $default != null:
return $default(_that.id,_that.name,_that.code,_that.category,_that.currentValue,_that.allocationPercentage,_that.lastUpdatedAt,_that.totalCost,_that.marketSymbol,_that.quantity,_that.avgBuyPrice,_that.priceCurrency);case _:
  return null;

}
}

}

/// @nodoc


class _Asset extends Asset {
  const _Asset({required this.id, required this.name, required this.code, required this.category, required this.currentValue, required this.allocationPercentage, required this.lastUpdatedAt, this.totalCost, this.marketSymbol, this.quantity, this.avgBuyPrice, this.priceCurrency}): super._();
  

@override final  String id;
@override final  String name;
@override final  String code;
@override final  AssetCategory category;
@override final  double currentValue;
@override final  double allocationPercentage;
@override final  DateTime lastUpdatedAt;
/// Total modal yang disetor ke aset ini; `null` bila belum diisi.
@override final  double? totalCost;
/// Simbol Yahoo Finance (mis. `BMRI.JK`, `BTC-USD`); `null` bila aset
/// tidak punya harga pasar.
@override final  String? marketSymbol;
/// Jumlah unit yang dimiliki (lot, lembar, koin, gram); `null` bila belum
/// diisi.
@override final  double? quantity;
/// Harga rata-rata beli per unit, dalam [priceCurrency]. Nilai display
/// murni; tidak dipakai untuk menghitung PnL (PnL selalu IDR).
@override final  double? avgBuyPrice;
/// Mata uang [avgBuyPrice] (mis. `IDR`, `USD`). `null` dianggap `IDR`.
/// Tidak ditebak dari kategori: BTC bisa dibeli dalam IDR atau USD.
@override final  String? priceCurrency;

/// Create a copy of Asset
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssetCopyWith<_Asset> get copyWith => __$AssetCopyWithImpl<_Asset>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Asset&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code)&&(identical(other.category, category) || other.category == category)&&(identical(other.currentValue, currentValue) || other.currentValue == currentValue)&&(identical(other.allocationPercentage, allocationPercentage) || other.allocationPercentage == allocationPercentage)&&(identical(other.lastUpdatedAt, lastUpdatedAt) || other.lastUpdatedAt == lastUpdatedAt)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.marketSymbol, marketSymbol) || other.marketSymbol == marketSymbol)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.avgBuyPrice, avgBuyPrice) || other.avgBuyPrice == avgBuyPrice)&&(identical(other.priceCurrency, priceCurrency) || other.priceCurrency == priceCurrency));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,code,category,currentValue,allocationPercentage,lastUpdatedAt,totalCost,marketSymbol,quantity,avgBuyPrice,priceCurrency);

@override
String toString() {
  return 'Asset(id: $id, name: $name, code: $code, category: $category, currentValue: $currentValue, allocationPercentage: $allocationPercentage, lastUpdatedAt: $lastUpdatedAt, totalCost: $totalCost, marketSymbol: $marketSymbol, quantity: $quantity, avgBuyPrice: $avgBuyPrice, priceCurrency: $priceCurrency)';
}


}

/// @nodoc
abstract mixin class _$AssetCopyWith<$Res> implements $AssetCopyWith<$Res> {
  factory _$AssetCopyWith(_Asset value, $Res Function(_Asset) _then) = __$AssetCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String code, AssetCategory category, double currentValue, double allocationPercentage, DateTime lastUpdatedAt, double? totalCost, String? marketSymbol, double? quantity, double? avgBuyPrice, String? priceCurrency
});




}
/// @nodoc
class __$AssetCopyWithImpl<$Res>
    implements _$AssetCopyWith<$Res> {
  __$AssetCopyWithImpl(this._self, this._then);

  final _Asset _self;
  final $Res Function(_Asset) _then;

/// Create a copy of Asset
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? code = null,Object? category = null,Object? currentValue = null,Object? allocationPercentage = null,Object? lastUpdatedAt = null,Object? totalCost = freezed,Object? marketSymbol = freezed,Object? quantity = freezed,Object? avgBuyPrice = freezed,Object? priceCurrency = freezed,}) {
  return _then(_Asset(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as AssetCategory,currentValue: null == currentValue ? _self.currentValue : currentValue // ignore: cast_nullable_to_non_nullable
as double,allocationPercentage: null == allocationPercentage ? _self.allocationPercentage : allocationPercentage // ignore: cast_nullable_to_non_nullable
as double,lastUpdatedAt: null == lastUpdatedAt ? _self.lastUpdatedAt : lastUpdatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,totalCost: freezed == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as double?,marketSymbol: freezed == marketSymbol ? _self.marketSymbol : marketSymbol // ignore: cast_nullable_to_non_nullable
as String?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double?,avgBuyPrice: freezed == avgBuyPrice ? _self.avgBuyPrice : avgBuyPrice // ignore: cast_nullable_to_non_nullable
as double?,priceCurrency: freezed == priceCurrency ? _self.priceCurrency : priceCurrency // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
