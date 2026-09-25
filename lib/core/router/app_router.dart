import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/core/router/route_names.dart';
import 'package:flutter_wasilah_app/features/backup/presentation/pages/restore_page.dart';
import 'package:flutter_wasilah_app/features/market/presentation/pages/market_detail_page.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/pages/asset_form_page.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/pages/dashboard_page.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/pages/holding_detail_page.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/pages/master_asset_list_page.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/pages/portfolio_history_page.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/pages/portfolio_page.dart';
import 'package:flutter_wasilah_app/features/portfolio/presentation/pages/update_asset_value_page.dart';
import 'package:flutter_wasilah_app/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter_wasilah_app/features/target/presentation/pages/target_detail_page.dart';
import 'package:flutter_wasilah_app/features/target/presentation/pages/target_form_page.dart';
import 'package:flutter_wasilah_app/features/target/presentation/pages/target_page.dart';
import 'package:flutter_wasilah_app/l10n/l10n_extensions.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.dashboard,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _AppShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.dashboard,
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.history,
                builder: (context, state) => const PortfolioHistoryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.portfolio,
                builder: (context, state) => const PortfolioPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.target,
                builder: (context, state) => const TargetPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.settings,
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
      // ======================= PORTOFOLIO ========================
      // Holding: nilai, modal, histori. Rute statis sebelum `:id`.
      GoRoute(
        path: RouteNames.portfolioUpdate,
        builder: (context, state) => const UpdateAssetValuePage(),
      ),
      GoRoute(
        path: '${RouteNames.portfolio}/:id',
        builder: (context, state) {
          final assetId = state.pathParameters['id']!;
          return HoldingDetailPage(assetId: assetId);
        },
        routes: [
          GoRoute(
            path: 'update',
            builder: (context, state) {
              final assetId = state.pathParameters['id']!;
              return UpdateAssetValuePage(assetId: assetId);
            },
          ),
          GoRoute(
            path: RouteNames.portfolioMarketSegment,
            builder: (context, state) {
              final assetId = state.pathParameters['id']!;
              return MarketDetailPage(assetId: assetId);
            },
          ),
        ],
      ),

      // ======================= MASTER ASET =======================
      // Identitas aset (nama, kode, kategori, simbol pasar), dari Pengaturan.
      GoRoute(
        path: RouteNames.masterAssets,
        builder: (context, state) => const MasterAssetListPage(),
      ),
      GoRoute(
        path: RouteNames.masterAssetCreate,
        builder: (context, state) => const AssetFormPage(),
      ),
      GoRoute(
        path: '${RouteNames.masterAssets}/:id',
        builder: (context, state) {
          final assetId = state.pathParameters['id']!;
          return AssetFormPage(assetId: assetId);
        },
      ),

      GoRoute(
        path: RouteNames.targetCreate,
        builder: (context, state) => const TargetFormPage(),
      ),
      GoRoute(
        path: RouteNames.backupRestore,
        builder: (context, state) => const RestorePage(),
      ),
      GoRoute(
        path: '${RouteNames.target}/:id',
        builder: (context, state) {
          final targetId = state.pathParameters['id']!;
          return TargetDetailPage(targetId: targetId);
        },
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) {
              final targetId = state.pathParameters['id']!;
              return TargetFormPage(targetId: targetId);
            },
          ),
        ],
      ),
    ],
  );
});

class _AppShellScaffold extends StatelessWidget {
  const _AppShellScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static List<NavigationDestination> _destinations(BuildContext context) {
    final l10n = context.l10n;
    return [
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: l10n.navDashboardLabel,
      ),
      NavigationDestination(
        icon: const Icon(Icons.history_outlined),
        selectedIcon: const Icon(Icons.history),
        label: l10n.historyTitle,
      ),
      NavigationDestination(
        icon: const Icon(Icons.account_balance_wallet_outlined),
        selectedIcon: const Icon(Icons.account_balance_wallet),
        label: l10n.portfolioTitle,
      ),
      NavigationDestination(
        icon: const Icon(Icons.flag_outlined),
        selectedIcon: const Icon(Icons.flag),
        label: l10n.targetTitle,
      ),
      NavigationDestination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings),
        label: l10n.settingsTitle,
      ),
    ];
  }

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Material 3 memindahkan navigasi ke sisi kiri mulai lebar 600dp. Di
    // tablet dan ponsel landscape, bar bawah memakan tinggi layar yang justru
    // paling langka di sana.
    if (MediaQuery.sizeOf(context).width < 600) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 0,
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: _destinations(context),
          ),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final destination in _destinations(context))
                NavigationRailDestination(
                  icon: destination.icon,
                  selectedIcon: destination.selectedIcon,
                  label: Text(destination.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
