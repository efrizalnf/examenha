import 'package:get_it/get_it.dart';

import 'core/services/security_service.dart';
import 'features/home/data/repositories/home_repository_impl.dart';
import 'features/home/domain/repositories/home_repository.dart';
import 'features/home/domain/usecases/validate_exam_url_usecase.dart';
import 'features/home/presentation/bloc/home_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // === Services (Singleton) ===
  sl.registerLazySingleton<SecurityService>(() => SecurityService());

  // === Repositories (Singleton) ===
  sl.registerLazySingleton<HomeRepository>(() => const HomeRepositoryImpl());

  // === Use Cases (Singleton) ===
  sl.registerLazySingleton<ValidateExamUrlUsecase>(
    () => ValidateExamUrlUsecase(sl()),
  );

  // === BLoCs (Factory — baru setiap kali dibutuhkan) ===
  sl.registerFactory<HomeBloc>(() => HomeBloc(sl()));

  // Note: ExamBloc dibuat secara manual di ExamPage (butuh ExamLink param)
}
