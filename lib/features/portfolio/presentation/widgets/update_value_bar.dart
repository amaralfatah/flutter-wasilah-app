import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/router/route_names.dart';
import 'package:flutter_wasilah_app/core/theme/app_colors.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:go_router/go_router.dart';

/// Bar tombol yang menempel di bawah layar, untuk slot
/// `Scaffold.bottomNavigationBar`: "Beli" bergaris hijau dan "Jual"
/// bergaris merah, pasangan tombol Buy/Sell di Stockbit. "Edit portofolio"
/// dan "Keluarkan" ada di menu AppBar. Aset tanpa beli/jual (kas) hanya
/// mendapat satu tombol "Catat nilai".
class UpdateValueBar extends StatelessWidget {
  const UpdateValueBar({
    required this.assetId,
    super.key,
    this.onRecordPurchase,
    this.onRecordSale,
  });

  final String assetId;
  final VoidCallback? onRecordPurchase;
  final VoidCallback? onRecordSale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final positive = AppColors.positiveOf(context);
    final negative = AppColors.negativeOf(context);
    final onRecordPurchase = this.onRecordPurchase;
    final onRecordSale = this.onRecordSale;

    ButtonStyle outlined(Color color) => OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color),
      minimumSize: const Size.fromHeight(44),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
    );

    Widget button(String label, Color color, VoidCallback onPressed) =>
        Expanded(
          child: OutlinedButton(
            style: outlined(color),
            onPressed: onPressed,
            child: _OneLine(label),
          ),
        );

    final buttons = <Widget>[
      if (onRecordPurchase != null)
        button(l10n.recordPurchaseButton, positive, onRecordPurchase),
      if (onRecordSale != null) button(l10n.sellButton, negative, onRecordSale),
      if (onRecordPurchase == null && onRecordSale == null)
        button(
          l10n.updateValueButton,
          positive,
          () => context.push('${RouteNames.portfolio}/$assetId/update'),
        ),
    ];

    // Padding di dalam SafeArea supaya jaraknya ditambahkan ke inset nav bar;
    // `SafeArea.minimum` hanya mengambil nilai terbesar.
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              for (var i = 0; i < buttons.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.md),
                buttons[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Label tombol selalu satu baris; mengecil bila terjemahannya panjang.
class _OneLine extends StatelessWidget {
  const _OneLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(text, maxLines: 1),
    );
  }
}
