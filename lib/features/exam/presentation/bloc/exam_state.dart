import 'package:equatable/equatable.dart';

enum ExamStatus {
  loading,
  running,
  securityAlert,
  exitPrompt,

  /// Waktu habis: UI mengunci WebView, lalu sesi ditutup di server.
  timeUp,

  /// Form terkirim: sesi sedang ditutup di server.
  submitted,

  /// Keluar sementara dengan kode pengawas (sesi server tetap berjalan).
  exited,

  /// Sesi sudah ditandai selesai di server.
  finished,
}

/// Penyebab ujian selesai (untuk pesan akhir).
enum ExamFinishReason { submitted, timeUp }

class ExamState extends Equatable {
  final Duration remaining;
  final ExamStatus status;
  final ExamFinishReason? finishReason;
  final String? alertMessage;
  final String? exitCodeError;

  const ExamState({
    this.remaining = Duration.zero,
    this.status = ExamStatus.loading,
    this.finishReason,
    this.alertMessage,
    this.exitCodeError,
  });

  ExamState copyWith({
    Duration? remaining,
    ExamStatus? status,
    ExamFinishReason? finishReason,
    String? alertMessage,
    String? exitCodeError,
    bool clearAlert = false,
    bool clearExitError = false,
  }) {
    return ExamState(
      remaining: remaining ?? this.remaining,
      status: status ?? this.status,
      finishReason: finishReason ?? this.finishReason,
      alertMessage: clearAlert ? null : (alertMessage ?? this.alertMessage),
      exitCodeError: clearExitError
          ? null
          : (exitCodeError ?? this.exitCodeError),
    );
  }

  /// Format HH:mm:ss.
  String get formattedRemaining {
    final h = remaining.inHours.toString().padLeft(2, '0');
    final m = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  List<Object?> get props => [
    remaining,
    status,
    finishReason,
    alertMessage,
    exitCodeError,
  ];
}
