import 'package:flutter/foundation.dart';

import '../services/app_cache_service.dart';
import '../services/firebase_account_service.dart';

class TransaksiDummyData {
  const TransaksiDummyData({
    required this.greeting,
    required this.userName,
    required this.title,
    required this.subtitle,
    required this.emptyState,
  });

  final String greeting;
  final String userName;
  final String title;
  final String subtitle;
  final String emptyState;
}

class TransaksiItem {
  const TransaksiItem({
    required this.transactionId,
    required this.productName,
    required this.target,
    required this.amount,
    required this.date,
    required this.status,
  });

  final String transactionId;
  final String productName;
  final String target;
  final String amount;
  final String date;
  final String status;
}

class TransaksiViewModel extends ChangeNotifier {
  static const int pageSize = 8;
  static const dummyData = TransaksiDummyData(
    greeting: 'Halo,',
    userName: 'Haidar Rais',
    title: 'Daftar Transaksi PPOB',
    subtitle: 'Transaksi PPOB',
    emptyState: 'Memuat data transaksi...',
  );

  String? _fetchedUserName;
  bool _loadingProfile = false;
  String? _currentEmail;
  int? _nasabahId;
  bool _loadingTransaksi = false;
  List<TransaksiItem> _transactions = [];
  bool _hasLoadedTransactions = false;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _hasSearched = false;
  int _currentPage = 0;
  bool _hasNextPage = false;
  String? _errorMessage;

  String get userName => _fetchedUserName ?? dummyData.userName;
  bool get loadingTransaksi => _loadingTransaksi;
  bool get hasSearched => _hasSearched;
  DateTime? get fromDate => _fromDate;
  DateTime? get toDate => _toDate;
  int? get nasabahId => _nasabahId;
  int get currentPage => _currentPage;
  bool get hasNextPage => _hasNextPage;
  String? get errorMessage => _errorMessage;
  bool get canSearch =>
      _nasabahId != null && _fromDate != null && _toDate != null;

  List<TransaksiItem> get visibleTransactions {
    if (_hasSearched) return List.unmodifiable(_transactions);
    return List.unmodifiable(
      _transactions.where((item) => item.status.toLowerCase() == 'pending'),
    );
  }

  Future<void> loadProfile({
    String? emailArgument,
    bool forceRefresh = false,
    bool loadInitialTransactions = true,
  }) async {
    if (_loadingProfile) return;
    _setLoadingProfile(true);

    try {
      final firebaseUser = FirebaseAccountService.currentUser;
      final email = emailArgument ?? firebaseUser?.email ?? _currentEmail;
      _currentEmail = email;

      if (email != null && email.isNotEmpty) {
        final record = await AppCacheService.fetchNasabahByEmail(
          email,
          forceRefresh: forceRefresh,
        );

        if (record != null) {
          final nasabahId = (record['id_nasabah'] as num?)?.toInt();
          _fetchedUserName =
              (record['nama_lengkap'] as String?) ??
              (record['user_name'] as String?);
          _nasabahId = nasabahId;
          _notify();

          if (nasabahId != null &&
              loadInitialTransactions &&
              !_hasLoadedTransactions) {
            await loadTransactions(
              pendingOnly: true,
              forceRefresh: forceRefresh,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Load user name error: $e');
    } finally {
      _setLoadingProfile(false);
    }
  }

  Future<void> refresh({String? emailArgument}) async {
    await loadProfile(
      emailArgument: emailArgument,
      forceRefresh: true,
      loadInitialTransactions: false,
    );
    await loadTransactions(
      pendingOnly: !_hasSearched,
      page: _currentPage,
      forceRefresh: true,
    );
  }

  Future<void> loadTransactions({
    bool pendingOnly = false,
    int page = 0,
    bool forceRefresh = false,
  }) async {
    final nasabahId = _nasabahId;
    if (nasabahId == null || _loadingTransaksi) return;

    _setLoadingTransaksi(true);
    _errorMessage = null;
    try {
      final res = await AppCacheService.fetchPpobTransactionPage(
        nasabahId: nasabahId,
        page: page,
        pageSize: pageSize,
        pendingOnly: pendingOnly,
        from: pendingOnly ? null : _fromDate,
        to: pendingOnly ? null : _toDate,
        forceRefresh: forceRefresh,
      );

      _transactions = res.items.map(_mapTransactionItem).toList();
      _currentPage = page;
      _hasNextPage = res.hasNextPage;
      _hasLoadedTransactions = true;
      _notify();
    } catch (e) {
      debugPrint('Load transaksi error: $e');
      _errorMessage = 'Gagal memuat transaksi: $e';
      _notify();
    } finally {
      _setLoadingTransaksi(false);
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
    await loadTransactions(page: 0);
  }

  void loadPreviousPage() {
    if (_nasabahId == null || _currentPage == 0) return;
    loadTransactions(pendingOnly: !_hasSearched, page: _currentPage - 1);
  }

  void loadNextPage() {
    if (_nasabahId == null || !_hasNextPage) return;
    loadTransactions(pendingOnly: !_hasSearched, page: _currentPage + 1);
  }

  void clearError() {
    _errorMessage = null;
  }

  void _setLoadingProfile(bool value) {
    if (_loadingProfile == value) return;
    _loadingProfile = value;
    _notify();
  }

  void _setLoadingTransaksi(bool value) {
    if (_loadingTransaksi == value) return;
    _loadingTransaksi = value;
    _notify();
  }

  TransaksiItem _mapTransactionItem(Map<String, dynamic> e) {
    final id = e['id_penarikan'] as int?;
    final nominal = (e['nominal'] as num?)?.toDouble() ?? 0.0;
    return TransaksiItem(
      transactionId: id == null ? '-' : 'TRX-$id',
      productName: (e['jenis_penukaran']?.toString() ?? '-').toUpperCase(),
      target: formatPpobTarget(e['deskripsi']?.toString() ?? ''),
      amount: formatRupiah(nominal.round()),
      date: formatDate(e['tanggal_pengajuan']?.toString()),
      status: e['status']?.toString() ?? '-',
    );
  }

  void _notify() {
    notifyListeners();
  }

  static String formatRupiah(int value) {
    if (value == 0) return 'Rp 0';
    final s = value.toString();
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return 'Rp ${s.replaceAllMapped(reg, (m) => '.')}';
  }

  static String formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final normalized = raw.contains('T')
          ? raw.split('T').first
          : (raw.contains(' ') ? raw.split(' ').first : raw);
      final date = DateTime.parse(normalized);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      return '$day-$month-$year';
    } catch (_) {
      return raw;
    }
  }

  static String formatDateQuery(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$year-$month-$day';
  }

  static String formatPpobTarget(String raw) {
    if (raw.isEmpty) return '-';
    if (raw.startsWith('emoney:')) {
      return 'No Tujuan ${raw.replaceFirst('emoney:', '')}';
    }
    if (raw.startsWith('pulsa:')) {
      final parts = raw.split(':');
      if (parts.length >= 3) {
        final operator = parts[1].toUpperCase();
        final noHp = parts.sublist(2).join(':');
        return 'No HP $noHp ($operator)';
      }
      return 'No HP ${raw.replaceFirst('pulsa:', '')}';
    }
    return raw;
  }
}
