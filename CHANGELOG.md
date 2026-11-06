# Changelog

Format mengikuti [Keep a Changelog](https://keepachangelog.com/id-ID/1.1.0/).

## [1.6.3] — 2026-11-06

### Diperbaiki
- **Ujian langsung selesai saat siswa mengklik jawaban / pindah halaman Form.** Deteksi "terkirim" sebelumnya memakai URL `/formResponse`, padahal Google Forms bersekat juga memuat URL itu saat "Berikutnya". Kini yang dipercaya adalah teks konfirmasi di halaman `/formResponse` ("Jawaban Anda telah terkirim…", teks yang dipasang backend), dengan beberapa percobaan ulang.

## [1.6.2] — 2026-11-06

### Diperbaiki
- Pesan "Respons server tidak valid" kini menyertakan status HTTP dan cuplikan isi respons untuk memudahkan diagnosis.
- `ApiClient` menolak lebih awal bila `API_BASE_URL` masih berisi placeholder `GANTI_DEPLOYMENT_ID` (penyebab paling umum: URL belum diisi lewat `--dart-define`).

## [1.6.1] — 2026-11-06

### Diubah
- **Kode keluar pengawas dibuat guru/admin per ujian** dan diverifikasi server (`siswa.sesi.exit`); tidak ada lagi kode tertanam di APK. `AppConstants.examExitCode` dihapus.
- `ExamBloc` memverifikasi kode secara async (anti klik ganda), menampilkan pesan dari server (`KODE_KELUAR_SALAH`, `TOO_MANY_ATTEMPTS`, `KODE_KELUAR_BELUM_ADA`).
- `ExamRepository.verifyExitCode`.

Butuh backend ExamForm CBT ≥ 1.2.0 (deploy versi baru).

## [1.6.0] — 2026-11-06

Alur baru terhubung ke backend **ExamForm CBT** (Google Apps Script):
Login siswa → Dashboard ujian aktif → input Token → WebView Google Form.

### Ditambahkan
- `core/network/api_client.dart`: klien dispatcher `{action, token, data}`; mengikuti redirect 302 Apps Script dengan GET ke `Location`.
- Fitur `auth`: login NIS + password, token disimpan di `flutter_secure_storage`, `AuthBloc` (singleton), `AuthGate`, kembali ke login saat `UNAUTHORIZED`.
- Fitur `dashboard`: daftar ujian aktif (`siswa.ujian.list`), tarik-untuk-muat-ulang, refresh saat aplikasi kembali aktif, dialog token (ketik atau scan QR).
- `ExamRepository` (`list`, `start`, `finish`), entitas `ExamSummary` dan `GformSession`.
- `ExamBloc`: hitung mundur dari sisa waktu server (Stopwatch), penutupan sesi ke server dengan retry, status `timeUp`, `submitted`, `exited`.
- `ExamPage`: navigasi WebView dibatasi ke `docs.google.com` / `forms.gle` / `forms.google.com`; deteksi halaman `/formResponse`; layar dikunci saat waktu habis; dialog akhir.
- Dependensi: `http`, `flutter_secure_storage`.
- Konfigurasi `API_BASE_URL` lewat `--dart-define`.

### Diubah
- `TimerDisplay` kini hitung mundur (merah saat ≤ 5 menit), bukan waktu berjalan.
- `ExamLink` menambah `sesiId`, `judul`, `remainingSeconds` (bernilai default agar fitur `home` lama tetap dapat dikompilasi).
- `main.dart` memakai `AuthGate`; `injection_container.dart` mendaftarkan API, auth, dan exam.
- `AppConstants.appVersion` 1.6.0; `pubspec.yaml` 1.6.0+3.

### Usang
- Fitur `home` (input tautan/kode lokal) tidak lagi dipasang; `AppConstants.examAccessCode` ditandai `@Deprecated`. Aman dihapus setelah alur baru diuji.

### Perlu diverifikasi di perangkat
- Deteksi "terkirim" lewat URL `/formResponse`.
