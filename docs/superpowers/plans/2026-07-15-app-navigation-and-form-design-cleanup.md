# App Navigation And Form Design Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make subpages behave like proper Material drill-down screens while keeping the existing app features intact.

**Architecture:** Keep the five top-level destinations inside the existing `StatefulShellRoute`, move asset detail and update routes outside the shell, and adjust page actions to use push-based navigation for drill-down flows. Add focused widget coverage for shell visibility and subpage navigation, then make small semantic UI fixes in touched pages.

**Tech Stack:** Flutter, Material 3, GoRouter, Riverpod, flutter_test

---

### Task 1: Add Failing Navigation Regression Tests

**Files:**
- Create: `test/app/router/app_router_test.dart`
- Modify: `test/features/portfolio/pages/update_asset_value_page_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wasilah_app/app/router/app_router.dart';
import 'package:flutter_wasilah_app/app/router/route_names.dart';
import 'package:flutter_wasilah_app/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter_wasilah_app/features/portfolio/repository/mock_portfolio_repository.dart';

void main() {
  testWidgets('asset detail hides bottom navigation when opened directly', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        portfolioRepositoryProvider.overrideWithValue(
          MockPortfolioRepository(simulatedDelay: Duration.zero),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider)
      ..go('${RouteNames.assets}/btc');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detail Aset'), findsOneWidget);
    expect(find.text('Beranda'), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('asset update hides bottom navigation when opened directly', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        portfolioRepositoryProvider.overrideWithValue(
          MockPortfolioRepository(simulatedDelay: Duration.zero),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider)
      ..go('${RouteNames.assets}/btc/update');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Update Nilai Aset'), findsOneWidget);
    expect(find.text('Beranda'), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
```

```dart
testWidgets('successful submit pops back to the previous route', (tester) async {
  final repository = MockPortfolioRepository(simulatedDelay: Duration.zero);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        portfolioRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(
        home: UpdateAssetValuePage(assetId: 'btc'),
      ),
    ),
  );

  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextFormField).at(1), '50000000');
  await tester.tap(find.byIcon(Icons.calendar_today_outlined));
  await tester.pumpAndSettle();
  await tester.tap(find.text('15'));
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).last, 'Catatan tes');

  await tester.tap(find.text('Simpan', skipOffstage: false).last);
  await tester.pumpAndSettle();

  expect(find.textContaining('berhasil diperbarui'), findsOneWidget);
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
flutter test test/app/router/app_router_test.dart
flutter test test/features/portfolio/pages/update_asset_value_page_test.dart
```

Expected:

- `app_router_test.dart` fails because the shell still renders the `NavigationBar` on asset detail and update pages
- `update_asset_value_page_test.dart` may fail because the success flow assumptions do not yet match the route structure we want to verify

- [ ] **Step 3: Commit the red tests**

```bash
git add test/app/router/app_router_test.dart test/features/portfolio/pages/update_asset_value_page_test.dart
git commit -m "test: add navigation cleanup regression coverage"
```

### Task 2: Move Drill-Down Routes Outside The Shell

**Files:**
- Modify: `lib/app/router/app_router.dart`
- Test: `test/app/router/app_router_test.dart`

- [ ] **Step 1: Write the minimal router change**

```dart
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
```

And keep the shell branch for assets limited to:

```dart
StatefulShellBranch(
  routes: [
    GoRoute(
      path: RouteNames.assets,
      builder: (context, state) => const AssetListPage(),
    ),
  ],
),
```

- [ ] **Step 2: Run the router tests**

Run:

```bash
flutter test test/app/router/app_router_test.dart
```

Expected: PASS

- [ ] **Step 3: Commit the router change**

```bash
git add lib/app/router/app_router.dart test/app/router/app_router_test.dart
git commit -m "feat: move asset subpages outside shell"
```

### Task 3: Use Push Navigation For Drill-Down Flows

**Files:**
- Modify: `lib/features/portfolio/pages/dashboard_page.dart`
- Modify: `lib/features/portfolio/pages/asset_list_page.dart`
- Modify: `lib/features/portfolio/pages/asset_detail_page.dart`

- [ ] **Step 1: Update drill-down actions**

Replace `go` with `push` only for subpage transitions:

```dart
onTap: () => context.push('${RouteNames.assets}/${asset.id}'),
```

```dart
onUpdate: () => context.push('${RouteNames.assets}/${asset.id}/update'),
```

```dart
onPressed: () => context.push('${RouteNames.assets}/${asset.id}/update'),
```

Keep tab switches such as `context.go(RouteNames.assets)` unchanged.

- [ ] **Step 2: Run the router and dashboard tests**

Run:

```bash
flutter test test/app/router/app_router_test.dart test/features/portfolio/pages/dashboard_page_test.dart
```

Expected: PASS

- [ ] **Step 3: Commit the navigation behavior update**

```bash
git add lib/features/portfolio/pages/dashboard_page.dart lib/features/portfolio/pages/asset_list_page.dart lib/features/portfolio/pages/asset_detail_page.dart
git commit -m "feat: use push for asset drill-down navigation"
```

### Task 4: Clean Up Touched UI Copy And Semantic Feedback

**Files:**
- Modify: `lib/features/portfolio/pages/portfolio_history_page.dart`
- Modify: `lib/features/settings/pages/settings_page.dart`
- Modify: `test/features/portfolio/pages/update_asset_value_page_test.dart`

- [ ] **Step 1: Add or update the failing expectation for semantic feedback**

Use an expectation that distinguishes positive and negative changes by rendered wording and visible color semantics after the cleanup.

```dart
expect(find.textContaining('Turun'), findsOneWidget);
```

Then update the page implementation so the text style color depends on the value sign:

```dart
Color _changeColor(BuildContext context, double value) {
  final colorScheme = Theme.of(context).colorScheme;
  if (value > 0) {
    return Colors.green;
  }
  if (value < 0) {
    return colorScheme.error;
  }
  return colorScheme.onSurfaceVariant;
}
```

Also update settings copy:

```dart
'Mode tema'
```

- [ ] **Step 2: Run focused tests and analyzer**

Run:

```bash
flutter analyze
flutter test test/features/portfolio/pages/update_asset_value_page_test.dart
```

Expected: PASS

- [ ] **Step 3: Commit the semantic cleanup**

```bash
git add lib/features/portfolio/pages/portfolio_history_page.dart lib/features/settings/pages/settings_page.dart test/features/portfolio/pages/update_asset_value_page_test.dart
git commit -m "fix: align page semantics and copy"
```

### Task 5: Full Verification

**Files:**
- Verify only

- [ ] **Step 1: Run the complete verification suite**

```bash
flutter analyze
flutter test
```

Expected:

- analyzer exits with code 0
- all tests pass

- [ ] **Step 2: Review the diff**

```bash
git status --short
git diff -- lib/app/router/app_router.dart lib/features/portfolio/pages/dashboard_page.dart lib/features/portfolio/pages/asset_list_page.dart lib/features/portfolio/pages/asset_detail_page.dart lib/features/portfolio/pages/update_asset_value_page.dart lib/features/portfolio/pages/portfolio_history_page.dart lib/features/settings/pages/settings_page.dart test/app/router/app_router_test.dart test/features/portfolio/pages/update_asset_value_page_test.dart
```

Expected: only the planned files contain relevant changes

- [ ] **Step 3: Commit the verified implementation**

```bash
git add lib/app/router/app_router.dart lib/features/portfolio/pages/dashboard_page.dart lib/features/portfolio/pages/asset_list_page.dart lib/features/portfolio/pages/asset_detail_page.dart lib/features/portfolio/pages/portfolio_history_page.dart lib/features/settings/pages/settings_page.dart test/app/router/app_router_test.dart test/features/portfolio/pages/update_asset_value_page_test.dart docs/superpowers/plans/2026-07-15-app-navigation-and-form-design-cleanup.md
git commit -m "feat: clean up app navigation and form flows"
```
