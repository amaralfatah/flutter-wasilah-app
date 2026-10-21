import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/router/route_names.dart';
import 'package:flutter_wasilah_app/core/theme/app_colors.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:go_router/go_router.dart';

/// Bar tombol yang menempel di bawah layar, untuk slot
/// `Scaffold.bottomNavigationBar`: "Catat nilai" dan, bila diisi, "Catat
/// beli" bergaris hijau. Selama ada "Catat beli", "Catat nilai" bergaris
/// netral supaya hijau tetap milik aksi beli. "Keluarkan" sengaja tidak di
/// sini (menu AppBar): bersebelahan dengan "Catat beli" ia terbaca sebagai
/// tombol jual, padahal menghapus nilai dan histori.
class UpdateValueBar extends StatelessWidget {
  const UpdateValueBar({
    required this.assetId,
    super.key,
    this.onRecordPurchase,
  });

  final String assetId;
  final VoidCallback? onRecordPurchase;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final positive = AppColors.positiveOf(context);
    final onRecordPurchase = this.onRecordPurchase;

    ButtonStyle outlined(Color color) => OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color),
      minimumSize: const Size.fromHeight(44),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
    );

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
              if (onRecordPurchase != null) ...[
                Expanded(
                  child: OutlinedButton(
                    style: outlined(positive),
                    onPressed: onRecordPurchase,
                    child: _OneLine(l10n.recordPurchaseButton),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: OutlinedButton(
                  style: outlined(
                    onRecordPurchase == null
                        ? positive
                        : colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () =>
                      context.push('${RouteNames.portfolio}/$assetId/update'),
                  child: _OneLine(l10n.updateValueButton),
                ),
              ),
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
