# Wasilah App Navigation And Form Design Cleanup

## Goal

Bring the app's navigation and page behavior closer to standard Material 3 mobile patterns without changing business logic, storage, or feature scope.

The cleanup focuses on:

- keeping bottom navigation only for top-level destinations
- making drill-down pages behave like normal subpages with back navigation
- improving task focus for forms
- aligning copy, feedback, and visual semantics across pages

## Scope

In scope:

- router structure
- navigation behavior between top-level tabs and subpages
- page-level scaffold patterns
- form page layout and submission flow
- feedback semantics such as positive and negative state colors
- small copy consistency fixes in visible UI

Out of scope:

- data model changes
- repository or provider refactors
- adding new features
- major dashboard visual redesign
- auth, backup, or sync behavior

## Current Problems

1. `AssetDetailPage` and `UpdateAssetValuePage` live inside the shell route, so the bottom navigation remains visible in deeper flows.
2. Asset list and asset detail actions use `context.go`, which replaces branch state instead of behaving like forward navigation in a nested task flow.
3. The update form is a focused task page but still shares the same navigation affordance as top-level tabs.
4. Some visible labels mix language or wording styles, such as `Theme mode`.
5. Historical change text always uses a positive color even when the value is negative.
6. Top-level screens mostly follow one page pattern, but deeper pages need a clearer distinction from tab destinations.

## Design Decisions

### Navigation Hierarchy

Top-level destinations remain:

- Dashboard
- Histori
- Aset
- Target
- Setelan

These routes stay inside `StatefulShellRoute.indexedStack` and continue using the bottom `NavigationBar`.

Subpages move outside the shell:

- asset detail
- update asset value

This makes the bottom navigation disappear on drill-down screens and restores a standard Material back flow.

### Route Behavior

Use `push` when moving from a list or summary into a subpage:

- dashboard to asset detail
- asset list to asset detail
- asset list to update form
- asset detail to update form

Use `go` only for switching top-level tabs.

### Page Patterns

Top-level tab pages:

- may use a standard app bar or a custom dashboard header
- keep the bottom navigation visible
- represent browsing, overview, or settings destinations

Subpages:

- always use a normal `AppBar` with implicit back behavior
- do not show the bottom navigation
- focus on one object or one task

### Form Behavior

`UpdateAssetValuePage` remains a full page, not a dialog or sheet.

The page should:

- focus on a single asset update task
- preserve inline validation
- keep preview information visible
- show success feedback with a snackbar
- return to the previous screen after success

The selected asset field stays editable so the form can still support entry from multiple entry points.

### Feedback Semantics

Historical change styling must reflect the sign of the value:

- positive change uses a success color
- negative change uses an error color
- neutral change uses a subdued on-surface variant color

Copy should be consistently Indonesian in visible labels where practical within touched files.

## File-Level Changes

### Router

Update `lib/app/router/app_router.dart` to:

- keep only top-level tab routes inside the shell
- register asset detail and asset update pages as standalone root routes outside the shell
- preserve deep-linkable paths

### Portfolio Pages

Update asset navigation calls in:

- `dashboard_page.dart`
- `asset_list_page.dart`
- `asset_detail_page.dart`

So that drill-down transitions use `push`.

Update `update_asset_value_page.dart` only for task-focused navigation behavior and copy consistency, without changing submission logic.

Update `portfolio_history_page.dart` so performance text color reflects actual gain or loss.

### Settings

Update `settings_page.dart` to use Indonesian-facing copy for section titles that are currently inconsistent with the rest of the app.

## Error Handling

Existing retry, loading, validation, and snackbar behavior remain unchanged unless needed for navigation correctness.

No new global error handling pattern is introduced in this cleanup.

## Testing

Verification should cover:

- top-level tabs still render through the shell
- asset detail opens as a subpage without bottom navigation
- update asset page opens as a subpage without bottom navigation
- back navigation returns to the previous page naturally
- `flutter analyze` passes
- existing widget tests still pass, with small updates only if route behavior affects them

## Acceptance Criteria

1. Bottom navigation is visible only on the five top-level destinations.
2. Asset detail and asset update screens behave like normal subpages with back navigation.
3. Navigating into asset detail or update does not reset the tab stack.
4. The update asset form remains functionally equivalent but is visually and behaviorally more focused.
5. Visible copy in touched screens is internally consistent.
6. Positive and negative historical changes are not shown with the same semantic color.
