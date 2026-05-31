import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class UrlChangedEvent extends HomeEvent {
  final String url;
  const UrlChangedEvent(this.url);

  @override
  List<Object?> get props => [url];
}

class ExamCodeChangedEvent extends HomeEvent {
  final String code;
  const ExamCodeChangedEvent(this.code);

  @override
  List<Object?> get props => [code];
}

class QrScannedEvent extends HomeEvent {
  final String scannedUrl;
  const QrScannedEvent(this.scannedUrl);

  @override
  List<Object?> get props => [scannedUrl];
}

class StartExamPressedEvent extends HomeEvent {
  const StartExamPressedEvent();
}
