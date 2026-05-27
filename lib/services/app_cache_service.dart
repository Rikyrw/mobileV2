import 'package:flutter/foundation.dart';

import 'greenpoint_api_service.dart';

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

    final request = _fetchNasabahByEmail(email);
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

    final pageResult = await GreenPointApiService.fetchSetorHistoryPage(
      nasabahId: nasabahId,
      page: safePage,
      pageSize: safePageSize,
      from: from,
      to: to,
      pendingOnly: pendingOnly,
    );
    final items = _copyList(pageResult.items);
    final result = PagedCacheResult(
      items: items,
      hasNextPage: pageResult.hasNextPage,
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

    final pageResult = await GreenPointApiService.fetchPpobTransactionPage(
      nasabahId: nasabahId,
      page: safePage,
      pageSize: safePageSize,
      from: from,
      to: to,
      pendingOnly: pendingOnly,
    );
    final items = _copyList(pageResult.items);
    final result = PagedCacheResult(
      items: items,
      hasNextPage: pageResult.hasNextPage,
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
  ) async {
    try {
      final profile = await GreenPointApiService.fetchNasabahByEmail(rawEmail);
      if (profile != null) {
        putNasabahProfile(profile);
        return Map<String, dynamic>.from(profile);
      }
    } catch (e) {
      debugPrint('Cached nasabah lookup through Laravel failed: $e');
    }

    return null;
  }

  static Future<List<Map<String, dynamic>>> _fetchWasteTypes() async {
    final items = await GreenPointApiService.fetchWasteTypes();

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
