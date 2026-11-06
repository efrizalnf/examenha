import 'package:equatable/equatable.dart';

/// Tautan ujian yang dibuka di WebView.
///
/// Alur baru (Google Form dari server): [url] = formUrl, [examCode] = token
/// yang diinput siswa, serta [sesiId] dan [remainingSeconds] dari server.
/// Field baru punya default agar fitur `home` lama tetap dapat dikompilasi.
class ExamLink extends Equatable {
  final String url;
  final String examCode;
  final String sesiId;
  final String judul;
  final int remainingSeconds;

  const ExamLink({
    required this.url,
    required this.examCode,
    this.sesiId = '',
    this.judul = '',
    this.remainingSeconds = 0,
  });

  @override
  List<Object?> get props => [url, examCode, sesiId, judul, remainingSeconds];
}
