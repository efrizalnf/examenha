import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/exam_summary.dart';
import '../entities/gform_session.dart';

abstract class ExamRepository {
  Future<Either<Failure, List<ExamSummary>>> listAvailable();

  /// [token] wajib saat pertama kali; kosongkan untuk melanjutkan sesi berjalan.
  Future<Either<Failure, GformSession>> start({
    required String ujianId,
    String token = '',
  });

  Future<Either<Failure, void>> finish(String sesiId);

  /// Verifikasi kode keluar pengawas (dibuat guru/admin) di server.
  Future<Either<Failure, void>> verifyExitCode({
    required String sesiId,
    required String kode,
  });
}
