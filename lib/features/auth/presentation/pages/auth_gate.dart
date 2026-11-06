import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/brand_loader.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../bloc/auth_bloc.dart';
import 'login_page.dart';

/// Penentu halaman awal: login atau dashboard.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (_, s) => switch (s.status) {
        AuthStatus.unknown => const Scaffold(
          body: Center(child: BrandLoader(size: 96)),
        ),
        AuthStatus.authenticated => const DashboardPage(),
        AuthStatus.unauthenticated => const LoginPage(),
      },
    );
  }
}
