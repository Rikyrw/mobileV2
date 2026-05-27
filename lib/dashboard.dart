import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mob_2/email_verification_notice.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/app_cache_service.dart';
import 'services/firebase_account_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const String _greeting = 'Hallo,';
  static const String _fallbackUserName = 'Nasabah';
  static const String _welcomeMessage = 'Selamat datang di Green Point';
  static const double _monthlyWeightTargetKg = 50;

  String? _fetchedUserName;
  double? _saldo;
  bool _loadingProfile = false;
  String? _currentEmail;
  bool _loadingDashboard = false;
  DashboardStats _stats = DashboardStats.empty;
  List<DashboardSetorPreview> _recentSetor = [];
  List<DashboardPpobPreview> _recentPpob = [];
  DateTime _now = DateTime.now();
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
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
        final record = await AppCacheService.fetchNasabahByEmail(
          email,
          forceRefresh: true,
        );

        if (record != null) {
          if (_emailNeedsVerification(record)) {
            await FirebaseAccountService.signOut();
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => EmailVerificationNoticeScreen(
                  email: (record['email'] as String?) ?? email,
                ),
              ),
            );
            return;
          }

          final nasabahId = record['id_nasabah'] as int?;
          final saldo = (record['saldo'] as num?)?.toDouble();
          setState(() {
            _fetchedUserName =
                (record['nama_lengkap'] as String?) ??
                (record['user_name'] as String?);
            _saldo = saldo;
          });
          if (nasabahId != null) {
            _loadDashboardStats(nasabahId);
          }
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

  Future<void> _loadDashboardStats(int nasabahId) async {
    if (_loadingDashboard) return;
    setState(() => _loadingDashboard = true);

    try {
      final now = DateTime.now();
      final currentStart = DateTime(now.year, now.month, 1);
      final currentEnd = DateTime(now.year, now.month + 1, 0);
      final stats = await _fetchDashboardStats(
        nasabahId,
        currentStart,
        currentEnd,
      );
      final recentSetor = await _fetchRecentSetor(nasabahId);
      final recentPpob = await _fetchRecentPpob(nasabahId);

      if (!mounted) return;
      setState(() {
        _stats = stats;
        _recentSetor = recentSetor;
        _recentPpob = recentPpob;
      });
    } catch (e) {
      debugPrint('Load dashboard stats error: $e');
    } finally {
      if (mounted) setState(() => _loadingDashboard = false);
    }
  }

  Future<DashboardStats> _fetchDashboardStats(
    int nasabahId,
    DateTime from,
    DateTime to,
  ) async {
    final fromDate = _formatDateQuery(from);
    final toDate = _formatDateQuery(to);
    final setorRowsRaw = await Supabase.instance.client
        .from('transaksi_setor')
        .select(
          'id_transaksi_setor,total_nilai,status,'
          'detail_setor(berat_kg,subtotal)',
        )
        .eq('id_nasabah', nasabahId)
        .gte('tanggal_setor', fromDate)
        .lte('tanggal_setor', toDate);

    final ppobRowsRaw = await Supabase.instance.client
        .from('penarikan_saldo')
        .select('id_penarikan,jenis_penukaran,nominal,status,deskripsi')
        .eq('id_nasabah', nasabahId)
        .gte('tanggal_pengajuan', fromDate)
        .lte('tanggal_pengajuan', toDate);

    final setorRows = _asMapList(setorRowsRaw);
    final ppobRows = _asMapList(ppobRowsRaw);

    var totalWeightKg = 0.0;
    var completedSetorValue = 0;
    var waitingSetorCount = 0;
    var completedSetorCount = 0;
    var rejectedSetorCount = 0;

    for (final row in setorRows) {
      final bucket = _setorStatusBucket(row['status']);
      switch (bucket) {
        case DashboardSetorStatusBucket.waiting:
          waitingSetorCount++;
        case DashboardSetorStatusBucket.completed:
          completedSetorCount++;
          completedSetorValue += ((row['total_nilai'] as num?) ?? 0).round();
        case DashboardSetorStatusBucket.rejected:
          rejectedSetorCount++;
        case null:
          break;
      }

      final details = row['detail_setor'];
      if (details is List) {
        for (final detail in details.whereType<Map>()) {
          totalWeightKg += (detail['berat_kg'] as num?)?.toDouble() ?? 0.0;
        }
      }
    }

    var ppobCount = 0;
    var ppobAmount = 0;
    var withdrawalCount = 0;
    var withdrawalAmount = 0;

    for (final row in ppobRows) {
      final nominal = ((row['nominal'] as num?) ?? 0).round();
      if (_isPpobTransaction(row)) {
        ppobCount++;
        ppobAmount += nominal;
      } else {
        withdrawalCount++;
        withdrawalAmount += nominal;
      }
    }

    return DashboardStats(
      setorCount: setorRows.length,
      totalWeightKg: totalWeightKg,
      completedSetorValue: completedSetorValue,
      ppobCount: ppobCount,
      ppobAmount: ppobAmount,
      withdrawalCount: withdrawalCount,
      withdrawalAmount: withdrawalAmount,
      waitingSetorCount: waitingSetorCount,
      completedSetorCount: completedSetorCount,
      rejectedSetorCount: rejectedSetorCount,
    );
  }

  Future<List<DashboardSetorPreview>> _fetchRecentSetor(int nasabahId) async {
    final rowsRaw = await Supabase.instance.client
        .from('transaksi_setor')
        .select(
          'id_transaksi_setor,total_nilai,tanggal_setor,status,'
          'detail_setor(berat_kg)',
        )
        .eq('id_nasabah', nasabahId)
        .order('tanggal_setor', ascending: false)
        .limit(3);

    return _asMapList(rowsRaw).map((row) {
      var weightKg = 0.0;
      final details = row['detail_setor'];
      if (details is List) {
        for (final detail in details.whereType<Map>()) {
          weightKg += (detail['berat_kg'] as num?)?.toDouble() ?? 0.0;
        }
      }

      return DashboardSetorPreview(
        title: 'Setor #${row['id_transaksi_setor'] ?? '-'}',
        subtitle: '${_formatWeight(weightKg)} - ${_statusLabel(row['status'])}',
        amount: _formatRupiah(((row['total_nilai'] as num?) ?? 0).round()),
        date: _formatShortDate(row['tanggal_setor']?.toString()),
      );
    }).toList();
  }

  Future<List<DashboardPpobPreview>> _fetchRecentPpob(int nasabahId) async {
    final rowsRaw = await Supabase.instance.client
        .from('penarikan_saldo')
        .select(
          'id_penarikan,jenis_penukaran,nominal,status,'
          'tanggal_pengajuan,deskripsi',
        )
        .eq('id_nasabah', nasabahId)
        .order('tanggal_pengajuan', ascending: false)
        .limit(8);

    return _asMapList(rowsRaw).where(_isPpobTransaction).take(3).map((row) {
      final product = (row['jenis_penukaran']?.toString() ?? '-').toUpperCase();
      return DashboardPpobPreview(
        title: product,
        subtitle: _statusLabel(row['status']),
        amount: _formatRupiah(((row['nominal'] as num?) ?? 0).round()),
        date: _formatShortDate(row['tanggal_pengajuan']?.toString()),
      );
    }).toList();
  }

  List<Map<String, dynamic>> _asMapList(Object? rows) {
    if (rows is! List) {
      return const [];
    }

    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  DashboardSetorStatusBucket? _setorStatusBucket(Object? status) {
    final value = status?.toString().trim().toLowerCase() ?? '';

    if (value == 'pending' ||
        value == 'menunggu' ||
        value == 'diproses' ||
        value == 'process') {
      return DashboardSetorStatusBucket.waiting;
    }

    if (value == 'success' ||
        value == 'approved' ||
        value == 'berhasil' ||
        value == 'selesai' ||
        value == 'sukses') {
      return DashboardSetorStatusBucket.completed;
    }

    if (value == 'rejected' ||
        value == 'reject' ||
        value == 'ditolak' ||
        value == 'failed' ||
        value == 'gagal' ||
        value == 'cancelled' ||
        value == 'canceled') {
      return DashboardSetorStatusBucket.rejected;
    }

    return null;
  }

  bool _isPpobTransaction(Map<String, dynamic> row) {
    final description = row['deskripsi']?.toString().trim().toLowerCase() ?? '';
    if (description.startsWith('emoney:') ||
        description.startsWith('pln:') ||
        description.startsWith('pulsa:')) {
      return true;
    }

    final type = row['jenis_penukaran']?.toString().trim().toLowerCase() ?? '';
    return const {
      'dana',
      'gopay',
      'ovo',
      'shopeepay',
      'linkaja',
      'emoney',
      'pln',
      'pulsa',
    }.contains(type);
  }

  String _formatDateQuery(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$year-$month-$day';
  }

  String _formatRupiah(int value) {
    if (value == 0) return 'Rp 0';
    final s = value.toString();
    final reg = RegExp(r"\B(?=(\d{3})+(?!\d))");
    return 'Rp ${s.replaceAllMapped(reg, (m) => '.')}';
  }

  String _formatWeight(double value) {
    if (value <= 0) return '0 kg';
    if (value == value.roundToDouble()) {
      return '${value.round()} kg';
    }
    return '${value.toStringAsFixed(1)} kg';
  }

  String _formatShortDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '-';

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

  String _statusLabel(Object? status) {
    final value = status?.toString().trim();
    if (value == null || value.isEmpty) return '-';

    final lower = value.toLowerCase();
    if (lower == 'pending') return 'Menunggu';
    if (lower == 'success' ||
        lower == 'approved' ||
        lower == 'berhasil' ||
        lower == 'sukses') {
      return 'Selesai';
    }
    if (lower == 'rejected' || lower == 'reject' || lower == 'failed') {
      return 'Ditolak';
    }

    return value;
  }

  String _dashboardLevel(double monthWeightKg) {
    if (monthWeightKg >= 30) {
      return 'Pahlawan Daur Ulang';
    }
    if (monthWeightKg >= 10) {
      return 'Aktif Setor';
    }
    if (monthWeightKg > 0) {
      return 'Mulai Hijau';
    }
    return 'Level Hijau';
  }

  String _formatDayDateTime(DateTime date) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final dayName = days[date.weekday - 1];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');
    return '$dayName, $day $month $year $hour:$minute:$second';
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final saldoText = _saldo == null
        ? (_loadingProfile ? 'Memuat...' : 'Rp 0')
        : _formatRupiah(_saldo!.round());
    final level = _dashboardLevel(stats.totalWeightKg);
    final progress = (stats.totalWeightKg / _monthlyWeightTargetKg)
        .clamp(0.0, 1.0)
        .toDouble();

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Opacity(
                      opacity: 0.8,
                      child: Text(
                        _greeting,
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
                      _fetchedUserName ?? _fallbackUserName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Opacity(
                      opacity: 0.8,
                      child: Text(
                        _formatDayDateTime(_now),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                        ),
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
                    const Text(
                      _welcomeMessage,
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 14,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_loadingDashboard)
                      const LinearProgressIndicator(
                        minHeight: 3,
                        color: Color(0xFF315A39),
                        backgroundColor: Color(0xFFE8F5E9),
                      ),
                    if (_loadingDashboard) const SizedBox(height: 17),
                    _DashboardHeroBalance(
                      saldoText: saldoText,
                      level: level,
                      monthWeight: _formatWeight(stats.totalWeightKg),
                      onTopup: _openTopupSaldo,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _DashboardQuickAction(
                            label: 'E-Money',
                            icon: Icons.account_balance_wallet_rounded,
                            onTap: _openEmoney,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DashboardQuickAction(
                            label: 'PLN',
                            icon: Icons.bolt_rounded,
                            onTap: _openPln,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DashboardQuickAction(
                            label: 'Pulsa',
                            icon: Icons.phone_android_rounded,
                            onTap: _openPulsa,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                      children: [
                        _DashboardMetricCard(
                          title: 'Setor Bulan Ini',
                          value: stats.setorCount.toString(),
                          caption: 'Transaksi',
                          icon: Icons.recycling_outlined,
                          onTap: _openRiwayat,
                        ),
                        _DashboardMetricCard(
                          title: 'Berat Bulan Ini',
                          value: _formatWeight(stats.totalWeightKg),
                          caption: 'Total sampah',
                          icon: Icons.scale_outlined,
                          onTap: _openRiwayat,
                        ),
                        _DashboardMetricCard(
                          title: 'Saldo Masuk',
                          value: _formatRupiah(stats.completedSetorValue),
                          caption: 'Dari setor selesai',
                          icon: Icons.savings_outlined,
                          onTap: _openRiwayat,
                        ),
                        _DashboardMetricCard(
                          title: 'PPOB Bulan Ini',
                          value: _formatRupiah(stats.ppobAmount),
                          caption: '${stats.ppobCount} transaksi',
                          icon: Icons.receipt_long_outlined,
                          onTap: _openTransaksi,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _DashboardImpactCard(
                      currentWeightText: _formatWeight(stats.totalWeightKg),
                      targetWeightText: _formatWeight(_monthlyWeightTargetKg),
                      progress: progress,
                    ),
                    const SizedBox(height: 24),
                    const _DashboardSectionTitle(title: 'Ringkasan Bulan Ini'),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F8F6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE4EAE4)),
                      ),
                      child: Column(
                        children: [
                          _DashboardSummaryRow(
                            label: 'Setor bulan ini',
                            value: '${stats.setorCount} transaksi',
                          ),
                          _DashboardSummaryRow(
                            label: 'Total berat bulan ini',
                            value: _formatWeight(stats.totalWeightKg),
                          ),
                          _DashboardSummaryRow(
                            label: 'Saldo masuk dari setor',
                            value: _formatRupiah(stats.completedSetorValue),
                          ),
                          _DashboardSummaryRow(
                            label: 'PPOB bulan ini',
                            value: _formatRupiah(stats.ppobAmount),
                          ),
                          if (stats.withdrawalCount > 0)
                            _DashboardSummaryRow(
                              label: 'Penarikan saldo',
                              value:
                                  '${_formatRupiah(stats.withdrawalAmount)} (${stats.withdrawalCount})',
                              isLast: true,
                            )
                          else
                            const _DashboardSummaryRow(
                              label: 'Penarikan saldo',
                              value: 'Belum ada',
                              isLast: true,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _DashboardSectionTitle(title: 'Status Setor'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _DashboardStatusTile(
                            label: 'Menunggu',
                            value: stats.waitingSetorCount,
                            color: const Color(0xFFB7791F),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _DashboardStatusTile(
                            label: 'Selesai',
                            value: stats.completedSetorCount,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _DashboardStatusTile(
                            label: 'Ditolak',
                            value: stats.rejectedSetorCount,
                            color: const Color(0xFFB71C1C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _DashboardRecentSection(
                      title: 'Transaksi Setor Terbaru',
                      emptyText: 'Belum ada transaksi setor.',
                      onTap: _openRiwayat,
                      children: _recentSetor
                          .map(
                            (item) => _DashboardRecentTile(
                              title: item.title,
                              subtitle: item.subtitle,
                              amount: item.amount,
                              date: item.date,
                              icon: Icons.recycling_rounded,
                              onTap: _openRiwayat,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    _DashboardRecentSection(
                      title: 'Transaksi PPOB Terbaru',
                      emptyText: 'Belum ada transaksi PPOB.',
                      onTap: _openTransaksi,
                      children: _recentPpob
                          .map(
                            (item) => _DashboardRecentTile(
                              title: item.title,
                              subtitle: item.subtitle,
                              amount: item.amount,
                              date: item.date,
                              icon: Icons.receipt_long_rounded,
                              onTap: _openTransaksi,
                            ),
                          )
                          .toList(),
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

  Object? get _routeArguments {
    final email = _currentEmail;
    return email == null ? null : {'email': email};
  }

  void _openRiwayat() {
    Navigator.of(
      context,
    ).pushReplacementNamed('/riwayat', arguments: _routeArguments);
  }

  void _openTransaksi() {
    Navigator.of(
      context,
    ).pushReplacementNamed('/transaksi', arguments: _routeArguments);
  }

  void _openTopupSaldo() {
    Navigator.of(
      context,
    ).pushReplacementNamed('/topup-saldo', arguments: _routeArguments);
  }

  void _openEmoney() {
    Navigator.of(
      context,
    ).pushReplacementNamed('/emoney', arguments: _routeArguments);
  }

  void _openPln() {
    Navigator.of(
      context,
    ).pushReplacementNamed('/pln', arguments: _routeArguments);
  }

  void _openPulsa() {
    Navigator.of(
      context,
    ).pushReplacementNamed('/pulsa', arguments: _routeArguments);
  }

  static bool _emailNeedsVerification(Map<String, dynamic> record) {
    final emailVerifiedAt = record['email_verified_at']?.toString().trim();
    final googleId = record['google_id']?.toString().trim();

    return (emailVerifiedAt == null || emailVerifiedAt.isEmpty) &&
        (googleId == null || googleId.isEmpty);
  }
}

enum DashboardSetorStatusBucket { waiting, completed, rejected }

class DashboardStats {
  const DashboardStats({
    required this.setorCount,
    required this.totalWeightKg,
    required this.completedSetorValue,
    required this.ppobCount,
    required this.ppobAmount,
    required this.withdrawalCount,
    required this.withdrawalAmount,
    required this.waitingSetorCount,
    required this.completedSetorCount,
    required this.rejectedSetorCount,
  });

  static const empty = DashboardStats(
    setorCount: 0,
    totalWeightKg: 0,
    completedSetorValue: 0,
    ppobCount: 0,
    ppobAmount: 0,
    withdrawalCount: 0,
    withdrawalAmount: 0,
    waitingSetorCount: 0,
    completedSetorCount: 0,
    rejectedSetorCount: 0,
  );

  final int setorCount;
  final double totalWeightKg;
  final int completedSetorValue;
  final int ppobCount;
  final int ppobAmount;
  final int withdrawalCount;
  final int withdrawalAmount;
  final int waitingSetorCount;
  final int completedSetorCount;
  final int rejectedSetorCount;
}

class DashboardSetorPreview {
  const DashboardSetorPreview({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
  });

  final String title;
  final String subtitle;
  final String amount;
  final String date;
}

class DashboardPpobPreview {
  const DashboardPpobPreview({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
  });

  final String title;
  final String subtitle;
  final String amount;
  final String date;
}

class _DashboardSectionTitle extends StatelessWidget {
  const _DashboardSectionTitle({required this.title, this.onTap});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF333333),
              fontSize: 16,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (onTap != null)
          IconButton(
            onPressed: onTap,
            icon: const Icon(Icons.chevron_right_rounded),
            color: const Color(0xFF315A39),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }
}

class _DashboardHeroBalance extends StatelessWidget {
  const _DashboardHeroBalance({
    required this.saldoText,
    required this.level,
    required this.monthWeight,
    required this.onTopup,
  });

  final String saldoText;
  final String level;
  final String monthWeight;
  final VoidCallback onTopup;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF315A39),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF315A39).withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Saldo Saat Ini',
                  style: TextStyle(
                    color: Color(0xFFE8F5E9),
                    fontSize: 13,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  level,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              saldoText,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.eco_outlined,
                      color: Color(0xFFBFE6C6),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$monthWeight bulan ini',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE8F5E9),
                          fontSize: 12,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: onTopup,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Top Up'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF315A39),
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w800,
                    ),
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

class _DashboardQuickAction extends StatelessWidget {
  const _DashboardQuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          height: 74,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8F6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE4EAE4)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF315A39), size: 24),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 12,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardImpactCard extends StatelessWidget {
  const _DashboardImpactCard({
    required this.currentWeightText,
    required this.targetWeightText,
    required this.progress,
  });

  final String currentWeightText;
  final String targetWeightText;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8F1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9EADB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF315A39),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.eco_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Dampak Lingkungan',
                  style: TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 15,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '$currentWeightText sampah terkumpul bulan ini',
            style: const TextStyle(
              color: Color(0xFF315A39),
              fontSize: 17,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              color: const Color(0xFF315A39),
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Target bulanan $targetWeightText',
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 12,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardMetricCard extends StatelessWidget {
  const _DashboardMetricCard({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8F6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE4EAE4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: const Color(0xFF315A39), size: 20),
                  ),
                  const Spacer(),
                  if (onTap != null)
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF7A867E),
                      size: 20,
                    ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 12,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Color(0xFF315A39),
                    fontSize: 19,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF7A867E),
                  fontSize: 11,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardSummaryRow extends StatelessWidget {
  const _DashboardSummaryRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 13,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 13,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFE4EAE4)),
          ),
      ],
    );
  }
}

class _DashboardStatusTile extends StatelessWidget {
  const _DashboardStatusTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF333333),
              fontSize: 12,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardRecentSection extends StatelessWidget {
  const _DashboardRecentSection({
    required this.title,
    required this.emptyText,
    required this.children,
    required this.onTap,
  });

  final String title;
  final String emptyText;
  final List<Widget> children;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DashboardSectionTitle(title: title, onTap: onTap),
        const SizedBox(height: 12),
        if (children.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8F6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE4EAE4)),
            ),
            child: Text(
              emptyText,
              style: const TextStyle(
                color: Color(0xFF7A867E),
                fontSize: 13,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
              ),
            ),
          )
        else
          Column(children: children),
      ],
    );
  }
}

class _DashboardRecentTile extends StatelessWidget {
  const _DashboardRecentTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String amount;
  final String date;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8F6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE4EAE4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF315A39), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 13,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF7A867E),
                          fontSize: 12,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF315A39),
                        fontSize: 13,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(
                        color: Color(0xFF7A867E),
                        fontSize: 11,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Color(0xFF7A867E),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
            color: Colors.black.withValues(alpha: 0.1),
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
              colors: [
                backgroundColor,
                backgroundColor.withValues(alpha: 0.95),
              ],
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

    if (bottom <= 0) {
      return navChild;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: navChild,
    );
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
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
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

class PaginationControls extends StatelessWidget {
  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.hasNextPage,
    required this.isLoading,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final bool hasNextPage;
  final bool isLoading;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final canGoBack = currentPage > 0 && !isLoading;
    final canGoNext = hasNextPage && !isLoading;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 42,
            child: OutlinedButton(
              onPressed: canGoBack ? onPrevious : null,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(48, 42),
              ),
              child: const Icon(Icons.chevron_left_rounded, size: 22),
            ),
          ),
          Expanded(
            child: Text(
              'Halaman ${currentPage + 1}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF333333),
                fontSize: 13,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            height: 42,
            child: ElevatedButton(
              onPressed: canGoNext ? onNext : null,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(48, 42),
              ),
              child: const Icon(Icons.chevron_right_rounded, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
