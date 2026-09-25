/// Titik histori nilai bulanan; dipenuhi `AssetSnapshot` (per aset) dan
/// `PortfolioSnapshot` (gabungan) supaya widget histori bisa dipakai
/// keduanya.
abstract interface class ValueSnapshot {
  String get id;
  double get totalValue;
  DateTime get recordedAt;
  String? get note;
  double? get totalCost;
  double? get profitLoss;
  double? get profitLossPercentage;
}
