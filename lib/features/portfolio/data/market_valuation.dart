import 'package:flutter_wasilah_app/features/market/data/models/market_quote.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_position.dart';

/// Kategori yang nilainya mengikuti harga pasar: jumlah unit × harga Yahoo
/// mewakili nilai sebenarnya. Logam mulia (harga spot global ≠ harga
/// Antam/buyback), reksa dana (NAB tidak ada di Yahoo), kas, dan lainnya
/// tetap memakai nilai yang dicatat.
bool tracksMarketPrice(AssetCategory category) => switch (category) {
  AssetCategory.stock || AssetCategory.crypto || AssetCategory.indexEtf => true,
  AssetCategory.mutualFund ||
  AssetCategory.preciousMetal ||
  AssetCategory.cash ||
  AssetCategory.other => false,
};

/// Simbol Yahoo yang harganya menentukan nilai [position]; `null` bila
/// posisi tidak dinilai dengan harga pasar (kategori tidak didukung, tanpa
/// simbol, atau jumlah unit kosong).
String? marketValuationSymbolOf(PortfolioPosition position) {
  final symbol = position.marketSymbol;
  final quantity = position.quantity;
  if (symbol == null ||
      symbol.isEmpty ||
      quantity == null ||
      quantity <= 0 ||
      !tracksMarketPrice(position.category)) {
    return null;
  }
  return symbol;
}

/// Saham IDX (simbol `.JK`) dicatat dalam lot, sedangkan harga per
/// lembar; 1 lot = 100 lembar. Aset lain 1:1.
double lotToShareFactor(String? symbol) =>
    symbol != null && symbol.toUpperCase().endsWith('.JK') ? 100 : 1;

/// Simbol forex Yahoo untuk kurs 1 unit [currency] dalam IDR.
String fxSymbolOf(String currency) => '${currency.trim().toUpperCase()}IDR=X';

/// Kurs [currency] ke IDR dari [quotes] (berisi quote forex
/// [fxSymbolOf]); `null` bila kurs belum tersedia.
double? rateToIdrFrom(String currency, Map<String, MarketQuote> quotes) {
  final normalized = currency.trim().toUpperCase();
  if (normalized.isEmpty || normalized == 'IDR') {
    return 1;
  }
  return quotes[fxSymbolOf(normalized)]?.price;
}

/// Nilai pasar dalam IDR: jumlah unit × harga per lembar/unit × kurs.
double marketValueIdr({
  required double quantity,
  required String symbol,
  required double price,
  required double rateToIdr,
}) => quantity * lotToShareFactor(symbol) * price * rateToIdr;

/// Nilai holding yang dinilai pasar diganti hasil hitung harga di
/// [quotes] (per simbol, termasuk kurs forex); posisi lain dan posisi yang
/// quote/kursnya belum ada tetap memakai nilai tercatat. Alokasi dihitung
/// ulang dan urutan mengikuti repository (nilai terbesar dulu, lalu nama).
List<PortfolioPosition> applyMarketPrices(
  List<PortfolioPosition> positions,
  Map<String, MarketQuote> quotes,
) {
  if (quotes.isEmpty) {
    return positions;
  }
  final valued = [
    for (final position in positions)
      _valueAtMarket(position, quotes) ?? position,
  ];
  final total = valued.fold<double>(
    0,
    (sum, position) => sum + position.currentValue,
  );
  return [
    for (final position in valued)
      position.copyWith(
        allocationPercentage: total == 0
            ? 0
            : position.currentValue / total * 100,
      ),
  ]..sort((left, right) {
    final byValue = right.currentValue.compareTo(left.currentValue);
    return byValue != 0 ? byValue : left.name.compareTo(right.name);
  });
}

PortfolioPosition? _valueAtMarket(
  PortfolioPosition position,
  Map<String, MarketQuote> quotes,
) {
  final symbol = marketValuationSymbolOf(position);
  final quote = symbol == null ? null : quotes[symbol];
  if (symbol == null || quote == null) {
    return null;
  }
  final rate = rateToIdrFrom(quote.currency, quotes);
  if (rate == null) {
    return null;
  }
  return position.copyWith(
    holding: position.holding.copyWith(
      currentValue: marketValueIdr(
        quantity: position.quantity!,
        symbol: symbol,
        price: quote.price,
        rateToIdr: rate,
      ),
    ),
    marketPriceAt: quote.marketTime,
  );
}
