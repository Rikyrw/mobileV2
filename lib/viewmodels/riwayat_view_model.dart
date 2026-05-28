import 'package:flutter/foundation.dart';

import '../services/app_cache_service.dart';
import '../services/firebase_account_service.dart';

class RiwayatDummyData {
  const RiwayatDummyData({
    required this.greeting,
    required this.userName,
    required this.title,
    required this.subtitle,
    required this.fromDate,
    required this.untilDate,
    required this.note,
    required this.buttonText,
    required this.emptyState,
  });

  final String greeting;
  final String userName;
  final String title;
  final String subtitle;
  final String fromDate;
  final String untilDate;
  final String note;
  final String buttonText;
  final String emptyState;
}

class RiwayatViewModel extends ChangeNotifier {
  static const int pageSize = 8;
  static const dummyData = RiwayatDummyData(
    greeting: 'Halo,',
    userName: 'Haidar Rais',
    title: 'Riwayat Setor Sampah',
    subtitle: 'Daftar Riwayat Setor Sampah',
    fromDate: '20 - 11 - 2025',
    untilDate: '20 - 11 - 2025',
    note:
        'Catatan:\n- Periode mutasi yang dapat dipilih 7 hari.\n- Mutasi setor sampah maksimum 31 hari yang lalu.',
    buttonText: 'Tampilkan',
    emptyState: 'Memuat data riwayat...',
  );

  String? _fetchedUserName;
  bool _loadingProfile = false;
  int? _nasabahId;
  bool _loadingRiwayat = false;
  List<Map<String, dynamic>> _riwayatItems = [];
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _hasSearched = false;
  bool _hasLoadedRiwayat = false;
  int _currentPage = 0;
  bool _hasNextPage = false;
  String? _errorMessage;

  String get userName => _fetchedUserName ?? dummyData.userName;
  bool get loadingRiwayat => _loadingRiwayat;
  bool get hasSearched => _hasSearched;
  DateTime? get fromDate => _fromDate;
  DateTime? get toDate => _toDate;
  int? get nasabahId => _nasabahId;
  int get currentPage => _currentPage;
  bool get hasNextPage => _hasNextPage;
  String? get errorMessage => _errorMessage;
  bool get canSearch =>
      _nasabahId != null && _fromDate != null && _toDate != null;

  List<Map<String, dynamic>> get visibleItems {
    if (_hasSearched) return List.unmodifiable(_riwayatItems);
    return List.unmodifiable(
      _riwayatItems.where(
        (item) => (item['status'] ?? '').toString().toLowerCase() == 'pending',
      ),
    );
  }

  Future<void> loadProfile({String? emailArgument}) async {
    if (_loadingProfile) return;
    _setLoadingProfile(true);

    try {
      final firebaseUser = FirebaseAccountService.currentUser;
      final email = emailArgument ?? firebaseUser?.email;

      if (email != null && email.isNotEmpty) {
        final record = await AppCacheService.fetchNasabahByEmail(email);

        if (record != null) {
          final nasabahId = (record['id_nasabah'] as num?)?.toInt();
          _fetchedUserName =
              (record['nama_lengkap'] as String?) ??
              (record['user_name'] as String?);
          _nasabahId = nasabahId;
          _notify();

          if (nasabahId != null && !_hasLoadedRiwayat) {
            await loadRiwayat(pendingOnly: true);
          }
        }
      }
    } catch (e) {
      debugPrint('Load user name error: $e');
    } finally {
      _setLoadingProfile(false);
    }
  }

  Future<void> loadRiwayat({
    DateTime? from,
    DateTime? to,
    bool pendingOnly = false,
    int page = 0,
    bool forceRefresh = false,
  }) async {
    final nasabahId = _nasabahId;
    if (nasabahId == null || _loadingRiwayat) return;

    _setLoadingRiwayat(true);
    _errorMessage = null;
    try {
      final res = await AppCacheService.fetchSetorHistoryPage(
        nasabahId: nasabahId,
        page: page,
        pageSize: pageSize,
        pendingOnly: pendingOnly,
        from: pendingOnly ? null : from,
        to: pendingOnly ? null : to,
        forceRefresh: forceRefresh,
      );

      _riwayatItems = res.items.map(_mapRiwayatItem).toList();
      _currentPage = page;
      _hasNextPage = res.hasNextPage;
      _hasLoadedRiwayat = true;
      _notify();
    } catch (e) {
      debugPrint('Load riwayat error: $e');
      _errorMessage = 'Gagal memuat riwayat: $e';
      _notify();
    } finally {
      _setLoadingRiwayat(false);
    }
  }

  void applyPickedDate({required bool isFrom, required DateTime picked}) {
    if (isFrom) {
      _fromDate = picked;
      if (_toDate != null && _toDate!.isBefore(picked)) {
        _toDate = picked;
      }
    } else {
      _toDate = picked;
      if (_fromDate != null && _fromDate!.isAfter(picked)) {
        _fromDate = picked;
      }
    }
    _notify();
  }

  String? validateSearchRange() {
    final from = _fromDate;
    final to = _toDate;
    if (from == null || to == null) return null;
    return to.difference(from).inDays <= 7
        ? null
        : 'Periode mutasi maksimal 7 hari.';
  }

  Future<void> search() async {
    _hasSearched = true;
    _currentPage = 0;
    _hasNextPage = false;
    _notify();
    await loadRiwayat(from: _fromDate, to: _toDate, page: 0);
  }

  void loadPreviousPage() {
    if (_nasabahId == null || _currentPage == 0) return;
    loadRiwayat(
      from: _hasSearched ? _fromDate : null,
      to: _hasSearched ? _toDate : null,
      pendingOnly: !_hasSearched,
      page: _currentPage - 1,
    );
  }

  void loadNextPage() {
    if (_nasabahId == null || !_hasNextPage) return;
    loadRiwayat(
      from: _hasSearched ? _fromDate : null,
      to: _hasSearched ? _toDate : null,
      pendingOnly: !_hasSearched,
      page: _currentPage + 1,
    );
  }

  void clearError() {
    _errorMessage = null;
  }

  Map<String, dynamic> _mapRiwayatItem(Map<String, dynamic> e) {
    return {
      'id': e['id_transaksi_setor'] as int,
      'total': (e['total_nilai'] as num).toDouble(),
      'tanggal': e['tanggal_setor']?.toString(),
      'status': e['status']?.toString() ?? '-',
      'details': (e['detail_setor'] as List<dynamic>? ?? [])
          .map(
            (d) => {
              'nama': (d['jenis_sampah']?['nama_jenis'] ?? '-').toString(),
              'berat': (d['berat_kg'] as num?)?.toDouble() ?? 0.0,
              'subtotal': (d['subtotal'] as num?)?.toDouble() ?? 0.0,
            },
          )
          .toList(),
    };
  }

  void _setLoadingProfile(bool value) {
    if (_loadingProfile == value) return;
    _loadingProfile = value;
    _notify();
  }

  void _setLoadingRiwayat(bool value) {
    if (_loadingRiwayat == value) return;
    _loadingRiwayat = value;
    _notify();
  }

  void _notify() {
    notifyListeners();
  }

  static String formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final date = DateTime.parse(raw);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      return '$day-$month-$year';
    } catch (_) {
      return raw;
    }
  }

  static String formatRupiah(int value) {
    if (value == 0) return 'Rp 0';
    final s = value.toString();
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return 'Rp ${s.replaceAllMapped(reg, (m) => '.')}';
  }

  static String formatDateQuery(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$year-$month-$day';
  }

  static String formatWeight(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }
}
