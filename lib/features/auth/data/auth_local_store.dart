import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StoredSession {
  final String token;
  final Map<String, dynamic> student; // {nis, nama, kelas, jenjang}
  const StoredSession(this.token, this.student);
}

/// Token login disimpan terenkripsi (Keystore Android).
class AuthLocalStore {
  final FlutterSecureStorage _s;
  const AuthLocalStore(this._s);

  Future<void> save(String token, Map<String, dynamic> student) async {
    await _s.write(key: 'token', value: token);
    await _s.write(key: 'student', value: jsonEncode(student));
  }

  Future<StoredSession?> read() async {
    final t = await _s.read(key: 'token');
    final s = await _s.read(key: 'student');
    if (t == null || s == null) return null;
    try {
      return StoredSession(t, jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> clear() => _s.deleteAll();
}
