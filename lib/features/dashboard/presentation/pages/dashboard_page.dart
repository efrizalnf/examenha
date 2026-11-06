import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/brand_loader.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../exam/domain/entities/exam_summary.dart';
import '../../../exam/domain/repositories/exam_repository.dart';
import '../../../exam/presentation/pages/exam_page.dart';
import '../../../home/domain/entities/exam_link.dart';
import '../../../qr_scanner/presentation/pages/qr_scanner_page.dart';
import '../bloc/exam_list_bloc.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ExamListBloc>(
      create: (_) => GetIt.I<ExamListBloc>()..add(const ExamListRequested()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView>
    with WidgetsBindingObserver {
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<ExamListBloc>().add(const ExamListRequested());
    }
  }

  Future<void> _refresh() async {
    final bloc = context.read<ExamListBloc>();
    bloc.add(const ExamListRequested());
    await bloc.stream.firstWhere(
      (s) => s.status != ExamListStatus.loading,
      orElse: () => bloc.state,
    );
  }

  Future<void> _startExam(ExamSummary exam) async {
    if (_starting) return; // cegah klik ganda
    final repo = GetIt.I<ExamRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final listBloc = context.read<ExamListBloc>();

    // Sesi yang sudah berjalan dilanjutkan tanpa token.
    var token = '';
    if (exam.status == StudentExamStatus.belum) {
      final input = await showDialog<String>(
        context: context,
        builder: (_) => const _TokenDialog(),
      );
      if (input == null || input.trim().isEmpty) return;
      token = input.trim();
    }

    if (!mounted) return;
    setState(() => _starting = true);
    final r = await repo.start(ujianId: exam.id, token: token);
    if (!mounted) return;
    setState(() => _starting = false);

    await r.fold<Future<void>>(
      (f) async => messenger.showSnackBar(SnackBar(content: Text(f.message))),
      (s) async {
        final link = ExamLink(
          url: s.formUrl,
          examCode: token,
          sesiId: s.sesiId,
          judul: s.judul,
          remainingSeconds: s.remainingSeconds,
        );
        await navigator.push(
          MaterialPageRoute<void>(builder: (_) => ExamPage(link: link)),
        );
        if (!listBloc.isClosed) listBloc.add(const ExamListRequested());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final student = context.select((AuthBloc b) => b.state.student);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              student?.nama ?? AppConstants.appName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (student != null)
              Text(
                'NIS ${student.nis} · ${student.kelas}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout_rounded, color: AppColors.coral),
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthLoggedOut()),
          ),
        ],
      ),
      body: Stack(
        children: [
          BlocBuilder<ExamListBloc, ExamListState>(
            builder: (context, state) {
              if (state.status == ExamListStatus.loading) {
                return const Center(child: BrandLoader(size: 96));
              }
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (state.status == ExamListStatus.failure)
                      _Notice(
                        icon: Icons.wifi_off_rounded,
                        text: state.error ?? 'Gagal memuat ujian.',
                      )
                    else if (state.exams.isEmpty)
                      const _Notice(
                        icon: Icons.event_busy_rounded,
                        text:
                            'Belum ada ujian aktif untuk Anda. Tarik ke bawah untuk memuat ulang.',
                      ),
                    for (final e in state.exams)
                      _ExamCard(
                        exam: e,
                        busy: _starting,
                        onTap: () => _startExam(e),
                      ),
                  ],
                ),
              );
            },
          ),
          if (_starting)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66000000),
                child: Center(child: BrandLoader(size: 96)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Notice({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 44, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final ExamSummary exam;
  final bool busy;
  final VoidCallback onTap;
  const _ExamCard({
    required this.exam,
    required this.busy,
    required this.onTap,
  });

  String _fmt(int sec) {
    final h = (sec ~/ 3600).toString().padLeft(2, '0');
    final m = ((sec % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final String? hint;
    String? action;
    Color actionColor = AppColors.primary;

    if (!exam.isGform) {
      hint = 'Belum dipublikasikan oleh guru';
    } else {
      switch (exam.status) {
        case StudentExamStatus.selesai:
          hint = exam.nilai != null ? 'Selesai · nilai ${exam.nilai}' : 'Selesai';
        case StudentExamStatus.berlangsung:
          hint = 'Sisa waktu ${_fmt(exam.sisaDetik ?? 0)}';
          action = 'Lanjutkan';
          actionColor = AppColors.accent;
        case StudentExamStatus.belum:
          if (exam.bisaMulai) {
            hint = null;
            action = 'Mulai';
          } else {
            hint = 'Belum dibuka / sedang diperbarui guru';
          }
      }
    }

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exam.judul,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${exam.mapel} · ${exam.jenisUjian} · ${exam.guru}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${exam.durasiMenit} menit · ${exam.jumlahSoal} soal',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    hint ?? '',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (action != null)
                  ElevatedButton(
                    onPressed: busy ? null : onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: actionColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(action),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog input token ujian (ketik atau scan QR).
class _TokenDialog extends StatefulWidget {
  const _TokenDialog();

  @override
  State<_TokenDialog> createState() => _TokenDialogState();
}

class _TokenDialogState extends State<_TokenDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final value = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const QrScannerPage()),
    );
    if (value != null && mounted) {
      _controller.text = value.trim().toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      title: const Text(
        'Token ujian',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Masukkan token dari guru/pengawas.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (v) => Navigator.of(context).pop(v),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Token',
              suffixIcon: IconButton(
                tooltip: 'Scan QR',
                icon: const Icon(Icons.qr_code_scanner_rounded),
                onPressed: _scan,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Mulai'),
        ),
      ],
    );
  }
}
