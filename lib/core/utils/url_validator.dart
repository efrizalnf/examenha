import '../constants/app_constants.dart';

class UrlValidator {
  const UrlValidator._();

  static bool isValid(String url) {
    final extracted = _extractUrl(url);
    if (extracted == null) return false;
    
    try {
      final normalized = extracted.startsWith('http')
          ? extracted
          : 'https://$extracted';
      final uri = Uri.parse(normalized);
      if (uri.host.isEmpty) return false;
      return AppConstants.allowedUrlPatterns.any((p) => normalized.contains(p));
    } catch (_) {
      return false;
    }
  }

  static String normalize(String url) {
    final extracted = _extractUrl(url) ?? url.trim();
    if (!extracted.startsWith('http')) return 'https://$extracted';
    return extracted;
  }

  static String? _extractUrl(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    // Jika sudah berupa URL (mengandung titik dan tidak ada spasi di tengah)
    if (trimmed.contains('.') && !trimmed.contains(' ')) {
      return trimmed;
    }

    // Coba cari URL di dalam teks menggunakan regex sederhana
    final urlRegex = RegExp(
      r'(https?://[^\s]+)|([a-zA-Z0-9-]+\.[a-zA-Z]{2,}[^\s]*)',
      caseSensitive: false,
    );
    final match = urlRegex.firstMatch(trimmed);
    return match?.group(0);
  }
}
