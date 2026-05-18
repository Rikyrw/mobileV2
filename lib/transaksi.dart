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

  String? _fetchedUserName;
  bool _loadingProfile = false;
  String? _currentEmail;
  int? _nasabahId;
  bool _loadingTransaksi = false;
  List<TransaksiItem> _transactions = [];
  bool _hasLoadedTransactions = false;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _hasSearched = false;

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
    if (_nasabahId != null && !_loadingTransaksi && !_hasLoadedTransactions) {
      _loadTransactions(_nasabahId!, pendingOnly: true);
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
            .select('id_nasabah,nama_lengkap,user_name,email')
            .eq('email', email)
            .limit(1);

        if (res.isNotEmpty) {
          final record = res.first;
          final nasabahId = record['id_nasabah'] as int?;
          setState(() {
            _fetchedUserName = (record['nama_lengkap'] as String?) ?? (record['user_name'] as String?);
            _nasabahId = nasabahId;
          });
          if (nasabahId != null && !_hasLoadedTransactions) {
            _loadTransactions(nasabahId, pendingOnly: true);
          }
        }
      }
    } catch (e) {
      debugPrint('Load user name error: $e');
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _loadTransactions(int nasabahId, {bool pendingOnly = false}) async {
    if (_loadingTransaksi) return;
    setState(() => _loadingTransaksi = true);

    try {
      final query = Supabase.instance.client
          .from('penarikan_saldo')
          .select('id_penarikan,jenis_penukaran,nominal,status,tanggal_pengajuan,deskripsi')
          .eq('id_nasabah', nasabahId);

      if (pendingOnly) {
        query.eq('status', 'pending');
      } else if (_fromDate != null && _toDate != null) {
        final fromDate = _formatDateQuery(_fromDate!);
        final toDate = _formatDateQuery(_toDate!);
        query.gte('tanggal_pengajuan', fromDate).lte('tanggal_pengajuan', toDate);
      }

      final res = await query.order('tanggal_pengajuan', ascending: false);

      setState(() {
        _transactions = res.map((e) {
          final id = e['id_penarikan'] as int?;
          final nominal = (e['nominal'] as num?)?.toDouble() ?? 0.0;
          return TransaksiItem(
            transactionId: id == null ? '-' : 'TRX-$id',
            productName: (e['jenis_penukaran']?.toString() ?? '-').toUpperCase(),
            target: _formatPpobTarget(e['deskripsi']?.toString() ?? ''),
            amount: _formatRupiah(nominal.round()),
            date: _formatDate(e['tanggal_pengajuan']?.toString()),
            status: e['status']?.toString() ?? '-',
          );
        }).toList();
        _hasLoadedTransactions = true;
      });
    } catch (e) {
      debugPrint('Load transaksi error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat transaksi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingTransaksi = false);
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final lastAllowed = DateTime(now.year, now.month, now.day);
    final firstAllowed = lastAllowed.subtract(const Duration(days: 31));
    final initial = isFrom ? (_fromDate ?? lastAllowed) : (_toDate ?? lastAllowed);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstAllowed) ? firstAllowed : initial,
      firstDate: firstAllowed,
      lastDate: lastAllowed,
    );

    if (picked == null) return;

    setState(() {
      if (isFrom) {
        _fromDate = picked;
        if (_toDate != null && _toDate!.isBefore(picked)) {
          _toDate = picked;
        }
      } else {
        _toDate = picked;
        if (_fromDate != null && _fromDate!.isAfter(picked)) {
          _fromDate = picked;
        }
      }
    });
  }

  bool _validateRange(DateTime from, DateTime to) {
    final diff = to.difference(from).inDays;
    return diff <= 7;
  }

  String _formatRupiah(int value) {
    if (value == 0) return 'Rp 0';
    final s = value.toString();
    final reg = RegExp(r"\B(?=(\d{3})+(?!\d))");
    return 'Rp ' + s.replaceAllMapped(reg, (m) => '.');
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final normalized = raw.contains('T')
          ? raw.split('T').first
          : (raw.contains(' ') ? raw.split(' ').first : raw);
      final date = DateTime.parse(normalized);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      return '$day-$month-$year';
    } catch (_) {
      return raw;
    }
  }

  String _formatDateQuery(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$year-$month-$day';
  }

  String _formatPpobTarget(String raw) {
    if (raw.isEmpty) return '-';
    if (raw.startsWith('emoney:')) {
      return 'No Tujuan ${raw.replaceFirst('emoney:', '')}';
    }
    if (raw.startsWith('pulsa:')) {
      final parts = raw.split(':');
      if (parts.length >= 3) {
        final operator = parts[1].toUpperCase();
        final noHp = parts.sublist(2).join(':');
        return 'No HP $noHp ($operator)';
      }
      return 'No HP ${raw.replaceFirst('pulsa:', '')}';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final visibleTransactions = _hasSearched
        ? _transactions
        : _transactions.where((item) => item.status.toLowerCase() == 'pending').toList();
    final hasTransactionData = visibleTransactions.isNotEmpty;

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
                                _DateField(
                                  value: _fromDate == null ? 'Pilih tanggal' : _formatDate(_formatDateQuery(_fromDate!)),
                                  onTap: () => _pickDate(isFrom: true),
                                ),
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
                                _DateField(
                                  value: _toDate == null ? 'Pilih tanggal' : _formatDate(_formatDateQuery(_toDate!)),
                                  onTap: () => _pickDate(isFrom: false),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: (_nasabahId == null || _fromDate == null || _toDate == null)
                                  ? null
                                  : () {
                                      final from = _fromDate!;
                                      final to = _toDate!;
                                      if (!_validateRange(from, to)) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Periode mutasi maksimal 7 hari.')),
                                        );
                                        return;
                                      }
                                      setState(() => _hasSearched = true);
                                      _loadTransactions(_nasabahId!);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF315A39),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Tampilkan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_loadingTransaksi)
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
                            )
                          else if (!_hasSearched && hasTransactionData)
                            Column(
                              children: visibleTransactions
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
                          else if (!_hasSearched)
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  'Belum ada transaksi pending.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 16,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            )
                          else if (hasTransactionData)
                            Column(
                              children: visibleTransactions
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
                                  'Belum ada transaksi PPOB.',
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

  final TransaksiItem item;

  @override
  Widget build(BuildContext context) {
    final statusValue = item.status.toLowerCase();
    final isSuccess = statusValue == 'berhasil' || statusValue == 'approved' || statusValue == 'sukses';
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

class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
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

class TransaksiItem {
  const TransaksiItem({
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
