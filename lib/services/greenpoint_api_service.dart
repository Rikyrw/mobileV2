import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GreenPointApiException implements Exception {
  GreenPointApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GreenPointApiService {
  GreenPointApiService._();

  static String get _baseUrl {
    final configured = dotenv.env['GREENPOINT_API_BASE_URL']?.trim();
    final base = (configured == null || configured.isEmpty)
        ? 'http://10.0.2.2:8000/api'
        : configured;

    return base.endsWith('/') ? base.substring(0, base.length - 1) : base;
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
    });
    final user = response['user'];

    return user is Map<String, dynamic> ? user : <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$_baseUrl$path');

    try {
      final response = await http
          .post(
            uri,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 45));

      final decoded = _decodeJson(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw GreenPointApiException(
          _messageFrom(decoded, response.statusCode),
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
}
