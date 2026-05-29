import 'package:flutter/foundation.dart';

import '../services/app_cache_service.dart';
import '../services/firebase_account_service.dart';
import '../services/greenpoint_api_service.dart';

enum PpobProductType { emoney, pln, pulsa }

class PpobSubmitResult {
  const PpobSubmitResult({
    required this.success,
    required this.message,
    this.shouldClearInput = false,
  });

  final bool success;
  final String message;
  final bool shouldClearInput;
}

class PpobFormViewModel extends ChangeNotifier {
  PpobFormViewModel({required this.productType});

  final PpobProductType productType;

  String? selectedKategori;
  String? selectedLayanan;
  String? selectedOperator;
  String? selectedNominal;

  String? _fetchedUserName;
  bool _loadingProfile = false;
  String? _currentEmail;
  int? _nasabahId;
  double? _saldo;
  bool _submitting = false;

  String? get currentEmail => _currentEmail;
  String get userName => _fetchedUserName ?? fallbackUserName;
  bool get submitting => _submitting;
  String get saldoText => 'Saldo: ${formatRupiah((_saldo ?? 0).round())}';
  Object get dashboardArguments => {'email': _currentEmail};

  String get fallbackUserName => 'Haidar Rais';

  Future<void> loadProfile({
    String? emailArgument,
    bool forceRefresh = false,
  }) async {
    if (_loadingProfile) return;
    _setLoadingProfile(true);

    try {
      final firebaseUser = FirebaseAccountService.currentUser;
      final email = emailArgument ?? firebaseUser?.email ?? _currentEmail;
      _currentEmail = email;
      _notify();

      if (email != null && email.isNotEmpty) {
        final record = await AppCacheService.fetchNasabahByEmail(
          email,
          forceRefresh: forceRefresh,
        );

        if (record != null) {
          _fetchedUserName =
              (record['nama_lengkap'] as String?) ??
              (record['user_name'] as String?);
          _nasabahId = (record['id_nasabah'] as num?)?.toInt();
          _saldo = (record['saldo'] as num?)?.toDouble();
          _notify();
        }
      }
    } catch (e) {
      debugPrint('Load user name error: $e');
    } finally {
      _setLoadingProfile(false);
    }
  }

  Future<void> refreshProfile({String? emailArgument}) {
    return loadProfile(emailArgument: emailArgument, forceRefresh: true);
  }

  void setKategori(String? value) {
    selectedKategori = value;
    _notify();
  }

  void setLayanan(String? value) {
    selectedLayanan = value;
    _notify();
  }

  void setOperator(String? value) {
    selectedOperator = value;
    _notify();
  }

  void setNominal(String? value) {
    selectedNominal = value;
    _notify();
  }

  Future<PpobSubmitResult> submit(String target) async {
    if (_submitting) {
      return const PpobSubmitResult(success: false, message: '');
    }

    final trimmedTarget = target.trim();
    final validation = _validate(trimmedTarget);
    if (validation != null) {
      return PpobSubmitResult(success: false, message: validation);
    }

    final nominal = _selectedNominalValue;
    if (nominal == null) {
      return const PpobSubmitResult(
        success: false,
        message: 'Nominal tidak valid.',
      );
    }

    _setSubmitting(true);
    try {
      await GreenPointApiService.submitPpob(
        nasabahId: _nasabahId!,
        jenisPenukaran: _jenisPenukaran,
        nominal: nominal,
        deskripsi: _description(trimmedTarget),
      );
      AppCacheService.invalidateActivity();
      _clearSelections();

      return const PpobSubmitResult(
        success: true,
        message: 'Permintaan berhasil dikirim.',
        shouldClearInput: true,
      );
    } catch (e) {
      debugPrint('Submit ppob error: $e');
      return const PpobSubmitResult(
        success: false,
        message: 'Gagal memproses transaksi.',
      );
    } finally {
      _setSubmitting(false);
    }
  }

  String? _validate(String target) {
    if (target.isEmpty || !_hasRequiredSelections) {
      return 'Lengkapi semua data terlebih dahulu.';
    }

    if (_nasabahId == null || _saldo == null) {
      return 'Data nasabah belum tersedia.';
    }

    final nominal = _selectedNominalValue;
    if (nominal == null) {
      return 'Nominal tidak valid.';
    }

    if ((_saldo ?? 0) < nominal) {
      return 'Saldo tidak mencukupi.';
    }

    return null;
  }

  bool get _hasRequiredSelections {
    switch (productType) {
      case PpobProductType.emoney:
        return selectedKategori != null && selectedLayanan != null;
      case PpobProductType.pln:
        return selectedNominal != null;
      case PpobProductType.pulsa:
        return selectedOperator != null && selectedNominal != null;
    }
  }

  int? get _selectedNominalValue {
    switch (productType) {
      case PpobProductType.emoney:
        return int.tryParse(selectedKategori ?? '');
      case PpobProductType.pln:
      case PpobProductType.pulsa:
        return int.tryParse(selectedNominal ?? '');
    }
  }

  String get _jenisPenukaran {
    switch (productType) {
      case PpobProductType.emoney:
        return selectedLayanan!;
      case PpobProductType.pln:
        return 'pln';
      case PpobProductType.pulsa:
        return 'pulsa';
    }
  }

  String _description(String target) {
    switch (productType) {
      case PpobProductType.emoney:
        return 'emoney:$target';
      case PpobProductType.pln:
        return 'pln:$target';
      case PpobProductType.pulsa:
        return 'pulsa:$selectedOperator:$target';
    }
  }

  void _clearSelections() {
    switch (productType) {
      case PpobProductType.emoney:
        selectedKategori = null;
        selectedLayanan = null;
      case PpobProductType.pln:
        selectedNominal = null;
      case PpobProductType.pulsa:
        selectedOperator = null;
        selectedNominal = null;
    }
    _notify();
  }

  void _setLoadingProfile(bool value) {
    if (_loadingProfile == value) return;
    _loadingProfile = value;
    _notify();
  }

  void _setSubmitting(bool value) {
    if (_submitting == value) return;
    _submitting = value;
    _notify();
  }

  void _notify() {
    notifyListeners();
  }

  static String formatRupiah(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final position = digits.length - i;
      buffer.write(digits[i]);
      if (position > 1 && position % 3 == 1) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString()}';
  }
}
