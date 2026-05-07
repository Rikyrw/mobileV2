import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dashboard.dart';

class PulsaScreen extends StatefulWidget {
  const PulsaScreen({super.key});

  @override
  State<PulsaScreen> createState() => _PulsaScreenState();
}

class _PulsaScreenState extends State<PulsaScreen> {
  String? selectedOperator;
  String? selectedNominal;
  final TextEditingController _noTeleponController = TextEditingController();

  static const _dummyData = PulsaDummyData(
    greeting: 'Halo,',
    userName: 'Haidar Rais',
    saldo: 'Saldo: Rp 0',
    title: 'Pulsa',
    subtitle: 'Isi pulsa telepon Anda',
    noTeleponLabel: 'No Telepon',
    noTeleponHint: 'Masukkan nomor telepon',
    operatorLabel: 'Pilih Operator',
    operatorPlaceholder: 'Pilih Operator',
    nominalLabel: 'Pilih Nominal',
    nominalPlaceholder: 'Pilih Nominal Pulsa',
    beliPulsaButtonText: 'Beli Pulsa',
  );

  String? _fetchedUserName;
  bool _loadingProfile = false;

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
      final user = Supabase.instance.client.auth.currentUser;
      final email = emailArg ?? user?.email;

      if (email != null && email.isNotEmpty) {
        final res = await Supabase.instance.client
            .from('nasabah')
            .select('nama_lengkap,user_name,email')
            .eq('email', email)
            .limit(1);

        if (res.isNotEmpty) {
          final record = res.first;
          setState(() {
            _fetchedUserName = (record['nama_lengkap'] as String?) ?? (record['user_name'] as String?);
          });
        }
      }
    } catch (e) {
      debugPrint('Load user name error: $e');
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
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
                padding: const EdgeInsetsDirectional.fromSTEB(
                  20,
                  40,
                  20,
                  30,
                ),
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
                            Navigator.of(context).pushReplacementNamed('/dashboard');
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
                                _dummyData.saldo,
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
                            'No Telepon',
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
                              controller: _noTeleponController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                hintText: 'Masukkan nomor telepon',
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
                            'Pilih Operator',
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
                                value: selectedOperator,
                                hint: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    'Pilih Operator',
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
                                    value: 'telkomsel',
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: const Text('Telkomsel'),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'indosat',
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: const Text('Indosat'),
                                    ),
                                  ),
                                  // DropdownMenuItem(
                                  //   value: 'axis',
                                  //   child: Padding(
                                  //     padding: const EdgeInsets.symmetric(
                                  //       horizontal: 16,
                                  //     ),
                                  //     child: const Text('Axis'),
                                  //   ),
                                  // ),
                                  // DropdownMenuItem(
                                  //   value: 'tri',
                                  //   child: Padding(
                                  //     padding: const EdgeInsets.symmetric(
                                  //       horizontal: 16,
                                  //     ),
                                  //     child: const Text('Tri'),
                                  //   ),
                                  // ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    selectedOperator = value;
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
                            'Pilih Nominal',
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
                                value: selectedNominal,
                                hint: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    'Pilih Nominal Pulsa',
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
                                    value: 'rp_5000',
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: const Text('Rp 5.000'),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'rp_10000',
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: const Text('Rp 10.000'),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'rp_20000',
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: const Text('Rp 20.000'),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'rp_50000',
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: const Text('Rp 50.000'),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    selectedNominal = value;
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
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF315A39),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Beli Pulsa',
                                style: TextStyle(
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
    _noTeleponController.dispose();
    super.dispose();
  }
}

class PulsaDummyData {
  const PulsaDummyData({
    required this.greeting,
    required this.userName,
    required this.saldo,
    required this.title,
    required this.subtitle,
    required this.noTeleponLabel,
    required this.noTeleponHint,
    required this.operatorLabel,
    required this.operatorPlaceholder,
    required this.nominalLabel,
    required this.nominalPlaceholder,
    required this.beliPulsaButtonText,
  });

  final String greeting;
  final String userName;
  final String saldo;
  final String title;
  final String subtitle;
  final String noTeleponLabel;
  final String noTeleponHint;
  final String operatorLabel;
  final String operatorPlaceholder;
  final String nominalLabel;
  final String nominalPlaceholder;
  final String beliPulsaButtonText;
}
