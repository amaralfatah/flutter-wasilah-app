import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_colors.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/percentage_formatter.dart';

/// Format untung/rugi bertanda, misalnya `+Rp2.000.000 (+20%)`.
///
/// Persentase dihitung terhadap [cost] dan dihilangkan bila modalnya nol.
String formatProfitLoss(double profitLoss, {required double cost}) {
  final sign = profitLoss > 0 ? '+' : '';
  final amount = '$sign${formatCurrency(profitLoss)}';
  if (cost == 0) {
    return amount;
  }

  return '$amount (${formatSignedPercentage(profitLoss / cost * 100)})';
}

/// Hijau untuk untung, merah untuk rugi, `null` (warna teks bawaan) untuk
/// impas.
Color? profitLossColorOf(BuildContext context, double profitLoss) {
  if (profitLoss > 0) {
    return AppColors.positiveOf(context);
  }
  if (profitLoss < 0) {
    return AppColors.negativeOf(context);
  }

  return null;
}
