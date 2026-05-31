import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/validate_exam_url_usecase.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ValidateExamUrlUsecase _validateExamUrl;

  HomeBloc(this._validateExamUrl) : super(const HomeState()) {
    on<UrlChangedEvent>(_onUrlChanged);
    on<ExamCodeChangedEvent>(_onExamCodeChanged);
    on<QrScannedEvent>(_onQrScanned);
    on<StartExamPressedEvent>(_onStartExam);
  }

  void _onUrlChanged(UrlChangedEvent event, Emitter<HomeState> emit) {
    emit(
      state.copyWith(
        url: event.url,
        status: HomeStatus.initial,
        clearError: true,
        clearLink: true,
      ),
    );
  }

  void _onExamCodeChanged(ExamCodeChangedEvent event, Emitter<HomeState> emit) {
    emit(state.copyWith(examCode: event.code, clearError: true));
  }

  void _onQrScanned(QrScannedEvent event, Emitter<HomeState> emit) {
    emit(
      state.copyWith(
        url: event.scannedUrl,
        status: HomeStatus.initial,
        clearError: true,
        clearLink: true,
      ),
    );
  }

  void _onStartExam(StartExamPressedEvent event, Emitter<HomeState> emit) {
    final result = _validateExamUrl(
      ValidateParams(url: state.url, examCode: state.examCode),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: HomeStatus.invalid,
          errorMessage: failure.message,
          clearLink: true,
        ),
      ),
      (link) => emit(
        state.copyWith(
          status: HomeStatus.ready,
          validatedLink: link,
          clearError: true,
        ),
      ),
    );
  }
}
