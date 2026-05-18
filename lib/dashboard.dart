import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/firebase_account_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _dummyData = DashboardDummyData(
    greeting: 'Hallo,',
    userName: 'Haidar Rais',
    welcomeMessage: 'Selamat datang di Green Point',
    setorSampahCount: '145',
    setorSampahGrowth: '+12 dari bulan lalu',
    ppobBalance: 'Rp 2.326.000',
    ppobGrowth: '+12 dari bulan lalu',
  );

  String? _fetchedUserName;
  bool _loadingProfile = false;
  String? _currentEmail;

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
            .select('nama_lengkap,user_name,email')
            .eq('email', email)
            .limit(1);

        if (res.isNotEmpty) {
          final record = res.first;
          setState(() {
            _fetchedUserName =
                (record['nama_lengkap'] as String?) ??
                (record['user_name'] as String?);
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
      const BottomNavigationItemConfig(
        iconAsset: 'assets/home11.png',
        label: 'Home',
        isActive: true,
        fallbackIcon: Icons.home,
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
      BottomNavigationItemConfig(
        iconAsset: 'assets/person.png',
        label: 'Profil',
        isActive: false,
        fallbackIcon: Icons.person,
        onTap: () {
          Navigator.of(context).pushReplacementNamed(
            '/profil',
            arguments: {'email': _currentEmail},
          );
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
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _fetchedUserName ?? _dummyData.userName,
                            style: TextStyle(
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
                          const Text(
                            'Dashboard',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 20,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _dummyData.welcomeMessage,
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 14,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F8F4),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(
                                        context,
                                      ).pushReplacementNamed(
                                        '/setor-sampah',
                                        arguments: {'email': _currentEmail},
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(14),
                                          bottomLeft: Radius.circular(14),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Transaksi\nSetor Sampah',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Color(0xFF315A39),
                                              fontSize: 14,
                                              fontFamily: 'Roboto',
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            _dummyData.setorSampahCount,
                                            style: TextStyle(
                                              color: Color(0xFF315A39),
                                              fontSize: 20,
                                              fontFamily: 'Roboto',
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            _dummyData.setorSampahGrowth,
                                            style: TextStyle(
                                              color: Color(0xFF4CAF50),
                                              fontSize: 12,
                                              fontFamily: 'Roboto',
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 80,
                                  color: const Color(0xFFE0E0E0),
                                ),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEDF7ED),
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(14),
                                        bottomRight: Radius.circular(14),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Transaksi\nPPOB',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFF315A39),
                                            fontSize: 14,
                                            fontFamily: 'Roboto',
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          _dummyData.ppobBalance,
                                          style: TextStyle(
                                            color: Color(0xFF315A39),
                                            fontSize: 20,
                                            fontFamily: 'Roboto',
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          _dummyData.ppobGrowth,
                                          style: TextStyle(
                                            color: Color(0xFF4CAF50),
                                            fontSize: 12,
                                            fontFamily: 'Roboto',
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            'Layanan Lainnya',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 16,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(
                                        context,
                                      ).pushReplacementNamed(
                                        '/emoney',
                                        arguments: {'email': _currentEmail},
                                      );
                                    },
                                    child: _serviceCard(
                                      label: 'E-Money',
                                      iconAsset: 'assets/wallet2.png',
                                      fallbackIcon:
                                          Icons.account_balance_wallet,
                                      rightMargin: 16,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(
                                        context,
                                      ).pushReplacementNamed(
                                        '/pln',
                                        arguments: {'email': _currentEmail},
                                      );
                                    },
                                    child: _serviceCard(
                                      label: 'PLN',
                                      iconAsset: 'assets/pln1.png',
                                      fallbackIcon: Icons.bolt,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushReplacementNamed(
                                    '/pulsa',
                                    arguments: {'email': _currentEmail},
                                  );
                                },
                                child: _serviceCard(
                                  label: 'Pulsa',
                                  iconAsset: 'assets/pulsa1.png',
                                  fallbackIcon: Icons.phone_android,
                                ),
                              ),
                            ],
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

  static Widget _serviceCard({
    required String label,
    required String iconAsset,
    required IconData fallbackIcon,
    double rightMargin = 0,
  }) {
    return Container(
      width: 100,
      height: 100,
      margin: EdgeInsets.only(right: rightMargin),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _AssetIcon(
            assetPath: iconAsset,
            fallbackIcon: fallbackIcon,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF333333),
              fontSize: 12,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetIcon extends StatelessWidget {
  const _AssetIcon({
    required this.assetPath,
    required this.fallbackIcon,
    required this.size,
  });

  final String assetPath;
  final IconData fallbackIcon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(fallbackIcon, size: size, color: const Color(0xFF333333));
      },
    );
  }
}

class DashboardDummyData {
  const DashboardDummyData({
    required this.greeting,
    required this.userName,
    required this.welcomeMessage,
    required this.setorSampahCount,
    required this.setorSampahGrowth,
    required this.ppobBalance,
    required this.ppobGrowth,
  });

  final String greeting;
  final String userName;
  final String welcomeMessage;
  final String setorSampahCount;
  final String setorSampahGrowth;
  final String ppobBalance;
  final String ppobGrowth;
}

class DashboardBottomNavigation extends StatelessWidget {
  const DashboardBottomNavigation({
    super.key,
    this.items = _defaultItems,
    this.backgroundColor = const Color.fromARGB(255, 255, 255, 255),
    this.bottom = 0,
    this.fixedHeight,
    this.useSafeArea = true,
    this.safeAreaBottomSpacing = 8,
    this.borderRadius = const BorderRadius.only(
      topLeft: Radius.circular(24),
      topRight: Radius.circular(24),
    ),
    this.elevation = 8,
    this.paddingHorizontal = 4,
    this.marginHorizontal = 0,
  });

  static const List<BottomNavigationItemConfig> _defaultItems = [
    BottomNavigationItemConfig(
      iconAsset: 'assets/home11.png',
      label: 'Home',
      isActive: true,
      fallbackIcon: Icons.home,
    ),
    BottomNavigationItemConfig(
      iconAsset: 'assets/riwayat1.png',
      label: 'Transaksi',
      isActive: false,
      fallbackIcon: Icons.swap_horiz,
    ),
    BottomNavigationItemConfig(
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
    ),
    BottomNavigationItemConfig(
      iconAsset: 'assets/person.png',
      label: 'Profil',
      isActive: false,
      fallbackIcon: Icons.person,
    ),
  ];

  final List<BottomNavigationItemConfig> items;
  final Color backgroundColor;
  final double bottom;
  final double? fixedHeight;
  final bool useSafeArea;
  final double safeAreaBottomSpacing;
  final BorderRadius borderRadius;
  final double elevation;
  final double paddingHorizontal;
  final double marginHorizontal;

  @override
  Widget build(BuildContext context) {
    // Get responsive screen dimensions
    final screenHeight = MediaQuery.sizeOf(context).height;
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Responsive height: 7-9% of screen height, with min 56 and max 80
    final navHeight = fixedHeight ?? (screenHeight * 0.08).clamp(56.0, 80.0);

    // Responsive padding: larger padding on wider screens
    final responsivePaddingHorizontal = screenWidth > 600
        ? paddingHorizontal + 8
        : paddingHorizontal;

    // Responsive margin: add margin on tablets
    final responsiveMarginHorizontal = screenWidth > 600
        ? marginHorizontal + 16
        : marginHorizontal;

    final navBar = Container(
      margin: EdgeInsets.symmetric(horizontal: responsiveMarginHorizontal),
      height: navHeight,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: elevation,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: responsivePaddingHorizontal,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            // Optional: Add subtle gradient for premium look
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [backgroundColor, backgroundColor.withOpacity(0.95)],
            ),
          ),
          child: Row(
            children: items
                .map(
                  (item) => Expanded(
                    child: _BottomNavItem(
                      iconAsset: item.iconAsset,
                      label: item.label,
                      isActive: item.isActive,
                      fallbackIcon: item.fallbackIcon,
                      onTap: item.onTap,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );

    final navChild = useSafeArea
        ? SafeArea(
            top: false,
            minimum: EdgeInsets.only(bottom: safeAreaBottomSpacing),
            child: navBar,
          )
        : navBar;

    return Positioned(left: 0, right: 0, bottom: bottom, child: navChild);
  }
}

// Optional: Enhanced _BottomNavItem with responsive sizing
class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.iconAsset,
    required this.label,
    required this.isActive,
    required this.fallbackIcon,
    this.onTap,
  });

  final String iconAsset;
  final String label;
  final bool isActive;
  final IconData fallbackIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth > 600;

    // Responsive icon size
    final iconSize = isTablet ? 28.0 : 24.0;

    // Responsive font size
    final fontSize = isTablet ? 14.0 : 12.0;

    // Active color - you can customize this
    final activeColor = const Color.fromARGB(255, 33, 90, 36);
    final inactiveColor = const Color.fromARGB(255, 187, 186, 186);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with animation
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Image.asset(
                iconAsset,
                key: ValueKey(iconAsset),
                width: iconSize,
                height: iconSize,
                color: isActive ? activeColor : inactiveColor,
                errorBuilder: (context, error, stackTrace) => Icon(
                  fallbackIcon,
                  size: iconSize,
                  color: isActive ? activeColor : inactiveColor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Label with animation
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? activeColor : inactiveColor,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomNavigationItemConfig {
  const BottomNavigationItemConfig({
    required this.iconAsset,
    required this.label,
    required this.isActive,
    required this.fallbackIcon,
    this.onTap,
  });

  final String iconAsset;
  final String label;
  final bool isActive;
  final IconData fallbackIcon;
  final VoidCallback? onTap;
}

// class _BottomNavItem extends StatelessWidget {
//   const _BottomNavItem({
//     required this.iconAsset,
//     required this.label,
//     required this.isActive,
//     required this.fallbackIcon,
//     required this.onTap,
//   });

//   final String iconAsset;
//   final String label;
//   final bool isActive;
//   final IconData fallbackIcon;
//   final VoidCallback? onTap;

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       child: Padding(
//         padding: const EdgeInsets.all(8),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               width: 32,
//               height: 32,
//               padding: const EdgeInsets.all(6),
//               alignment: Alignment.center,
//               child: _BottomNavIcon(
//                 assetPath: iconAsset,
//                 fallbackIcon: fallbackIcon,
//                 size: 24,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 color: isActive
//                     ? const Color(0xFF315A39)
//                     : const Color(0xFF666666),
//                 fontSize: 10,
//                 fontFamily: 'Roboto',
//                 fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class _BottomNavIcon extends StatelessWidget {
  const _BottomNavIcon({
    required this.assetPath,
    required this.fallbackIcon,
    required this.size,
  });

  final String assetPath;
  final IconData fallbackIcon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(fallbackIcon, size: size, color: const Color(0xFF333333));
      },
    );
  }
}
