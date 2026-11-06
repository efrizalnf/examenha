import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import 'core/constants/app_constants.dart';
import 'core/network/api_client.dart';
import 'features/auth/data/auth_local_store.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/dashboard/presentation/bloc/exam_list_bloc.dart';
import 'features/exam/data/repositories/exam_repository_impl.dart';
import 'features/exam/domain/repositories/exam_repository.dart';

import 'core/services/security_service.dart';
import 'features/home/data/repositories/home_repository_impl.dart';
import 'features/home/domain/repositories/home_repository.dart';
import 'features/home/domain/usecases/validate_exam_url_usecase.dart';
import 'features/home/presentation/bloc/home_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // === Services (Singleton) ===
  sl.registerLazySingleton<SecurityService>(() => SecurityService());

  // === Jaringan & penyimpanan ===
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(baseUrl: AppConstants.apiBaseUrl),
  );
  sl.registerLazySingleton<AuthLocalStore>(
    () => const AuthLocalStore(FlutterSecureStorage()),
  );

  // === Repositories (Singleton) ===
  sl.registerLazySingleton<HomeRepository>(() => const HomeRepositoryImpl());
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<ExamRepository>(() => ExamRepositoryImpl(sl()));

  // === Use Cases (Singleton) ===
  sl.registerLazySingleton<ValidateExamUrlUsecase>(
    () => ValidateExamUrlUsecase(sl()),
  );

  // === BLoCs (Factory — baru setiap kali dibutuhkan) ===
  sl.registerFactory<HomeBloc>(() => HomeBloc(sl()));
  sl.registerLazySingleton<AuthBloc>(() => AuthBloc(sl())..add(const AuthStarted()));
  sl.registerFactory<ExamListBloc>(() => ExamListBloc(sl()));

  // Token kedaluwarsa -> kembali ke halaman login.
  sl<ApiClient>().onUnauthorized = () =>
      sl<AuthBloc>().add(const AuthSessionExpired());

  // Note: ExamBloc dibuat secara manual di ExamPage (butuh ExamLink param)
}
