import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'services/external_url_opener.dart';
import 'viewmodels/topup_saldo_view_model.dart';
import 'viewmodels/topup_web_view_model.dart';

class TopupSaldoScreen extends StatefulWidget {
  const TopupSaldoScreen({super.key});

  @override
  State<TopupSaldoScreen> createState() => _TopupSaldoScreenState();
}

class _TopupSaldoScreenState extends State<TopupSaldoScreen> {
  final TopupSaldoViewModel _viewModel = TopupSaldoViewModel();
  final TextEditingController _nominalController = TextEditingController();
  bool _profileLoadRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_profileLoadRequested) {
      _profileLoadRequested = true;
      _viewModel.loadUserProfile(emailArgument: _routeEmailArgument);
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _nominalController.dispose();
    super.dispose();
  }

  String? get _routeEmailArgument {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['email'] is String) {
      return args['email'] as String;
    }
    return null;
  }

  Future<void> _pickTopupHistoryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _viewModel.topupHistoryDate ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
    );

    if (picked == null) return;
    await _viewModel.setTopupHistoryDate(picked);
  }

  Future<void> _clearTopupHistoryDate() async {
    await _viewModel.setTopupHistoryDate(null);
  }

  Future<void> _submitTopup() async {
    final result = await _viewModel.submitTopup(
      TopupSaldoViewModel.parseNominal(_nominalController.text),
    );
    if (!mounted) return;

    if (!result.hasPayment) {
      _showSnack(result.message ?? '');
      return;
    }

    final paymentResult = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => kIsWeb
            ? TopupExternalPaymentScreen(
                redirectUrl: result.redirectUrl!,
                orderId: result.orderId!,
              )
            : TopupWebViewScreen(
                redirectUrl: result.redirectUrl!,
                orderId: result.orderId!,
              ),
      ),
    );

    if (paymentResult == true) {
      final message = await _viewModel.checkTopupStatus(result.orderId!);
      if (!mounted) return;
      _showSnack(message);
    }
  }

  void _showSnack(String message) {
    if (!mounted || message.isEmpty) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final errorMessage = _viewModel.errorMessage;
        if (errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showSnack(errorMessage);
            _viewModel.clearError();
          });
        }

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
                            arguments: _viewModel.profileArguments,
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
                              _viewModel.saldoText,
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
                          onPressed: _viewModel.submitting
                              ? null
                              : _submitTopup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF315A39),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _viewModel.submitting
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
      },
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
          TopupSaldoViewModel.formatRupiah(amount),
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
                  onPressed:
                      _viewModel.loadingTopupHistory ||
                          _viewModel.nasabahId == null
                      ? null
                      : _viewModel.loadTopupHistory,
                  icon: _viewModel.loadingTopupHistory
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
                  onPressed: _viewModel.loadingTopupHistory
                      ? null
                      : _pickTopupHistoryDate,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _viewModel.topupHistoryDate == null
                        ? 'Pilih Tanggal'
                        : TopupSaldoViewModel.formatDateOnly(
                            _viewModel.topupHistoryDate!,
                          ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    side: const BorderSide(color: Color(0xFF315A39)),
                  ),
                ),
                if (_viewModel.topupHistoryDate != null)
                  TextButton.icon(
                    onPressed: _viewModel.loadingTopupHistory
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
          if (_viewModel.loadingTopupHistory && _viewModel.topupHistory.isEmpty)
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
          else if (_viewModel.topupHistory.isEmpty)
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
                rows: _viewModel.topupHistory.map((item) {
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
        TopupSaldoViewModel.statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
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
  final TopupWebViewModel _viewModel = TopupWebViewModel();

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => _viewModel.pageStarted(),
          onPageFinished: (_) => _viewModel.pageFinished(),
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
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
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_viewModel.loading)
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFF315A39)),
                ),
            ],
          );
        },
      ),
    );
  }
}
