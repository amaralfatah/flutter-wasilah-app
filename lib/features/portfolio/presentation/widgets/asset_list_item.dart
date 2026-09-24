import 'package:flutter/material.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/utils/currency_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/date_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/percentage_formatter.dart';
import 'package:flutter_wasilah_app/core/utils/profit_loss_formatter.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/l10n/app_localizations.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';

/// Baris aset bergaya tabel portofolio (ala Stockbit): kode, modal, nilai,
/// dan untung/rugi terlihat sekaligus tanpa membuka detail.
///
/// Tiap kolom dua baris — angka utama di atas, keterangan kecil di bawah —
/// dan urutannya dijelaskan oleh [AssetTableHeader]. Pasang header itu
/// sebagai baris pertama kartu daftar yang sama.
class AssetListItem extends StatelessWidget {
  const AssetListItem({required this.asset, super.key, this.onTap});

  final Asset asset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final primaryStyle = textTheme.bodyMedium;
    final captionStyle = textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    final cost = asset.totalCost;
    final profitLoss = asset.profitLoss;
    final profitLossPercentage = asset.profitLossPercentage;
    final profitLossStyle = profitLoss == null
        ? primaryStyle
        : primaryStyle?.copyWith(
            color: profitLossColorOf(context, profitLoss),
            fontWeight: FontWeight.w500,
          );

    return Semantics(
      button: onTap != null,
      label: _semanticLabel(context, l10n),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: _AssetTableRow(
          code: _Cell(
            primary: Text(
              asset.code,
              style: textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            secondary: Text(
              asset.name,
              style: captionStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          cost: _Cell.number(
            primary: cost == null ? '-' : formatNumber(cost),
            secondary: formatPercentage(asset.allocationPercentage),
            primaryStyle: primaryStyle,
            secondaryStyle: captionStyle,
          ),
          value: _Cell.number(
            primary: formatNumber(asset.currentValue),
            secondary: formatDayMonth(
              asset.lastUpdatedAt,
              Localizations.localeOf(context),
            ),
            primaryStyle: primaryStyle,
            secondaryStyle: captionStyle,
          ),
          profitLoss: _Cell.number(
            primary: profitLoss == null ? '-' : formatSignedNumber(profitLoss),
            secondary: profitLossPercentage == null
                ? '-'
                : formatSignedPercentage(profitLossPercentage),
            primaryStyle: profitLossStyle,
            secondaryStyle: profitLoss == null
                ? captionStyle
                : captionStyle?.copyWith(
                    color: profitLossColorOf(context, profitLoss),
                  ),
          ),
        ),
      ),
    );
  }

  String _semanticLabel(BuildContext context, AppLocalizations l10n) {
    final buffer = StringBuffer(
      '${asset.code}, ${asset.name}. '
      '${l10n.assetSemanticValueAllocation(
        formatCurrency(asset.currentValue),
        formatPercentage(asset.allocationPercentage),
      )}.',
    );
    final cost = asset.totalCost;
    final profitLoss = asset.profitLoss;
    if (cost != null && profitLoss != null) {
      buffer.write(
        ' ${l10n.assetSemanticCostProfitLoss(
          formatCurrency(cost),
          profitLossLabel(context, profitLoss),
          formatCurrency(profitLoss.abs()),
        )}.',
      );
    }
    return buffer.toString();
  }
}

/// Judul kolom untuk [AssetListItem]; baris kedua menjelaskan keterangan
/// kecil di bawah setiap angka.
class AssetTableHeader extends StatelessWidget {
  const AssetTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final primaryStyle = textTheme.labelMedium?.copyWith(
      color: colorScheme.onSurface,
    );
    final secondaryStyle = textTheme.labelSmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    Widget cell(String primary, String secondary, {bool number = true}) {
      final alignment = number ? Alignment.centerRight : Alignment.centerLeft;
      Widget fit(String text, TextStyle? style) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: Text(text, style: style, maxLines: 1),
      );

      return _Cell(
        crossAxisAlignment: number
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        primary: fit(primary, primaryStyle),
        secondary: fit(secondary, secondaryStyle),
      );
    }

    return ExcludeSemantics(
      child: _AssetTableRow(
        code: cell(
          l10n.assetTableCodeHeader,
          l10n.assetTableNameHeader,
          number: false,
        ),
        cost: cell(
          l10n.dashboardCapitalLabel,
          l10n.assetTableAllocationHeader,
        ),
        value: cell(l10n.assetTableValueHeader, l10n.assetTableUpdatedHeader),
        profitLoss: cell(
          l10n.assetTableProfitLossHeader,
          l10n.commonReturnLabel,
        ),
      ),
    );
  }
}

/// Tata letak kolom bersama header dan baris supaya selalu sejajar.
class _AssetTableRow extends StatelessWidget {
  const _AssetTableRow({
    required this.code,
    required this.cost,
    required this.value,
    required this.profitLoss,
  });

  final Widget code;
  final Widget cost;
  final Widget value;
  final Widget profitLoss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(flex: 5, child: code),
          const SizedBox(width: AppSpacing.sm),
          Expanded(flex: 6, child: cost),
          const SizedBox(width: AppSpacing.sm),
          Expanded(flex: 6, child: value),
          const SizedBox(width: AppSpacing.sm),
          Expanded(flex: 6, child: profitLoss),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.primary,
    required this.secondary,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  /// Sel angka rata kanan. Angka mengecil seperlunya (tidak pernah
  /// terpotong) di layar sempit atau skala teks besar.
  factory _Cell.number({
    required String primary,
    required String secondary,
    required TextStyle? primaryStyle,
    required TextStyle? secondaryStyle,
  }) {
    Widget fit(String text, TextStyle? style) => FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(text, style: style, maxLines: 1),
    );

    return _Cell(
      crossAxisAlignment: CrossAxisAlignment.end,
      primary: fit(primary, primaryStyle),
      secondary: fit(secondary, secondaryStyle),
    );
  }

  final Widget primary;
  final Widget secondary;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        primary,
        const SizedBox(height: AppSpacing.xs),
        secondary,
      ],
    );
  }
}
