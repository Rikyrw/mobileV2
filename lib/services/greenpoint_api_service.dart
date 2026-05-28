import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class GreenPointApiException implements Exception {
  GreenPointApiException(this.message, {this.statusCode, this.data});

  final String message;
  final int? statusCode;
  final Map<String, dynamic>? data;

  @override
  String toString() => message;
}

class GreenPointPagedResult {
  const GreenPointPagedResult({required this.items, required this.hasNextPage});

  final List<Map<String, dynamic>> items;
  final bool hasNextPage;
}

class GreenPointSetorItem {
  const GreenPointSetorItem({
    required this.idJenis,
    required this.beratKg,
    required this.photos,
  });

  final int idJenis;
  final double beratKg;
  final List<XFile> photos;
}

class GreenPointApiService {
  GreenPointApiService._();

  static String? _accessToken;

  static String get _baseUrl {
    final configured = dotenv.env['GREENPOINT_API_BASE_URL']?.trim();
    final base = (configured == null || configured.isEmpty)
        ? 'http://10.0.2.2:8000/api'
        : configured;

    return base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  }

  static String? get accessToken => _accessToken;

  static Map<String, String> get jsonHeaders {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (_accessToken != null && _accessToken!.isNotEmpty)
        'Authorization': 'Bearer $_accessToken',
    };
  }

  static void clearAuthToken() {
    _accessToken = null;
  }

  static void _storeAuthToken(Map<String, dynamic> response) {
    final token = response['access_token']?.toString().trim();
    if (token != null && token.isNotEmpty) {
      _accessToken = token;
    }
  }

  static Future<void> registerNasabah({
    required String fullName,
    required String userName,
    required String email,
    required String password,
    required String confirmPassword,
    String? address,
    String? phone,
  }) async {
    await _post('/mobile/nasabah/register', {
      'nama': fullName,
      'username': userName,
      'email': email,
      'password': password,
      'konfirmasi_password': confirmPassword,
      'alamat': address,
      'no_hp': phone,
    });
  }

  static Future<Map<String, dynamic>?> fetchNasabahByEmail(String email) async {
    final response = await _get('/mobile/nasabah/profile', {
      'email': email.trim().toLowerCase(),
    });
    final data = response['data'];
    _storeAuthToken(response);

    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  static Future<Map<String, dynamic>?> lookupNasabah(
    String identifier, {
    bool includeEmailMatch = true,
  }) async {
    final response = await _get('/mobile/nasabah/lookup', {
      'identifier': identifier.trim(),
      'include_email_match': includeEmailMatch ? '1' : '0',
    });
    final data = response['data'];

    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  static Future<bool> emailExists(String email) async {
    final response = await _get('/mobile/nasabah/email-availability', {
      'email': email.trim().toLowerCase(),
    });

    return response['exists'] == true;
  }

  static Future<Map<String, dynamic>?> updateProfile({
    required String oldEmail,
    required String fullName,
    required String userName,
    required String email,
    required String address,
    required String phone,
  }) async {
    final response = await _patch('/mobile/nasabah/profile', {
      'old_email': oldEmail,
      'nama_lengkap': fullName,
      'user_name': userName,
      'email': email,
      'alamat': address,
      'no_hp': phone,
    });
    final data = response['data'];

    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  static Future<Map<String, dynamic>?> mirrorNasabahProfile({
    required String firebaseUid,
    required String email,
    String? userName,
    String? fullName,
    String? address,
    String? phone,
    String? photoUrl,
    String? googleId,
    String? provider,
    num? balance,
  }) async {
    final response = await _post(
      '/mobile/nasabah/mirror-profile',
      {
        'firebase_uid': firebaseUid,
        'email': email,
        'user_name': userName,
        'nama_lengkap': fullName,
        'alamat': address,
        'no_hp': phone,
        'photo_url': photoUrl,
        'google_id': googleId,
        'provider': provider,
        'saldo': balance,
        'device_name': 'greenpoint-mobile',
      }..removeWhere((_, value) => value == null),
    );
    final data = response['data'];
    _storeAuthToken(response);

    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  static Future<void> markPasswordManagedByFirebase({
    required String email,
    required String firebaseUid,
  }) async {
    await _patch('/mobile/nasabah/password-marker', {
      'email': email,
      'firebase_uid': firebaseUid,
    });
  }

  static Future<void> resendVerificationEmail(String email) async {
    await _post('/mobile/nasabah/email-verification/resend', {'email': email});
  }

  static Future<void> sendPasswordReset(
    String identifier, {
    String? email,
  }) async {
    final normalizedIdentifier = identifier.trim();
    final emailCandidate =
        _emailCandidate(email) ?? _emailCandidate(normalizedIdentifier);
    final body = <String, dynamic>{'identifier': normalizedIdentifier};

    if (emailCandidate != null) {
      body['email'] = emailCandidate;
    } else if (normalizedIdentifier.isNotEmpty) {
      body['username'] = normalizedIdentifier;
    }

    await _post('/mobile/nasabah/password-reset', body);
  }

  static Future<Map<String, dynamic>> verifyManualLogin({
    required String identifier,
    required String password,
  }) async {
    final response = await _post('/mobile/nasabah/verify-login', {
      'identifier': identifier,
      'password': password,
      'device_name': 'greenpoint-mobile',
    });
    _storeAuthToken(response);
    final user = response['user'];

    return user is Map<String, dynamic> ? user : <String, dynamic>{};
  }

  static Future<void> logout() async {
    if (_accessToken == null || _accessToken!.isEmpty) {
      clearAuthToken();
      return;
    }

    try {
      await _post('/mobile/nasabah/logout', {
        'device_name': 'greenpoint-mobile',
      });
    } finally {
      clearAuthToken();
    }
  }

  static Future<List<Map<String, dynamic>>> fetchWasteTypes() async {
    final response = await _get('/mobile/nasabah/waste-types');

    return _asMapList(response['data']);
  }

  static Future<GreenPointPagedResult> fetchSetorHistoryPage({
    required int nasabahId,
    required int page,
    required int pageSize,
    DateTime? from,
    DateTime? to,
    bool pendingOnly = false,
  }) async {
    final response = await _get('/mobile/nasabah/setor-history', {
      'nasabah_id': nasabahId.toString(),
      'page': page.toString(),
      'page_size': pageSize.toString(),
      'pending_only': pendingOnly ? '1' : '0',
      if (from != null) 'from': _formatDateQuery(from),
      if (to != null) 'to': _formatDateQuery(to),
    });

    return GreenPointPagedResult(
      items: _asMapList(response['items']),
      hasNextPage: response['has_next_page'] == true,
    );
  }

  static Future<GreenPointPagedResult> fetchPpobTransactionPage({
    required int nasabahId,
    required int page,
    required int pageSize,
    DateTime? from,
    DateTime? to,
    bool pendingOnly = false,
  }) async {
    final response = await _get('/mobile/nasabah/ppob-transactions', {
      'nasabah_id': nasabahId.toString(),
      'page': page.toString(),
      'page_size': pageSize.toString(),
      'pending_only': pendingOnly ? '1' : '0',
      if (from != null) 'from': _formatDateQuery(from),
      if (to != null) 'to': _formatDateQuery(to),
    });

    return GreenPointPagedResult(
      items: _asMapList(response['items']),
      hasNextPage: response['has_next_page'] == true,
    );
  }

  static Future<Map<String, dynamic>> fetchDashboard({
    required int nasabahId,
    required DateTime from,
    required DateTime to,
  }) {
    return _get('/mobile/nasabah/dashboard', {
      'nasabah_id': nasabahId.toString(),
      'from': _formatDateQuery(from),
      'to': _formatDateQuery(to),
    });
  }

  static Future<List<Map<String, dynamic>>> fetchTopupHistory({
    required int nasabahId,
    DateTime? date,
    int limit = 5,
  }) async {
    final response = await _get('/mobile/nasabah/topups', {
      'nasabah_id': nasabahId.toString(),
      'limit': limit.toString(),
      if (date != null) 'date': _formatDateQuery(date),
    });

    return _asMapList(response['data']);
  }

  static Future<Map<String, dynamic>> checkTopupStatus(String orderId) {
    return _get('/mobile/nasabah/topup/status', {'order_id': orderId});
  }

  static Future<void> submitPpob({
    required int nasabahId,
    required String jenisPenukaran,
    required int nominal,
    required String deskripsi,
  }) async {
    await _post('/mobile/nasabah/ppob', {
      'id_nasabah': nasabahId,
      'jenis_penukaran': jenisPenukaran,
      'nominal': nominal,
      'deskripsi': deskripsi,
    });
  }

  static Future<void> submitSetorSampah({
    required int nasabahId,
    required List<GreenPointSetorItem> items,
  }) async {
    final payloadItems = <Map<String, dynamic>>[];

    for (final item in items) {
      final photos = <Map<String, dynamic>>[];
      for (final photo in item.photos) {
        final bytes = await photo.readAsBytes();
        final extension = _fileExtension(photo.path);
        photos.add({
          'data': base64Encode(bytes),
          'mime_type': photo.mimeType ?? _mimeTypeFromExtension(extension),
          'extension': extension,
        });
      }

      payloadItems.add({
        'id_jenis': item.idJenis,
        'berat_kg': item.beratKg,
        'photos': photos,
      });
    }

    await _post('/mobile/nasabah/setor', {
      'id_nasabah': nasabahId,
      'items': payloadItems,
    });
  }

  static Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, String>? queryParameters,
  ]) async {
    return _request('GET', path, queryParameters: queryParameters);
  }

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    return _request('POST', path, body: body);
  }

  static Future<Map<String, dynamic>> _patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    return _request('PATCH', path, body: body);
  }

  static Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl$path',
    ).replace(queryParameters: queryParameters);

    try {
      final headers = jsonHeaders;
      final encodedBody = body == null ? null : jsonEncode(body);
      final request = switch (method) {
        'GET' => http.get(uri, headers: headers),
        'PATCH' => http.patch(uri, headers: headers, body: encodedBody),
        _ => http.post(uri, headers: headers, body: encodedBody),
      };
      final response = await request.timeout(const Duration(seconds: 45));

      final decoded = _decodeJson(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw GreenPointApiException(
          _messageFrom(decoded, response.statusCode),
          statusCode: response.statusCode,
          data: decoded,
        );
      }

      return decoded;
    } on GreenPointApiException {
      rethrow;
    } on TimeoutException {
      throw GreenPointApiException(
        'Server GreenPoint terlalu lama memproses request. Coba lagi beberapa saat.',
      );
    } catch (_) {
      throw GreenPointApiException(
        'Tidak bisa terhubung ke server GreenPoint. Pastikan server Laravel aktif.',
      );
    }
  }

  static Map<String, dynamic> _decodeJson(String body) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  static String _messageFrom(Map<String, dynamic> decoded, int statusCode) {
    final errors = decoded['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) {
        return first.first.toString();
      }

      if (first != null) {
        return first.toString();
      }
    }

    final message = decoded['message'];
    if (message != null && message.toString().trim().isNotEmpty) {
      return message.toString();
    }

    return 'Request GreenPoint gagal (HTTP $statusCode).';
  }

  static String? _emailCandidate(String? value) {
    final text = value?.trim().toLowerCase();
    if (text == null || text.isEmpty || !text.contains('@')) {
      return null;
    }

    return text;
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

  static String _formatDateQuery(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$year-$month-$day';
  }

  static String _fileExtension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) {
      return 'jpg';
    }

    final ext = path.substring(dot + 1).toLowerCase();
    return ext == 'png' ? 'png' : 'jpg';
  }

  static String _mimeTypeFromExtension(String extension) {
    return extension == 'png' ? 'image/png' : 'image/jpeg';
  }
}
