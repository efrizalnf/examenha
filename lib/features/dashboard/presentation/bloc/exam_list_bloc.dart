import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../exam/domain/entities/exam_summary.dart';
import '../../../exam/domain/repositories/exam_repository.dart';

abstract class ExamListEvent extends Equatable {
  const ExamListEvent();
  @override
  List<Object?> get props => [];
}

class ExamListRequested extends ExamListEvent {
  const ExamListRequested();
}

enum ExamListStatus { loading, loaded, failure }

class ExamListState extends Equatable {
  final ExamListStatus status;
  final List<ExamSummary> exams;
  final String? error;

  const ExamListState({
    this.status = ExamListStatus.loading,
    this.exams = const [],
    this.error,
  });

  ExamListState copyWith({
    ExamListStatus? status,
    List<ExamSummary>? exams,
    String? error,
  }) => ExamListState(
    status: status ?? this.status,
    exams: exams ?? this.exams,
    error: error,
  );

  @override
  List<Object?> get props => [status, exams, error];
}

class ExamListBloc extends Bloc<ExamListEvent, ExamListState> {
  final ExamRepository _repo;

  ExamListBloc(this._repo) : super(const ExamListState()) {
    on<ExamListRequested>((e, emit) async {
      if (state.exams.isEmpty) {
        emit(state.copyWith(status: ExamListStatus.loading));
      }
      final r = await _repo.listAvailable();
      r.fold(
        (f) => emit(
          state.copyWith(status: ExamListStatus.failure, error: f.message),
        ),
        (list) =>
            emit(ExamListState(status: ExamListStatus.loaded, exams: list)),
      );
    });
  }
}
