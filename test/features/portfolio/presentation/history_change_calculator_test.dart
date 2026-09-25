import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/portfolio_snapshot.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/utils/history_change_calculator.dart';

PortfolioSnapshot _snapshot(String id, double value) =>
    PortfolioSnapshot(id: id, totalValue: value, recordedAt: DateTime(2026));

void main() {
  group('buildHistoryChangeMap', () {
    test('compares each entry with the older one after it', () {
      final map = buildHistoryChangeMap([
        _snapshot('jul', 110),
        _snapshot('jun', 100),
        _snapshot('may', 125),
      ]);

      expect(map['jul'], closeTo(10, 1e-9));
      expect(map['jun'], closeTo(-20, 1e-9));
      expect(map['may'], 0);
    });

    test('treats a zero previous value as no change', () {
      final map = buildHistoryChangeMap([
        _snapshot('jul', 50),
        _snapshot('jun', 0),
      ]);

      expect(map['jul'], 0);
    });
  });

  group('formatHistoryChange', () {
    test('labels the first snapshot as initial data', () {
      expect(
        formatHistoryChange(5, isFirstSnapshot: true, initialDataLabel: 'Awal'),
        'Awal',
      );
      expect(
        formatHistoryChange(
          null,
          isFirstSnapshot: false,
          initialDataLabel: 'Awal',
        ),
        'Awal',
      );
    });

    test('formats other entries as a signed percentage', () {
      expect(
        formatHistoryChange(
          5,
          isFirstSnapshot: false,
          initialDataLabel: 'Awal',
        ),
        isNot('Awal'),
      );
    });
  });
}
