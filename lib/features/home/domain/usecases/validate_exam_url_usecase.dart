import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../entities/exam_link.dart';
import '../repositories/home_repository.dart';

class ValidateExamUrlUsecase {
  final HomeRepository _repository;

  const ValidateExamUrlUsecase(this._repository);

  Either<Failure, ExamLink> call(ValidateParams params) {
    return _repository.validateAndBuildLink(
      url: params.url,
      examCode: params.examCode,
    );
  }
}

class ValidateParams extends Equatable {
  final String url;
  final String examCode;

  const ValidateParams({required this.url, required this.examCode});

  @override
  List<Object?> get props => [url, examCode];
}
