import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dashboard.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  static const _dummyData = RiwayatDummyData(
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
    final navItems = [
      BottomNavigationItemConfig(
        iconAsset: 'assets/home11.png',
        label: 'Home',
        isActive: false,
        fallbackIcon: Icons.home,
        onTap: () {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        },
      ),
      BottomNavigationItemConfig(
        iconAsset: 'assets/riwayat1.png',
        label: 'Transaksi',
        isActive: false,
        fallbackIcon: Icons.swap_horiz,
        onTap: () {
          Navigator.of(context).pushReplacementNamed('/transaksi');
        },
      ),
      const BottomNavigationItemConfig(
        iconAsset: 'assets/chat_ai.png',
        label: 'Chat AI',
        isActive: false,
        fallbackIcon: Icons.smart_toy,
      ),
      const BottomNavigationItemConfig(
        iconAsset: 'assets/history.png',
        label: 'Riwayat',
        isActive: true,
        fallbackIcon: Icons.history,
      ),
      BottomNavigationItemConfig(
        iconAsset: 'assets/person.png',
        label: 'Profil',
        isActive: false,
        fallbackIcon: Icons.person,
        onTap: () {
          Navigator.of(context).pushReplacementNamed('/profil');
        },
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            bottom: 130,
            child: SingleChildScrollView(
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
                                  'Periode Mutasi',
                                  style: TextStyle(
                                    color: Color(0xFF333333),
                                    fontSize: 16,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Dari Tanggal:',
                                  style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 14,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _DateField(value: _dummyData.fromDate),
                                const SizedBox(height: 16),
                                const Text(
                                  'Sampai Tanggal:',
                                  style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 14,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _DateField(value: _dummyData.untilDate),
                                const SizedBox(height: 20),
                                Text(
                                  _dummyData.note,
                                  style: const TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 12,
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
                              child: Text(
                                _dummyData.buttonText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                _dummyData.emptyState,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 16,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
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
          DashboardBottomNavigation(items: navItems),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF333333),
                fontSize: 14,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const Icon(
            Icons.calendar_today_outlined,
            size: 20,
            color: Color(0xFF666666),
          ),
        ],
      ),
    );
  }
}

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
