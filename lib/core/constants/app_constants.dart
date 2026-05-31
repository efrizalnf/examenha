class AppConstants {
  AppConstants._();

  static const String appName = 'Exam Forms';
  static const String appVersion = '1.5.2';

  // MethodChannel names (must match MainActivity.kt)
  static const String securityMethodChannel = 'com.enha_exam/security';
  static const String securityEventChannel = 'com.enha_exam/security_events';

  // Kode ujian untuk masuk (validasi siswa sebelum mulai)
  // TODO(api): ganti dengan panggilan API ketika backend tersedia
  static const String examAccessCode = '111290';

  // Kode keluar ujian untuk pengawas/admin
  // TODO(api): pisahkan dari konfigurasi lokal ketika backend tersedia
  static const String examExitCode = '111290';

  // Allowed exam URL domains
  static const List<String> allowedUrlPatterns = [
    'docs.google.com/forms',
    'forms.gle',
    'forms.office.com',
    'forms.microsoft.com',
  ];
}
