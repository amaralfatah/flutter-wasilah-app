import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/time_weighted_return.dart';

AssetSnapshot _snapshot(DateTime recordedAt, double value, double? cost) {
  return AssetSnapshot(
    id: 'portfolio-${recordedAt.year}-${recordedAt.month}',
    assetId: 'portfolio',
    totalValue: value,
    recordedAt: recordedAt,
    totalCost: cost,
  );
}

void main() {
  test('chains monthly returns regardless of input order', () {
    final result = timeWeightedReturn([
      _snapshot(DateTime(2026, 2, 28), 108, 100),
      _snapshot(DateTime(2025, 12, 31), 100, 100),
      _snapshot(DateTime(2026, 1, 31), 120, 100),
    ]);

    // +20% lalu -10% = 1,2 x 0,9 - 1 = +8%.
    expect(result!.cumulative, closeTo(8, 1e-9));
    expect(result.annualized, isNull);
  });

  test('excludes deposits from the return', () {
    final result = timeWeightedReturn([
      _snapshot(DateTime(2025, 12, 31), 10, 10),
      _snapshot(DateTime(2026, 1, 31), 12, 10),
      // Setor 90 di Februari: hasil 5,7 atas basis 12 + 90/2 = +10%.
      _snapshot(DateTime(2026, 2, 28), 107.7, 100),
    ]);

    expect(result!.cumulative, closeTo(32, 1e-9));
  });

  test('year filter starts from the previous year closing value', () {
    final history = [
      _snapshot(DateTime(2025, 11, 30), 50, 100),
      _snapshot(DateTime(2025, 12, 31), 100, 100),
      _snapshot(DateTime(2026, 1, 31), 110, 100),
    ];

    expect(
      timeWeightedReturn(history, year: 2026)!.cumulative,
      closeTo(10, 1e-9),
    );
    expect(
      timeWeightedReturn(history, year: 2025)!.cumulative,
      closeTo(100, 1e-9),
    );
  });

  test('annualizes spans of at least a year', () {
    final result = timeWeightedReturn([
      _snapshot(DateTime(2024), 100, 100),
      _snapshot(DateTime(2025), 110, 100),
      _snapshot(DateTime(2026), 121, 100),
    ]);

    expect(result!.cumulative, closeTo(21, 1e-9));
    expect(result.annualized, closeTo(10, 0.05));
  });

  test('returns null without two snapshots that have a cost', () {
    expect(timeWeightedReturn([]), isNull);
    expect(
      timeWeightedReturn([_snapshot(DateTime(2026), 100, 100)]),
      isNull,
    );
    expect(
      timeWeightedReturn([
        _snapshot(DateTime(2025, 12), 100, null),
        _snapshot(DateTime(2026), 110, null),
      ]),
      isNull,
    );
  });
}
