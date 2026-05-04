import 'package:flutter/material.dart';

import 'dashboard.dart';
import 'perbarui_profil.dart';

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

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
      BottomNavigationItemConfig(
        iconAsset: 'assets/history.png',
        label: 'Riwayat',
        isActive: false,
        fallbackIcon: Icons.history,
        onTap: () {
          Navigator.of(context).pushReplacementNamed('/riwayat');
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
                            _dummyData.userName,
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
                                Text(
                                  _dummyData.fullName,
                                  style: const TextStyle(
                                    color: Color(0xFF333333),
                                    fontSize: 18,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _dummyData.username,
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
                                      _dummyData.saldo,
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
                                  _dummyData.address,
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
                                        _dummyData.email,
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
                                        _dummyData.phone,
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
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => PerbaruiProfilScreen(
                                          userData: {
                                            'nama': _dummyData.fullName,
                                            'username': _dummyData.username,
                                            'email': _dummyData.email,
                                            'alamat': _dummyData.address,
                                            'phone': _dummyData.phone,
                                          },
                                        ),
                                      ),
                                    );
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
                                    Navigator.of(
                                      context,
                                    ).pushReplacementNamed('/setor-sampah');
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
