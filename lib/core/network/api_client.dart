import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String code;
  final String message;
  const ApiException(this.code, this.message);

  @override
  String toString() => 'ApiException($code): $message';
}

/// Klien untuk dispatcher tunggal `{action, token, data}` -> `{success, data|error}`.
///
/// Apps Script membalas POST dengan HTTP 302. `package:http` tidak mengikuti
/// redirect untuk POST, jadi hasilnya diambil dengan GET ke header `Location`.
class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  /// Token login; diisi AuthRepository setelah login / restore sesi.
  String? token;

  /// Dipanggil saat server membalas UNAUTHORIZED (token kedaluwarsa).
  void Function()? onUnauthorized;

  static const _timeout = Duration(seconds: 30);
  static const _redirectCodes = {301, 302, 303, 307, 308};

  /// Mengembalikan isi `data` bila sukses; melempar [ApiException] bila gagal.
  Future<dynamic> call(
    String action, {
    Map<String, dynamic> data = const {},
  }) async {
    if (baseUrl.contains('GANTI_DEPLOYMENT_ID')) {
      throw const ApiException(
        'CONFIG',
        'API_BASE_URL belum diisi. Jalankan dengan '
            '--dart-define=API_BASE_URL=https://script.google.com/macros/s/ID_DEPLOYMENT/exec',
      );
    }
    final payload = jsonEncode({'action': action, 'token': token, 'data': data});

    final http.Response res;
    try {
      res = await _post(Uri.parse(baseUrl), payload).timeout(_timeout);
    } on TimeoutException {
      throw const ApiException(
        'NETWORK',
        'Server tidak merespons. Periksa koneksi internet.',
      );
    } on SocketException {
      throw const ApiException('NETWORK', 'Tidak ada koneksi internet.');
    } on http.ClientException {
      throw const ApiException('NETWORK', 'Gagal terhubung ke server.');
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      // Sertakan status HTTP + cuplikan isi agar penyebab (URL salah, belum
      // di-deploy ulang, perlu login Google, dsb.) terlihat saat debugging.
      final raw = utf8.decode(res.bodyBytes, allowMalformed: true);
      final snippet = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
      final preview = snippet.length > 100 ? snippet.substring(0, 100) : snippet;
      throw ApiException(
        'BAD_RESPONSE',
        'Respons server tidak valid (HTTP ${res.statusCode}). Periksa API_BASE_URL '
        'dan pastikan Web App sudah di-deploy ulang (versi baru) dengan akses "Anyone". '
        'Isi: $preview',
      );
    }

    if (json['success'] == true) return json['data'];

    final err = (json['error'] as Map?) ?? const {};
    final code = (err['code'] as String?) ?? 'INTERNAL_ERROR';
    if (code == 'UNAUTHORIZED') onUnauthorized?.call();
    throw ApiException(
      code,
      (err['message'] as String?) ?? 'Terjadi kesalahan.',
    );
  }

  Future<http.Response> _post(Uri uri, String body) async {
    final req = http.Request('POST', uri)
      ..followRedirects = false
      // text/plain: tanpa preflight, tetap terbaca oleh doPost.
      ..headers['Content-Type'] = 'text/plain; charset=utf-8'
      ..body = body;

    var res = await http.Response.fromStream(await _client.send(req));
    var target = uri;
    for (var i = 0; i < 5 && _redirectCodes.contains(res.statusCode); i++) {
      final location = res.headers['location'];
      if (location == null) break;
      target = target.resolve(location);
      res = await _client.get(target); // hasil doPost diambil lewat GET
    }
    return res;
  }
}
