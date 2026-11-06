import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/security_service.dart';
import '../../../../core/widgets/brand_loader.dart';
import '../../../home/domain/entities/exam_link.dart';
import '../../domain/repositories/exam_repository.dart';
import '../bloc/exam_bloc.dart';
import '../bloc/exam_event.dart';
import '../bloc/exam_state.dart';
import '../widgets/exit_dialog.dart';
import '../widgets/timer_display.dart';

class ExamPage extends StatelessWidget {
  final ExamLink link;

  const ExamPage({super.key, required this.link});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          ExamBloc(
            securityService: ctx.read<SecurityService>(),
            repository: GetIt.I<ExamRepository>(),
            link: link,
          )..add(const ExamStartedEvent()),
      child: _ExamView(link: link),
    );
  }
}

class _ExamView extends StatefulWidget {
  final ExamLink link;

  const _ExamView({required this.link});

  @override
  State<_ExamView> createState() => _ExamViewState();
}

class _ExamViewState extends State<_ExamView> with WidgetsBindingObserver {
  /// Siswa hanya boleh berada di Google Forms (tautan lain dalam form diblokir).
  static const _allowedHosts = {
    'docs.google.com',
    'forms.gle',
    'forms.google.com',
  };

  late final WebViewController _webController;
  bool _isWebViewReady = false;
  bool _isSecurityAlertShown = false;
  bool _isExitDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initWebView();
  }

  void _initWebView() {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/90.0.4430.91 Mobile Safari/537.36',
      )
      ..setBackgroundColor(AppColors.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (req) {
            // about:blank dipakai untuk mengunci layar saat waktu habis.
            if (req.url == 'about:blank') return NavigationDecision.navigate;
            final host = Uri.tryParse(req.url)?.host ?? '';
            return _allowedHosts.contains(host)
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _isWebViewReady = true);
            _checkSubmitted(url);
          },
          onWebResourceError: (error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.link.url));
  }

  bool _submittedSent = false;

  /// Google Forms yang bersekat (kolom NIS/Nama + halaman soal) juga memuat
  /// `.../formResponse` saat pindah halaman ("Berikutnya"), jadi URL saja TIDAK
  /// cukup untuk menyimpulkan form terkirim. Yang dipercaya: teks konfirmasi
  /// yang kita pasang di Form ("Jawaban Anda telah terkirim...") pada halaman
  /// `/formResponse`, atau tautan "kirim jawaban lain" bawaan Google.
  Future<void> _checkSubmitted(String url) async {
    if (_submittedSent || !url.contains('/formResponse')) return;
    for (var i = 0; i < 3; i++) {
      try {
        final r = await _webController.runJavaScriptReturningResult(
          "(function(){var t=((document.body&&document.body.innerText)||'').toLowerCase();"
          "return t.indexOf('jawaban anda telah terkirim')>=0"
          "||t.indexOf('examform_terkirim')>=0"
          "||t.indexOf('your response has been recorded')>=0"
          "||t.indexOf('jawaban anda telah direkam')>=0"
          "||document.querySelector('a[href*=\"form_confirm\"]')!==null;})()",
        );
        if ('$r'.contains('true')) {
          if (!mounted || _submittedSent) return;
          _submittedSent = true;
          context.read<ExamBloc>().add(const ExamFormSubmittedEvent());
          return;
        }
      } catch (_) {
        // halaman belum siap; coba lagi
      }
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && mounted) {
      context.read<ExamBloc>().add(
        const ExamSecurityAlertEvent('userLeaveHint'),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: BlocListener<ExamBloc, ExamState>(
        listener: _onStateChange,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: WebViewWidget(controller: _webController),
                ),

                IgnorePointer(
                  ignoring: _isWebViewReady,
                  child: AnimatedOpacity(
                    opacity: _isWebViewReady ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: _LoadingOverlay(isVisible: !_isWebViewReady),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ExitButton(
                        onPressed: () {
                          context.read<ExamBloc>().add(
                            const ExamExitAttemptEvent(),
                          );
                        },
                      ),
                      const TimerDisplay(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onStateChange(BuildContext context, ExamState state) {
    switch (state.status) {
      case ExamStatus.securityAlert:
        if (!_isSecurityAlertShown && !_isExitDialogShown) {
          _isSecurityAlertShown = true;
          _showSecurityAlert(
            context,
            state.alertMessage ?? 'Peringatan keamanan!',
          );
        }
      case ExamStatus.exitPrompt:
        if (!_isExitDialogShown) {
          _isExitDialogShown = true;
          _showExitDialog(context);
        }
      case ExamStatus.timeUp:
        // Kunci layar: tutup form selagi sesi ditutup di server.
        _webController.loadRequest(Uri.parse('about:blank'));
      case ExamStatus.exited:
        Navigator.of(context).pop();
      case ExamStatus.finished:
        _onFinished(context, state.finishReason);
      case ExamStatus.running:
        _isSecurityAlertShown = false;
        _isExitDialogShown = false;
      default:
        break;
    }
  }

  Future<void> _onFinished(
    BuildContext context,
    ExamFinishReason? reason,
  ) async {
    final navigator = Navigator.of(context);
    // Tutup dialog keluar bila sedang terbuka agar pop() tidak salah sasaran.
    if (_isExitDialogShown) {
      navigator.pop();
      _isExitDialogShown = false;
    }
    if (reason != null) {
      final timeUp = reason == ExamFinishReason.timeUp;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          title: Text(
            timeUp ? 'Waktu ujian habis' : 'Jawaban terkirim',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            timeUp
                ? 'Jawaban yang sudah Anda kirim tetap tercatat.'
                : 'Terima kasih. Nilai akan diumumkan oleh guru.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
    if (mounted) navigator.pop(); // kembali ke dashboard
  }

  void _showSecurityAlert(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: const Row(
          children: [
            _SecurityAlertBadge(),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Peringatan keamanan',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 18,
                    color: AppColors.primaryDark,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Kembali ke layar ujian untuk menjaga sesi tetap valid dan aman.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              context.read<ExamBloc>().add(const ExamDismissAlertEvent());
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Kembali ke Ujian'),
          ),
        ],
      ),
    ).then((_) => _isSecurityAlertShown = false);
  }

  void _showExitDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<ExamBloc>(),
        child: BlocListener<ExamBloc, ExamState>(
          listenWhen: (p, c) =>
              p.status != c.status && c.status == ExamStatus.exited,
          listener: (_, _) => Navigator.of(context).pop(),
          child: const ExitDialog(),
        ),
      ),
    ).then((_) => _isExitDialogShown = false);
  }
}

class _SecurityAlertBadge extends StatelessWidget {
  const _SecurityAlertBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  final bool isVisible;

  const _LoadingOverlay({required this.isVisible});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.92, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value.clamp(0, 1),
              child: Transform.scale(scale: value, child: child),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x120E2030),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandLoader(size: 136),
                const SizedBox(height: 16),
                const Text(
                  'Menyiapkan ruang ujian',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Halaman ujian sedang dibuka. Tunggu sebentar hingga siap digunakan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  height: isVisible ? 10 : 0,
                ),
                AnimatedOpacity(
                  opacity: isVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Text(
                    'Halaman hampir siap ditampilkan.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExitButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ExitButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.timerBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.close_rounded, color: Colors.white, size: 15),
              SizedBox(width: 5),
              Text(
                'Keluar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
