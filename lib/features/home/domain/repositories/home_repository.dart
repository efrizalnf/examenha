import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/exam_link.dart';

abstract class HomeRepository {
  Either<Failure, ExamLink> validateAndBuildLink({
    required String url,
    required String examCode,
  });
}
