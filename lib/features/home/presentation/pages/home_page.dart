import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/security_service.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../exam/presentation/pages/exam_page.dart';
import '../../../qr_scanner/presentation/pages/qr_scanner_page.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  late AnimationController _appearanceController;

  @override
  void initState() {
    super.initState();
    _appearanceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SecurityService>().startExam();
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _appearanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showExitConfirmation(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // Decorative background elements
            _AnimatedBackground(controller: _appearanceController),

            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    _EntranceAnimation(
                      delay: 0,
                      controller: _appearanceController,
                      child: const BrandLogo(size: 140),
                    ),
                    const SizedBox(height: 32),
                    _EntranceAnimation(
                      delay: 200,
                      controller: _appearanceController,
                      child: Column(
                        children: [
                          const Text(
                            'Selamat Datang',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Silakan pilih metode masuk',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.7,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    _EntranceAnimation(
                      delay: 300,
                      controller: _appearanceController,
                      child: _SimpleActionCard(
                        icon: Icons.qr_code_scanner_rounded,
                        title: 'Scan QR Code',
                        color: AppColors.primary,
                        onTap: _triggerQrScan,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _EntranceAnimation(
                      delay: 450,
                      controller: _appearanceController,
                      child: _SimpleActionCard(
                        icon: Icons.link_rounded,
                        title: 'Input Link Manual',
                        color: AppColors.accent,
                        onTap: () => _showLinkInputDialog(context),
                      ),
                    ),
                    const SizedBox(height: 64),
                    _EntranceAnimation(
                      delay: 600,
                      controller: _appearanceController,
                      child: const _SimpleInfoTile(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Wrapper for QR scan trigger to maintain logic
  void _showLinkInputDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Input Link Manual',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: TextField(
          controller: _urlController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'https://...',
            filled: true,
            fillColor: AppColors.surfaceMuted,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = _urlController.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(context);
                _openCodePageFromLink(url);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
  }

  void _triggerQrScan() async {
    final scanned = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const QrScannerPage()));
    if (scanned != null && mounted) {
      _openCodePageFromQr(scanned);
    }
  }

  Future<void> _showExitConfirmation(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
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
              _DialogBadge(icon: Icons.exit_to_app_rounded),
              SizedBox(width: 12),
              Expanded(child: Text('Keluar Aplikasi')),
            ],
          ),
          content: const Text(
            'Sesi akan ditutup dan aplikasi keluar dari mode aman. Yakin ingin melanjutkan?',
            style: TextStyle(color: AppColors.textSecondary, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Batal',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
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
    );

    if (shouldExit == true && context.mounted) {
      await context.read<SecurityService>().stopExam();
      await SystemNavigator.pop();
    }
  }

  void _openCodePageFromLink(String url) {
    context.read<HomeBloc>().add(UrlChangedEvent(url));
    context.read<HomeBloc>().add(const ExamCodeChangedEvent(''));
    Navigator.of(context).push(
      _buildStepRoute(
        child: BlocProvider.value(
          value: context.read<HomeBloc>(),
          child: const _ExamCodePage(openedFromQr: false),
        ),
      ),
    );
  }

  void _openCodePageFromQr(String url) {
    context.read<HomeBloc>().add(QrScannedEvent(url));
    context.read<HomeBloc>().add(const ExamCodeChangedEvent(''));
    Navigator.of(context).push(
      _buildStepRoute(
        child: BlocProvider.value(
          value: context.read<HomeBloc>(),
          child: const _ExamCodePage(openedFromQr: true),
        ),
      ),
    );
  }

  PageRouteBuilder<void> _buildStepRoute({required Widget child}) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final offsetTween = Tween<Offset>(
          begin: const Offset(0.08, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        final fadeTween = Tween<double>(
          begin: 0,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOut));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(offsetTween),
            child: child,
          ),
        );
      },
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: -120 * controller.value,
              right: -100 * controller.value,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(
                        alpha: 0.15 * controller.value,
                      ),
                      AppColors.background.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -50 * controller.value,
              left: -80 * controller.value,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(
                        alpha: 0.08 * controller.value,
                      ),
                      AppColors.background.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EntranceAnimation extends StatelessWidget {
  final Widget child;
  final int delay;
  final AnimationController controller;

  const _EntranceAnimation({
    required this.child,
    required this.delay,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final double start = delay / 1200;
    final double end = (delay + 400) / 1200;

    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        start.clamp(0.0, 1.0),
        end.clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _SimpleActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _SimpleActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SimpleInfoTile extends StatelessWidget {
  const _SimpleInfoTile();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.shield_rounded, color: AppColors.success, size: 24),
        const SizedBox(height: 12),
        const Text(
          'Mode Aman Aktif',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Aplikasi dalam kondisi terkunci untuk memastikan kejujuran ujian.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// Removed old widgets: _HeroActionCard, _AppHeader, _LinkStepCard, _SectionTitle, _InfoSection

class _DialogBadge extends StatelessWidget {
  final IconData icon;

  const _DialogBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.accent),
    );
  }
}

class _ExamCodePage extends StatefulWidget {
  final bool openedFromQr;

  const _ExamCodePage({required this.openedFromQr});

  @override
  State<_ExamCodePage> createState() => _ExamCodePageState();
}

class _ExamCodePageState extends State<_ExamCodePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  late AnimationController _appearanceController;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _appearanceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _appearanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeBloc, HomeState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == HomeStatus.ready &&
            state.validatedLink != null &&
            !_isNavigating) {
          _isNavigating = true;
          Navigator.of(context)
              .pushReplacement(
                PageRouteBuilder<void>(
                  transitionDuration: const Duration(milliseconds: 360),
                  reverseTransitionDuration: const Duration(milliseconds: 260),
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      ExamPage(link: state.validatedLink!),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        final fadeTween = Tween<double>(
                          begin: 0,
                          end: 1,
                        ).chain(CurveTween(curve: Curves.easeOut));
                        final scaleTween = Tween<double>(
                          begin: 0.98,
                          end: 1,
                        ).chain(CurveTween(curve: Curves.easeOutCubic));

                        return FadeTransition(
                          opacity: animation.drive(fadeTween),
                          child: ScaleTransition(
                            scale: animation.drive(scaleTween),
                            child: child,
                          ),
                        );
                      },
                ),
              )
              .then((_) {
                _isNavigating = false;
              });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
          title: const Text(
            'Langkah Terakhir',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              fontSize: 18,
            ),
          ),
        ),
        body: Stack(
          children: [
            _AnimatedBackground(controller: _appearanceController),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _EntranceAnimation(
                      delay: 0,
                      controller: _appearanceController,
                      child: const _StepProgressHeader(),
                    ),
                    const SizedBox(height: 32),
                    _EntranceAnimation(
                      delay: 200,
                      controller: _appearanceController,
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: BlocBuilder<HomeBloc, HomeState>(
                          builder: (context, state) {
                            final codeError = _isCodeError(state.errorMessage)
                                ? state.errorMessage
                                : null;
                            final otherError =
                                state.status == HomeStatus.invalid &&
                                    codeError == null
                                ? state.errorMessage
                                : null;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        widget.openedFromQr
                                            ? 'VIA QR CODE'
                                            : 'VIA LINK MANUAL',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.primary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Masukkan Kode',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ujian siap dimulai. Masukkan kode akses yang diberikan oleh pengawas.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.7,
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                TextField(
                                  controller: _codeController,
                                  autofocus: true,
                                  obscureText: true,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 12,
                                    color: AppColors.primary,
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    context.read<HomeBloc>().add(
                                      ExamCodeChangedEvent(value),
                                    );
                                  },
                                  onSubmitted: (_) => _startExam(context),
                                  decoration: InputDecoration(
                                    hintText: '•••••',
                                    hintStyle: TextStyle(
                                      color: AppColors.border,
                                      letterSpacing: 12,
                                    ),
                                    errorText: codeError,
                                    filled: true,
                                    fillColor: AppColors.surfaceMuted,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 24,
                                    ),
                                  ),
                                ),
                                if (otherError != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          color: AppColors.error,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            otherError,
                                            style: const TextStyle(
                                              color: AppColors.error,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => _startExam(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.rocket_launch_rounded,
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'MULAI UJIAN SEKARANG',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _EntranceAnimation(
                      delay: 400,
                      controller: _appearanceController,
                      child: const _SimpleInfoTile(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startExam(BuildContext context) {
    context.read<HomeBloc>().add(ExamCodeChangedEvent(_codeController.text));
    context.read<HomeBloc>().add(const StartExamPressedEvent());
  }

  bool _isCodeError(String? message) =>
      message != null &&
      (message.contains('kode ujian') || message.contains('Kode ujian'));
}

class _StepProgressHeader extends StatelessWidget {
  const _StepProgressHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const _ProgressNode(
            step: '1',
            label: 'Verifikasi',
            isActive: false,
            isDone: true,
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
          const _ProgressNode(
            step: '2',
            label: 'Input Kode',
            isActive: true,
            isDone: false,
          ),
        ],
      ),
    );
  }
}

class _ProgressNode extends StatelessWidget {
  final String step;
  final String label;
  final bool isActive;
  final bool isDone;

  const _ProgressNode({
    required this.step,
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDone
        ? AppColors.primary
        : isActive
        ? AppColors.primary
        : AppColors.surfaceMuted;
    final foregroundColor = isDone || isActive
        ? Colors.white
        : AppColors.textSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : Text(
                    step,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
