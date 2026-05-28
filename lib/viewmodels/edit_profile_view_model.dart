import 'package:flutter/foundation.dart';

import '../services/app_cache_service.dart';
import '../services/greenpoint_api_service.dart';

enum EditProfileResultType { success, validationError, failure }

class EditProfileResult {
  const EditProfileResult._({required this.type, required this.message});

  factory EditProfileResult.success() {
    return const EditProfileResult._(
      type: EditProfileResultType.success,
      message: 'Profil berhasil diperbarui!',
    );
  }

  factory EditProfileResult.validationError(String message) {
    return EditProfileResult._(
      type: EditProfileResultType.validationError,
      message: message,
    );
  }

  factory EditProfileResult.failure(String message) {
    return EditProfileResult._(
      type: EditProfileResultType.failure,
      message: message,
    );
  }

  final EditProfileResultType type;
  final String message;
}

class EditProfileViewModel extends ChangeNotifier {
  EditProfileViewModel({required Map<String, dynamic>? userData})
    : oldEmail = (userData?['email'] ?? '').toString();

  final String oldEmail;
  bool _loading = false;

  bool get loading => _loading;

  Future<EditProfileResult> updateProfile({
    required String fullName,
    required String userName,
    required String email,
    required String address,
    required String phone,
  }) async {
    final nama = fullName.trim();
    final username = userName.trim();
    final nextEmail = email.trim();
    final alamat = address.trim();
    final noHp = phone.trim();

    final validationMessage = _validate(
      fullName: nama,
      userName: username,
      email: nextEmail,
      address: alamat,
      phone: noHp,
    );
    if (validationMessage != null) {
      return EditProfileResult.validationError(validationMessage);
    }

    _setLoading(true);
    try {
      final response = await GreenPointApiService.updateProfile(
        oldEmail: oldEmail,
        fullName: nama,
        userName: username,
        email: nextEmail,
        address: alamat,
        phone: noHp,
      );

      if (response != null) {
        AppCacheService.invalidateNasabahByEmail(oldEmail);
        AppCacheService.putNasabahProfile(response);
        return EditProfileResult.success();
      }

      return EditProfileResult.failure('Gagal memperbarui profil');
    } catch (e) {
      return EditProfileResult.failure('Error: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  String? _validate({
    required String fullName,
    required String userName,
    required String email,
    required String address,
    required String phone,
  }) {
    if (fullName.isEmpty) return 'Nama tidak boleh kosong';
    if (userName.isEmpty) return 'Username tidak boleh kosong';
    if (email.isEmpty) return 'Email tidak boleh kosong';
    if (!_isValidEmail(email)) return 'Format email tidak valid';
    if (address.isEmpty) return 'Alamat tidak boleh kosong';
    if (phone.isEmpty) return 'No Handphone tidak boleh kosong';
    return null;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  void _setLoading(bool value) {
    if (_loading == value) return;
    _loading = value;
    notifyListeners();
  }
}
