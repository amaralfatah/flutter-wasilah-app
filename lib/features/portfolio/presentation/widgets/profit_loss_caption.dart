import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/profit_loss_formatter.dart';

/// Caption histori: modal pada bulan itu dan untung/rugi terhadapnya.
class ProfitLossCaption extends StatelessWidget {
  const ProfitLossCaption({
    required this.cost,
    required this.profitLoss,
    super.key,
  });

  final double cost;
  final double profitLoss;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;

    return Text.rich(
      TextSpan(
        style: style?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        children: [
          TextSpan(text: 'Modal ${formatCurrency(cost)} · '),
          TextSpan(
            text: formatProfitLoss(profitLoss, cost: cost),
            style: TextStyle(color: profitLossColorOf(context, profitLoss)),
          ),
        ],
      ),
    );
  }
}
