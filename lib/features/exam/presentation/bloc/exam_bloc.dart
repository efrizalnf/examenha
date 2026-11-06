import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/security_service.dart';
import '../../../home/domain/entities/exam_link.dart';
import '../../domain/repositories/exam_repository.dart';
import 'exam_event.dart';
import 'exam_state.dart';

class ExamBloc extends Bloc<ExamEvent, ExamState> {
  final SecurityService _securityService;
  final ExamRepository _repo;
  final ExamLink _link;

  /// Jangan percaya jam perangkat: sisa waktu = nilai server - Stopwatch
  /// (monotonik, tidak terpengaruh perubahan jam sistem).
  final Stopwatch _clock = Stopwatch();
  Timer? _ticker;
  Timer? _retry;
  StreamSubscription<String>? _securitySub;
  ExamFinishReason? _reason;
  bool _verifyingExit = false;

  ExamBloc({
    required SecurityService securityService,
    required ExamRepository repository,
    required ExamLink link,
  }) : _securityService = securityService,
       _repo = repository,
       _link = link,
       super(ExamState(remaining: Duration(seconds: link.remainingSeconds))) {
    on<ExamStartedEvent>(_onStarted);
    on<ExamTimerTickedEvent>(_onTimerTicked);
    on<ExamFormSubmittedEvent>(_onFormSubmitted);
    on<ExamFinishRetryEvent>((e, emit) => _finish(emit));
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
    _clock
      ..reset()
      ..start();
    await _securityService.startExam();
    emit(state.copyWith(status: ExamStatus.running));

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isClosed) add(const ExamTimerTickedEvent());
    });
    _securitySub = _securityService.securityEvents.listen((event) {
      if (!isClosed) add(ExamSecurityAlertEvent(event));
    });
  }

  Future<void> _onTimerTicked(
    ExamTimerTickedEvent event,
    Emitter<ExamState> emit,
  ) async {
    final left = (_link.remainingSeconds - _clock.elapsed.inSeconds).clamp(
      0,
      1 << 30,
    );
    emit(state.copyWith(remaining: Duration(seconds: left)));

    final closing =
        state.status == ExamStatus.timeUp ||
        state.status == ExamStatus.submitted ||
        state.status == ExamStatus.finished ||
        state.status == ExamStatus.exited;
    if (left == 0 && !closing) {
      _reason ??= ExamFinishReason.timeUp;
      emit(state.copyWith(status: ExamStatus.timeUp, clearAlert: true));
      // Wajib di-await: emit tidak boleh dipanggil setelah handler selesai.
      await _finish(emit);
    }
  }

  Future<void> _onFormSubmitted(
    ExamFormSubmittedEvent event,
    Emitter<ExamState> emit,
  ) async {
    final closing =
        state.status == ExamStatus.timeUp ||
        state.status == ExamStatus.submitted ||
        state.status == ExamStatus.finished ||
        state.status == ExamStatus.exited;
    if (closing) return;
    _reason = ExamFinishReason.submitted;
    emit(state.copyWith(status: ExamStatus.submitted, clearAlert: true));
    await _finish(emit);
  }

  /// Tandai sesi selesai di server. Gagal jaringan -> coba lagi tiap 5 detik.
  /// Nilai TIDAK dikembalikan di sini (muncul setelah guru menyinkronkan
  /// respons Form).
  Future<void> _finish(Emitter<ExamState> emit) async {
    _retry?.cancel();
    final r = await _repo.finish(_link.sesiId);
    r.fold(
      (f) {
        final done =
            f is ApiFailure &&
            (f.code == 'SUDAH_SELESAI' || f.code == 'NOT_FOUND');
        if (done) {
          _cleanUp();
          emit(
            state.copyWith(status: ExamStatus.finished, finishReason: _reason),
          );
        } else {
          _retry = Timer(const Duration(seconds: 5), () {
            if (!isClosed) add(const ExamFinishRetryEvent());
          });
        }
      },
      (_) {
        _cleanUp();
        emit(state.copyWith(status: ExamStatus.finished, finishReason: _reason));
      },
    );
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
    if (state.status != ExamStatus.securityAlert) return;
    emit(state.copyWith(status: ExamStatus.running, clearAlert: true));
  }

  void _onExitAttempt(ExamExitAttemptEvent event, Emitter<ExamState> emit) {
    if (state.status == ExamStatus.timeUp ||
        state.status == ExamStatus.submitted) {
      return;
    }
    _securityService.beep();
    emit(
      state.copyWith(
        status: ExamStatus.exitPrompt,
        clearAlert: true,
        clearExitError: true,
      ),
    );
  }

  /// Keluar sementara dengan kode pengawas yang diverifikasi SERVER
  /// (dibuat guru/admin per ujian). Timer di server TETAP berjalan, siswa
  /// dapat "Lanjutkan" dari dashboard.
  Future<void> _onExitWithCode(
    ExamExitWithCodeEvent event,
    Emitter<ExamState> emit,
  ) async {
    final kode = event.code.trim();
    if (kode.isEmpty || _verifyingExit) return;
    _verifyingExit = true;
    final r = await _repo.verifyExitCode(sesiId: _link.sesiId, kode: kode);
    _verifyingExit = false;
    r.fold(
      (f) {
        _securityService.beep();
        emit(state.copyWith(exitCodeError: f.message));
      },
      (_) {
        _cleanUp();
        emit(state.copyWith(status: ExamStatus.exited, clearExitError: true));
      },
    );
  }

  void _onCancelExit(ExamCancelExitEvent event, Emitter<ExamState> emit) {
    if (state.status != ExamStatus.exitPrompt) return;
    emit(
      state.copyWith(
        status: ExamStatus.running,
        clearAlert: true,
        clearExitError: true,
      ),
    );
  }

  void _cleanUp() {
    _ticker?.cancel();
    _retry?.cancel();
    _securitySub?.cancel();
    _securityService.stopExam();
  }

  @override
  Future<void> close() {
    _cleanUp();
    return super.close();
  }
}
