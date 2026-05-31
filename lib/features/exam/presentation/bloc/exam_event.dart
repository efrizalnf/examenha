import 'package:equatable/equatable.dart';

abstract class ExamEvent extends Equatable {
  const ExamEvent();

  @override
  List<Object?> get props => [];
}

/// Dipanggil saat ExamPage selesai di-mount
class ExamStartedEvent extends ExamEvent {
  const ExamStartedEvent();
}

/// Tick setiap detik dari Timer.periodic
class ExamTimerTickedEvent extends ExamEvent {
  final Duration elapsed;
  const ExamTimerTickedEvent(this.elapsed);

  @override
  List<Object?> get props => [elapsed];
}

/// Event dari native: 'userLeaveHint' atau 'windowFocusLost'
class ExamSecurityAlertEvent extends ExamEvent {
  final String alertType;
  const ExamSecurityAlertEvent(this.alertType);

  @override
  List<Object?> get props => [alertType];
}

/// Dismiss dialog peringatan keamanan
class ExamDismissAlertEvent extends ExamEvent {
  const ExamDismissAlertEvent();
}

/// User menekan tombol Back / ingin keluar
class ExamExitAttemptEvent extends ExamEvent {
  const ExamExitAttemptEvent();
}

/// User memasukkan kode ujian untuk keluar dari ujian
class ExamExitWithCodeEvent extends ExamEvent {
  final String code;

  const ExamExitWithCodeEvent(this.code);

  @override
  List<Object?> get props => [code];
}

/// Batal keluar dan kembali ke ujian
class ExamCancelExitEvent extends ExamEvent {
  const ExamCancelExitEvent();
}
