import 'package:equatable/equatable.dart';

import '../../domain/entities/exam_link.dart';

enum HomeStatus { initial, invalid, ready }

class HomeState extends Equatable {
  final String url;
  final String examCode;
  final HomeStatus status;
  final String? errorMessage;
  final ExamLink? validatedLink;

  const HomeState({
    this.url = '',
    this.examCode = '',
    this.status = HomeStatus.initial,
    this.errorMessage,
    this.validatedLink,
  });

  HomeState copyWith({
    String? url,
    String? examCode,
    HomeStatus? status,
    String? errorMessage,
    ExamLink? validatedLink,
    bool clearError = false,
    bool clearLink = false,
  }) {
    return HomeState(
      url: url ?? this.url,
      examCode: examCode ?? this.examCode,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      validatedLink: clearLink ? null : (validatedLink ?? this.validatedLink),
    );
  }

  @override
  List<Object?> get props => [
    url,
    examCode,
    status,
    errorMessage,
    validatedLink,
  ];
}
