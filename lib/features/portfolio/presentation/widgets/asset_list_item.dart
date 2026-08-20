import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/allocation_badge.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/asset_category_icon.dart';

/// Satu baris aset dengan proporsi tetap: ikon, kode + satu baris caption,
/// lalu nominal + badge alokasi.
///
/// Semua layar (home, daftar aset, detail target) memakai widget ini dengan
/// tepat satu caption aktif — di layar yang sudah mengelompokkan per kategori
/// caption-nya tanggal pembaruan, di layar tanpa grup caption-nya kategori.
/// Menyalakan keduanya membuat baris jadi tiga baris dan tinggi antar layar
/// tidak lagi seragam.
class AssetListItem extends StatelessWidget {
  const AssetListItem({
    required this.asset,
    super.key,
    this.onTap,
    this.showCategory = true,
    this.showUpdatedAt = true,
  });

  final Asset asset;
  final VoidCallback? onTap;
  final bool showCategory;
  final bool showUpdatedAt;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final captionStyle = textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    // Sengaja tidak memakai ListTile: `trailing`-nya mengambil lebar sesuka
    // hati, sehingga nominal panjang menyisakan ruang nyaris nol untuk nama
    // aset dan teks membungkus per huruf ke bawah.
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            AssetCategoryIcon(category: asset.category),
            const SizedBox(width: AppSpacing.md),
            // Kode dijamin dapat 3/5 ruang sisa; nominal maksimal 2/5 dan
            // boleh lebih sempit. Tanpa pembagian tegas ini, nominal besar
            // menggencet kode sampai tak terbaca.
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    asset.code,
                    style: textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (showCategory) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      asset.category.label,
                      style: captionStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (showUpdatedAt) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Diperbarui ${formatShortDate(asset.lastUpdatedAt)}',
                      style: captionStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pengaman untuk nominal ekstrem / skala teks besar:
                  // mengecil seperlunya, tidak pernah meluber.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      formatCurrency(asset.currentValue),
                      style: textTheme.titleMedium,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AllocationBadge(percentage: asset.allocationPercentage),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
