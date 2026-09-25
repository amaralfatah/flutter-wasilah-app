import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_colors.dart';
import 'package:flutter_wasilah_app/core/utils/percentage_formatter.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/value_snapshot.dart';

/// Peta perubahan persentase tiap snapshot dibanding snapshot sebelumnya
/// (lebih lama), dipakai sama antara histori portofolio dan histori aset.
Map<String, double> buildHistoryChangeMap(List<ValueSnapshot> history) {
  final map = <String, double>{};
  for (var index = 0; index < history.length; index++) {
    final current = history[index];
    final next = index + 1 < history.length ? history[index + 1] : null;
    if (next == null || next.totalValue == 0) {
      map[current.id] = 0;
      continue;
    }

    map[current.id] =
        ((current.totalValue - next.totalValue) / next.totalValue) * 100;
  }

  return map;
}

String formatHistoryChange(
  double? value, {
  required bool isFirstSnapshot,
  required String initialDataLabel,
}) {
  if (isFirstSnapshot || value == null) {
    return initialDataLabel;
  }

  return formatSignedPercentage(value);
}

Color historyChangeColor(
  BuildContext context,
  double? value, {
  required bool isFirstSnapshot,
}) {
  if (isFirstSnapshot || value == null) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  if (value > 0) {
    return AppColors.positiveOf(context);
  }
  if (value < 0) {
    return AppColors.negativeOf(context);
  }

  return Theme.of(context).colorScheme.onSurfaceVariant;
}
