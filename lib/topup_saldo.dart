import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TopupSaldoScreen extends StatefulWidget {
  const TopupSaldoScreen({super.key});

  @override
  State<TopupSaldoScreen> createState() => _TopupSaldoScreenState();
}

class _TopupSaldoScreenState extends State<TopupSaldoScreen> {
  static const _minNominal = 10000;
  static const _maxNominal = 10000000;
    static const _defaultCreateTopupUrl =
      'https://rural-pregame-happening.ngrok-free.dev/api/create-topup';

  final TextEditingController _nominalController = TextEditingController();

  String? _currentEmail;
  double? _saldo;
  bool _loadingProfile = false;
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
        final res = await Supabase.instance.client
            .from('nasabah')
            .select('id_nasabah,nama_lengkap,user_name,email,saldo')
            .eq('email', email)
            .limit(1);

        if (res.isNotEmpty) {
          final record = res.first;
          final saldoValue = (record['saldo'] as num?)?.toDouble();
          setState(() {
            _saldo = saldoValue;
          });
        }
      }
    } catch (e) {
      debugPrint('Load topup profile error: $e');
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
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

    setState(() => _submitting = true);

    try {
      final apiUrl = _resolveTopupUrl();
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'nominal': nominal}),
      );

      if (response.statusCode == 401) {
        _showSnack('Silakan login terlebih dahulu.');
        return;
      }

      if (response.statusCode == 404) {
        _showSnack('Endpoint top up tidak ditemukan. Cek TOPUP_API_URL.');
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = _extractMessage(response.body) ??
            'Gagal membuat transaksi top up.';
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

      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => TopupWebViewScreen(
            redirectUrl: redirectUrl,
            orderId: orderId,
          ),
        ),
      );

      if (result == true) {
        await _checkTopupStatus(orderId);
      }
    } catch (e) {
      debugPrint('Topup submit error: $e');
      _showSnack('Gagal memproses top up.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _resolveTopupUrl() {
    final value = dotenv.env['TOPUP_API_URL']?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return _defaultCreateTopupUrl;
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

      final row = res.first as Map<String, dynamic>;
      final status = (row['status'] as String?) ?? 'pending';
      final transactionStatus =
          (row['transaction_status'] as String?) ?? status;

      if (transactionStatus == 'settlement' || transactionStatus == 'capture') {
        await _loadUserProfile();
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
              child: CircularProgressIndicator(
                color: Color(0xFF315A39),
              ),
            ),
        ],
      ),
    );
  }
}
