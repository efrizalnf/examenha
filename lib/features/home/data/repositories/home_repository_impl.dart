import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/url_validator.dart';
import '../../domain/entities/exam_link.dart';
import '../../domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl();

  @override
  Either<Failure, ExamLink> validateAndBuildLink({
    required String url,
    required String examCode,
  }) {
    // Validasi URL
    if (!UrlValidator.isValid(url)) {
      return const Left(
        ValidationFailure(
          'URL tidak valid.\nGunakan link Google Forms atau Microsoft Forms.',
        ),
      );
    }

    // Validasi kode ujian — wajib diisi
    if (examCode.trim().isEmpty) {
      return const Left(ValidationFailure('Kode ujian wajib diisi.'));
    }

    // TODO(api): ganti logika di bawah dengan panggilan API validasi kode ujian
    // Contoh: final response = await examApiService.validateCode(examCode);
    // if (!response.isValid) return Left(ValidationFailure(response.message));
    if (examCode.trim() != AppConstants.examAccessCode) {
      return const Left(ValidationFailure('Kode ujian tidak valid.'));
    }

    return Right(
      ExamLink(url: UrlValidator.normalize(url), examCode: examCode.trim()),
    );
  }
}
