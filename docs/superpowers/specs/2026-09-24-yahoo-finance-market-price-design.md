# Harga pasar & chart dari Yahoo Finance

## Context

Wasilah mencatat **total nilai** per aset secara manual; tidak ada jumlah
unit dan tidak ada transaksi. Permintaan: tampilkan harga terkini dan chart
harga dari Yahoo Finance untuk aset yang punya simbol pasar (mis. `BMRI.JK`,
`BTC-USD`, `SPY`), dengan tampilan halaman detail saham ala **Stockbit**.

Keputusan (2026-09-24):

1. **Info saja.** Harga pasar hanya ditampilkan. Nilai aset tetap diinput
   manual; tidak ada kolom unit, tidak ada valuasi otomatis, tidak ada
   snapshot otomatis.
2. **Line chart harga penutupan (close)** dengan area fill, digambar dengan
   `CustomPainter`. Tanpa candlestick, tanpa dependency chart.
3. **Cache quote terakhir di drift** supaya offline tetap tampil harga
   terakhir yang diketahui. Seri chart **tidak** di-cache.
4. **Halaman terpisah ala Stockbit.** Alur navigasi:

   ```
   Daftar Aset ──tap──▶ Detail Aset (porto, halaman lama)
                            │ tap kartu "Harga Pasar"
                            ▼
                        Detail Pasar (halaman baru, ala Stockbit)
                            │ tombol "Perbarui Nilai"
                            ▼
                        Update Nilai (halaman lama)
   ```

   Tombol "Beli"/"Jual" Stockbit diganti **satu** tombol "Perbarui Nilai".

Tidak ada dependency baru: `http` dan `intl` sudah ada di `pubspec.yaml`.

## Endpoint

```text
GET https://query1.finance.yahoo.com/v8/finance/chart/{SYMBOL}?interval={INTERVAL}&range={RANGE}
GET https://query1.finance.yahoo.com/v8/finance/chart/{SYMBOL}?interval={INTERVAL}&period1={EPOCH}&period2={EPOCH}
```

- `meta` selalu ada di setiap response chart. Ambil: `symbol`, `currency`,
  `regularMarketPrice`, `chartPreviousClose` (fallback `previousClose`),
  `regularMarketTime` (epoch detik, UTC).
- Seri chart: `timestamp[]` dan `indicators.quote[0].close[]`.
- **Quote = request range `1D`** (`interval=1m&range=1d`). Satu request
  menghasilkan quote (dari `meta`) sekaligus seri chart 1D.
- Kirim header `User-Agent` browser-like (tanpa itu Yahoo sering membalas
  429). Timeout 10 detik.
- API tidak resmi dan bisa berubah/ditutup. Seluruh akses Yahoo terkurung
  di satu kelas (`YahooFinanceClient`) supaya gampang diganti.

## Data model

### Kolom baru `assets.market_symbol`

- `TEXT NULL`. `NULL` = aset tidak punya harga pasar (reksa dana, kas,
  logam mulia, dst.); kartu "Harga Pasar" tidak ditampilkan.
- Disimpan huruf besar, di-trim; string kosong disimpan sebagai `NULL`.
- `Asset` (freezed) dapat field `String? marketSymbol`; `fromJson`/`toJson`
  pakai key `marketSymbol` (nullable, JSON lama tetap terbaca).
- `DriftPortfolioRepository`: semua `SELECT`/`INSERT`/`UPDATE assets` yang
  memetakan kolom aset ikut membaca/menulis `market_symbol`.
  `mock_portfolio_repository.dart` disesuaikan bila perlu supaya compile.

### Tabel baru `market_quotes` (cache)

```sql
CREATE TABLE IF NOT EXISTS market_quotes (
  symbol TEXT PRIMARY KEY NOT NULL,
  currency TEXT NOT NULL,
  price REAL NOT NULL,
  previous_close REAL,
  market_time INTEGER NOT NULL,   -- epoch detik, dari regularMarketTime
  fetched_at INTEGER NOT NULL     -- epoch detik, waktu app fetch
);
```

Satu baris per simbol, di-upsert (`INSERT ... ON CONFLICT(symbol) DO
UPDATE`). Tanpa foreign key ke `assets`: simbol bisa dipakai lebih dari
satu aset; baris yatim kecil dan tidak berbahaya.

### Migrasi (schemaVersion 5 → 6)

- `onCreate`: tambah `market_symbol TEXT` pada `CREATE TABLE assets` dan
  buat `market_quotes`.
- `onUpgrade` `if (from < 6)`:
  `_addColumnIfMissing('assets', 'market_symbol', 'TEXT')` lalu
  `CREATE TABLE IF NOT EXISTS market_quotes (...)`.
- Backup via `VACUUM INTO` otomatis membawa kolom & tabel baru. Restore dari
  backup v5 lewat jalur `onUpgrade` yang sama.

## Feature `lib/features/market/`

Ikuti pola `features/portfolio`: `data/`, `providers/`, `presentation/`.
Provider ditulis manual (`Provider`/`FutureProvider`), sama seperti
provider yang ada; migrasi ke `@riverpod` di luar scope.

### `data/models/market_quote.dart` (freezed)

```dart
MarketQuote({
  required String symbol,
  required String currency,       // "IDR", "USD", ...
  required double price,
  double? previousClose,
  required DateTime marketTime,   // lokal, dari epoch UTC
  required DateTime fetchedAt,
})
double? get change        // price - previousClose
double? get changePercent // change / previousClose * 100; null bila prevClose null/0
```

### `data/models/price_series.dart` (freezed)

```dart
PricePoint({required DateTime time, required double close})
PriceSeries({
  required String symbol,
  required String currency,
  required ChartRange range,
  required List<PricePoint> points,
  double? previousClose,          // dari meta.chartPreviousClose
})
```

### `data/models/chart_range.dart`

Sama dengan tab Stockbit: `1D 1W 1M 3M YTD 1Y 3Y 5Y`.

| Enum          | Tab  | Query Yahoo                                  |
|---------------|------|----------------------------------------------|
| `oneDay`      | 1D   | `range=1d&interval=1m`                       |
| `oneWeek`     | 1W   | `range=5d&interval=15m`                      |
| `oneMonth`    | 1M   | `range=1mo&interval=60m`                     |
| `threeMonths` | 3M   | `range=3mo&interval=1d`                      |
| `yearToDate`  | YTD  | `range=ytd&interval=1d`                      |
| `oneYear`     | 1Y   | `range=1y&interval=1d`                       |
| `threeYears`  | 3Y   | `period1=now-3y&period2=now&interval=1wk`    |
| `fiveYears`   | 5Y   | `range=5y&interval=1wk`                      |

`3y` bukan `validRanges` Yahoo, jadi 3Y memakai `period1`/`period2`
(epoch detik; `period1` = sekarang dikurangi 3 tahun kalender).

```dart
enum ChartRange {
  oneDay('1d', '1m'),
  oneWeek('5d', '15m'),
  oneMonth('1mo', '60m'),
  threeMonths('3mo', '1d'),
  yearToDate('ytd', '1d'),
  oneYear('1y', '1d'),
  threeYears(null, '1wk'),   // pakai period1/period2
  fiveYears('5y', '1wk');

  const ChartRange(this.range, this.interval);
  final String? range;
  final String interval;
}
```

Default saat halaman dibuka: `oneDay`.

### `data/yahoo_finance_client.dart`

```dart
class YahooFinanceClient {
  YahooFinanceClient(this._httpClient, {DateTime Function()? clock});
  final http.Client _httpClient;

  /// Satu request; mengembalikan quote dari meta + seri chart-nya.
  Future<({MarketQuote quote, PriceSeries series})> fetch(
    String symbol,
    ChartRange range,
  );
}
```

`clock` di-inject supaya `period1`/`period2` (3Y) dan `fetchedAt` bisa dites.

Aturan parsing:

- Simbol di-`Uri.encodeComponent` (simbol index seperti `^JKSE` punya `^`).
- HTTP 404, atau `chart.error != null`, atau `chart.result` kosong/null
  → `MarketSymbolNotFoundException`.
- Error jaringan (`SocketException`, `ClientException`, `TimeoutException`),
  HTTP 429/5xx, atau JSON tidak sesuai bentuk → `MarketDataUnavailableException`.
- `regularMarketPrice` null → `MarketDataUnavailableException`.
- Chart: zip `timestamp[i]` dengan `close[i]`; **buang titik yang `close`
  -nya null** (Yahoo mengisi null untuk menit/hari tanpa transaksi). Bila
  `timestamp` tidak ada → `points` kosong, bukan error.
- Angka JSON bisa `int` atau `double` → selalu `(x as num).toDouble()`.

Dua exception baru di `lib/core/errors/app_exceptions.dart`, gaya sama
dengan yang ada (`class X implements Exception { const X(); }`).

### `data/market_repository.dart`

Kelas konkret (tanpa interface).

```dart
class MarketRepository {
  MarketRepository(this._database, this._client);

  /// Fetch range 1D, upsert quote ke cache, kembalikan quote + seri 1D.
  /// Gagal dengan MarketDataUnavailableException dan cache ada
  /// → quote dari cache, isStale = true, series = null.
  /// Tanpa cache → rethrow. MarketSymbolNotFoundException selalu rethrow.
  Future<QuoteResult> getQuote(String symbol);

  /// Range selain 1D. Tanpa cache. Quote dari response ini TIDAK
  /// menimpa cache (cukup dari getQuote).
  Future<PriceSeries> getChart(String symbol, ChartRange range);

  /// Baca cache saja, untuk kartu di detail aset saat offline.
  Future<MarketQuote?> getCachedQuote(String symbol);
}

typedef QuoteResult = ({MarketQuote quote, PriceSeries? oneDaySeries, bool isStale});
```

### `providers/market_providers.dart`

```dart
final httpClientProvider        // Provider<http.Client>, ref.onDispose(close)
final yahooFinanceClientProvider
final marketRepositoryProvider  // pakai appDatabaseProvider
final marketQuoteProvider = FutureProvider.autoDispose.family<QuoteResult, String>
final priceChartProvider  = FutureProvider.autoDispose
    .family<PriceSeries, ({String symbol, ChartRange range})>
```

- `priceChartProvider` untuk `oneDay` **tidak fetch ulang**: ambil
  `oneDaySeries` dari `marketQuoteProvider(symbol)`; bila `null` (stale)
  lempar `MarketDataUnavailableException`. Range lain → `getChart`.
- `autoDispose` supaya membuka ulang halaman = fetch ulang. Tidak ada
  polling/timer; refresh hanya lewat buka halaman atau pull-to-refresh.

### Utilitas simbol: `data/market_symbol_suggestion.dart`

```dart
String? suggestMarketSymbol(AssetCategory category, String code)
```

| Kategori              | Hasil           | Contoh              |
|-----------------------|-----------------|---------------------|
| `stock`               | `'${CODE}.JK'`  | `BMRI` → `BMRI.JK`  |
| `crypto`              | `'${CODE}-USD'` | `BTC` → `BTC-USD`   |
| `indexEtf`            | `CODE`          | `SPY` → `SPY`       |
| lainnya / code kosong | `null`          |                     |

`CODE` = `code.trim().toUpperCase()`. Bila `code` sudah mengandung `.`,
`-`, `^`, atau `=`, kembalikan apa adanya.

## Presentasi

Ikuti theme app (light/dark mengikuti setting), bukan memaksa dark seperti
screenshot Stockbit. Warna naik/turun pakai `AppColors.positiveOf` /
`AppColors.negativeOf`.

### 1. Form aset (`asset_form_page.dart`)

- Field baru `AppTextField` "Simbol Yahoo Finance (opsional)", di bawah
  field kode. Helper text: `BMRI.JK · BTC-USD · SPY`.
- Mode **tambah**: saat kategori atau kode berubah dan user **belum pernah
  mengetik** di field simbol, isi otomatis dengan `suggestMarketSymbol`.
  Sekali user mengedit field simbol (termasuk mengosongkan), prefill
  berhenti.
- Mode **edit**: tampilkan nilai tersimpan, tanpa prefill.
- Tanpa validasi online saat simpan; simbol salah terlihat sebagai pesan
  "simbol tidak ditemukan" di halaman pasar.

### 2. Detail aset (`asset_detail_page.dart`) — pintu masuk

Bila `asset.marketSymbol != null`, sisipkan **kartu "Harga Pasar"** di
antara `AppListCard` metrik dan tombol "Perbarui Nilai":

```
┌─────────────────────────────────────────────┐
│ Harga Pasar · BMRI.JK                        │
│ 4.070        ▼ -120 (-2,86%) hari ini      › │
└─────────────────────────────────────────────┘
```

- Widget `market_price_tile.dart` (di `features/market/presentation/widgets/`),
  watch `marketQuoteProvider(symbol)`. Satu baris, tap → push
  `'${RouteNames.assets}/${asset.id}/market'`.
- Loading: teks "Memuat harga…" di posisi harga. Error: "Harga tidak
  tersedia" (tile tetap bisa di-tap supaya user lihat detail error di
  halaman pasar). Stale: tampil harga cache + teks kecil "Offline".
- Pull-to-refresh detail aset juga `ref.invalidate(marketQuoteProvider(symbol))`.

### 3. Halaman baru Detail Pasar (`market_detail_page.dart`)

Route: child `'market'` di bawah `'${RouteNames.assets}/:id'` di
`app_router.dart`, sejajar `update`/`edit`. Page menerima `assetId`, watch
`assetDetailProvider(assetId)` untuk kode/nama/kategori, lalu
`asset.marketSymbol` untuk data pasar. `asset == null` atau
`marketSymbol == null` → `AppEmptyState` (sama seperti detail aset).

Layout, atas ke bawah (mengikuti screenshot Stockbit):

```
 ‹                                          ✎        AppBar: back + edit aset
                                                      (push .../edit)
 BMRI                                  ┌────┐
 Bank Mandiri (Persero) Tbk.           │icon│         code = titleLarge bold
                                       └────┘         name = bodyMedium, muted
 4.070                                                AssetCategoryIcon besar
 ↘ -120 (-2,86%) Hari Ini                             di kanan (pengganti logo)
 per 24 Sep 2026 16.00 WIB · BMRI.JK   [Offline]
 [Saham]                                              chip kategori (outlined,
                                                      warna positif, 8dp radius)
 4.190                                 4.200
 - - - - - - - - - - - - - - - - - -   4.180
 ▔╲▁▁╱▔╲▁▁▁▁▁▁▁                         4.160        chart + sumbu Y kanan
          ╲▁▁▁▁▁▁▁▁▁▁                   ...
                    ╲▁▁ 4.070          4.060

 1D  1W  1M  3M  YTD  1Y  3Y  5Y                     tab range (teks), aktif =
 ══                                                   warna primer + underline

 ┌──────────── Perbarui Nilai ────────────┐          FilledButton full width
 └────────────────────────────────────────┘          push .../update
```

Bagian header (`market_quote_header.dart`):

- **Harga besar**: `displaySmall` bold (≈ 36sp), `formatPrice`. Selalu harga
  quote terkini, kecuali saat scrub (lihat bawah).
- **Baris perubahan**: ikon panah (`Icons.north_east` / `Icons.south_east`,
  `trending_flat` bila 0) + `formatSignedPrice(change)` + `(±x,xx%)` dalam
  warna naik/turun, diikuti label periode warna muted:

  | Range | Label `id`          | Label `en`       |
  |-------|---------------------|------------------|
  | 1D    | Hari Ini            | Today            |
  | 1W    | 1 Minggu Terakhir   | Past Week        |
  | 1M    | 1 Bulan Terakhir    | Past Month       |
  | 3M    | 3 Bulan Terakhir    | Past 3 Months    |
  | YTD   | Sejak Awal Tahun    | Year to Date     |
  | 1Y    | 1 Tahun Terakhir    | Past Year        |
  | 3Y    | 3 Tahun Terakhir    | Past 3 Years     |
  | 5Y    | 5 Tahun Terakhir    | Past 5 Years     |

- **Harga acuan** (`referencePrice`) per range:
  - 1D → `quote.previousClose`.
  - lainnya → `series.points.first.close`.
  - `change = quote.price − referencePrice`; persen terhadap
    `referencePrice`. Bila acuan null/0 → baris perubahan disembunyikan.
  - Saat chart range belum termuat → baris perubahan tampil skeleton;
    harga besar tetap tampil dari quote.
- **Baris waktu** (`bodySmall`, muted): "per {tanggal jam}" dari
  `quote.marketTime` + simbol Yahoo + chip "Offline" bila `isStale`.
- **Chip kategori**: satu chip outlined dengan `asset.category.label`
  (pengganti tag "Bank"/"Day Trade").

Chart (`price_line_chart.dart`, `CustomPainter` + `GestureDetector`):

- Tinggi ±240dp, full-bleed kiri; ruang sumbu Y ±56dp di kanan.
- **Garis** close, stroke 1.5dp, warna naik/turun sesuai `change` range
  aktif. **Area fill** di bawah garis: gradient vertikal warna garis
  alpha 0.25 → 0.
- **Garis acuan putus-putus** horizontal pada `referencePrice` (warna
  `outlineVariant`). Skala Y harus mencakup `referencePrice`.
- **Label titik ekstrem** (angka kecil, warna garis): nilai `max` di atas
  titik tertingginya, nilai `min` di bawah titik terendahnya, digeser
  supaya tidak keluar tepi. (Screenshot 1D: `4,190` kiri atas & `4,070`
  kanan bawah; 1Y: `2,840` di puncak & `1,650` di lembah.)
- **Sumbu Y kanan**: 5–8 tick "nice number" (kelipatan 1/2/5 × 10ⁿ) antara
  min–max, `labelSmall` muted, tanpa garis grid.
- Tanpa sumbu X / label tanggal (seperti Stockbit).
- **Scrub**: long-press atau drag horizontal menampilkan garis vertikal +
  titik di data terdekat. Selama scrub, header menampilkan harga titik
  itu, perubahan terhadap `referencePrice`, dan label periode diganti
  tanggal/jam titik (1D/1W/1M: `d MMM HH.mm`; lainnya: `d MMM yyyy`).
  Lepas jari → kembali ke harga terkini. `HapticFeedback.selectionClick`
  saat pindah titik. State scrub dipegang `market_detail_page`
  (`ValueNotifier<PricePoint?>`), bukan provider.
- `< 2` titik → placeholder "Data chart belum tersedia" setinggi chart.
- Loading → area chart kosong + `CircularProgressIndicator` kecil di tengah.
  Error → teks satu baris di tengah area chart.

Tab range (`chart_range_tabs.dart`): `Row` teks 8 item rata, `labelLarge`;
aktif = `colorScheme.primary` + underline 2dp; tidak aktif = muted.
Tidak pakai `SegmentedButton`. Toggle candle/line dan tombol fullscreen
di screenshot **tidak** dibuat.

Tombol **Perbarui Nilai**: `FilledButton` full width, padding horizontal
`AppSpacing.xl`, label `l10n.updateValueButton` (key yang sudah ada), push
`'${RouteNames.assets}/${assetId}/update'`. Satu-satunya tombol (pengganti
Jual/Beli).

Pull-to-refresh (`RefreshablePageBody`): invalidate
`marketQuoteProvider(symbol)` dan `priceChartProvider` range aktif.

State error halaman:

| Kondisi                                   | Tampilan                                                        |
|-------------------------------------------|-----------------------------------------------------------------|
| quote loading                             | header skeleton (kode & nama tetap tampil dari aset)            |
| `MarketSymbolNotFoundException`           | ganti header+chart dengan `AppEmptyState`: "Simbol {symbol} tidak ditemukan di Yahoo Finance." + tombol "Edit Aset" |
| `MarketDataUnavailableException` tanpa cache | `AppErrorView` "Harga belum bisa dimuat. Tarik untuk coba lagi." |
| stale (cache)                             | harga cache + chip Offline; chart menampilkan error per-range   |

Tombol Perbarui Nilai **selalu** tampil, di semua state.

Widget baru, semua di `lib/features/market/presentation/`:

```
pages/market_detail_page.dart
widgets/market_price_tile.dart
widgets/market_quote_header.dart
widgets/price_line_chart.dart
widgets/chart_range_tabs.dart
```

Logika murni dipisah dari widget supaya bisa dites tanpa render:
`lib/features/market/presentation/chart_math.dart` —
`niceTicks(min, max, {int target = 6})`, `nearestPointIndex(points, dx, width)`,
`referencePrice(range, quote, series)`.

### Format harga

Tambah di `lib/core/utils/currency_formatter.dart`:

```dart
String formatPrice(double value, String currency)
String formatSignedPrice(double value, String currency)
```

- `IDR` → tanpa simbol, pemisah ribuan titik, tanpa desimal (`4.070`),
  seperti Stockbit. Harga < 1 pakai 2 desimal koma.
- Mata uang lain → simbol + 2 desimal (`$4,070.12`), lewat
  `NumberFormat.simpleCurrency(name: currency, decimalDigits: 2)`.
- Label sumbu Y dan label min/max chart pakai format sama tanpa simbol.
- Tanpa konversi kurs.

### l10n

Tambah key di `app_en.arb` dan `app_id.arb`:
`marketPriceTitle`, `marketSymbolLabel`, `marketSymbolHelper`,
`marketAsOf` (placeholder waktu), `marketOfflineChip`, `marketLoading`,
`marketUnavailableShort`, `marketSymbolNotFound` (placeholder simbol),
`marketUnavailable`, `marketChartEmpty`, `editAssetButton` (bila belum ada),
label tab `chartRange1D … chartRange5Y`, dan label periode
`chartPeriodToday … chartPeriodFiveYears` (tabel di atas).

## Out of scope

- Jumlah unit, valuasi otomatis, snapshot otomatis, kurs USD/IDR.
- Harga di daftar aset atau dashboard.
- Candlestick, toggle candle/line, fullscreen chart, volume.
- Logo emiten, tag sektor, tab Stream/Keystats/Orderbook, watchlist,
  alarm, share.
- Cache seri chart, background refresh, notifikasi harga.
- Pencarian simbol (Yahoo search API).
- Migrasi provider ke `@riverpod`.

## Testing

- `test/features/market/data/yahoo_finance_client_test.dart` — `MockClient`
  dari `package:http/testing.dart`, fixture JSON dari contoh response:
  - quote BMRI.JK benar (price 4070, prevClose 4190, currency IDR).
  - seri: jumlah titik = jumlah `close` non-null; titik null dibuang.
  - `chart.error` terisi / HTTP 404 → `MarketSymbolNotFoundException`.
  - HTTP 429, 500, body bukan JSON, `ClientException` →
    `MarketDataUnavailableException`.
  - URL: simbol ter-encode (`%5EJKSE`), `range`/`interval` sesuai tabel;
    3Y memakai `period1`/`period2` dari `clock`; header `User-Agent`
    terkirim.
- `test/features/market/data/market_repository_test.dart` — DB in-memory
  (`AppDatabase.forTesting(NativeDatabase.memory())`) + client fake:
  sukses → cache ter-upsert; gagal + cache → `isStale: true`,
  `oneDaySeries == null`; gagal tanpa cache → rethrow; not-found →
  rethrow walau cache ada; `getChart` tidak menyentuh cache.
- `test/features/market/data/market_symbol_suggestion_test.dart`.
- `test/features/market/presentation/chart_math_test.dart` — `niceTicks`
  (4060–4190 → 4060…4200 step 20 atau setara), `nearestPointIndex` di tepi
  & tengah, `referencePrice` 1D vs range lain.
- `test/core/database/app_database_test.dart` — migrasi v5 → v6 menambah
  `market_symbol` dan `market_quotes`; data aset lama utuh.
- `test/features/portfolio/models` — `Asset` JSON round-trip dengan
  `marketSymbol` null dan terisi.
- Widget test dengan provider di-override:
  - `market_price_tile`: tampil harga + persen; tap push route `market`.
  - `market_detail_page`: harga besar, label "Hari Ini"; ganti tab 1Y →
    label "1 Tahun Terakhir" dan perubahan dihitung dari titik pertama;
    chip Offline saat stale; not-found → empty state; tombol Perbarui
    Nilai ada di semua state dan push route `update`.
- Detail aset tanpa `marketSymbol` tidak menampilkan tile (regresi).

## Verification

`dart run build_runner build --force-jit` (freezed), `flutter gen-l10n`
bila tidak otomatis, `flutter analyze` bersih, `flutter test` hijau. Cek
manual di device: BMRI.JK, BTC-USD, SPY tampil di semua 8 tab; scrub
jalan; mode pesawat → harga cache + chip Offline; simbol ngawur → empty
state not-found; alur Daftar Aset → Detail Aset → Detail Pasar → Perbarui
Nilai → kembali.

## Urutan implementasi yang disarankan

1. Migrasi DB + `Asset.marketSymbol` + repository portfolio (+ tes).
2. Model market, `ChartRange`, `YahooFinanceClient` (+ tes).
3. `MarketRepository` + providers (+ tes).
4. `formatPrice` + l10n + `chart_math.dart` (+ tes).
5. Field simbol di form aset + `suggestMarketSymbol`.
6. `market_price_tile` di detail aset + route `market`.
7. `market_detail_page`: header, tab range, tombol Perbarui Nilai.
8. `price_line_chart`: garis, area, acuan, label ekstrem, sumbu Y.
9. Scrub interaktif.
