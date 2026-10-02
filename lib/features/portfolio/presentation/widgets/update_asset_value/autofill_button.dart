import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';

/// Tombol kecil di bawah field nominal untuk mengisinya dengan [amount]
/// hasil hitung field lain.
class AutofillButton extends StatelessWidget {
  const AutofillButton({
    required this.amount,
    required this.onPressed,
    super.key,
  });

  /// Nominal yang akan diisikan, sudah diformat untuk ditampilkan.
  final String amount;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Tooltip(
        message: context.l10n.autofillButton(amount),
        child: TextButton.icon(
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            textStyle: Theme.of(context).textTheme.labelMedium,
          ),
          icon: const Icon(Icons.auto_fix_high, size: 14),
          label: Text(amount),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
