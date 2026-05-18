import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dashboard.dart';
import 'perbarui_profil.dart';
import 'services/firebase_account_service.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  static const _dummyData = ProfilDummyData(
    greeting: 'Halo,',
    userName: 'Haidar Rais',
    title: 'Profil Saya',
    subtitle: 'Tentang profil saya',
    fullName: 'Jarot Rohim',
    username: 'Jarot User',
    saldo: 'Rp. 0,-',
    address:
        'Jl. Mastrip, Krajan Timur, Sumbersari, Kec. Sumbersari, Kabupaten Jember, Java Timur 68121',
    email: 'dhimas@example.com',
    phone: '081234567890',
  );

  String? _fetchedUserName;
  bool _loadingProfile = false;
  String? _currentEmail;
  String? _fetchedFullName;
  String? _fetchedUsername;
  String? _fetchedEmail;
  String? _fetchedPhone;
  String? _fetchedAddress;
  String? _fetchedSaldo;

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
      final user = Supabase.instance.client.auth.currentUser;
      final email = emailArg ?? firebaseUser?.email ?? user?.email;
      _currentEmail = email;

      if (email != null && email.isNotEmpty) {
        final res = await Supabase.instance.client
            .from('nasabah')
            .select('nama_lengkap,user_name,email,no_hp,alamat,saldo')
            .eq('email', email)
            .limit(1);

        if (res.isNotEmpty) {
          final record = res.first;
          setState(() {
            _fetchedUserName =
                (record['nama_lengkap'] as String?) ??
                (record['user_name'] as String?);
            _fetchedFullName = record['nama_lengkap'] as String?;
            _fetchedUsername = record['user_name'] as String?;
            _fetchedEmail = record['email'] as String?;
            _fetchedPhone = record['no_hp'] as String?;
            _fetchedAddress = record['alamat'] as String?;
            _fetchedSaldo = record['saldo'] != null
                ? 'Rp ${record['saldo'].toString()}'
                : 'Rp 0';
          });
          return;
        }

        final firebaseProfile =
            await FirebaseAccountService.currentUserProfile();
        if (firebaseProfile != null && firebaseProfile['email'] == email) {
          setState(() {
            _fetchedUserName =
                (firebaseProfile['nama_lengkap'] as String?) ??
                (firebaseProfile['user_name'] as String?);
            _fetchedFullName = firebaseProfile['nama_lengkap'] as String?;
            _fetchedUsername = firebaseProfile['user_name'] as String?;
            _fetchedEmail = firebaseProfile['email'] as String?;
            _fetchedPhone = firebaseProfile['no_hp'] as String?;
            _fetchedAddress = firebaseProfile['alamat'] as String?;
            _fetchedSaldo = firebaseProfile['saldo'] != null
                ? 'Rp ${firebaseProfile['saldo'].toString()}'
                : 'Rp 0';
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
          Navigator.of(context).pushReplacementNamed(
            '/dashboard',
            arguments: {'email': _currentEmail},
          );
        },
      ),
      BottomNavigationItemConfig(
        iconAsset: 'assets/riwayat1.png',
        label: 'Transaksi',
        isActive: false,
        fallbackIcon: Icons.swap_horiz,
        onTap: () {
          Navigator.of(context).pushReplacementNamed(
            '/transaksi',
            arguments: {'email': _currentEmail},
          );
        },
      ),
      BottomNavigationItemConfig(
        iconAsset: 'assets/chat_ai.png',
        label: 'Chat AI',
        isActive: false,
        fallbackIcon: Icons.smart_toy,
        onTap: () {
          Navigator.of(context).pushNamed('/chatbot');
        },
      ),
      BottomNavigationItemConfig(
        iconAsset: 'assets/history.png',
        label: 'Riwayat',
        isActive: false,
        fallbackIcon: Icons.history,
        onTap: () {
          Navigator.of(context).pushReplacementNamed(
            '/riwayat',
            arguments: {'email': _currentEmail},
          );
        },
      ),
      const BottomNavigationItemConfig(
        iconAsset: 'assets/person2.png',
        label: 'Profil',
        isActive: true,
        fallbackIcon: Icons.person,
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white),
                            tooltip: 'Keluar',
                            onPressed: () async {
                              final navigator = Navigator.of(context);
                              final shouldLogout = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Konfirmasi'),
                                  content: const Text(
                                    'Apakah Anda yakin ingin keluar?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('Keluar'),
                                    ),
                                  ],
                                ),
                              );

                              if (shouldLogout == true) {
                                await FirebaseAccountService.signOut();
                                if (!mounted) return;
                                navigator.pushNamedAndRemoveUntil(
                                  '/welcome',
                                  (route) => false,
                                );
                              }
                            },
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
                                Text(
                                  _fetchedFullName ?? _dummyData.fullName,
                                  style: const TextStyle(
                                    color: Color(0xFF333333),
                                    fontSize: 18,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _fetchedUsername ?? _dummyData.username,
                                  style: const TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 14,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Saldo',
                                        style: TextStyle(
                                          color: Color(0xFF666666),
                                          fontSize: 14,
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _fetchedSaldo ?? _dummyData.saldo,
                                      style: const TextStyle(
                                        color: Color(0xFF315A39),
                                        fontSize: 16,
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Alamat',
                                  style: TextStyle(
                                    color: Color(0xFF333333),
                                    fontSize: 14,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _fetchedAddress ?? _dummyData.address,
                                  style: const TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 12,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w400,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Email',
                                        style: TextStyle(
                                          color: Color(0xFF666666),
                                          fontSize: 14,
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        _fetchedEmail ?? _dummyData.email,
                                        textAlign: TextAlign.end,
                                        style: const TextStyle(
                                          color: Color(0xFF333333),
                                          fontSize: 14,
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Expanded(
                                      flex: 2,
                                      child: Text(
                                        'No HP',
                                        style: TextStyle(
                                          color: Color(0xFF666666),
                                          fontSize: 14,
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        _fetchedPhone ?? _dummyData.phone,
                                        textAlign: TextAlign.end,
                                        style: const TextStyle(
                                          color: Color(0xFF333333),
                                          fontSize: 14,
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                InkWell(
                                  onTap: () {
                                    Navigator.of(context)
                                        .push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PerbaruiProfilScreen(
                                                  userData: {
                                                    'nama':
                                                        _fetchedFullName ??
                                                        _dummyData.fullName,
                                                    'username':
                                                        _fetchedUsername ??
                                                        _dummyData.username,
                                                    'email':
                                                        _fetchedEmail ??
                                                        _dummyData.email,
                                                    'alamat':
                                                        _fetchedAddress ??
                                                        _dummyData.address,
                                                    'phone':
                                                        _fetchedPhone ??
                                                        _dummyData.phone,
                                                  },
                                                ),
                                          ),
                                        )
                                        .then((result) {
                                          if (result == true) {
                                            _loadUserName();
                                          }
                                        });
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    height: 45,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFF315A39),
                                      ),
                                    ),
                                    child: const Text(
                                      'Perbarui Profil',
                                      style: TextStyle(
                                        color: Color(0xFF315A39),
                                        fontSize: 14,
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                InkWell(
                                  onTap: () {
                                    Navigator.of(context).pushReplacementNamed(
                                      '/setor-sampah',
                                      arguments: {'email': _currentEmail},
                                    );
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    height: 45,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF315A39),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Setor Sampah',
                                      style: TextStyle(
                                        color: Colors.white,
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

class ProfilDummyData {
  const ProfilDummyData({
    required this.greeting,
    required this.userName,
    required this.title,
    required this.subtitle,
    required this.fullName,
    required this.username,
    required this.saldo,
    required this.address,
    required this.email,
    required this.phone,
  });

  final String greeting;
  final String userName;
  final String title;
  final String subtitle;
  final String fullName;
  final String username;
  final String saldo;
  final String address;
  final String email;
  final String phone;
}
