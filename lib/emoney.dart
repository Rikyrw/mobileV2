import 'package:flutter/material.dart';

import 'viewmodels/ppob_form_view_model.dart';
import 'widgets/greenpoint_header.dart';

class EmoneyScreen extends StatefulWidget {
  const EmoneyScreen({super.key});

  @override
  State<EmoneyScreen> createState() => _EmoneyScreenState();
}

class _EmoneyScreenState extends State<EmoneyScreen> {
  final PpobFormViewModel _viewModel = PpobFormViewModel(
    productType: PpobProductType.emoney,
  );
  final TextEditingController _noTujuanController = TextEditingController();

  static const _dummyData = EmoneyDummyData(
    greeting: 'Halo,',
    userName: 'Haidar Rais',
    saldo: 'Saldo: Rp 0',
    title: 'E-money',
    subtitle: 'Isi saldo e-money',
    noTujuanLabel: 'No Tujuan',
    noTujuanHint: 'Masukkan nomor e-money',
    kategoriLabel: 'Kategori',
    kategoriPlaceholder: 'Pilih Kategori',
    layananLabel: 'Layanan',
    layananPlaceholder: 'Pilih Layanan',
    prosesButtonText: 'Proses',
  );

  bool _profileLoadRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_profileLoadRequested) {
      _profileLoadRequested = true;
      _viewModel.loadProfile(emailArgument: _routeEmailArgument);
    }
  }

  String? get _routeEmailArgument {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['email'] is String) {
      return args['email'] as String;
    }
    return null;
  }

  Future<void> _refreshProfile() {
    return _viewModel.refreshProfile(emailArgument: _routeEmailArgument);
  }

  Future<void> _submitEmoney() async {
    final result = await _viewModel.submit(_noTujuanController.text);
    if (!mounted || result.message.isEmpty) return;
    if (result.shouldClearInput) {
      _noTujuanController.clear();
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  void _returnToDashboard() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushReplacementNamed(
      '/dashboard',
      arguments: _viewModel.dashboardArguments,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: RefreshIndicator(
            color: const Color(0xFF315A39),
            backgroundColor: Colors.white,
            onRefresh: _refreshProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                width: double.infinity,
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GreenPointHeader(
                      eyebrow: _dummyData.greeting,
                      title: _viewModel.userName,
                      subtitle: _viewModel.saldoText,
                      avatarText: _viewModel.userName,
                      avatarSize: 58,
                      leading: GreenPointHeaderIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Kembali',
                        onPressed: _returnToDashboard,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _dummyData.title,
                            style: const TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 20,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _dummyData.subtitle,
                            style: const TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 14,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F7F8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Isi data pembelian',
                                  style: TextStyle(
                                    color: Color(0xFF333333),
                                    fontSize: 16,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'No Tujuan',
                                  style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 14,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 50,
                                  child: TextField(
                                    controller: _noTujuanController,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      hintText: 'Masukkan nomor e-money',
                                      hintStyle: const TextStyle(
                                        color: Color(0xFF999999),
                                        fontSize: 14,
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.w400,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE0E0E0),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE0E0E0),
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                    ),
                                    style: const TextStyle(
                                      color: Color(0xFF333333),
                                      fontSize: 14,
                                      fontFamily: 'Roboto',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Kategori',
                                  style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 14,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 50,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFE0E0E0),
                                      ),
                                    ),
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      underline: const SizedBox.shrink(),
                                      value: _viewModel.selectedKategori,
                                      hint: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Text(
                                          'Pilih Kategori',
                                          style: TextStyle(
                                            color: const Color(0xFF999999),
                                            fontSize: 14,
                                            fontFamily: 'Roboto',
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      items: [
                                        DropdownMenuItem(
                                          value: '5000',
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: const Text('Rp. 5.000'),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: '10000',
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: const Text('Rp. 10.000'),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: '20000',
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: const Text('Rp. 20.000'),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: '50000',
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: const Text('Rp. 50.000'),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: '100000',
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: const Text('Rp. 100.000'),
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        _viewModel.setKategori(value);
                                      },
                                      icon: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Icon(
                                          Icons.arrow_drop_down,
                                          color: const Color(0xFF666666),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Layanan',
                                  style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 14,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 50,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFE0E0E0),
                                      ),
                                    ),
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      underline: const SizedBox.shrink(),
                                      value: _viewModel.selectedLayanan,
                                      hint: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Text(
                                          'Pilih Layanan',
                                          style: TextStyle(
                                            color: const Color(0xFF999999),
                                            fontSize: 14,
                                            fontFamily: 'Roboto',
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      items: [
                                        DropdownMenuItem(
                                          value: 'gopay',
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: const Text('GoPay'),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'dana',
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: const Text('DANA'),
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        _viewModel.setLayanan(value);
                                      },
                                      icon: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Icon(
                                          Icons.arrow_drop_down,
                                          color: const Color(0xFF666666),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 30),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _viewModel.submitting
                                        ? null
                                        : _submitEmoney,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF315A39),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      _viewModel.submitting
                                          ? 'Memproses...'
                                          : 'Proses',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _noTujuanController.dispose();
    super.dispose();
  }
}

class EmoneyDummyData {
  const EmoneyDummyData({
    required this.greeting,
    required this.userName,
    required this.saldo,
    required this.title,
    required this.subtitle,
    required this.noTujuanLabel,
    required this.noTujuanHint,
    required this.kategoriLabel,
    required this.kategoriPlaceholder,
    required this.layananLabel,
    required this.layananPlaceholder,
    required this.prosesButtonText,
  });

  final String greeting;
  final String userName;
  final String saldo;
  final String title;
  final String subtitle;
  final String noTujuanLabel;
  final String noTujuanHint;
  final String kategoriLabel;
  final String kategoriPlaceholder;
  final String layananLabel;
  final String layananPlaceholder;
  final String prosesButtonText;
}
