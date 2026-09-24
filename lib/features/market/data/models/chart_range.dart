/// Rentang chart harga, meniru tab Stockbit (1D 1W 1M 3M YTD 1Y 3Y 5Y).
///
/// `range` adalah parameter `range` Yahoo Finance; `null` untuk [threeYears]
/// karena `3y` bukan salah satu `validRanges` Yahoo -- range itu memakai
/// `period1`/`period2` (epoch detik) sebagai gantinya.
enum ChartRange {
  oneDay('1d', '1m'),
  oneWeek('5d', '15m'),
  oneMonth('1mo', '60m'),
  threeMonths('3mo', '1d'),
  yearToDate('ytd', '1d'),
  oneYear('1y', '1d'),
  threeYears(null, '1wk'),
  fiveYears('5y', '1wk');

  const ChartRange(this.range, this.interval);

  final String? range;
  final String interval;
}
