import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/app/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/core/widgets/app_card.dart';
import 'package:flutter_wasilah_app/core/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/core/widgets/async_value_view.dart';
import 'package:flutter_wasilah_app/core/widgets/refreshable_page_body.dart';
import 'package:flutter_wasilah_app/core/widgets/section_header.dart';
import 'package:flutter_wasilah_app/features/target/providers/target_providers.dart';
import 'package:flutter_wasilah_app/features/target/widgets/target_allocation_item.dart';

class TargetPage extends ConsumerWidget {
  const TargetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetItemsValue = ref.watch(targetAllocationItemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Target')),
      body: AsyncValueView(
        value: targetItemsValue,
        onRetry: () => ref.invalidate(targetAllocationItemsProvider),
        data: (items) {
          if (items.isEmpty) {
            return RefreshablePageBody(
              onRefresh: () =>
                  ref.refresh(targetAllocationItemsProvider.future),
              child: const AppEmptyState(
                title: 'Belum ada target alokasi',
                message: 'Target kategori akan tampil di sini.',
              ),
            );
          }

          final onTrackCount = items
              .where((item) => item.status == TargetStatus.onTrack)
              .length;

          return RefreshablePageBody(
            onRefresh: () => ref.refresh(targetAllocationItemsProvider.future),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bandingkan alokasi aktual dengan target ideal agar portofolio tetap seimbang.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$onTrackCount dari ${items.length} kategori sudah sesuai target',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Gunakan status tiap kategori untuk menentukan prioritas penyesuaian.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'Rincian kategori'),
                const SizedBox(height: AppSpacing.md),
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppCard(child: TargetAllocationItem(item: item)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
