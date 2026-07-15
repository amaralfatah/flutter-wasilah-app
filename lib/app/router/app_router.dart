import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wasilah_app/app/router/route_names.dart';
import 'package:flutter_wasilah_app/features/portfolio/pages/asset_detail_page.dart';
import 'package:flutter_wasilah_app/features/portfolio/pages/asset_list_page.dart';
import 'package:flutter_wasilah_app/features/portfolio/pages/dashboard_page.dart';
import 'package:flutter_wasilah_app/features/portfolio/pages/portfolio_history_page.dart';
import 'package:flutter_wasilah_app/features/portfolio/pages/update_asset_value_page.dart';
import 'package:flutter_wasilah_app/features/settings/pages/settings_page.dart';
import 'package:flutter_wasilah_app/features/target/pages/target_page.dart';
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
                path: RouteNames.assets,
                builder: (context, state) => const AssetListPage(),
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
      GoRoute(
        path: RouteNames.assetUpdate,
        builder: (context, state) => const UpdateAssetValuePage(),
      ),
      GoRoute(
        path: '${RouteNames.assets}/:id',
        builder: (context, state) {
          final assetId = state.pathParameters['id']!;
          return AssetDetailPage(assetId: assetId);
        },
        routes: [
          GoRoute(
            path: 'update',
            builder: (context, state) {
              final assetId = state.pathParameters['id']!;
              return UpdateAssetValuePage(assetId: assetId);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Histori',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Aset',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Target',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Setelan',
          ),
        ],
      ),
    );
  }
}
