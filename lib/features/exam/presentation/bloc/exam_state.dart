import 'package:equatable/equatable.dart';

import '../../domain/entities/exam_session.dart';

enum ExamStatus { loading, running, securityAlert, exitPrompt, finished }

class ExamState extends Equatable {
  final ExamSession? session;
  final ExamStatus status;
  final String? alertMessage;
  final String? exitCodeError;

  const ExamState({
    this.session,
    this.status = ExamStatus.loading,
    this.alertMessage,
    this.exitCodeError,
  });

  ExamState copyWith({
    ExamSession? session,
    ExamStatus? status,
    String? alertMessage,
    String? exitCodeError,
    bool clearAlert = false,
    bool clearExitError = false,
  }) {
    return ExamState(
      session: session ?? this.session,
      status: status ?? this.status,
      alertMessage: clearAlert ? null : (alertMessage ?? this.alertMessage),
      exitCodeError: clearExitError
          ? null
          : (exitCodeError ?? this.exitCodeError),
    );
  }

  @override
  List<Object?> get props => [session, status, alertMessage, exitCodeError];
}
