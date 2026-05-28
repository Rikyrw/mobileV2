import 'package:flutter/foundation.dart';

import '../services/firebase_account_service.dart';

enum SignInResultType {
  success,
  validationError,
  emailVerificationRequired,
  failure,
  cancelled,
  resetSent,
}

class SignInResult {
  const SignInResult._({required this.type, this.email, this.message});

  factory SignInResult.success({String? email}) {
    return SignInResult._(type: SignInResultType.success, email: email);
  }

  factory SignInResult.validationError(String message) {
    return SignInResult._(
      type: SignInResultType.validationError,
      message: message,
    );
  }

  factory SignInResult.emailVerificationRequired(String? email) {
    return SignInResult._(
      type: SignInResultType.emailVerificationRequired,
      email: email,
    );
  }

  factory SignInResult.failure(String message) {
    return SignInResult._(type: SignInResultType.failure, message: message);
  }

  factory SignInResult.cancelled() {
    return const SignInResult._(type: SignInResultType.cancelled);
  }

  factory SignInResult.resetSent(String message) {
    return SignInResult._(type: SignInResultType.resetSent, message: message);
  }

  final SignInResultType type;
  final String? email;
  final String? message;
}

class SignInViewModel extends ChangeNotifier {
  bool _obscurePassword = true;
  bool _loading = false;
  bool _googleLoading = false;
  bool _resetLoading = false;

  bool get obscurePassword => _obscurePassword;
  bool get loading => _loading;
  bool get googleLoading => _googleLoading;
  bool get resetLoading => _resetLoading;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<SignInResult> signIn({
    required String identifier,
    required String password,
  }) async {
    if (identifier.trim().isEmpty || password.isEmpty) {
      return SignInResult.validationError('Please enter email and password');
    }

    _setLoading(true);
    try {
      final user = await FirebaseAccountService.signInWithEmailOrUsername(
        identifier: identifier.trim(),
        password: password,
      );

      return SignInResult.success(email: user['email']?.toString());
    } catch (e) {
      if (FirebaseAccountService.isEmailNotVerifiedError(e)) {
        return SignInResult.emailVerificationRequired(
          FirebaseAccountService.emailFromEmailNotVerifiedError(e),
        );
      }

      return SignInResult.failure(FirebaseAccountService.messageForError(e));
    } finally {
      _setLoading(false);
    }
  }

  Future<SignInResult> sendPasswordReset(String identifier) async {
    if (identifier.trim().isEmpty) {
      return SignInResult.validationError(
        'Masukkan email atau username terlebih dahulu.',
      );
    }

    _setResetLoading(true);
    try {
      await FirebaseAccountService.sendPasswordResetForIdentifier(
        identifier.trim(),
      );

      return SignInResult.resetSent(
        'Jika akun ditemukan, link reset password sudah dikirim ke email Anda.',
      );
    } catch (e) {
      return SignInResult.failure(e.toString());
    } finally {
      _setResetLoading(false);
    }
  }

  Future<SignInResult> signInWithGoogle() async {
    _setGoogleLoading(true);
    try {
      final credential = await FirebaseAccountService.signInWithGoogle();
      if (credential == null) {
        return SignInResult.cancelled();
      }

      return SignInResult.success(email: credential.user?.email);
    } catch (e) {
      return SignInResult.failure(
        FirebaseAccountService.messageForGoogleError(e),
      );
    } finally {
      _setGoogleLoading(false);
    }
  }

  void _setLoading(bool value) {
    if (_loading == value) return;
    _loading = value;
    notifyListeners();
  }

  void _setGoogleLoading(bool value) {
    if (_googleLoading == value) return;
    _googleLoading = value;
    notifyListeners();
  }

  void _setResetLoading(bool value) {
    if (_resetLoading == value) return;
    _resetLoading = value;
    notifyListeners();
  }
}
