import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/student.dart';
import '../../domain/repositories/auth_repository.dart';
import '../auth_local_store.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _api;
  final AuthLocalStore _store;
  const AuthRepositoryImpl(this._api, this._store);

  @override
  Future<Either<Failure, Student>> login(String nis, String password) async {
    try {
      final d =
          await _api.call(
                'auth.login',
                data: {
                  'role': 'siswa',
                  'username': nis.trim(),
                  'password': password,
                },
              )
              as Map<String, dynamic>;
      final user = d['user'] as Map<String, dynamic>;
      _api.token = d['token'] as String;
      await _store.save(_api.token!, user);
      return Right(Student.fromJson(user));
    } on ApiException catch (e) {
      return Left(ApiFailure(e.message, code: e.code));
    }
  }

  /// Pulihkan sesi saat aplikasi dibuka. Token tidak diverifikasi di sini
  /// (bisa offline); bila kedaluwarsa, panggilan API berikutnya mengembalikan
  /// UNAUTHORIZED -> onUnauthorized -> logout.
  @override
  Future<Student?> restore() async {
    final s = await _store.read();
    if (s == null) return null;
    _api.token = s.token;
    return Student.fromJson(s.student);
  }

  @override
  Future<void> logout() async {
    _api.token = null;
    await _store.clear();
  }
}
