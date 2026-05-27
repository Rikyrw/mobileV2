import 'package:flutter/material.dart';

import 'perbarui_profil.dart';
import 'services/app_cache_service.dart';
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
      final email = emailArg ?? firebaseUser?.email;
      _currentEmail = email;

      if (email != null && email.isNotEmpty) {
        final record = await AppCacheService.fetchNasabahByEmail(email);

        if (record != null) {
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
    return ColoredBox(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 40, 20, 30),
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
                          const SizedBox(height: 18),
                          _profileActionButton(
                            icon: Icons.edit_outlined,
                            title: 'Perbarui Profil',
                            subtitle: 'Ubah data diri dan kontak',
                            accentColor: const Color(0xFF315A39),
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
                          ),
                          const SizedBox(height: 12),
                          _profileActionButton(
                            icon: Icons.recycling,
                            title: 'Setor Sampah',
                            subtitle: 'Ajukan setoran baru',
                            accentColor: const Color(0xFF315A39),
                            isPrimary: true,
                            onTap: () {
                              Navigator.of(context).pushReplacementNamed(
                                '/setor-sampah',
                                arguments: {'email': _currentEmail},
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _profileActionButton(
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'Top Up Saldo',
                            subtitle: 'Isi saldo untuk transaksi',
                            accentColor: const Color(0xFFB26A00),
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                '/topup-saldo',
                                arguments: {'email': _currentEmail},
                              );
                            },
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

  Widget _profileActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    const radius = 10.0;
    final titleColor = isPrimary ? Colors.white : const Color(0xFF26362B);
    final subtitleColor = isPrimary
        ? Colors.white.withValues(alpha: 0.78)
        : const Color(0xFF68736B);
    final iconBackground = isPrimary
        ? Colors.white.withValues(alpha: 0.18)
        : accentColor.withValues(alpha: 0.12);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: isPrimary
                ? const Color(0x33315A39)
                : const Color(0x14000000),
            blurRadius: isPrimary ? 18 : 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            color: isPrimary ? null : Colors.white,
            gradient: isPrimary
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF315A39), Color(0xFF39744B)],
                  )
                : null,
            borderRadius: BorderRadius.circular(radius),
            border: isPrimary
                ? null
                : Border.all(color: const Color(0xFFDCE6DE), width: 1.1),
          ),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: iconBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: isPrimary ? Colors.white : accentColor,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 14,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 12,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: isPrimary
                          ? Colors.white.withValues(alpha: 0.9)
                          : accentColor,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
