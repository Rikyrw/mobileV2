import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dashboard.dart';

class TransaksiScreen extends StatefulWidget {
  const TransaksiScreen({super.key});

  @override
  State<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends State<TransaksiScreen> {
  static const _dummyData = TransaksiDummyData(
    greeting: 'Halo,',
    userName: 'Haidar Rais',
    title: 'Daftar Transaksi PPOB',
    subtitle: 'Transaksi PPOB',
    emptyState: 'Memuat data transaksi...',
  );

  static const _dummyTransactions = [
    TransaksiItemDummy(
      transactionId: 'TRX-240421-001',
      productName: 'Token Listrik',
      target: 'PLN 12345678901',
      amount: 'Rp 50.000',
      date: '21 Apr 2026, 09:10',
      status: 'Berhasil',
    ),
    TransaksiItemDummy(
      transactionId: 'TRX-240420-002',
      productName: 'Pulsa Telkomsel',
      target: '0812 3456 7890',
      amount: 'Rp 25.000',
      date: '20 Apr 2026, 18:42',
      status: 'Diproses',
    ),
    TransaksiItemDummy(
      transactionId: 'TRX-240419-003',
      productName: 'BPJS Kesehatan',
      target: '0001122334455',
      amount: 'Rp 150.000',
      date: '19 Apr 2026, 07:55',
      status: 'Berhasil',
    ),
  ];

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
      final user = Supabase.instance.client.auth.currentUser;
      final email = emailArg ?? user?.email;
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
    final hasTransactionData = _dummyTransactions.isNotEmpty;

    final transaksiNavItems = [
      BottomNavigationItemConfig(
        iconAsset: 'assets/home11.png',
        label: 'Home',
        isActive: false,
        fallbackIcon: Icons.home,
        onTap: () {
          Navigator.of(context).pushReplacementNamed('/dashboard', arguments: {'email': _currentEmail});
        },
      ),
      const BottomNavigationItemConfig(
        iconAsset: 'assets/riwayat1.png',
        label: 'Transaksi',
        isActive: true,
        fallbackIcon: Icons.swap_horiz,
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
          Navigator.of(context).pushReplacementNamed('/riwayat', arguments: {'email': _currentEmail});
        },
      ),
      BottomNavigationItemConfig(
        iconAsset: 'assets/person.png',
        label: 'Profil',
        isActive: false,
        fallbackIcon: Icons.person,
        onTap: () {
          Navigator.of(context).pushReplacementNamed('/profil', arguments: {'email': _currentEmail});
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
                          if (hasTransactionData)
                            Column(
                              children: _dummyTransactions
                                  .map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: _TransactionCard(item: item),
                                    ),
                                  )
                                  .toList(),
                            )
                          else
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
          DashboardBottomNavigation(items: transaksiNavItems),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.item});

  final TransaksiItemDummy item;

  @override
  Widget build(BuildContext context) {
    final isSuccess = item.status == 'Berhasil';
    final statusBackground = isSuccess
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFF3E0);
    final statusTextColor = isSuccess
        ? const Color(0xFF2E7D32)
        : const Color(0xFFF57C00);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 14,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.target} - ${item.transactionId}',
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.date,
                  style: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 11,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.amount,
                style: const TextStyle(
                  color: Color(0xFF315A39),
                  fontSize: 14,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.status,
                  style: TextStyle(
                    color: statusTextColor,
                    fontSize: 11,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TransaksiDummyData {
  const TransaksiDummyData({
    required this.greeting,
    required this.userName,
    required this.title,
    required this.subtitle,
    required this.emptyState,
  });

  final String greeting;
  final String userName;
  final String title;
  final String subtitle;
  final String emptyState;
}

class TransaksiItemDummy {
  const TransaksiItemDummy({
    required this.transactionId,
    required this.productName,
    required this.target,
    required this.amount,
    required this.date,
    required this.status,
  });

  final String transactionId;
  final String productName;
  final String target;
  final String amount;
  final String date;
  final String status;
}
