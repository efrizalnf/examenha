import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../bloc/exam_bloc.dart';
import '../bloc/exam_state.dart';

/// Widget floating timer: HITUNG MUNDUR sisa waktu (HH:mm:ss) dari server.
class TimerDisplay extends StatelessWidget {
  const TimerDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExamBloc, ExamState>(
      buildWhen: (prev, curr) => prev.remaining != curr.remaining,
      builder: (context, state) {
        final time = state.formattedRemaining;
        final urgent = state.remaining.inSeconds <= 300;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.timerBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  Icons.timer_outlined,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 13,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                time,
                style: TextStyle(
                  color: urgent ? AppColors.coral : AppColors.timerText,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
