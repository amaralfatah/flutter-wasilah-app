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
      alignment: Alignment.centerLeft,
      child: TextButton(
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          minimumSize: Size.zero,
          textStyle: Theme.of(context).textTheme.labelMedium,
        ),
        onPressed: onPressed,
        child: Text(context.l10n.autofillButton(amount)),
      ),
    );
  }
}
