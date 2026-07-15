# Wasilah Google Material Redesign Design

## Goal

Redesign Wasilah so it feels closer to a modern Google app: quiet, clear, personal, and strongly aligned with Material 3. The app should feel like a simple portfolio companion, not a trading terminal.

The visual reference is Google Wallet and Google Finance style: a calm dashboard, strong information hierarchy, useful surfaces, bottom navigation for top-level destinations, and one obvious primary action for recording portfolio value.

## References

- Flutter Material 3 theming: https://docs.flutter.dev/release/breaking-changes/material-3-migration
- Flutter Material design overview: https://docs.flutter.dev/ui/design/material
- Material 3 navigation bar: https://m3.material.io/components/navigation-bar/overview
- Material 3 cards: https://m3.material.io/components/cards
- Material 3 text fields: https://m3.material.io/components/text-fields
- Material 3 floating action button: https://m3.material.io/components/floating-action-button/overview

## Product Direction

The redesign keeps the MVP scope unchanged:

- Manual valuation entry stays the main behavior.
- Dashboard still shows total portfolio, allocation drift, and category progress.
- History remains a monthly snapshot list.
- Google login, backup, and restore remain available from dashboard overflow.
- No chart package, no realtime prices, no new data model.

The change is presentation and navigation only.

## Architecture

Use the existing Flutter structure:

- `lib/app/theme.dart` owns the Material 3 theme and shared component styling.
- `lib/app/router.dart` keeps the current GoRouter routes.
- `DashboardScreen`, `EntryScreen`, and `HistoryScreen` remain feature screens.
- Add one small shared scaffold/navigation widget only if it prevents repeating the same `NavigationBar` setup across all three screens.

Do not add a new design dependency. Flutter Material widgets already cover the target style.

## Navigation

`Dashboard`, `Catat`, and `Histori` become top-level destinations.

On compact screens:

- Use a Material 3 `NavigationBar` at the bottom.
- Selected destinations:
  - Dashboard: `Icons.account_balance_wallet_outlined`
  - Catat: `Icons.add_chart_outlined`
  - Histori: `Icons.history_outlined`

Routing remains:

- `/` for dashboard
- `/entry` for manual input
- `/history` for monthly history

The dashboard keeps an extended FAB for `Catat Nilai` because recording value is the most important repeated action. Tapping it routes to `/entry`.

## Theme

Use `ColorScheme.fromSeed` with a Google-like green seed that suits Wasilah finance:

- Seed: `0xFF1E8E3E`
- Background and surface colors come from Material 3 color roles.
- Avoid a beige-heavy app background.
- Cards use filled or outlined Material 3 roles, not custom decorative panels.

Theme updates:

- `useMaterial3: true`
- `scaffoldBackgroundColor: colorScheme.surface`
- `AppBarTheme` flat, center title false, surface tint from scheme
- `CardThemeData` with 8px radius, subtle border or filled container
- `InputDecorationTheme` uses filled text fields
- `FloatingActionButtonThemeData` uses primary container colors
- `NavigationBarThemeData` uses indicator color from secondary container

## Dashboard

The dashboard becomes a Google-style overview screen:

1. Top app bar
   - Title: `Wasilah`
   - Overflow menu: Login Google, Backup, Restore
   - History icon can be removed because history is in bottom navigation.

2. Hero summary surface
   - Label: `Total Portofolio`
   - Large value using headline typography
   - Month snapshot label
   - Small status chip: `Perlu rebalancing` or `Dekat target`

3. Allocation section
   - Title: `Alokasi`
   - Rows for each asset class
   - Each row shows:
     - category label
     - value in IDR
     - actual percent and target percent
     - progress indicator
     - drift text colored error only when beyond threshold

4. Status guidance
   - If drift alert: a filled tonal warning card with concise action copy.
   - If no drift alert: a calm success/info card.

Empty state:

- Total remains `Rp0`
- Show a friendly prompt: `Catat nilai aset pertama kamu`
- FAB remains available.

## Entry Screen

Entry remains a tabbed form, but it should feel lighter:

- Use filled text fields.
- Keep tabs: `Nilai`, `Aset`, `Target`.
- Use concise labels:
  - `Pilih aset`
  - `Nilai sekarang`
  - `Kode aset`
  - `Nama aset`
  - `Kategori`
- Primary action stays a filled button.
- Cancel edit stays an icon button.
- History and asset lists use Material `ListTile` with clean trailing icon actions.

No behavioral changes:

- Save, edit, delete valuation
- Add, edit, delete asset
- Update target allocation

## History Screen

History becomes a simple Google-style list:

- App bar title: `Histori`
- Each month is a list item with:
  - month label
  - total value
- Empty state: `Belum ada snapshot bulanan`

## Error Handling

Keep existing snackbar behavior for:

- Google login success
- Backup success
- Restore success
- Missing backup
- Google or Drive errors

Snackbar copy should stay short and actionable.

Form validation remains minimal for MVP:

- Empty or zero value silently does not save today.
- A future improvement can add inline errors, but this redesign should not widen behavior.

## Testing

Update existing widget tests only where labels or navigation change:

- Dashboard still finds `Total Portofolio`
- Dashboard still finds allocation content
- Entry screen still saves valuation
- Entry screen still shows `Nilai`, `Aset`, `Target`
- History route remains reachable

Add one lightweight widget test:

- App shell shows bottom navigation labels `Dashboard`, `Catat`, `Histori`

Run:

```bash
flutter analyze
flutter test
```

## Implementation Notes

Keep this redesign small:

- Prefer Flutter Material widgets over custom drawing.
- Reuse current screens and controller.
- Avoid new packages.
- Avoid changing domain, storage, backup, or widget logic.
- Add small private widgets only when they reduce repeated layout code.

## Acceptance Criteria

- App visually follows Material 3 Google app conventions.
- Dashboard hierarchy is clearer than the current card stack.
- Top-level navigation is visible and predictable.
- Entry and history screens stay functionally equivalent.
- Existing tests pass after label/navigation updates.
- No unrelated user worktree changes are reverted or included.
