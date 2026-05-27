import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PagedCacheResult<T> {
  const PagedCacheResult({
    required this.items,
    required this.hasNextPage,
    required this.fromCache,
  });

  final List<T> items;
  final bool hasNextPage;
  final bool fromCache;
}

class _CacheEntry<T> {
  const _CacheEntry(this.data, this.cachedAt);

  final T data;
  final DateTime cachedAt;

  bool isFresh(Duration ttl) => DateTime.now().difference(cachedAt) < ttl;
}

class AppCacheService {
  AppCacheService._();

  static const Duration _profileTtl = Duration(minutes: 5);
  static const Duration _wasteTypeTtl = Duration(minutes: 15);
  static const Duration _activityTtl = Duration(minutes: 2);

  static const String _nasabahProfileColumns =
      'id_nasabah,nama_lengkap,user_name,email,no_hp,alamat,saldo,'
      'email_verified_at,google_id,photo_url,provider';

  static final Map<String, _CacheEntry<Map<String, dynamic>>> _profiles = {};
  static final Map<String, Future<Map<String, dynamic>?>> _profileInflight = {};

  static _CacheEntry<List<Map<String, dynamic>>>? _wasteTypes;
  static Future<List<Map<String, dynamic>>>? _wasteTypesInflight;

  static final Map<String, _CacheEntry<PagedCacheResult<Map<String, dynamic>>>>
  _setorHistoryPages = {};
  static final Map<String, _CacheEntry<PagedCacheResult<Map<String, dynamic>>>>
  _ppobTransactionPages = {};

  static Future<Map<String, dynamic>?> fetchNasabahByEmail(
    String email, {
    bool forceRefresh = false,
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return Future.value(null);
    }

    final cached = _profiles[normalizedEmail];
    if (!forceRefresh && cached != null && cached.isFresh(_profileTtl)) {
      return Future.value(Map<String, dynamic>.from(cached.data));
    }

    final existingRequest = _profileInflight[normalizedEmail];
    if (!forceRefresh && existingRequest != null) {
      return existingRequest;
    }

    final request = _fetchNasabahByEmail(email, normalizedEmail);
    _profileInflight[normalizedEmail] = request;

    request.whenComplete(() => _profileInflight.remove(normalizedEmail));
    return request;
  }

  static Future<List<Map<String, dynamic>>> fetchWasteTypes({
    bool forceRefresh = false,
  }) {
    final cached = _wasteTypes;
    if (!forceRefresh && cached != null && cached.isFresh(_wasteTypeTtl)) {
      return Future.value(_copyList(cached.data));
    }

    final existingRequest = _wasteTypesInflight;
    if (!forceRefresh && existingRequest != null) {
      return existingRequest;
    }

    final request = _fetchWasteTypes();
    _wasteTypesInflight = request;
    request.whenComplete(() => _wasteTypesInflight = null);
    return request;
  }

  static Future<PagedCacheResult<Map<String, dynamic>>> fetchSetorHistoryPage({
    required int nasabahId,
    required int page,
    required int pageSize,
    DateTime? from,
    DateTime? to,
    bool pendingOnly = false,
    bool forceRefresh = false,
  }) async {
    final safePage = page < 0 ? 0 : page;
    final safePageSize = pageSize < 1 ? 1 : pageSize;
    final cacheKey = _activityKey(
      prefix: 'setor',
      nasabahId: nasabahId,
      page: safePage,
      pageSize: safePageSize,
      pendingOnly: pendingOnly,
      from: from,
      to: to,
    );

    final cached = _setorHistoryPages[cacheKey];
    if (!forceRefresh && cached != null && cached.isFresh(_activityTtl)) {
      final cachedResult = cached.data;
      return PagedCacheResult(
        items: _copyList(cachedResult.items),
        hasNextPage: cachedResult.hasNextPage,
        fromCache: true,
      );
    }

    final offset = safePage * safePageSize;
    dynamic query = Supabase.instance.client
        .from('transaksi_setor')
        .select(
          'id_transaksi_setor,total_nilai,tanggal_setor,status,'
          'detail_setor(berat_kg,harga_kg,subtotal,jenis_sampah(nama_jenis))',
        )
        .eq('id_nasabah', nasabahId);

    if (pendingOnly) {
      query = query.eq('status', 'pending');
    } else if (from != null && to != null) {
      query = query
          .gte('tanggal_setor', _formatDateQuery(from))
          .lte('tanggal_setor', _formatDateQuery(to));
    }

    final rows = await query
        .order('tanggal_setor', ascending: false)
        .range(offset, offset + safePageSize);
    final pageRows = _copyList(_asMapList(rows));
    final hasNext = pageRows.length > safePageSize;
    final items = pageRows.take(safePageSize).toList();
    final result = PagedCacheResult(
      items: items,
      hasNextPage: hasNext,
      fromCache: false,
    );

    _setorHistoryPages[cacheKey] = _CacheEntry(result, DateTime.now());
    return result;
  }

  static Future<PagedCacheResult<Map<String, dynamic>>>
  fetchPpobTransactionPage({
    required int nasabahId,
    required int page,
    required int pageSize,
    DateTime? from,
    DateTime? to,
    bool pendingOnly = false,
    bool forceRefresh = false,
  }) async {
    final safePage = page < 0 ? 0 : page;
    final safePageSize = pageSize < 1 ? 1 : pageSize;
    final cacheKey = _activityKey(
      prefix: 'ppob',
      nasabahId: nasabahId,
      page: safePage,
      pageSize: safePageSize,
      pendingOnly: pendingOnly,
      from: from,
      to: to,
    );

    final cached = _ppobTransactionPages[cacheKey];
    if (!forceRefresh && cached != null && cached.isFresh(_activityTtl)) {
      final cachedResult = cached.data;
      return PagedCacheResult(
        items: _copyList(cachedResult.items),
        hasNextPage: cachedResult.hasNextPage,
        fromCache: true,
      );
    }

    final offset = safePage * safePageSize;
    dynamic query = Supabase.instance.client
        .from('penarikan_saldo')
        .select(
          'id_penarikan,jenis_penukaran,nominal,status,'
          'tanggal_pengajuan,deskripsi',
        )
        .eq('id_nasabah', nasabahId);

    if (pendingOnly) {
      query = query.eq('status', 'pending');
    } else if (from != null && to != null) {
      query = query
          .gte('tanggal_pengajuan', _formatDateQuery(from))
          .lte('tanggal_pengajuan', _formatDateQuery(to));
    }

    final rows = await query
        .order('tanggal_pengajuan', ascending: false)
        .range(offset, offset + safePageSize);
    final pageRows = _copyList(_asMapList(rows));
    final hasNext = pageRows.length > safePageSize;
    final items = pageRows.take(safePageSize).toList();
    final result = PagedCacheResult(
      items: items,
      hasNextPage: hasNext,
      fromCache: false,
    );

    _ppobTransactionPages[cacheKey] = _CacheEntry(result, DateTime.now());
    return result;
  }

  static void putNasabahProfile(Map<String, dynamic> profile) {
    final email = _text(profile['email'])?.toLowerCase();
    if (email == null) {
      return;
    }

    _profiles[email] = _CacheEntry(
      Map<String, dynamic>.from(profile),
      DateTime.now(),
    );
  }

  static void invalidateNasabahByEmail(String? email) {
    final normalizedEmail = email?.trim().toLowerCase();
    if (normalizedEmail == null || normalizedEmail.isEmpty) {
      return;
    }

    _profiles.remove(normalizedEmail);
    _profileInflight.remove(normalizedEmail);
  }

  static void invalidateActivity() {
    _setorHistoryPages.clear();
    _ppobTransactionPages.clear();
  }

  static void invalidateAll() {
    _profiles.clear();
    _profileInflight.clear();
    _wasteTypes = null;
    _wasteTypesInflight = null;
    invalidateActivity();
  }

  static Future<Map<String, dynamic>?> _fetchNasabahByEmail(
    String rawEmail,
    String normalizedEmail,
  ) async {
    final candidates = <String>{rawEmail.trim(), normalizedEmail}
      ..removeWhere((value) => value.isEmpty);

    try {
      for (final candidate in candidates) {
        final rows = await Supabase.instance.client
            .from('nasabah')
            .select(_nasabahProfileColumns)
            .eq('email', candidate)
            .limit(1);

        if (rows.isNotEmpty) {
          final profile = Map<String, dynamic>.from(rows.first);
          putNasabahProfile(profile);
          return Map<String, dynamic>.from(profile);
        }
      }
    } catch (e) {
      debugPrint('Cached nasabah lookup failed: $e');
    }

    return null;
  }

  static Future<List<Map<String, dynamic>>> _fetchWasteTypes() async {
    final rows = await Supabase.instance.client
        .from('jenis_sampah')
        .select('id_jenis_sampah, nama_jenis, harga_per_kg')
        .order('nama_jenis', ascending: true);

    final items = _asMapList(rows)
        .map(
          (item) => {
            'id': item['id_jenis_sampah'] as int,
            'name': item['nama_jenis'] as String,
            'price': (item['harga_per_kg'] as num).toDouble(),
          },
        )
        .toList();

    _wasteTypes = _CacheEntry(_copyList(items), DateTime.now());
    return _copyList(items);
  }

  static String _activityKey({
    required String prefix,
    required int nasabahId,
    required int page,
    required int pageSize,
    required bool pendingOnly,
    DateTime? from,
    DateTime? to,
  }) {
    return [
      prefix,
      nasabahId,
      page,
      pageSize,
      pendingOnly,
      from == null ? '-' : _formatDateQuery(from),
      to == null ? '-' : _formatDateQuery(to),
    ].join('|');
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

  static List<Map<String, dynamic>> _copyList(
    List<Map<String, dynamic>> items,
  ) {
    return items.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  static String _formatDateQuery(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$year-$month-$day';
  }

  static String? _text(Object? value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
