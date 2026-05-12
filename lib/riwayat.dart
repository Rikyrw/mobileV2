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
  String? _currentEmail;
  int? _nasabahId;
  bool _loadingRiwayat = false;
  List<Map<String, dynamic>> _riwayatItems = [];
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _hasSearched = false;
  bool _hasLoadedRiwayat = false;

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
    if (_nasabahId != null && !_loadingRiwayat && !_hasLoadedRiwayat) {
      _loadRiwayat(_nasabahId!, pendingOnly: true);
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
          if (nasabahId != null && !_hasLoadedRiwayat) {
            _loadRiwayat(nasabahId, pendingOnly: true);
          }
        }
      }
    } catch (e) {
      debugPrint('Load user name error: $e');
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _loadRiwayat(int nasabahId, {DateTime? from, DateTime? to, bool pendingOnly = false}) async {
    if (_loadingRiwayat) return;
    setState(() => _loadingRiwayat = true);

    try {
      final query = Supabase.instance.client
          .from('transaksi_setor')
          .select('id_transaksi_setor,total_nilai,tanggal_setor,status,detail_setor(berat_kg,harga_kg,subtotal,jenis_sampah(nama_jenis))')
          .eq('id_nasabah', nasabahId);

      if (pendingOnly) {
        query.eq('status', 'pending');
      } else if (from != null && to != null) {
        final fromDate = _formatDateQuery(from);
        final toDate = _formatDateQuery(to);
        query.gte('tanggal_setor', fromDate).lte('tanggal_setor', toDate);
      }

      final res = await query.order('tanggal_setor', ascending: false);

      setState(() {
        _riwayatItems = res.map((e) => {
          'id': e['id_transaksi_setor'] as int,
          'total': (e['total_nilai'] as num).toDouble(),
          'tanggal': e['tanggal_setor']?.toString(),
          'status': e['status']?.toString() ?? '-',
          'details': (e['detail_setor'] as List<dynamic>? ?? []).map((d) => {
            'nama': (d['jenis_sampah']?['nama_jenis'] ?? '-').toString(),
            'berat': (d['berat_kg'] as num?)?.toDouble() ?? 0.0,
            'subtotal': (d['subtotal'] as num?)?.toDouble() ?? 0.0,
          }).toList(),
        }).toList();
        _hasLoadedRiwayat = true;
      });
    } catch (e) {
      debugPrint('Load riwayat error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat riwayat: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingRiwayat = false);
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

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final date = DateTime.parse(raw);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      return '$day-$month-$year';
    } catch (_) {
      return raw;
    }
  }

  String _formatRupiah(int value) {
    if (value == 0) return 'Rp 0';
    final s = value.toString();
    final reg = RegExp(r"\B(?=(\d{3})+(?!\d))");
    return 'Rp ' + s.replaceAllMapped(reg, (m) => '.');
  }

  String _formatDateQuery(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$year-$month-$day';
  }

  String _formatWeight(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _hasSearched
        ? _riwayatItems
        : _riwayatItems.where((item) => (item['status'] ?? '').toString().toLowerCase() == 'pending').toList();
    final navItems = [
      BottomNavigationItemConfig(
        iconAsset: 'assets/home11.png',
        label: 'Home',
        isActive: false,
        fallbackIcon: Icons.home,
        onTap: () {
          Navigator.of(context).pushReplacementNamed('/dashboard', arguments: {'email': _currentEmail});
        },
      ),
      BottomNavigationItemConfig(
        iconAsset: 'assets/riwayat1.png',
        label: 'Transaksi',
        isActive: false,
        fallbackIcon: Icons.swap_horiz,
        onTap: () {
          Navigator.of(context).pushReplacementNamed('/transaksi', arguments: {'email': _currentEmail});
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
                                      _loadRiwayat(_nasabahId!, from: from, to: to);
                                    },
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
                          if (_loadingRiwayat)
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
                          else if (!_hasSearched && visibleItems.isNotEmpty)
                            Column(
                              children: visibleItems.map((item) {
                                final details = item['details'] as List<dynamic>? ?? [];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE0E0E0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _formatDate(item['tanggal'] as String?),
                                                  style: const TextStyle(
                                                    color: Color(0xFF333333),
                                                    fontSize: 14,
                                                    fontFamily: 'Roboto',
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'Total ${_formatRupiah((item['total'] as double).round())}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF666666),
                                                    fontSize: 12,
                                                    fontFamily: 'Roboto',
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            (item['status'] as String).toUpperCase(),
                                            style: const TextStyle(
                                              color: Color(0xFF315A39),
                                              fontSize: 12,
                                              fontFamily: 'Roboto',
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (details.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Column(
                                          children: details.map((d) {
                                            final name = (d['nama'] ?? '-').toString();
                                            final weight = d['berat'] as double? ?? 0.0;
                                            final subtotal = d['subtotal'] as double? ?? 0.0;
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 6),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      '$name - ${_formatWeight(weight)} kg',
                                                      style: const TextStyle(
                                                        color: Color(0xFF666666),
                                                        fontSize: 12,
                                                        fontFamily: 'Roboto',
                                                        fontWeight: FontWeight.w400,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    _formatRupiah(subtotal.round()),
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
                                          }).toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                            )
                          else if (!_hasSearched)
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  'Belum ada riwayat pending.',
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
                          else if (visibleItems.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  'Belum ada riwayat setor sampah.',
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
                          else
                            Column(
                              children: visibleItems.map((item) {
                                final details = item['details'] as List<dynamic>? ?? [];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE0E0E0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _formatDate(item['tanggal'] as String?),
                                                  style: const TextStyle(
                                                    color: Color(0xFF333333),
                                                    fontSize: 14,
                                                    fontFamily: 'Roboto',
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'Total ${_formatRupiah((item['total'] as double).round())}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF666666),
                                                    fontSize: 12,
                                                    fontFamily: 'Roboto',
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            (item['status'] as String).toUpperCase(),
                                            style: const TextStyle(
                                              color: Color(0xFF315A39),
                                              fontSize: 12,
                                              fontFamily: 'Roboto',
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (details.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Column(
                                          children: details.map((d) {
                                            final name = (d['nama'] ?? '-').toString();
                                            final weight = d['berat'] as double? ?? 0.0;
                                            final subtotal = d['subtotal'] as double? ?? 0.0;
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 6),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      '$name - ${_formatWeight(weight)} kg',
                                                      style: const TextStyle(
                                                        color: Color(0xFF666666),
                                                        fontSize: 12,
                                                        fontFamily: 'Roboto',
                                                        fontWeight: FontWeight.w400,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    _formatRupiah(subtotal.round()),
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
                                          }).toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
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
