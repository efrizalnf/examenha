import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'core/constants/app_colors.dart';
import 'core/services/security_service.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Paksa orientasi portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inisialisasi dependensi
  await initDependencies();

  runApp(const EnhaExam());
}

class EnhaExam extends StatelessWidget {
  const EnhaExam({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SecurityService>(
          create: (_) => GetIt.I<SecurityService>(),
        ),
      ],
      child: MaterialApp(
        title: 'Enha Exam',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ),
          fontFamily: 'Roboto',
        ),
        home: BlocProvider<HomeBloc>(
          create: (_) => GetIt.I<HomeBloc>(),
          child: const HomePage(),
        ),
      ),
    );
  }
}
