# Google Drive Backup — Design

**Date:** 2026-07-18
**Project:** flutter_wasilah_app (Wasilah — portfolio tracker, Drift/SQLite lokal)
**Status:** Approved

## Tujuan

Melindungi data user dari kehilangan device dengan backup otomatis database lokal ke Google Drive milik user, plus restore saat pindah/install ulang device.

## Keputusan Produk

| Keputusan | Pilihan |
|---|---|
| Model | Backup otomatis berkala + backup/restore manual dari Settings |
| Lokasi penyimpanan | Google Drive **App Data Folder** (scope `drive.appdata`, tersembunyi dari user, non-sensitive scope) |
| Trigger otomatis | Saat app launch/resume, maksimal 1x per 24 jam |
| Retensi | 7 backup terakhir; yang lebih lama dihapus otomatis setelah upload sukses |
| Format backup | File SQLite mentah (snapshot via `VACUUM INTO`), nama `wasilah_backup_<timestamp>.sqlite` |
| Platform | Android (utama). iOS mengikuti dengan konfigurasi OAuth terpisah saat dibutuhkan. |

## Pendekatan Teknis

Dependencies baru:

- `google_sign_in` ^7.x — autentikasi (`GoogleSignIn.instance.authenticate()`) dan otorisasi scope (`authorizationClient.authorizeScopes` / `authorizationForScopes`)
- `googleapis` — Drive API v3
- `extension_google_sign_in_as_googleapis_auth` — jembatan auth google_sign_in → client `googleapis` (verifikasi kompatibilitas versi dengan google_sign_in v7 saat implementasi)

Scope OAuth: hanya `https://www.googleapis.com/auth/drive.appdata`.

## Arsitektur

Fitur baru `lib/features/backup/` mengikuti struktur feature existing:

```
lib/features/backup/
  data/
    google_auth_service.dart    # wrap GoogleSignIn.instance; connect/disconnect;
                                # menyediakan authenticated HTTP client utk Drive
    drive_backup_service.dart   # Drive v3: upload, list, download, prune (>7 dihapus)
    backup_snapshot.dart        # VACUUM INTO temp file; validasi file SQLite
  providers/
    backup_controller.dart      # Riverpod: state + aksi backupNow/restore/connect/disconnect
  presentation/
    widgets/backup_section.dart # seksi di SettingsPage
    pages/restore_page.dart     # daftar backup utk dipilih saat restore
```

Perubahan pada kode existing:

- `core/storage/preferences_service.dart` — tambah `lastBackupAt` (DateTime) dan `autoBackupEnabled` (bool, default true setelah user connect)
- `app.dart` / `bootstrap.dart` — `WidgetsBindingObserver` untuk trigger auto-backup saat launch/resume
- `features/settings/presentation/pages/settings_page.dart` — pasang `BackupSection`
- Provider database (`app_database.dart` / providers) — perlu mekanisme close + re-create instance untuk restore

## Alur Data

### Backup (otomatis & manual)

1. Cek precondition (auto): user terhubung Google, `autoBackupEnabled`, `lastBackupAt` > 24 jam lalu. Manual: langsung jalan.
2. `VACUUM INTO '<temp>/wasilah_backup_<ts>.sqlite'` — snapshot konsisten tanpa menutup DB.
3. Upload ke App Data Folder via Drive v3 (`spaces=appDataFolder`).
4. Sukses → update `lastBackupAt`, hapus file temp, list backup di Drive terurut `createdTime` desc, hapus indeks ke-8 dst.
5. Gagal → log via talker; auto-backup diam (retry sesi berikutnya), manual tampilkan error.

### Restore

1. User buka halaman Restore → list backup dari Drive (tanggal + ukuran).
2. Pilih backup → download ke file temp.
3. Validasi: file adalah SQLite sehat (header magic + buka read-only + `PRAGMA integrity_check`).
4. Konfirmasi user ("data saat ini akan diganti").
5. Tutup instance Drift → ganti file DB → re-create instance DB (invalidate provider) → kembali ke dashboard.
6. Kegagalan pada langkah mana pun sebelum langkah 5 tidak menyentuh DB lokal. Penggantian file dilakukan atomik (rename), dengan file lama dipertahankan sebagai `.bak` sampai DB baru sukses dibuka.

Backup dari versi app lama aman: Drift menjalankan migrasi skema saat DB dibuka, sama seperti upgrade app biasa.

## Error Handling

- **Auto-backup gagal** (offline, token expired, quota): silent — log talker, tidak ada UI. `lastBackupAt` tidak diupdate sehingga dicoba lagi di resume berikutnya.
- **Token/otorisasi**: coba `authorizationForScopes` (silent) dulu; kalau null pada aksi manual, panggil `authorizeScopes` (interaktif). Pada auto-backup, jika butuh interaksi → skip silent.
- **Manual backup/restore gagal**: SnackBar/dialog dengan pesan jelas + opsi retry.
- **Restore**: DB lokal tidak boleh korup — validasi sebelum replace, replace atomik, `.bak` sebagai jaring pengaman.
- **Disconnect akun**: hentikan auto-backup, state UI kembali ke "belum terhubung". File di appDataFolder otomatis terhapus oleh Google jika user men-disconnect app dari akun Google-nya.

## Setup di Luar Kode (Google Cloud Console)

1. Buat project di Google Cloud Console (atau pakai project Firebase existing).
2. Aktifkan Google Drive API.
3. Konfigurasi OAuth consent screen (external, scope `drive.appdata`, non-sensitive — tidak butuh verifikasi Google).
4. Buat OAuth Client ID tipe Android: package `com.amar.wasilah` + SHA-1 (debug dan release keystore).
5. Tidak butuh perubahan `google-services.json` untuk sign-in (Firebase hanya dipakai untuk Crashlytics saat ini).

## Testing

- **Unit**: logika prune (7 versi), keputusan trigger 24 jam, validasi file SQLite — dengan fake `DriveBackupService`/clock.
- **Widget**: `BackupSection` pada state belum-terhubung / terhubung / sedang backup / error.
- **Manual e2e**: connect → backup → cek muncul di list → uninstall/clear data → restore → data kembali; plus skenario offline dan cancel sign-in.

## Di Luar Cakupan (YAGNI)

- Sync multi-device dua arah / real-time
- Enkripsi backup (App Data Folder sudah privat per-akun)
- Background scheduler (workmanager)
- Backup ke iCloud / penyedia lain
