import 'package:flutter/material.dart';

import 'services/app_cache_service.dart';
import 'services/firebase_account_service.dart';
import 'services/greenpoint_api_service.dart';

class EmoneyScreen extends StatefulWidget {
  const EmoneyScreen({super.key});

  @override
  State<EmoneyScreen> createState() => _EmoneyScreenState();
}

class _EmoneyScreenState extends State<EmoneyScreen> {
  String? selectedKategori;
  String? selectedLayanan;
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

  String? _fetchedUserName;
  bool _loadingProfile = false;
  String? _currentEmail;
  int? _nasabahId;
  double? _saldo;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_fetchedUserName == null && !_loadingProfile) {
      _loadUserName();
    }
  }

  Future<void> _loadUserName() async {
    setState(() => _loadingProfile = true);

    try {
      // Try to get email from route arguments (if provided)
      final args = ModalRoute.of(context)?.settings.arguments;
      String? emailArg;
      if (args is Map && args['email'] is String) {
        emailArg = args['email'] as String;
      }

      // Prefer route argument, otherwise use auth currentUser
      final firebaseUser = FirebaseAccountService.currentUser;
      final email = emailArg ?? firebaseUser?.email;
      _currentEmail = email;

      if (email != null && email.isNotEmpty) {
        final record = await AppCacheService.fetchNasabahByEmail(email);

        if (record != null) {
          final saldoValue = (record['saldo'] as num?)?.toDouble();
          setState(() {
            _fetchedUserName =
                (record['nama_lengkap'] as String?) ??
                (record['user_name'] as String?);
            _nasabahId = record['id_nasabah'] as int?;
            _saldo = saldoValue;
          });
        }
      }
    } catch (e) {
      debugPrint('Load user name error: $e');
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  String _formatRupiah(int value) {
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

  Future<void> _submitEmoney() async {
    if (_submitting) return;

    final noTujuan = _noTujuanController.text.trim();
    if (noTujuan.isEmpty ||
        selectedKategori == null ||
        selectedLayanan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua data terlebih dahulu.')),
      );
      return;
    }

    if (_nasabahId == null || _saldo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data nasabah belum tersedia.')),
      );
      return;
    }

    final nominal = int.tryParse(selectedKategori ?? '');
    if (nominal == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nominal tidak valid.')));
      return;
    }

    if ((_saldo ?? 0) < nominal) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saldo tidak mencukupi.')));
      return;
    }

    setState(() => _submitting = true);

    try {
      await GreenPointApiService.submitPpob(
        nasabahId: _nasabahId!,
        jenisPenukaran: selectedLayanan!,
        nominal: nominal,
        deskripsi: 'emoney:$noTujuan',
      );
      AppCacheService.invalidateActivity();

      if (!mounted) return;
      setState(() {
        selectedKategori = null;
        selectedLayanan = null;
        _noTujuanController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permintaan berhasil dikirim.')),
      );
    } catch (e) {
      debugPrint('Submit emoney error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memproses transaksi.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 40, 20, 30),
                decoration: const BoxDecoration(color: Color(0xFF315A39)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed(
                              '/dashboard',
                              arguments: {'email': _currentEmail},
                            );
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Opacity(
                                opacity: 0.8,
                                child: Text(
                                  _dummyData.greeting,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _fetchedUserName ?? _dummyData.userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _saldo == null
                                    ? _dummyData.saldo
                                    : 'Saldo: ${_formatRupiah(_saldo!.round())}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
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
                                contentPadding: const EdgeInsets.symmetric(
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
                                value: selectedKategori,
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
                                  setState(() {
                                    selectedKategori = value;
                                  });
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
                                value: selectedLayanan,
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
                                  setState(() {
                                    selectedLayanan = value;
                                  });
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
                              onPressed: _submitting ? null : _submitEmoney,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF315A39),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _submitting ? 'Memproses...' : 'Proses',
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
    );
  }

  @override
  void dispose() {
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
