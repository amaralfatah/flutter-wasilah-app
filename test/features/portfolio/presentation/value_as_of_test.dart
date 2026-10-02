import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/utils/value_as_of.dart';

AssetSnapshot _snapshot(DateTime recordedAt, double value) => AssetSnapshot(
  id: 'cash-${recordedAt.year}-${recordedAt.month}',
  assetId: 'cash',
  totalValue: value,
  recordedAt: recordedAt,
);

void main() {
  final history = [
    _snapshot(DateTime(2026, 9, 20), 9000000),
    _snapshot(DateTime(2026, 7, 12), 7000000),
    _snapshot(DateTime(2026, 6, 12), 6000000),
  ];

  test('uses the latest snapshot before the date', () {
    expect(valueAsOf(history, DateTime(2026, 8, 5)), 7000000);
  });

  test('includes the snapshot of the same month even if later that month', () {
    expect(valueAsOf(history, DateTime(2026, 9)), 9000000);
  });

  test('is zero before the first snapshot', () {
    expect(valueAsOf(history, DateTime(2026, 5, 31)), 0);
  });
}
