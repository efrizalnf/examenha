import 'package:flutter/services.dart';

import '../constants/app_constants.dart';

/// Bridge ke native Android (MethodChannel + EventChannel).
/// Mengatur FLAG_SECURE, FLAG_KEEP_SCREEN_ON, LockTask, dan beep.
class SecurityService {
  static const _methodChannel = MethodChannel(
    AppConstants.securityMethodChannel,
  );
  static const _eventChannel = EventChannel(AppConstants.securityEventChannel);

  Stream<String>? _eventStream;

  /// Stream event dari native: 'userLeaveHint' | 'windowFocusLost'
  Stream<String> get securityEvents {
    _eventStream ??= _eventChannel.receiveBroadcastStream().map(
      (event) => event.toString(),
    );
    return _eventStream!;
  }

  /// Aktifkan mode ujian: FLAG_SECURE + FLAG_KEEP_SCREEN_ON + LockTask
  Future<void> startExam() async {
    try {
      await _methodChannel.invokeMethod<void>('startExam');
    } on PlatformException {
      // Non-fatal: fitur mungkin tidak tersedia di platform lain
    }
  }

  /// Nonaktifkan mode ujian dan lepaskan semua flag
  Future<void> stopExam() async {
    try {
      await _methodChannel.invokeMethod<void>('stopExam');
    } on PlatformException {
      // Non-fatal
    }
  }

  /// Mainkan suara beep peringatan
  Future<void> beep() async {
    try {
      await _methodChannel.invokeMethod<void>('beep');
    } on PlatformException {
      // Non-fatal
    }
  }
}
