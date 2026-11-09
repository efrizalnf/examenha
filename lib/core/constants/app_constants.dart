class AppConstants {
  AppConstants._();

  static const String appName = 'Exam ENHA';
  static const String appVersion = '1.6.4';

  // URL Web App ExamForm CBT (Apps Script, deployment "Anyone"). Bisa ditimpa saat build:
  //   flutter run --dart-define=API_BASE_URL=https://script.google.com/macros/s/XXXX/exec
  static const String _apiBaseUrlRaw = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'https://script.google.com/macros/s/AKfycby0hPmzlF_DHWjM7R68T3ifqF0gUv-Bi9ResihzoIf4nY_fQcy_A848ppLhmgfjGxZ9/exec',
  );

  /// URL bersih. Bila nilai mentah tak sengaja berisi teks lain (mis. seluruh perintah
  /// "flutter run --dart-define=..."), hanya URL https pertama yang dipakai.
  static String get apiBaseUrl {
    final m = RegExp(r'https://[^\s"\x27]+').firstMatch(_apiBaseUrlRaw);
    return m == null ? _apiBaseUrlRaw.trim() : m.group(0)!;
  }

  // MethodChannel names (must match MainActivity.kt)
  static const String securityMethodChannel = 'com.enha_exam/security';
  static const String securityEventChannel = 'com.enha_exam/security_events';

  // Kode ujian lokal LAMA — tidak dipakai lagi (token kini divalidasi server).
  // Hanya dirujuk fitur `home` lama yang sudah tidak dipasang di main.dart.
  @Deprecated('Token ujian kini divalidasi server (siswa.ujian.start).')
  static const String examAccessCode = '140457';

  // Allowed exam URL domains
  static const List<String> allowedUrlPatterns = [
    'docs.google.com/forms',
    'forms.gle',
    'forms.office.com',
    'forms.microsoft.com',
    'bit.ly',
    'tinyurl.com',
    's.id',
    'cutt.ly',
    't.ly',
    'gg.gg',
    'rebrand.ly',
    'is.gd',
    't.co',
    'shorturl.at',
    'tiny.cc',
    'bit.do',
    'buff.ly',
    'linktr.ee',
    'qrco.de',
    'l.ead.me',
    'me-qr.com',
    'qr1.be',
    'qrs.ly',
    'uqr.me',
    'flowcode.com',
    'qr.net',
    'qr.ae',
  ];
}
