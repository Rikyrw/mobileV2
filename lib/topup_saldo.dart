import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'services/app_cache_service.dart';
import 'services/external_url_opener.dart';

class TopupSaldoScreen extends StatefulWidget {
  const TopupSaldoScreen({super.key});

  @override
  State<TopupSaldoScreen> createState() => _TopupSaldoScreenState();
}

class _TopupSaldoScreenState extends State<TopupSaldoScreen> {
  static const _minNominal = 10000;
  static const _maxNominal = 10000000;
  static const _createTopupPath = '/api/mobile/nasabah/topup';
  static const _defaultCreateTopupUrl =
      'http://localhost:8000/api/mobile/nasabah/topup';

  final TextEditingController _nominalController = TextEditingController();

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadingProfile && _saldo == null) {
      _loadUserProfile();
    }
  }

  @override
  void dispose() {
    _nominalController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _loadingProfile = true);

    try {
      final args = ModalRoute.of(context)?.settings.arguments;
      String? emailArg;
      if (args is Map && args['email'] is String) {
        emailArg = args['email'] as String;
      }

      final user = Supabase.instance.client.auth.currentUser;
      final email = emailArg ?? user?.email;
      _currentEmail = email;

      if (email != null && email.isNotEmpty) {
        final record = await AppCacheService.fetchNasabahByEmail(
          email,
          forceRefresh: true,
        );

        if (record != null) {
          final saldoValue = (record['saldo'] as num?)?.toDouble();
          setState(() {
            _nasabahId = record['id_nasabah'] as int?;
            _fullName = record['nama_lengkap'] as String?;
            _phone = record['no_hp'] as String?;
            _saldo = saldoValue;
          });
          final nasabahId = record['id_nasabah'] as int?;
          if (nasabahId != null) {
            _loadTopupHistory(nasabahId);
          }
        }
      }
    } catch (e) {
      debugPrint('Load topup profile error: $e');
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _loadTopupHistory(int nasabahId) async {
    if (_loadingTopupHistory) return;
    setState(() => _loadingTopupHistory = true);

    try {
      final rows = await _fetchTopupHistoryRows(nasabahId);
      if (!mounted) return;
      setState(() {
        _topupHistory = rows.map(_mapTopupHistoryItem).toList();
      });
    } catch (e) {
      debugPrint('Load topup history error: $e');
      if (!mounted) return;
      _showSnack('Gagal memuat riwayat top up.');
    } finally {
      if (mounted) setState(() => _loadingTopupHistory = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTopupHistoryRows(
    int nasabahId,
  ) async {
    const orderColumns = <String?>[
      'created_at',
      'updated_at',
      'transaction_time',
      'tanggal_topup',
      null,
    ];
    Object? lastError;

    for (final orderColumn in orderColumns) {
      try {
        dynamic query = Supabase.instance.client
            .from('topup_saldo')
            .select('*')
            .eq('id_nasabah', nasabahId);

        if (_topupHistoryDate != null && orderColumn != null) {
          final start = DateTime(
            _topupHistoryDate!.year,
            _topupHistoryDate!.month,
            _topupHistoryDate!.day,
          );
          final end = start.add(const Duration(days: 1));
          query = query
              .gte(orderColumn, start.toUtc().toIso8601String())
              .lt(orderColumn, end.toUtc().toIso8601String());
        }

        if (orderColumn != null) {
          query = query.order(orderColumn, ascending: false);
        }

        final rows = await query.limit(5);
        return (rows as List)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
      } catch (e) {
        lastError = e;
        debugPrint('Topup history order failed ($orderColumn): $e');
      }
    }

    throw lastError ?? Exception('Topup history lookup failed.');
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
      orderId: _shortOrderId(orderId),
      amount: _formatRupiah(_asNum(amount).round()),
      status: status,
      date: _formatDate(date?.toString()),
    );
  }

  int? _parseNominal() {
    final raw = _nominalController.text.trim();
    final cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned);
  }

  String _formatRupiah(num value) {
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

  num _asNum(dynamic value) {
    if (value is num) return value;
    if (value is String) {
      return num.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    }
    return 0;
  }

  String _formatDate(String? raw) {
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

  String _formatDateOnly(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day-$month-$year';
  }

  String _shortOrderId(String orderId) {
    if (orderId == '-' || orderId.length <= 16) return orderId;
    return '${orderId.substring(0, 8)}...${orderId.substring(orderId.length - 4)}';
  }

  Future<void> _pickTopupHistoryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _topupHistoryDate ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
    );

    if (picked == null) return;

    setState(() => _topupHistoryDate = picked);
    final nasabahId = _nasabahId;
    if (nasabahId != null) {
      await _loadTopupHistory(nasabahId);
    }
  }

  Future<void> _clearTopupHistoryDate() async {
    setState(() => _topupHistoryDate = null);
    final nasabahId = _nasabahId;
    if (nasabahId != null) {
      await _loadTopupHistory(nasabahId);
    }
  }

  Future<void> _submitTopup() async {
    if (_submitting) return;

    final nominal = _parseNominal();
    if (nominal == null) {
      _showSnack('Nominal wajib diisi.');
      return;
    }

    if (nominal < _minNominal || nominal > _maxNominal) {
      _showSnack('Nominal harus antara Rp 10.000 - Rp 10.000.000.');
      return;
    }

    if (_nasabahId == null) {
      _showSnack('Data nasabah belum tersedia. Coba buka ulang halaman ini.');
      return;
    }

    setState(() => _submitting = true);

    try {
      final response = await _createTopupTransaction(nominal);

      if (response.statusCode == 401) {
        _showSnack('Silakan login terlebih dahulu.');
        return;
      }

      if (response.statusCode == 404) {
        _showSnack(
          'Endpoint top up tidak ditemukan. Cek TOPUP_API_URL atau GREENPOINT_API_BASE_URL.',
        );
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message =
            _extractMessage(response.body) ?? 'Gagal membuat transaksi top up.';
        _showSnack(message);
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final redirectUrl = data['redirect_url'] as String?;
      final orderId = data['order_id'] as String?;

      if (redirectUrl == null || redirectUrl.isEmpty || orderId == null) {
        _showSnack('Data pembayaran tidak lengkap.');
        return;
      }

      if (!mounted) return;
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => kIsWeb
              ? TopupExternalPaymentScreen(
                  redirectUrl: redirectUrl,
                  orderId: orderId,
                )
              : TopupWebViewScreen(redirectUrl: redirectUrl, orderId: orderId),
        ),
      );

      if (result == true) {
        await _checkTopupStatus(orderId);
      }
    } catch (e) {
      debugPrint('Topup submit error: $e');
      _showSnack(_friendlyTopupError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
              headers: const {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
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

  Future<void> _checkTopupStatus(String orderId) async {
    try {
      final res = await Supabase.instance.client
          .from('topup_saldo')
          .select('status,transaction_status,gross_amount')
          .eq('order_id', orderId)
          .limit(1);

      if (res.isEmpty) {
        _showSnack('Transaksi tidak ditemukan.');
        return;
      }

      final row = res.first;
      final status = (row['status'] as String?) ?? 'pending';
      final transactionStatus =
          (row['transaction_status'] as String?) ?? status;

      if (transactionStatus == 'settlement' || transactionStatus == 'capture') {
        AppCacheService.invalidateNasabahByEmail(_currentEmail);
        await _loadUserProfile();
        final nasabahId = _nasabahId;
        if (nasabahId != null) {
          await _loadTopupHistory(nasabahId);
        }
        _showSnack('Top up berhasil.');
      } else if (transactionStatus == 'pending') {
        _showSnack('Pembayaran masih pending.');
      } else {
        _showSnack('Status pembayaran: $transactionStatus');
      }
    } catch (e) {
      debugPrint('Check topup status error: $e');
      _showSnack('Gagal memeriksa status pembayaran.');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final saldoText = _saldo == null ? '-' : _formatRupiah(_saldo ?? 0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 40, 20, 24),
              decoration: const BoxDecoration(color: Color(0xFF315A39)),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed(
                        '/profil',
                        arguments: {'email': _currentEmail},
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Top Up Saldo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8F4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saldo Saat Ini',
                          style: TextStyle(
                            color: Color(0xFF315A39),
                            fontSize: 12,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          saldoText,
                          style: const TextStyle(
                            color: Color(0xFF315A39),
                            fontSize: 20,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Nominal Top Up',
                    style: TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 14,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nominalController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Masukkan nominal (min 10.000)',
                      filled: true,
                      fillColor: const Color(0xFFF6F7F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _quickAmountChip(10000),
                      _quickAmountChip(25000),
                      _quickAmountChip(50000),
                      _quickAmountChip(100000),
                      _quickAmountChip(200000),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submitTopup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF315A39),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Lanjutkan Pembayaran',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _topupHistorySection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAmountChip(int amount) {
    return GestureDetector(
      onTap: () {
        _nominalController.text = amount.toString();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF315A39)),
        ),
        child: Text(
          _formatRupiah(amount),
          style: const TextStyle(
            color: Color(0xFF315A39),
            fontSize: 12,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _topupHistorySection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1D9D1), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Riwayat Top Up',
                    style: TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 14,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _loadingTopupHistory || _nasabahId == null
                      ? null
                      : () => _loadTopupHistory(_nasabahId!),
                  icon: _loadingTopupHistory
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 20),
                  color: const Color(0xFF315A39),
                  tooltip: 'Muat ulang',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _loadingTopupHistory
                      ? null
                      : _pickTopupHistoryDate,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _topupHistoryDate == null
                        ? 'Pilih Tanggal'
                        : _formatDateOnly(_topupHistoryDate!),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    side: const BorderSide(color: Color(0xFF315A39)),
                  ),
                ),
                if (_topupHistoryDate != null)
                  TextButton.icon(
                    onPressed: _loadingTopupHistory
                        ? null
                        : _clearTopupHistoryDate,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reset'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF666666),
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
          ),
          if (_loadingTopupHistory && _topupHistory.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 4, 14, 16),
              child: Text(
                'Memuat riwayat top up...',
                style: TextStyle(
                  color: Color(0xFF777777),
                  fontSize: 12,
                  fontFamily: 'Roboto',
                ),
              ),
            )
          else if (_topupHistory.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 4, 14, 16),
              child: Text(
                'Belum ada riwayat top up.',
                style: TextStyle(
                  color: Color(0xFF777777),
                  fontSize: 12,
                  fontFamily: 'Roboto',
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                border: TableBorder.all(
                  color: const Color(0xFFCAD4CA),
                  width: 1,
                  borderRadius: BorderRadius.circular(0),
                ),
                dividerThickness: 1.2,
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF4F8F4),
                ),
                headingRowHeight: 38,
                dataRowMinHeight: 44,
                dataRowMaxHeight: 52,
                columnSpacing: 18,
                horizontalMargin: 14,
                columns: const [
                  DataColumn(label: Text('Tanggal')),
                  DataColumn(label: Text('Nominal')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Order')),
                ],
                rows: _topupHistory.map((item) {
                  return DataRow(
                    cells: [
                      DataCell(Text(item.date)),
                      DataCell(Text(item.amount)),
                      DataCell(_statusBadge(item.status)),
                      DataCell(Text(item.orderId)),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final normalized = status.toLowerCase();
    final color =
        normalized == 'settlement' ||
            normalized == 'capture' ||
            normalized == 'success' ||
            normalized == 'paid'
        ? const Color(0xFF2E7D32)
        : normalized == 'pending'
        ? const Color(0xFFB26A00)
        : const Color(0xFFB3261E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _statusLabel(String status) {
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

class TopupExternalPaymentScreen extends StatelessWidget {
  const TopupExternalPaymentScreen({
    super.key,
    required this.redirectUrl,
    required this.orderId,
  });

  final String redirectUrl;
  final String orderId;

  Future<void> _openPayment(BuildContext context) async {
    final opened = await openExternalUrl(redirectUrl);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          opened
              ? 'Pembayaran dibuka di tab baru.'
              : 'Tidak bisa membuka halaman pembayaran.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF315A39),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Pembayaran',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F8F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pembayaran Midtrans',
                    style: TextStyle(
                      color: Color(0xFF315A39),
                      fontSize: 16,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Buka halaman pembayaran, selesaikan transaksi, lalu kembali untuk cek status.',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 13,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () => _openPayment(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF315A39),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Buka Pembayaran',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Cek Status'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TopupWebViewScreen extends StatefulWidget {
  const TopupWebViewScreen({
    super.key,
    required this.redirectUrl,
    required this.orderId,
  });

  final String redirectUrl;
  final String orderId;

  @override
  State<TopupWebViewScreen> createState() => _TopupWebViewScreenState();
}

class _TopupWebViewScreenState extends State<TopupWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF315A39),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Pembayaran',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text(
              'Cek Status',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF315A39)),
            ),
        ],
      ),
    );
  }
}
