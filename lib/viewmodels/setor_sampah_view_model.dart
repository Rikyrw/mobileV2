import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/app_cache_service.dart';
import '../services/firebase_account_service.dart';
import '../services/greenpoint_api_service.dart';
import '../services/waste_photo_validation_service.dart';

class SetorSampahDummyData {
  const SetorSampahDummyData({
    required this.userName,
    required this.saldo,
    required this.totalHarga,
  });

  final String userName;
  final String saldo;
  final String totalHarga;
}

class WasteItem {
  WasteItem({
    required this.jenisId,
    required this.name,
    required this.price,
    this.selected = false,
    TextEditingController? weightController,
    List<XFile>? images,
  }) : weightController = weightController ?? TextEditingController(),
       images = images ?? [];

  final int jenisId;
  String name;
  double price;
  bool selected;
  final TextEditingController weightController;
  final List<XFile> images;

  void dispose() {
    weightController.dispose();
  }
}

class AddWasteResult {
  const AddWasteResult._({required this.success, required this.message});

  const AddWasteResult.success() : this._(success: true, message: '');
  const AddWasteResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;
  final String message;
}

class SetorPhotoResult {
  const SetorPhotoResult._({required this.message, this.warningMessage});

  const SetorPhotoResult.empty() : this._(message: '');
  const SetorPhotoResult.message(String message) : this._(message: message);
  const SetorPhotoResult.warning({
    required String message,
    required String warningMessage,
  }) : this._(message: message, warningMessage: warningMessage);

  final String message;
  final String? warningMessage;

  bool get hasMessage => message.isNotEmpty;
  bool get hasWarning => warningMessage != null && warningMessage!.isNotEmpty;
}

class SetorSubmitResult {
  const SetorSubmitResult._({
    required this.success,
    required this.message,
    this.profileArguments,
  });

  factory SetorSubmitResult.failure(String message) {
    return SetorSubmitResult._(success: false, message: message);
  }

  factory SetorSubmitResult.success({
    required String message,
    required Object? profileArguments,
  }) {
    return SetorSubmitResult._(
      success: true,
      message: message,
      profileArguments: profileArguments,
    );
  }

  final bool success;
  final String message;
  final Object? profileArguments;
}

class SetorSampahViewModel extends ChangeNotifier {
  SetorSampahViewModel({
    ImagePicker? picker,
    WastePhotoValidationService? photoValidator,
  }) : _picker = picker ?? ImagePicker(),
       _photoValidator = photoValidator ?? WastePhotoValidationService();

  static const int maxPhotosPerItem = 3;
  static const dummyData = SetorSampahDummyData(
    userName: 'User',
    saldo: 'Rp 0',
    totalHarga: 'Rp 0',
  );

  final TextEditingController namaController = TextEditingController();
  final TextEditingController alamatController = TextEditingController();
  final ImagePicker _picker;
  final WastePhotoValidationService _photoValidator;

  final List<WasteItem> _wasteItems = [];
  List<Map<String, dynamic>> _wasteTypes = [];
  String? _fetchedUserName;
  String? _fetchedFullName;
  String? _fetchedAddress;
  double? _saldo;
  String? _currentEmail;
  int? _nasabahId;
  bool _loadingProfile = false;
  bool _loadingWasteTypes = false;
  bool _submitting = false;
  bool _validatingPhoto = false;
  String? _errorMessage;

  List<WasteItem> get wasteItems => List.unmodifiable(_wasteItems);
  List<Map<String, dynamic>> get wasteTypes => List.unmodifiable(_wasteTypes);
  String? get currentEmail => _currentEmail;
  bool get loadingWasteTypes => _loadingWasteTypes;
  bool get submitting => _submitting;
  bool get validatingPhoto => _validatingPhoto;
  String? get errorMessage => _errorMessage;
  Object get profileArguments => {'email': _currentEmail};
  String get userName => _fetchedUserName ?? dummyData.userName;
  String get senderName {
    final typed = namaController.text.trim();
    return typed.isNotEmpty
        ? typed
        : (_fetchedFullName ?? _fetchedUserName ?? '');
  }

  String get senderAddress {
    final typed = alamatController.text.trim();
    return typed.isNotEmpty ? typed : (_fetchedAddress ?? '');
  }

  String get saldoText {
    if (_saldo == null) {
      return _loadingProfile ? 'Memuat...' : dummyData.saldo;
    }
    return formatRupiah(_saldo!.round());
  }

  bool get showAjukanButton => _hasValidSelection();
  int get totalHarga => computeTotal();

  Future<void> loadUserProfile({String? emailArgument}) async {
    if (_loadingProfile) return;
    _setLoadingProfile(true);

    try {
      final firebaseUser = FirebaseAccountService.currentUser;
      final email = emailArgument ?? firebaseUser?.email;
      _currentEmail = email;
      _notify();

      if (email == null || email.isEmpty) return;

      final record = await AppCacheService.fetchNasabahByEmail(
        email,
        forceRefresh: true,
      );

      if (record == null) return;

      _nasabahId = (record['id_nasabah'] as num?)?.toInt();
      final fullName = record['nama_lengkap'] as String?;
      final userName = record['user_name'] as String?;
      final address = record['alamat'] as String?;
      _fetchedUserName = fullName ?? userName;
      _fetchedFullName = fullName;
      _fetchedAddress = address;
      _saldo = (record['saldo'] as num?)?.toDouble();

      if (namaController.text.trim().isEmpty) {
        final nameToUse = fullName ?? userName;
        if (nameToUse != null && nameToUse.isNotEmpty) {
          namaController.text = nameToUse;
        }
      }

      if (alamatController.text.trim().isEmpty &&
          address != null &&
          address.isNotEmpty) {
        alamatController.text = address;
      }
      _notify();
    } catch (e) {
      debugPrint('Load user name error: $e');
    } finally {
      _setLoadingProfile(false);
    }
  }

  Future<void> loadWasteTypes() async {
    if (_loadingWasteTypes) return;
    _setLoadingWasteTypes(true);

    try {
      _wasteTypes = await AppCacheService.fetchWasteTypes();
      _notify();
    } catch (e) {
      debugPrint('Error loading waste types: $e');
      _errorMessage = 'Gagal memuat jenis sampah';
      _notify();
    } finally {
      _setLoadingWasteTypes(false);
    }
  }

  void clearError() {
    _errorMessage = null;
  }

  void toggleWasteItem(WasteItem item, bool selected) {
    item.selected = selected;
    _notify();
  }

  void refreshTotals() {
    _notify();
  }

  AddWasteResult addOrUpdateWaste({
    required int jenisId,
    required String name,
    required double price,
    required String rawWeight,
  }) {
    final normalized = rawWeight.replaceAll(',', '.').trim();
    final weight = double.tryParse(normalized) ?? 0.0;
    if (weight < 1) {
      return const AddWasteResult.failure('Minimal 1 kg.');
    }

    final existing = _wasteItems
        .where((item) => item.jenisId == jenisId)
        .toList();
    if (existing.isNotEmpty) {
      final item = existing.first;
      final currentRaw = item.weightController.text.replaceAll(',', '.').trim();
      final currentWeight = double.tryParse(currentRaw) ?? 0.0;
      item.weightController.text = (currentWeight + weight).toString();
      item.selected = true;
    } else {
      final item = WasteItem(
        jenisId: jenisId,
        name: name,
        price: price,
        selected: true,
      );
      item.weightController.text = normalized;
      _wasteItems.add(item);
    }

    _notify();
    return const AddWasteResult.success();
  }

  void removeImage(WasteItem item, XFile image) {
    item.images.remove(image);
    _notify();
  }

  void removeWasteItem(WasteItem item) {
    if (_wasteItems.remove(item)) {
      item.dispose();
      _notify();
    }
  }

  Future<SetorPhotoResult> pickAndValidateImage(
    WasteItem item,
    ImageSource source,
  ) async {
    if (_validatingPhoto) {
      return const SetorPhotoResult.message(
        'Tunggu sampai pemeriksaan foto selesai.',
      );
    }

    if (item.images.length >= maxPhotosPerItem) {
      return const SetorPhotoResult.message(
        'Maksimal 3 foto per jenis sampah.',
      );
    }

    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
      );
    } catch (e) {
      return SetorPhotoResult.message('Gagal mengambil gambar: $e');
    }

    if (picked == null) return const SetorPhotoResult.empty();

    return _validateAndAddImage(item, picked);
  }

  Future<SetorPhotoResult> _validateAndAddImage(
    WasteItem item,
    XFile picked,
  ) async {
    final allowedWasteNames = _wasteTypes
        .map((wasteType) => wasteType['name']?.toString().trim() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();

    _setValidatingPhoto(true);

    try {
      final validation = await _photoValidator.validateWastePhoto(
        image: picked,
        selectedWasteName: item.name,
        allowedWasteNames: allowedWasteNames,
      );

      if (!validation.isAccepted) {
        return SetorPhotoResult.warning(
          message: '',
          warningMessage: validation.warningMessage(item.name),
        );
      }

      if (!_wasteItems.contains(item)) {
        return const SetorPhotoResult.empty();
      }

      if (item.images.length >= maxPhotosPerItem) {
        return const SetorPhotoResult.message(
          'Maksimal 3 foto per jenis sampah.',
        );
      }

      item.images.add(picked);
      _notify();
      return SetorPhotoResult.message('Foto ${item.name} berhasil terdeteksi.');
    } on WastePhotoValidationException catch (e) {
      return SetorPhotoResult.warning(
        message: '',
        warningMessage: WastePhotoValidationResult.rejected(
          e.message,
        ).warningMessage(item.name),
      );
    } catch (e) {
      debugPrint('Waste photo validation error: $e');
      return SetorPhotoResult.warning(
        message: '',
        warningMessage: WastePhotoValidationResult.rejected(
          'Validasi foto gagal. Pastikan koneksi internet aktif lalu coba lagi.',
        ).warningMessage(item.name),
      );
    } finally {
      _setValidatingPhoto(false);
    }
  }

  Future<SetorSubmitResult> submitSetorSampah() async {
    if (_submitting) {
      return SetorSubmitResult.failure('');
    }

    final nasabahId = _nasabahId;
    if (nasabahId == null) {
      return SetorSubmitResult.failure('Data nasabah belum tersedia.');
    }

    final selectedItems = _selectedValidItems();
    if (selectedItems.isEmpty) {
      return SetorSubmitResult.failure(
        'Pilih jenis sampah dan isi berat minimal 1 kg.',
      );
    }

    if (selectedItems.any((item) => item.images.isEmpty)) {
      return SetorSubmitResult.failure(
        'Foto wajib diisi untuk setiap jenis sampah yang dipilih.',
      );
    }

    final totalNilai = computeTotal();
    if (totalNilai <= 0) {
      return SetorSubmitResult.failure('Total harga belum valid.');
    }

    _setSubmitting(true);
    try {
      final setorItems = selectedItems.map((item) {
        return GreenPointSetorItem(
          idJenis: item.jenisId,
          beratKg: _itemWeight(item),
          photos: item.images,
        );
      }).toList();

      await GreenPointApiService.submitSetorSampah(
        nasabahId: nasabahId,
        items: setorItems,
      );
      AppCacheService.invalidateActivity();

      final arguments = _currentEmail == null ? null : {'email': _currentEmail};
      _clearWasteItems();
      return SetorSubmitResult.success(
        message: 'Setor sampah berhasil diajukan.',
        profileArguments: arguments,
      );
    } catch (e) {
      return SetorSubmitResult.failure('Gagal mengajukan setor sampah: $e');
    } finally {
      _setSubmitting(false);
    }
  }

  int computeTotal() {
    double total = 0.0;
    for (final item in _wasteItems) {
      if (!item.selected) continue;

      final weight = _itemWeight(item);
      if (weight >= 1) {
        total += item.price * weight;
      }
    }
    return total.round();
  }

  bool _hasValidSelection() {
    for (final item in _wasteItems) {
      if (item.selected && _itemWeight(item) >= 1) {
        return true;
      }
    }
    return false;
  }

  List<WasteItem> _selectedValidItems() {
    return _wasteItems.where((item) {
      return item.selected && _itemWeight(item) >= 1;
    }).toList();
  }

  double _itemWeight(WasteItem item) {
    final raw = item.weightController.text.replaceAll(',', '.').trim();
    return double.tryParse(raw) ?? 0.0;
  }

  void _clearWasteItems() {
    for (final item in _wasteItems) {
      item.dispose();
    }
    _wasteItems.clear();
    _notify();
  }

  void _setLoadingProfile(bool value) {
    if (_loadingProfile == value) return;
    _loadingProfile = value;
    _notify();
  }

  void _setLoadingWasteTypes(bool value) {
    if (_loadingWasteTypes == value) return;
    _loadingWasteTypes = value;
    _notify();
  }

  void _setSubmitting(bool value) {
    if (_submitting == value) return;
    _submitting = value;
    _notify();
  }

  void _setValidatingPhoto(bool value) {
    if (_validatingPhoto == value) return;
    _validatingPhoto = value;
    _notify();
  }

  void _notify() {
    notifyListeners();
  }

  @override
  void dispose() {
    namaController.dispose();
    alamatController.dispose();
    for (final item in _wasteItems) {
      item.dispose();
    }
    super.dispose();
  }

  static String formatRupiah(int value) {
    if (value == 0) return 'Rp 0';
    final text = value.toString();
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return 'Rp ${text.replaceAllMapped(reg, (match) => '.')}';
  }
}
