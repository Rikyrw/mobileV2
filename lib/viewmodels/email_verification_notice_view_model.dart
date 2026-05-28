import 'package:flutter/foundation.dart';

import '../services/greenpoint_api_service.dart';

class EmailVerificationResult {
  const EmailVerificationResult({required this.message});

  final String message;
}

class EmailVerificationNoticeViewModel extends ChangeNotifier {
  EmailVerificationNoticeViewModel(String? email)
    : email = _normalizeEmail(email);

  final String? email;
  bool _resending = false;

  bool get resending => _resending;

  Future<EmailVerificationResult> resend() async {
    final value = email;
    if (value == null) {
      return const EmailVerificationResult(
        message: 'Email akun tidak ditemukan.',
      );
    }

    _setResending(true);
    try {
      await GreenPointApiService.resendVerificationEmail(value);
      return const EmailVerificationResult(
        message: 'Email verifikasi baru sudah dikirim.',
      );
    } catch (error) {
      return EmailVerificationResult(message: error.toString());
    } finally {
      _setResending(false);
    }
  }

  void _setResending(bool value) {
    if (_resending == value) return;
    _resending = value;
    notifyListeners();
  }

  static String? _normalizeEmail(String? email) {
    final value = email?.trim();
    return value == null || value.isEmpty ? null : value;
  }
}
