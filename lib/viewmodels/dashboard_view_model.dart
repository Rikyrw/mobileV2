import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/app_cache_service.dart';
import '../services/firebase_account_service.dart';
import '../services/greenpoint_api_service.dart';

class DashboardVerificationRedirect {
  const DashboardVerificationRedirect({required this.email});

  final String email;
}

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _now = DateTime.now();
      _notify();
    });
  }

  static const String greeting = 'Hallo,';
  static const String fallbackUserName = 'Nasabah';
  static const String welcomeMessage = 'Selamat datang di Green Point';
  static const double monthlyWeightTargetKg = 50;

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
  bool _disposed = false;

  String get userName => _fetchedUserName ?? fallbackUserName;
  bool get loadingProfile => _loadingProfile;
  bool get loadingDashboard => _loadingDashboard;
  String? get currentEmail => _currentEmail;
  DashboardStats get stats => _stats;
  List<DashboardSetorPreview> get recentSetor =>
      List.unmodifiable(_recentSetor);
  List<DashboardPpobPreview> get recentPpob => List.unmodifiable(_recentPpob);
  DateTime get now => _now;

  String get saldoText {
    if (_saldo == null) {
      return _loadingProfile ? 'Memuat...' : 'Rp 0';
    }

    return formatRupiah(_saldo!.round());
  }

  String get level => dashboardLevel(_stats.totalWeightKg);

  double get monthlyWeightProgress {
    return (_stats.totalWeightKg / monthlyWeightTargetKg)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  String get currentDateText => formatDayDateTime(_now);

  Object? get routeArguments {
    final email = _currentEmail;
    return email == null ? null : {'email': email};
  }

  Future<DashboardVerificationRedirect?> loadUserProfile({
    String? emailArgument,
  }) async {
    if (_loadingProfile) return null;

    _setLoadingProfile(true);
    try {
      final firebaseUser = FirebaseAccountService.currentUser;
      final email = emailArgument ?? firebaseUser?.email;
      _currentEmail = email;
      _notify();

      if (email != null && email.isNotEmpty) {
        final record = await AppCacheService.fetchNasabahByEmail(
          email,
          forceRefresh: true,
        );
        if (_disposed) return null;

        if (record != null) {
          if (_emailNeedsVerification(record)) {
            await FirebaseAccountService.signOut();
            return DashboardVerificationRedirect(
              email: (record['email'] as String?) ?? email,
            );
          }

          final nasabahId = (record['id_nasabah'] as num?)?.toInt();
          _fetchedUserName =
              (record['nama_lengkap'] as String?) ??
              (record['user_name'] as String?);
          _saldo = (record['saldo'] as num?)?.toDouble();
          _notify();

          if (nasabahId != null) {
            unawaited(loadDashboardStats(nasabahId));
          }
          return null;
        }

        final firebaseProfile =
            await FirebaseAccountService.currentUserProfile();
        if (_disposed) return null;

        if (firebaseProfile != null && firebaseProfile['email'] == email) {
          _fetchedUserName =
              (firebaseProfile['nama_lengkap'] as String?) ??
              (firebaseProfile['user_name'] as String?);
          _notify();
        }
      }
    } catch (e) {
      debugPrint('Load user name error: $e');
    } finally {
      _setLoadingProfile(false);
    }

    return null;
  }

  Future<void> loadDashboardStats(int nasabahId) async {
    if (_loadingDashboard) return;

    _setLoadingDashboard(true);
    try {
      final now = DateTime.now();
      final currentStart = DateTime(now.year, now.month, 1);
      final currentEnd = DateTime(now.year, now.month + 1, 0);
      final dashboard = await GreenPointApiService.fetchDashboard(
        nasabahId: nasabahId,
        from: currentStart,
        to: currentEnd,
      );
      if (_disposed) return;

      _stats = _dashboardStatsFromMap(dashboard['stats']);
      _recentSetor = _asMapList(
        dashboard['recent_setor'],
      ).map(_mapRecentSetorRow).toList();
      _recentPpob = _asMapList(
        dashboard['recent_ppob'],
      ).map(_mapRecentPpobRow).toList();
      _notify();
    } catch (e) {
      debugPrint('Load dashboard stats error: $e');
    } finally {
      _setLoadingDashboard(false);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _clockTimer?.cancel();
    super.dispose();
  }

  void _setLoadingProfile(bool value) {
    if (_loadingProfile == value) return;
    _loadingProfile = value;
    _notify();
  }

  void _setLoadingDashboard(bool value) {
    if (_loadingDashboard == value) return;
    _loadingDashboard = value;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  static DashboardStats _dashboardStatsFromMap(Object? value) {
    if (value is! Map) {
      return DashboardStats.empty;
    }

    final map = Map<String, dynamic>.from(value);
    return DashboardStats(
      setorCount: (map['setorCount'] as num?)?.round() ?? 0,
      totalWeightKg: (map['totalWeightKg'] as num?)?.toDouble() ?? 0,
      completedSetorValue: (map['completedSetorValue'] as num?)?.round() ?? 0,
      ppobCount: (map['ppobCount'] as num?)?.round() ?? 0,
      ppobAmount: (map['ppobAmount'] as num?)?.round() ?? 0,
      withdrawalCount: (map['withdrawalCount'] as num?)?.round() ?? 0,
      withdrawalAmount: (map['withdrawalAmount'] as num?)?.round() ?? 0,
      waitingSetorCount: (map['waitingSetorCount'] as num?)?.round() ?? 0,
      completedSetorCount: (map['completedSetorCount'] as num?)?.round() ?? 0,
      rejectedSetorCount: (map['rejectedSetorCount'] as num?)?.round() ?? 0,
    );
  }

  static DashboardSetorPreview _mapRecentSetorRow(Map<String, dynamic> row) {
    var weightKg = 0.0;
    final details = row['detail_setor'];
    if (details is List) {
      for (final detail in details.whereType<Map>()) {
        weightKg += (detail['berat_kg'] as num?)?.toDouble() ?? 0.0;
      }
    }

    return DashboardSetorPreview(
      title: 'Setor #${row['id_transaksi_setor'] ?? '-'}',
      subtitle: '${formatWeight(weightKg)} - ${statusLabel(row['status'])}',
      amount: formatRupiah(((row['total_nilai'] as num?) ?? 0).round()),
      date: formatShortDate(row['tanggal_setor']?.toString()),
    );
  }

  static DashboardPpobPreview _mapRecentPpobRow(Map<String, dynamic> row) {
    final product = (row['jenis_penukaran']?.toString() ?? '-').toUpperCase();

    return DashboardPpobPreview(
      title: product,
      subtitle: statusLabel(row['status']),
      amount: formatRupiah(((row['nominal'] as num?) ?? 0).round()),
      date: formatShortDate(row['tanggal_pengajuan']?.toString()),
    );
  }

  static List<Map<String, dynamic>> _asMapList(Object? rows) {
    if (rows is! List) {
      return const [];
    }

    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  static bool _emailNeedsVerification(Map<String, dynamic> record) {
    final emailVerifiedAt = record['email_verified_at']?.toString().trim();
    final googleId = record['google_id']?.toString().trim();

    return (emailVerifiedAt == null || emailVerifiedAt.isEmpty) &&
        (googleId == null || googleId.isEmpty);
  }

  static String formatRupiah(int value) {
    if (value == 0) return 'Rp 0';
    final s = value.toString();
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return 'Rp ${s.replaceAllMapped(reg, (m) => '.')}';
  }

  static String formatWeight(double value) {
    if (value <= 0) return '0 kg';
    if (value == value.roundToDouble()) {
      return '${value.round()} kg';
    }
    return '${value.toStringAsFixed(1)} kg';
  }

  static String formatShortDate(String? raw) {
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

  static String statusLabel(Object? status) {
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

  static String dashboardLevel(double monthWeightKg) {
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

  static String formatDayDateTime(DateTime date) {
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
}

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
