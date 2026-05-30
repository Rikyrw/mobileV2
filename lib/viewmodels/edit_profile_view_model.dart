import 'package:flutter/foundation.dart';

import '../services/app_cache_service.dart';
import '../services/firebase_account_service.dart';
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
    : oldEmail = (userData?['email'] ?? '').toString().trim().toLowerCase(),
      oldUserName = (userData?['username'] ?? '').toString().trim(),
      oldNasabahId = userData?['id_nasabah'];

  final String oldEmail;
  final String oldUserName;
  final Object? oldNasabahId;
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
      final usernameMessage = await _usernameAvailabilityMessage(username);
      if (usernameMessage != null) {
        return EditProfileResult.validationError(usernameMessage);
      }

      final response = await GreenPointApiService.updateProfile(
        oldEmail: oldEmail,
        fullName: nama,
        userName: username,
        email: nextEmail,
        address: alamat,
        phone: noHp,
      );

      if (response != null) {
        final updatedProfile = {
          ...response,
          'nama_lengkap': response['nama_lengkap'] ?? nama,
          'user_name': response['user_name'] ?? username,
          'email': response['email'] ?? nextEmail,
          'alamat': response['alamat'] ?? alamat,
          'no_hp': response['no_hp'] ?? noHp,
        };

        AppCacheService.invalidateNasabahByEmail(oldEmail);
        AppCacheService.invalidateNasabahByEmail(nextEmail);
        AppCacheService.putNasabahProfile(updatedProfile);
        await FirebaseAccountService.saveCurrentUserProfileSnapshot(
          updatedProfile,
        );
        return EditProfileResult.success();
      }

      return EditProfileResult.failure('Gagal memperbarui profil');
    } on GreenPointApiException catch (e) {
      if (e.statusCode == 422) {
        return EditProfileResult.validationError(e.message);
      }

      return EditProfileResult.failure(e.message);
    } catch (e) {
      return EditProfileResult.failure('Gagal memperbarui profil. Coba lagi.');
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> _usernameAvailabilityMessage(String username) async {
    if (username.toLowerCase() == oldUserName.toLowerCase()) {
      return null;
    }

    try {
      final existing = await GreenPointApiService.lookupNasabah(
        username,
        includeEmailMatch: false,
      );
      if (existing == null) {
        return null;
      }

      final existingId = _idText(existing['id_nasabah']);
      final currentId = _idText(oldNasabahId);
      if (currentId != null && existingId == currentId) {
        return null;
      }

      final existingEmail = _text(existing['email'])?.toLowerCase();
      if (oldEmail.isNotEmpty && existingEmail == oldEmail) {
        return null;
      }

      return 'Username sudah digunakan. Pilih username lain.';
    } catch (e) {
      debugPrint('Username availability check skipped: $e');
      return null;
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

  String? _idText(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  String? _text(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  void _setLoading(bool value) {
    if (_loading == value) return;
    _loading = value;
    notifyListeners();
  }
}
