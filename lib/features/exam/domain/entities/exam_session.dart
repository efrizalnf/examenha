import 'package:equatable/equatable.dart';

import '../../../home/domain/entities/exam_link.dart';

class ExamSession extends Equatable {
  final ExamLink link;
  final DateTime startTime;
  final Duration elapsed;
  final bool isActive;

  const ExamSession({
    required this.link,
    required this.startTime,
    this.elapsed = Duration.zero,
    this.isActive = true,
  });

  ExamSession copyWith({
    ExamLink? link,
    DateTime? startTime,
    Duration? elapsed,
    bool? isActive,
  }) {
    return ExamSession(
      link: link ?? this.link,
      startTime: startTime ?? this.startTime,
      elapsed: elapsed ?? this.elapsed,
      isActive: isActive ?? this.isActive,
    );
  }

  String get formattedElapsed {
    final h = elapsed.inHours.toString().padLeft(2, '0');
    final m = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  List<Object?> get props => [link, startTime, elapsed, isActive];
}
