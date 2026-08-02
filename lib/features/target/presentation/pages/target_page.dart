import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/router/route_names.dart';
import 'package:flutter_wasilah_app/core/theme/app_spacing.dart';
import 'package:flutter_wasilah_app/features/target/presentation/widgets/category_donut_chart.dart';
import 'package:flutter_wasilah_app/features/target/presentation/widgets/target_allocation_item.dart';
import 'package:flutter_wasilah_app/features/target/providers/target_providers.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_empty_state.dart';
import 'package:flutter_wasilah_app/shared/widgets/app_list_card.dart';
import 'package:flutter_wasilah_app/shared/widgets/async_value_view.dart';
import 'package:flutter_wasilah_app/shared/widgets/refreshable_page_body.dart';
import 'package:go_router/go_router.dart';

const _targetPagePadding = EdgeInsets.fromLTRB(
  AppSpacing.xl,
  AppSpacing.xl,
  AppSpacing.xl,
  AppSpacing.xxxl + (kFloatingActionButtonMargin * 3),
);

class TargetPage extends ConsumerWidget {
  const TargetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetItemsValue = ref.watch(targetAllocationItemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Target')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'target_create_fab',
        onPressed: () => context.push(RouteNames.targetCreate),
        tooltip: 'Tambah target',
        child: const Icon(Icons.add),
      ),
      body: AsyncValueView(
        value: targetItemsValue,
        onRetry: () => ref.invalidate(targetAllocationItemsProvider),
        data: (items) {
          if (items.isEmpty) {
            return RefreshablePageBody(
              onRefresh: () =>
                  ref.refresh(targetAllocationItemsProvider.future),
              padding: _targetPagePadding,
              child: AppEmptyState(
                title: 'Belum ada target alokasi',
                message:
                    'Tentukan porsi ideal tiap kategori aset supaya progres '
                    'portofolio bisa dihitung.',
                actionLabel: 'Tambah target',
                onAction: () => context.push(RouteNames.targetCreate),
              ),
            );
          }

          return RefreshablePageBody(
            onRefresh: () => ref.refresh(targetAllocationItemsProvider.future),
            padding: _targetPagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CategoryDonutChart(items: items),
                const SizedBox(height: AppSpacing.xl),
                AppListCard(
                  children: items
                      .map(
                        (item) => InkWell(
                          onTap: () =>
                              context.push('${RouteNames.target}/${item.id}'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.lg,
                            ),
                            child: TargetAllocationItem(item: item),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
