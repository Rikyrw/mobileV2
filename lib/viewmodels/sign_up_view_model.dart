import 'package:flutter/foundation.dart';

import '../services/firebase_account_service.dart';
import '../services/greenpoint_api_service.dart';

enum SignUpResultType {
  success,
  validationError,
  failure,
  googleSuccess,
  googleCancelled,
}

class SignUpResult {
  const SignUpResult._({required this.type, this.email, this.message});

  factory SignUpResult.success(String email) {
    return SignUpResult._(
      type: SignUpResultType.success,
      email: email,
      message: 'Pendaftaran berhasil. Cek email untuk verifikasi.',
    );
  }

  factory SignUpResult.validationError(String message) {
    return SignUpResult._(
      type: SignUpResultType.validationError,
      message: message,
    );
  }

  factory SignUpResult.failure(String message) {
    return SignUpResult._(type: SignUpResultType.failure, message: message);
  }

  factory SignUpResult.googleSuccess({String? email}) {
    return SignUpResult._(
      type: SignUpResultType.googleSuccess,
      email: email,
      message: 'Masuk dengan Google berhasil',
    );
  }

  factory SignUpResult.googleCancelled() {
    return const SignUpResult._(type: SignUpResultType.googleCancelled);
  }

  final SignUpResultType type;
  final String? email;
  final String? message;
}

class SignUpViewModel extends ChangeNotifier {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _creating = false;
  bool _googleLoading = false;

  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;
  bool get creating => _creating;
  bool get googleLoading => _googleLoading;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  Future<SignUpResult> signUp({
    required String fullName,
    required String userName,
    required String email,
    required String address,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    final trimmedFullName = fullName.trim();
    final trimmedUserName = userName.trim();
    final trimmedEmail = email.trim();
    final trimmedAddress = address.trim();
    final trimmedPhone = phone.trim();

    if (trimmedFullName.isEmpty ||
        trimmedUserName.isEmpty ||
        trimmedEmail.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        trimmedPhone.isEmpty) {
      return SignUpResult.validationError('Silakan isi semua field yang wajib');
    }

    if (password != confirmPassword) {
      return SignUpResult.validationError('Password dan konfirmasi tidak sama');
    }

    if (password.length < 8) {
      return SignUpResult.validationError('Password minimal 8 karakter');
    }

    _setCreating(true);
    try {
      await GreenPointApiService.registerNasabah(
        fullName: trimmedFullName,
        userName: trimmedUserName,
        email: trimmedEmail,
        password: password,
        confirmPassword: confirmPassword,
        address: trimmedAddress,
        phone: trimmedPhone,
      );

      return SignUpResult.success(trimmedEmail);
    } catch (e) {
      return SignUpResult.failure(FirebaseAccountService.messageForError(e));
    } finally {
      _setCreating(false);
    }
  }

  Future<SignUpResult> signUpWithGoogle() async {
    _setGoogleLoading(true);
    try {
      final credential = await FirebaseAccountService.signInWithGoogle();
      if (credential == null) {
        return SignUpResult.googleCancelled();
      }

      return SignUpResult.googleSuccess(email: credential.user?.email);
    } catch (e) {
      return SignUpResult.failure(
        FirebaseAccountService.messageForGoogleError(e),
      );
    } finally {
      _setGoogleLoading(false);
    }
  }

  void _setCreating(bool value) {
    if (_creating == value) return;
    _creating = value;
    notifyListeners();
  }

  void _setGoogleLoading(bool value) {
    if (_googleLoading == value) return;
    _googleLoading = value;
    notifyListeners();
  }
}
