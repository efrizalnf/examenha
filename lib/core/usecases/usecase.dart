import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../error/failures.dart';

abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

class SyncUseCase<T, Params> {
  Either<Failure, T> call(Params params) {
    throw UnimplementedError();
  }
}

class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
