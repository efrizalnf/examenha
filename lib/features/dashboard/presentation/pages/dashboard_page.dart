import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/brand_loader.dart';
import '../../../auth/domain/entities/student.dart';
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
      body: Stack(
        children: [
          BlocBuilder<ExamListBloc, ExamListState>(
            builder: (context, state) {
              final loading = state.status == ExamListStatus.loading;
              final exams = _sorted(state.exams);
              final running = exams
                  .where((e) => e.status == StudentExamStatus.berlangsung)
                  .length;
              final ready = exams
                  .where(
                    (e) =>
                        e.status == StudentExamStatus.belum &&
                        e.isGform &&
                        e.bisaMulai,
                  )
                  .length;
              return Column(
                children: [
                  _Header(
                    student: student,
                    total: exams.length,
                    ready: ready,
                    running: running,
                    loading: loading,
                    onLogout: () =>
                        context.read<AuthBloc>().add(const AuthLoggedOut()),
                  ),
                  Expanded(
                    child: loading
                        ? const Center(child: BrandLoader(size: 96))
                        : RefreshIndicator(
                            onRefresh: _refresh,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 4, bottom: 12),
                                  child: Text(
                                    'Ujian aktif',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                if (state.status == ExamListStatus.failure)
                                  _Notice(
                                    icon: Icons.wifi_off_rounded,
                                    text: state.error ?? 'Gagal memuat ujian.',
                                  )
                                else if (exams.isEmpty)
                                  const _Notice(
                                    icon: Icons.event_available_rounded,
                                    text:
                                        'Belum ada ujian aktif untuk Anda.\nTarik ke bawah untuk memuat ulang.',
                                  ),
                                for (final e in exams)
                                  _ExamCard(
                                    exam: e,
                                    busy: _starting,
                                    onTap: () => _startExam(e),
                                  ),
                              ],
                            ),
                          ),
                  ),
                ],
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

  /// Urutan: sedang berlangsung → siap dimulai → belum tersedia → selesai.
  List<ExamSummary> _sorted(List<ExamSummary> list) {
    int rank(ExamSummary e) {
      if (e.status == StudentExamStatus.berlangsung) return 0;
      if (e.status == StudentExamStatus.selesai) return 3;
      return e.isGform && e.bisaMulai ? 1 : 2;
    }

    final copy = List<ExamSummary>.of(list);
    copy.sort((a, b) => rank(a).compareTo(rank(b)));
    return copy;
  }
}

/// Kepala dashboard: gradien, identitas siswa, dan ringkasan jumlah ujian.
class _Header extends StatelessWidget {
  final Student? student;
  final int total, ready, running;
  final bool loading;
  final VoidCallback onLogout;
  const _Header({
    required this.student,
    required this.total,
    required this.ready,
    required this.running,
    required this.loading,
    required this.onLogout,
  });

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    final nama = student?.nama ?? AppConstants.appName;
    final initial = nama.trim().isEmpty ? '?' : nama.trim()[0].toUpperCase();
    final detail = student == null
        ? ''
        : [
            'NIS ${student!.nis}',
            if (student!.kelas.isNotEmpty) student!.kelas,
            if (student!.jenjang.isNotEmpty) student!.jenjang,
          ].join(' · ');
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.heroStart, AppColors.heroMid, AppColors.heroEnd],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0x33FFFFFF),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting,
                          style: const TextStyle(
                            color: Color(0xCCFFFFFF),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          nama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (detail.isNotEmpty)
                          Text(
                            detail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xCCFFFFFF),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Keluar',
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    onPressed: onLogout,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _StatPill(
                    icon: Icons.assignment_rounded,
                    label: loading ? 'Memuat…' : '$total ujian aktif',
                  ),
                  const SizedBox(width: 8),
                  if (ready > 0) _StatPill(icon: Icons.play_circle_rounded, label: '$ready siap dimulai'),
                  if (running > 0) ...[
                    const SizedBox(width: 8),
                    _StatPill(icon: Icons.timer_rounded, label: '$running berlangsung'),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0x29FFFFFF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: AppColors.accent),
          ),
          const SizedBox(height: 14),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
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
    String statusLabel;
    Color tone;
    String? action;
    String? note;

    if (!exam.isGform) {
      statusLabel = 'Belum tersedia';
      tone = AppColors.textSecondary;
      note = 'Soal belum dipublikasikan oleh guru.';
    } else {
      switch (exam.status) {
        case StudentExamStatus.selesai:
          statusLabel = 'Selesai';
          tone = AppColors.success;
          note = exam.nilai != null ? 'Nilai Anda: ${exam.nilai}' : null;
        case StudentExamStatus.berlangsung:
          statusLabel = 'Sedang berlangsung';
          tone = AppColors.accent;
          note = 'Sisa waktu ${_fmt(exam.sisaDetik ?? 0)}';
          action = 'Lanjutkan ujian';
        case StudentExamStatus.belum:
          if (exam.bisaMulai) {
            statusLabel = 'Siap dimulai';
            tone = AppColors.primary;
            action = 'Mulai ujian';
          } else {
            statusLabel = 'Belum dibuka';
            tone = AppColors.warning;
            note = 'Belum dibuka atau sedang diperbarui guru.';
          }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: tone),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: tone.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: tone,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          exam.jenisUjian,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      exam.judul,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${exam.mapel} · ${exam.guru}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: [
                        _Meta(Icons.schedule_rounded, '${exam.durasiMenit} menit'),
                        _Meta(Icons.help_outline_rounded, '${exam.jumlahSoal} soal'),
                      ],
                    ),
                    if (note != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        note,
                        style: TextStyle(
                          color: tone,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (action != null) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: busy ? null : onTap,
                          icon: Icon(
                            exam.status == StudentExamStatus.berlangsung
                                ? Icons.play_arrow_rounded
                                : Icons.rocket_launch_rounded,
                            size: 20,
                          ),
                          label: Text(action),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tone,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Meta(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
