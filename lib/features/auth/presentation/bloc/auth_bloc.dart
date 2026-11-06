import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/student.dart';
import '../../domain/repositories/auth_repository.dart';

// ---- events ----
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthLoginSubmitted extends AuthEvent {
  final String nis, password;
  const AuthLoginSubmitted(this.nis, this.password);
  @override
  List<Object?> get props => [nis, password];
}

class AuthLoggedOut extends AuthEvent {
  const AuthLoggedOut();
}

class AuthSessionExpired extends AuthEvent {
  const AuthSessionExpired();
}

// ---- state ----
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final Student? student;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.student,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({bool? isLoading, bool clearError = false}) => AuthState(
    status: status,
    student: student,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : errorMessage,
  );

  @override
  List<Object?> get props => [status, student, isLoading, errorMessage];
}

// ---- bloc (singleton: sesi login bersifat global) ----
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;

  AuthBloc(this._repo) : super(const AuthState()) {
    on<AuthStarted>((e, emit) async {
      final s = await _repo.restore();
      emit(
        s == null
            ? const AuthState(status: AuthStatus.unauthenticated)
            : AuthState(status: AuthStatus.authenticated, student: s),
      );
    });
    on<AuthLoginSubmitted>((e, emit) async {
      emit(state.copyWith(isLoading: true, clearError: true));
      final r = await _repo.login(e.nis, e.password);
      r.fold(
        (f) => emit(
          AuthState(
            status: AuthStatus.unauthenticated,
            errorMessage: f.message,
          ),
        ),
        (s) => emit(AuthState(status: AuthStatus.authenticated, student: s)),
      );
    });
    on<AuthLoggedOut>((e, emit) async {
      await _repo.logout();
      emit(const AuthState(status: AuthStatus.unauthenticated));
    });
    on<AuthSessionExpired>((e, emit) async {
      await _repo.logout();
      emit(
        const AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Sesi login berakhir. Silakan masuk kembali.',
        ),
      );
    });
  }
}
