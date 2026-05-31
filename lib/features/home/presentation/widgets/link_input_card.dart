import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';

class LinkInputCard extends StatefulWidget {
  const LinkInputCard({super.key});

  @override
  State<LinkInputCard> createState() => _LinkInputCardState();
}

class _LinkInputCardState extends State<LinkInputCard> {
  late final TextEditingController _urlController;
  late final TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listenWhen: (prev, curr) => prev.url != curr.url,
      listener: (context, state) {
        // Sync controller jika URL diisi via QR scan
        if (_urlController.text != state.url) {
          _urlController.text = state.url;
          _urlController.selection = TextSelection.fromPosition(
            TextPosition(offset: state.url.length),
          );
        }
      },
      builder: (context, state) {
        return Card(
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Akses Ujian',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Masukkan link dan kode agar kamu bisa langsung masuk ke sesi ujian.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Link Ujian',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _urlController,
                  onChanged: (v) =>
                      context.read<HomeBloc>().add(UrlChangedEvent(v)),
                  decoration: InputDecoration(
                    hintText: 'Paste link Google/Microsoft Forms...',
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
                        color: AppColors.primary,
                        width: 1.6,
                      ),
                    ),
                    errorText:
                        state.status == HomeStatus.invalid &&
                            !_isCodeError(state.errorMessage)
                        ? state.errorMessage
                        : null,
                    prefixIcon: const Icon(
                      Icons.link_rounded,
                      color: AppColors.primaryDark,
                    ),
                    suffixIcon: state.url.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _urlController.clear();
                              context.read<HomeBloc>().add(
                                const UrlChangedEvent(''),
                              );
                            },
                          )
                        : null,
                  ),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 20),

                // --- Kode Ujian (selalu wajib diisi) ---
                const Text(
                  'Kode Ujian',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _codeController,
                  onChanged: (v) =>
                      context.read<HomeBloc>().add(ExamCodeChangedEvent(v)),
                  decoration: InputDecoration(
                    hintText: 'Masukkan kode ujian...',
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
                    errorText:
                        state.status == HomeStatus.invalid &&
                            _isCodeError(state.errorMessage)
                        ? state.errorMessage
                        : null,
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.accent,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isCodeError(String? message) =>
      message != null &&
      (message.contains('kode ujian') || message.contains('Kode ujian'));
}
