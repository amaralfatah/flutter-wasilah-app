# Stockbit-style component theme (foundation phase)

## Context

App sudah dipangkas ke density M3 Compact ala Stockbit (typography, row
height list, appbar/navbar height, chip padding). Permintaan selanjutnya:
ikuti visual Stockbit lebih jauh di level komponen bersama, tetap di atas
Material 3. Skema warna (seed, hijau/merah gain-loss) di luar scope —
sudah diputuskan tetap seperti sekarang. Layout per layar (Dashboard,
Asset List, dst.) juga di luar scope — dibahas terpisah nanti.

## Scope

Ubah `lib/core/theme/app_theme.dart` saja, tanpa widget baru:

1. **Radius seragam 8dp** di semua komponen interaktif — card sudah 8dp;
   `chipTheme.shape` diganti dari `StadiumBorder` ke
   `RoundedRectangleBorder(borderRadius: 8)` supaya `ChoiceChip` dan
   `SegmentedButton` (yang mewarisi chip shape di M3) ikut konsisten.
2. **FilledButtonTheme** — shape `RoundedRectangleBorder(8)`, tinggi
   dibiarkan default M3 compact (40dp), tanpa elevation tambahan.
3. **SegmentedButtonTheme** — shape `RoundedRectangleBorder(8)`,
   `visualDensity: VisualDensity.compact` supaya tipis seperti toggle di
   Stockbit (dipakai di `update_asset_value_page.dart`).
4. **OutlinedButtonTheme** & **TextButtonTheme** — shape sama, 8dp, untuk
   konsistensi tombol di dialog (`confirm_dialog.dart`) dan halaman form.

## Out of scope

- Warna/seed/skema gain-loss.
- Perubahan layout/struktur layar apa pun.
- Widget baru (search bar, dsb.) — belum ada kebutuhan di app ini.

## Verification

`flutter analyze` bersih setelah perubahan; cek visual manual tidak
dilakukan (theme-level change, no dev server run diminta).
