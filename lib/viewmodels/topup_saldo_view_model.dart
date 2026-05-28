import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../services/app_cache_service.dart';
import '../services/firebase_account_service.dart';
import '../services/greenpoint_api_service.dart';

class TopupHistoryItem {
  const TopupHistoryItem({
    required this.date,
    required this.amount,
    required this.status,
    required this.orderId,
  });

  final String date;
  final String amount;
  final String status;
  final String orderId;
}

class TopupSubmitResult {
  const TopupSubmitResult._({this.message, this.redirectUrl, this.orderId});

  factory TopupSubmitResult.message(String message) {
    return TopupSubmitResult._(message: message);
  }

  factory TopupSubmitResult.payment({
    required String redirectUrl,
    required String orderId,
  }) {
    return TopupSubmitResult._(redirectUrl: redirectUrl, orderId: orderId);
  }

  final String? message;
  final String? redirectUrl;
  final String? orderId;

  bool get hasPayment => redirectUrl != null && orderId != null;
}

class TopupSaldoViewModel extends ChangeNotifier {
  static const minNominal = 10000;
  static const maxNominal = 10000000;
  static const _createTopupPath = '/api/mobile/nasabah/topup';
  static const _defaultCreateTopupUrl =
      'http://localhost:8000/api/mobile/nasabah/topup';

  String? _currentEmail;
  int? _nasabahId;
  String? _fullName;
  String? _phone;
  double? _saldo;
  List<TopupHistoryItem> _topupHistory = [];
  DateTime? _topupHistoryDate;
  bool _loadingProfile = false;
  bool _loadingTopupHistory = false;
  bool _submitting = false;
  String? _errorMessage;

  String? get currentEmail => _currentEmail;
  int? get nasabahId => _nasabahId;
  DateTime? get topupHistoryDate => _topupHistoryDate;
  bool get loadingTopupHistory => _loadingTopupHistory;
  bool get submitting => _submitting;
  String? get errorMessage => _errorMessage;
  List<TopupHistoryItem> get topupHistory => List.unmodifiable(_topupHistory);
  Object get profileArguments => {'email': _currentEmail};
  String get saldoText => _saldo == null ? '-' : formatRupiah(_saldo ?? 0);

  Future<void> loadUserProfile({String? emailArgument}) async {
    if (_loadingProfile) return;
    _setLoadingProfile(true);

    try {
      final firebaseUser = FirebaseAccountService.currentUser;
      final email = emailArgument ?? firebaseUser?.email;
      _currentEmail = email;
      _notify();

      if (email != null && email.isNotEmpty) {
        final record = await AppCacheService.fetchNasabahByEmail(
          email,
          forceRefresh: true,
        );

        if (record != null) {
          _nasabahId = (record['id_nasabah'] as num?)?.toInt();
          _fullName = record['nama_lengkap'] as String?;
          _phone = record['no_hp'] as String?;
          _saldo = (record['saldo'] as num?)?.toDouble();
          _notify();

          final nasabahId = _nasabahId;
          if (nasabahId != null) {
            await loadTopupHistory();
          }
        }
      }
    } catch (e) {
      debugPrint('Load topup profile error: $e');
    } finally {
      _setLoadingProfile(false);
    }
  }

  Future<void> loadTopupHistory() async {
    final nasabahId = _nasabahId;
    if (nasabahId == null || _loadingTopupHistory) return;

    _setLoadingTopupHistory(true);
    try {
      final rows = await GreenPointApiService.fetchTopupHistory(
        nasabahId: nasabahId,
        date: _topupHistoryDate,
        limit: 5,
      );
      _topupHistory = rows.map(_mapTopupHistoryItem).toList();
      _notify();
    } catch (e) {
      debugPrint('Load topup history error: $e');
      _errorMessage = 'Gagal memuat riwayat top up.';
      _notify();
    } finally {
      _setLoadingTopupHistory(false);
    }
  }

  Future<void> setTopupHistoryDate(DateTime? date) async {
    _topupHistoryDate = date;
    _notify();
    await loadTopupHistory();
  }

  Future<TopupSubmitResult> submitTopup(int? nominal) async {
    if (_submitting) return TopupSubmitResult.message('');

    if (nominal == null) {
      return TopupSubmitResult.message('Nominal wajib diisi.');
    }

    if (nominal < minNominal || nominal > maxNominal) {
      return TopupSubmitResult.message(
        'Nominal harus antara Rp 10.000 - Rp 10.000.000.',
      );
    }

    if (_nasabahId == null) {
      return TopupSubmitResult.message(
        'Data nasabah belum tersedia. Coba buka ulang halaman ini.',
      );
    }

    _setSubmitting(true);
    try {
      final response = await _createTopupTransaction(nominal);

      if (response.statusCode == 401) {
        return TopupSubmitResult.message('Silakan login terlebih dahulu.');
      }

      if (response.statusCode == 404) {
        return TopupSubmitResult.message(
          'Endpoint top up tidak ditemukan. Cek TOPUP_API_URL atau GREENPOINT_API_BASE_URL.',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message =
            _extractMessage(response.body) ?? 'Gagal membuat transaksi top up.';
        return TopupSubmitResult.message(message);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final redirectUrl = data['redirect_url'] as String?;
      final orderId = data['order_id'] as String?;

      if (redirectUrl == null || redirectUrl.isEmpty || orderId == null) {
        return TopupSubmitResult.message('Data pembayaran tidak lengkap.');
      }

      return TopupSubmitResult.payment(
        redirectUrl: redirectUrl,
        orderId: orderId,
      );
    } catch (e) {
      debugPrint('Topup submit error: $e');
      return TopupSubmitResult.message(_friendlyTopupError(e));
    } finally {
      _setSubmitting(false);
    }
  }

  Future<String> checkTopupStatus(String orderId) async {
    try {
      final res = await GreenPointApiService.checkTopupStatus(orderId);
      final status = (res['status'] as String?) ?? 'pending';

      if (status == 'not_found') {
        return 'Transaksi tidak ditemukan.';
      }

      final transactionStatus =
          (res['transaction_status'] as String?) ?? status;

      if (transactionStatus == 'settlement' || transactionStatus == 'capture') {
        AppCacheService.invalidateNasabahByEmail(_currentEmail);
        await loadUserProfile(emailArgument: _currentEmail);
        await loadTopupHistory();
        return 'Top up berhasil.';
      } else if (transactionStatus == 'pending') {
        return 'Pembayaran masih pending.';
      } else {
        return 'Status pembayaran: $transactionStatus';
      }
    } catch (e) {
      debugPrint('Check topup status error: $e');
      return 'Gagal memeriksa status pembayaran.';
    }
  }

  void clearError() {
    _errorMessage = null;
  }

  TopupHistoryItem _mapTopupHistoryItem(Map<String, dynamic> row) {
    final amount =
        row['gross_amount'] ?? row['nominal'] ?? row['amount'] ?? row['total'];
    final status =
        row['transaction_status']?.toString() ??
        row['status']?.toString() ??
        '-';
    final orderId =
        row['order_id']?.toString() ??
        row['id_topup_saldo']?.toString() ??
        row['id_topup']?.toString() ??
        '-';
    final date =
        row['created_at'] ??
        row['updated_at'] ??
        row['transaction_time'] ??
        row['tanggal_topup'] ??
        row['tanggal'];

    return TopupHistoryItem(
      orderId: shortOrderId(orderId),
      amount: formatRupiah(asNum(amount).round()),
      status: status,
      date: formatDate(date?.toString()),
    );
  }

  Future<http.Response> _createTopupTransaction(int nominal) async {
    final body = jsonEncode({
      'nominal': nominal,
      'id_nasabah': _nasabahId,
      if (_currentEmail != null && _currentEmail!.isNotEmpty)
        'email': _currentEmail,
      if (_fullName != null && _fullName!.isNotEmpty) 'nama_lengkap': _fullName,
      if (_phone != null && _phone!.isNotEmpty) 'no_hp': _phone,
    });
    http.Response? lastResponse;
    Object? lastError;

    for (final apiUrl in _resolveTopupUrls()) {
      try {
        final response = await http
            .post(
              Uri.parse(apiUrl),
              headers: {
                ...GreenPointApiService.jsonHeaders,
                'X-Requested-With': 'XMLHttpRequest',
              },
              body: body,
            )
            .timeout(const Duration(seconds: 30));

        lastResponse = response;
        if (!_shouldTryNextTopupEndpoint(response)) {
          return response;
        }

        debugPrint('Topup endpoint skipped: $apiUrl');
      } catch (e) {
        lastError = e;
        debugPrint('Topup request error for $apiUrl: $e');
      }
    }

    if (lastResponse != null) return lastResponse;
    throw lastError ?? Exception('Topup request failed.');
  }

  List<String> _resolveTopupUrls() {
    final urls = <String>[];
    final value = dotenv.env['TOPUP_API_URL']?.trim();
    if (value != null && value.isNotEmpty) {
      final originFallback = _urlFromOrigin(value, _createTopupPath);
      if (originFallback != null) {
        urls.add(originFallback);
      }
      urls.add(value);
    }

    final apiBaseUrl = dotenv.env['GREENPOINT_API_BASE_URL']?.trim();
    if (apiBaseUrl != null && apiBaseUrl.isNotEmpty) {
      urls.add(_joinUrl(apiBaseUrl, 'mobile/nasabah/topup'));
    }

    urls.add(_defaultCreateTopupUrl);
    return urls.toSet().toList();
  }

  String? _urlFromOrigin(String rawUrl, String path) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return null;
    }

    return uri.replace(path: path, query: '', fragment: '').toString();
  }

  String _joinUrl(String baseUrl, String path) {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$cleanBase/$cleanPath';
  }

  bool _shouldTryNextTopupEndpoint(http.Response response) {
    if (response.statusCode == 404 || response.statusCode == 419) {
      return true;
    }

    return _isCsrfMismatch(response.body);
  }

  bool _isCsrfMismatch(String body) {
    return body.toLowerCase().contains('csrf token mismatch');
  }

  String? _extractMessage(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String) return message;
      }
    } catch (_) {}
    return null;
  }

  String _friendlyTopupError(Object error) {
    if (error is FormatException) {
      return 'URL top up tidak valid. Cek TOPUP_API_URL atau GREENPOINT_API_BASE_URL.';
    }

    if (error is http.ClientException) {
      return 'Tidak bisa terhubung ke server. Periksa koneksi dan URL top up.';
    }

    return 'Gagal memproses top up.';
  }

  void _setLoadingProfile(bool value) {
    if (_loadingProfile == value) return;
    _loadingProfile = value;
    _notify();
  }

  void _setLoadingTopupHistory(bool value) {
    if (_loadingTopupHistory == value) return;
    _loadingTopupHistory = value;
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

  static int? parseNominal(String raw) {
    final cleaned = raw.trim().replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned);
  }

  static String formatRupiah(num value) {
    final digits = value.toStringAsFixed(0);
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

  static num asNum(dynamic value) {
    if (value is num) return value;
    if (value is String) {
      return num.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    }
    return 0;
  }

  static String formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final parsed = DateTime.parse(raw).toLocal();
      final day = parsed.day.toString().padLeft(2, '0');
      final month = parsed.month.toString().padLeft(2, '0');
      final year = parsed.year.toString();
      final hour = parsed.hour.toString().padLeft(2, '0');
      final minute = parsed.minute.toString().padLeft(2, '0');
      return '$day-$month-$year $hour:$minute';
    } catch (_) {
      final dateOnly = raw.contains('T') ? raw.split('T').first : raw;
      return dateOnly.contains(' ') ? dateOnly.split(' ').first : dateOnly;
    }
  }

  static String formatDateOnly(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day-$month-$year';
  }

  static String shortOrderId(String orderId) {
    if (orderId == '-' || orderId.length <= 16) return orderId;
    return '${orderId.substring(0, 8)}...${orderId.substring(orderId.length - 4)}';
  }

  static String statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'settlement':
      case 'capture':
      case 'success':
      case 'paid':
        return 'Berhasil';
      case 'pending':
        return 'Pending';
      case 'expire':
      case 'expired':
        return 'Kedaluwarsa';
      case 'cancel':
      case 'deny':
      case 'failure':
      case 'failed':
        return 'Gagal';
      default:
        return status.isEmpty ? '-' : status;
    }
  }
}
