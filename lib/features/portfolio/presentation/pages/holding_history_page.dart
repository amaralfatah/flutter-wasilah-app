import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/features/portfolio/data/models/asset.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/utils/history_delete.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/widgets/holding_history_section.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:flutter_wasilah_app/shared/widgets/refreshable_page_body.dart';

/// Histori lengkap satu holding (chart + tabel, baris bisa digeser untuk
/// dihapus); dibuka dari "Lihat semua" di kartu histori Detail Portofolio,
/// seperti "History › See All" di Stockbit.
class HoldingHistoryPage extends ConsumerStatefulWidget {
  const HoldingHistoryPage({required this.assetId, super.key});

  final String assetId;

  @override
  ConsumerState<HoldingHistoryPage> createState() => _HoldingHistoryPageState();
}

class _HoldingHistoryPageState extends ConsumerState<HoldingHistoryPage> {
  final Set<String> _removedIds = {};

  @override
  Widget build(BuildContext context) {
    final assetId = widget.assetId;
    final historyValue = ref.watch(assetHistoryProvider(assetId));
    final position = ref.watch(positionDetailProvider(assetId)).asData?.value;
    final isCash = position?.asset.category == AssetCategory.cash;

    return Scaffold(
      appBar: AppBar(
        title: Text(position?.asset.code ?? context.l10n.historySectionTitle),
      ),
      body: RefreshablePageBody(
        onRefresh: () => ref.refresh(assetHistoryProvider(assetId).future),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: HoldingHistorySection(
          history: historyValue,
          removedIds: _removedIds,
          showCost: !isCash,
          horizontalPadding: AppSpacing.xl,
          onDismissed: (snapshotId) {
            setState(() => _removedIds.add(snapshotId));
            unawaited(_deleteSnapshot(snapshotId));
          },
        ),
      ),
    );
  }

  Future<void> _deleteSnapshot(String snapshotId) => deleteHistoryEntry(
    context,
    delete: () =>
        ref.read(portfolioRepositoryProvider).deleteAssetSnapshot(snapshotId),
    onFailed: () => setState(() => _removedIds.remove(snapshotId)),
  );
}
