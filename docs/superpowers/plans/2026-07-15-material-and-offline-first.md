# Material And Offline-First Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish the remaining Material 3 cleanup and move the app to a persistent offline-first Drift + SQLite data source.

**Architecture:** Keep the current Flutter pages and domain models, add a Drift runtime database as the local source of truth, and swap the default repository binding from the mock implementation to a Drift-backed repository. Verify the UX cleanup and persistence behavior with widget and repository tests first.

**Tech Stack:** Flutter, Riverpod, GoRouter, Drift, SQLite, flutter_test

---

### Task 1: Lock Remaining Material Standards In Tests

**Files:**
- Create: `test/features/material/material_standards_test.dart`

- [ ] **Step 1: Write failing widget expectations**

```dart
expect(find.byType(RefreshIndicator), findsOneWidget);
expect(find.byType(Chip), findsWidgets);
expect(find.text('Tentang aplikasi'), findsOneWidget);
```

- [ ] **Step 2: Run the focused test file and verify failure**

Run: `flutter test test/features/material/material_standards_test.dart`

Expected: FAIL because the refreshed page wrapper, Material chips, or About tile flow are missing.

- [ ] **Step 3: Commit the red test**

```bash
git add test/features/material/material_standards_test.dart
git commit -m "test: add material standards coverage"
```

### Task 2: Finish Material 3 Cleanup

**Files:**
- Create: `lib/core/widgets/refreshable_page_body.dart`
- Modify: `lib/features/portfolio/pages/dashboard_page.dart`
- Modify: `lib/features/portfolio/pages/asset_list_page.dart`
- Modify: `lib/features/portfolio/pages/portfolio_history_page.dart`
- Modify: `lib/features/target/pages/target_page.dart`
- Modify: `lib/features/target/widgets/target_allocation_item.dart`
- Modify: `lib/features/settings/pages/settings_page.dart`
- Test: `test/features/material/material_standards_test.dart`

- [ ] **Step 1: Implement the minimal Material cleanup**

```dart
return RefreshIndicator(
  onRefresh: onRefresh,
  child: SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    child: child,
  ),
);
```

```dart
return Chip(
  backgroundColor: item.statusColor.withValues(alpha: 0.12),
  side: BorderSide.none,
  label: Text(item.statusLabel),
);
```

```dart
const AboutListTile(
  applicationName: 'Wasilah',
  applicationVersion: _appVersion,
  child: Text('Tentang aplikasi'),
)
```

- [ ] **Step 2: Run the focused Material tests**

Run: `flutter test test/features/material/material_standards_test.dart`

Expected: PASS

- [ ] **Step 3: Commit the Material cleanup**

```bash
git add lib/core/widgets/refreshable_page_body.dart lib/features/portfolio/pages/dashboard_page.dart lib/features/portfolio/pages/asset_list_page.dart lib/features/portfolio/pages/portfolio_history_page.dart lib/features/target/pages/target_page.dart lib/features/target/widgets/target_allocation_item.dart lib/features/settings/pages/settings_page.dart test/features/material/material_standards_test.dart
git commit -m "fix: finish material standards cleanup"
```

### Task 3: Add Failing Offline-First Repository Tests

**Files:**
- Create: `test/features/portfolio/repository/drift_portfolio_repository_test.dart`
- Modify: `pubspec.yaml`

- [ ] **Step 1: Write failing persistence tests**

```dart
test('seeds default portfolio data on first launch', () async {
  final repository = await createRepository();
  final assets = await repository.getAssets();
  expect(assets, isNotEmpty);
});

test('persists updated asset value after reopening the database', () async {
  final repository = await createRepository();
  await repository.updateAssetValue(
    assetId: 'btc',
    totalValue: 50000000,
    recordedAt: DateTime(2026, 7, 15),
  );
  await repository.close();

  final reopened = await createRepository();
  final asset = await reopened.getAssetById('btc');
  expect(asset!.currentValue, 50000000);
});
```

- [ ] **Step 2: Run the focused repository test and verify failure**

Run: `flutter test test/features/portfolio/repository/drift_portfolio_repository_test.dart`

Expected: FAIL because the Drift repository and dependencies do not exist yet.

- [ ] **Step 3: Commit the red repository test**

```bash
git add pubspec.yaml test/features/portfolio/repository/drift_portfolio_repository_test.dart
git commit -m "test: add offline first repository coverage"
```

### Task 4: Implement Drift Database And Repository

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/core/database/app_database.dart`
- Create: `lib/features/portfolio/repository/drift_portfolio_repository.dart`
- Modify: `lib/features/portfolio/providers/portfolio_providers.dart`
- Test: `test/features/portfolio/repository/drift_portfolio_repository_test.dart`
- Test: `test/features/portfolio/repository/mock_portfolio_repository_test.dart`

- [ ] **Step 1: Add the local database dependencies**

```yaml
dependencies:
  drift: ^2.28.2
  path: ^1.9.1
  path_provider: ^2.1.6
  sqlite3: ^2.9.3
  sqlite3_flutter_libs: ^0.5.39
```

- [ ] **Step 2: Implement the runtime database and repository**

```dart
class AppDatabase extends GeneratedDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openConnection());

  @override
  int get schemaVersion => 1;
}
```

```dart
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  return DriftPortfolioRepository(ref.watch(appDatabaseProvider));
});
```

- [ ] **Step 3: Run focused repository tests**

Run:

```bash
flutter pub get
flutter test test/features/portfolio/repository/drift_portfolio_repository_test.dart test/features/portfolio/repository/mock_portfolio_repository_test.dart
```

Expected: PASS

- [ ] **Step 4: Commit the offline-first implementation**

```bash
git add pubspec.yaml pubspec.lock lib/core/database/app_database.dart lib/features/portfolio/repository/drift_portfolio_repository.dart lib/features/portfolio/providers/portfolio_providers.dart test/features/portfolio/repository/drift_portfolio_repository_test.dart test/features/portfolio/repository/mock_portfolio_repository_test.dart
git commit -m "feat: add offline first drift storage"
```

### Task 5: Full Verification

**Files:**
- Verify only

- [ ] **Step 1: Run full verification**

Run:

```bash
flutter analyze
flutter test
```

Expected: analyzer exits with code 0 and all tests pass.

- [ ] **Step 2: Review changed files**

Run:

```bash
git status --short
git log --oneline -2
```

Expected: working tree only contains intended changes or is clean after commits.

- [ ] **Step 3: Commit plan and spec if still unstaged**

```bash
git add docs/superpowers/specs/2026-07-15-material-and-offline-first-design.md docs/superpowers/plans/2026-07-15-material-and-offline-first.md
git commit -m "docs: capture offline first implementation design"
```
