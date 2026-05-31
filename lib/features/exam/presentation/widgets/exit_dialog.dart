import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../bloc/exam_bloc.dart';
import '../bloc/exam_event.dart';
import '../bloc/exam_state.dart';

/// Dialog untuk memasukkan kode keluar ujian sebelum keluar
class ExitDialog extends StatefulWidget {
  const ExitDialog({super.key});

  @override
  State<ExitDialog> createState() => _ExitDialogState();
}

class _ExitDialogState extends State<ExitDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // dialog ini tidak bisa ditutup dengan tombol back
      child: BlocBuilder<ExamBloc, ExamState>(
        builder: (context, state) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
            contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: const Row(
              children: [
                _ExitDialogBadge(),
                SizedBox(width: 12),
                Expanded(child: Text('Keluar Ujian')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Masukkan kode keluar ujian untuk menutup ujian ini.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Kode ini khusus untuk pengawas atau admin.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Kode Keluar Ujian',
                    hintText: '••••••',
                    errorText: state.exitCodeError,
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.accent,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceMuted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: AppColors.accent,
                        width: 1.6,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _submitCode(context),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  context.read<ExamBloc>().add(const ExamCancelExitEvent());
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Batal',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () => _submitCode(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Keluar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _submitCode(BuildContext context) {
    context.read<ExamBloc>().add(ExamExitWithCodeEvent(_controller.text));
  }
}

class _ExitDialogBadge extends StatelessWidget {
  const _ExitDialogBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.exit_to_app_rounded, color: AppColors.coral),
    );
  }
}
