import '../constants/app_constants.dart';

class UrlValidator {
  const UrlValidator._();

  static bool isValid(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;
    try {
      final normalized = trimmed.startsWith('http')
          ? trimmed
          : 'https://$trimmed';
      final uri = Uri.parse(normalized);
      if (uri.host.isEmpty) return false;
      return AppConstants.allowedUrlPatterns.any((p) => normalized.contains(p));
    } catch (_) {
      return false;
    }
  }

  static String normalize(String url) {
    final trimmed = url.trim();
    if (!trimmed.startsWith('http')) return 'https://$trimmed';
    return trimmed;
  }
}
