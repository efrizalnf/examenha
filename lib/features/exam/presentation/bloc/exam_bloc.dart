import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/security_service.dart';
import '../../../home/domain/entities/exam_link.dart';
import '../../domain/entities/exam_session.dart';
import 'exam_event.dart';
import 'exam_state.dart';

class ExamBloc extends Bloc<ExamEvent, ExamState> {
  final SecurityService _securityService;
  final ExamLink _link;

  Timer? _timer;
  StreamSubscription<String>? _securitySub;
  DateTime? _startTime;

  ExamBloc({required SecurityService securityService, required ExamLink link})
    : _securityService = securityService,
      _link = link,
      super(const ExamState()) {
    on<ExamStartedEvent>(_onStarted);
    on<ExamTimerTickedEvent>(_onTimerTicked);
    on<ExamSecurityAlertEvent>(_onSecurityAlert);
    on<ExamDismissAlertEvent>(_onDismissAlert);
    on<ExamExitAttemptEvent>(_onExitAttempt);
    on<ExamExitWithCodeEvent>(_onExitWithCode);
    on<ExamCancelExitEvent>(_onCancelExit);
  }

  Future<void> _onStarted(
    ExamStartedEvent event,
    Emitter<ExamState> emit,
  ) async {
    _startTime = DateTime.now();
    await _securityService.startExam();

    // Buat sesi awal
    final session = ExamSession(link: _link, startTime: _startTime!);
    emit(state.copyWith(session: session, status: ExamStatus.running));

    // Mulai timer
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isClosed) {
        add(ExamTimerTickedEvent(DateTime.now().difference(_startTime!)));
      }
    });

    // Subscribe ke native security events
    _securitySub = _securityService.securityEvents.listen((event) {
      if (!isClosed) add(ExamSecurityAlertEvent(event));
    });
  }

  void _onTimerTicked(ExamTimerTickedEvent event, Emitter<ExamState> emit) {
    final updated = state.session?.copyWith(elapsed: event.elapsed);
    if (updated != null) emit(state.copyWith(session: updated));
  }

  void _onSecurityAlert(ExamSecurityAlertEvent event, Emitter<ExamState> emit) {
    // Hanya tampilkan alert jika sedang running (tidak menimpa dialog lain)
    if (state.status != ExamStatus.running) return;

    final message = switch (event.alertType) {
      'userLeaveHint' =>
        'Peringatan! Kamu mencoba meninggalkan aplikasi ujian.',
      'windowFocusLost' =>
        'Peringatan! Jangan membuka panel notifikasi selama ujian.',
      'lockTaskUnavailable' =>
        'Mode pin aplikasi belum aktif di perangkat ini. Aktifkan screen pinning di Android untuk perlindungan penuh.',
      _ => 'Peringatan keamanan terdeteksi.',
    };

    emit(
      state.copyWith(status: ExamStatus.securityAlert, alertMessage: message),
    );
  }

  void _onDismissAlert(ExamDismissAlertEvent event, Emitter<ExamState> emit) {
    emit(state.copyWith(status: ExamStatus.running, clearAlert: true));
  }

  void _onExitAttempt(ExamExitAttemptEvent event, Emitter<ExamState> emit) {
    _securityService.beep();
    emit(
      state.copyWith(
        status: ExamStatus.exitPrompt,
        clearAlert: true,
        clearExitError: true,
      ),
    );
  }

  void _onExitWithCode(ExamExitWithCodeEvent event, Emitter<ExamState> emit) {
    if (event.code.trim() == AppConstants.examExitCode) {
      _cleanUp();
      emit(state.copyWith(status: ExamStatus.finished, clearExitError: true));
      return;
    }

    _securityService.beep();
    emit(
      state.copyWith(
        exitCodeError: 'Kode keluar ujian salah. Ujian tetap berjalan.',
      ),
    );
  }

  void _onCancelExit(ExamCancelExitEvent event, Emitter<ExamState> emit) {
    emit(
      state.copyWith(
        status: ExamStatus.running,
        clearAlert: true,
        clearExitError: true,
      ),
    );
  }

  void _cleanUp() {
    _timer?.cancel();
    _securitySub?.cancel();
    _securityService.stopExam();
  }

  @override
  Future<void> close() {
    _cleanUp();
    return super.close();
  }
}
