import 'package:equatable/equatable.dart';

class ExamLink extends Equatable {
  final String url;
  final String examCode;

  const ExamLink({required this.url, required this.examCode});

  @override
  List<Object?> get props => [url, examCode];
}
