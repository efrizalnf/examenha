import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/exam_summary.dart';
import '../../domain/entities/gform_session.dart';
import '../../domain/repositories/exam_repository.dart';

class ExamRepositoryImpl implements ExamRepository {
  final ApiClient _api;
  const ExamRepositoryImpl(this._api);

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } on ApiException catch (e) {
      return Left(ApiFailure(e.message, code: e.code));
    }
  }

  @override
  Future<Either<Failure, List<ExamSummary>>> listAvailable() =>
      _guard(() async {
        final d = await _api.call('siswa.ujian.list') as Map<String, dynamic>;
        return [
          for (final u in (d['ujian'] as List).cast<Map<String, dynamic>>())
            ExamSummary(
              id: u['id'] as String,
              judul: u['judul'] as String,
              deskripsi: (u['deskripsi'] as String?) ?? '',
              mapel: (u['mapel'] as String?) ?? '-',
              jenisUjian: (u['jenisUjian'] as String?) ?? '-',
              guru: (u['guru'] as String?) ?? '-',
              durasiMenit: (u['durasiMenit'] as num).toInt(),
              jumlahSoal: (u['jumlahSoal'] as num).toInt(),
              mode: (u['mode'] as String?) ?? 'native',
              status: StudentExamStatus.values.firstWhere(
                (s) => s.name == u['status'],
                orElse: () => StudentExamStatus.belum,
              ),
              bisaMulai: u['bisaMulai'] == true,
              sesiId: u['sesiId'] as String?,
              mulai: u['mulai'] as String?,
              selesai: u['selesai'] as String?,
              sisaDetik: (u['sisaDetik'] as num?)?.toInt(),
              nilai: u['nilai'] as num?,
            ),
        ];
      });

  @override
  Future<Either<Failure, GformSession>> start({
    required String ujianId,
    String token = '',
  }) => _guard(() async {
    final d =
        await _api.call(
              'siswa.ujian.start',
              data: {'ujianId': ujianId, 'token': token},
            )
            as Map<String, dynamic>;
    final sesi = d['sesi'] as Map<String, dynamic>;
    final url = d['formUrl'] as String?;
    if (d['mode'] != 'gform' || url == null) {
      throw const ApiException(
        'UJIAN_TIDAK_TERSEDIA',
        'Ujian ini belum dipublikasikan ke Google Form.',
      );
    }
    return GformSession(
      sesiId: sesi['id'] as String,
      ujianId: sesi['ujianId'] as String,
      judul: sesi['judul'] as String,
      formUrl: url,
      remainingSeconds: (sesi['sisaDetik'] as num).toInt(),
    );
  });

  @override
  Future<Either<Failure, void>> finish(String sesiId) => _guard(() async {
    await _api.call('siswa.sesi.finish', data: {'sesiId': sesiId});
  });

  @override
  Future<Either<Failure, void>> verifyExitCode({
    required String sesiId,
    required String kode,
  }) => _guard(() async {
    await _api.call('siswa.sesi.exit', data: {'sesiId': sesiId, 'kode': kode});
  });
}
