import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

class SecurityFailure extends Failure {
  const SecurityFailure(super.message);
}

/// Error dari API ExamForm; `code` mengikuti tabel kode error di docs/API.md.
class ApiFailure extends Failure {
  final String code;
  const ApiFailure(super.message, {required this.code});

  bool get isNetwork => code == 'NETWORK';

  @override
  List<Object> get props => [message, code];
}
