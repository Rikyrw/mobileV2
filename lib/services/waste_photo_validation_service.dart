import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class WastePhotoValidationService {
  WastePhotoValidationService({http.Client? client})
    : _client = client ?? http.Client();

  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _defaultModelName =
      'meta-llama/llama-4-scout-17b-16e-instruct';

  final http.Client _client;

  Future<WastePhotoValidationResult> validateWastePhoto({
    required XFile image,
    required String selectedWasteName,
    required List<String> allowedWasteNames,
  }) async {
    final apiKey = dotenv.env['GROQ_API_KEY']?.trim() ?? '';
    if (apiKey.isEmpty) {
      throw WastePhotoValidationException(
        'Validasi foto belum aktif karena GROQ_API_KEY belum diatur.',
      );
    }

    final bytes = await image.readAsBytes();
    final modelName = dotenv.env['GROQ_VISION_MODEL']?.trim();
    final model = modelName == null || modelName.isEmpty
        ? _defaultModelName
        : modelName;

    try {
      final response = await _client
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {
                  'role': 'user',
                  'content': [
                    {
                      'type': 'text',
                      'text': _buildPrompt(
                        selectedWasteName,
                        allowedWasteNames,
                      ),
                    },
                    {
                      'type': 'image_url',
                      'image_url': {
                        'url':
                            'data:${_resolveMimeType(image)};base64,${base64Encode(bytes)}',
                      },
                    },
                  ],
                },
              ],
              'temperature': 0.1,
              'max_completion_tokens': 300,
              'response_format': {'type': 'json_object'},
            }),
          )
          .timeout(const Duration(seconds: 35));

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw WastePhotoValidationException(
          _formatGroqError(response.statusCode, decoded, response.body),
        );
      }

      final choices = decoded?['choices'];
      if (choices is! List || choices.isEmpty) {
        throw WastePhotoValidationException('Respons validasi foto kosong.');
      }

      final text = choices.first?['message']?['content']?.toString().trim();
      if (text == null || text.isEmpty) {
        throw WastePhotoValidationException('Respons validasi foto kosong.');
      }

      return WastePhotoValidationResult.fromJson(_decodeJsonObject(text));
    } on TimeoutException {
      throw WastePhotoValidationException(
        'Validasi foto terlalu lama. Cek koneksi, lalu coba lagi.',
      );
    } on WastePhotoValidationException {
      rethrow;
    } catch (e) {
      throw WastePhotoValidationException('Groq gagal dihubungi. Detail: $e');
    }
  }

  static String _formatGroqError(
    int statusCode,
    Object? decoded,
    String fallback,
  ) {
    String message = '';
    if (decoded is Map) {
      message = decoded['error']?['message']?.toString() ?? '';
    }
    if (message.trim().isEmpty) {
      message = fallback.trim();
    }

    if (statusCode == 401) {
      return 'GROQ_API_KEY tidak valid. Buat API key Groq baru lalu isi ulang .env.';
    }

    if (statusCode == 403) {
      return 'Akses model vision Groq ditolak. Aktifkan model di Groq project settings atau ganti GROQ_VISION_MODEL. Detail: $message';
    }

    if (statusCode == 429) {
      return 'Limit Groq sedang tercapai. Tunggu sebentar lalu coba lagi.';
    }

    return 'Groq gagal memvalidasi foto ($statusCode). Detail: $message';
  }

  static String _buildPrompt(
    String selectedWasteName,
    List<String> allowedWasteNames,
  ) {
    final names = _cleanWasteNames(allowedWasteNames);
    if (!names.contains(selectedWasteName.trim())) {
      names.add(selectedWasteName.trim());
    }
    names.removeWhere((name) => name.isEmpty);

    final adminList = names.isEmpty
        ? '- $selectedWasteName'
        : names.map((name) => '- $name').join('\n');

    return '''
Kamu adalah validator foto setor sampah untuk aplikasi Green Point.

Daftar jenis sampah yang valid dari admin:
$adminList

Jenis sampah yang dipilih nasabah:
$selectedWasteName

Tugas:
1. Pastikan gambar berisi sampah, barang bekas, atau material daur ulang yang terlihat jelas.
2. Pastikan objek utama cocok secara semantik dengan jenis sampah yang dipilih nasabah.
3. Jika gambar bukan sampah, bukan barang bekas, terlalu buram, atau jenisnya berbeda, tolak.
4. Gunakan daftar admin sebagai acuan nama jenis sampah. Jangan membuat nama jenis sampah baru.

Balas hanya JSON valid tanpa markdown dengan format:
{
  "is_waste": true,
  "matches_selected_waste": true,
  "detected_waste_name": "nama dari daftar admin atau kosong",
  "confidence": "high",
  "reason": "alasan singkat dalam bahasa Indonesia"
}
''';
  }

  static List<String> _cleanWasteNames(List<String> names) {
    final seen = <String>{};
    final cleaned = <String>[];

    for (final rawName in names) {
      final name = rawName.trim();
      if (name.isEmpty) continue;

      final key = name.toLowerCase();
      if (seen.add(key)) {
        cleaned.add(name);
      }
    }

    return cleaned;
  }

  static String _resolveMimeType(XFile image) {
    final mimeType = image.mimeType?.trim();
    if (mimeType != null && mimeType.startsWith('image/')) {
      return mimeType;
    }

    final cleanPath = image.path.split('?').first.toLowerCase();
    final dot = cleanPath.lastIndexOf('.');
    final extension = dot == -1 ? '' : cleanPath.substring(dot + 1);

    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => 'image/jpeg',
    };
  }

  static Map<String, dynamic> _decodeJsonObject(String rawText) {
    var text = rawText.trim();

    if (text.startsWith('```')) {
      text = text
          .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
          .replaceFirst(RegExp(r'\s*```$'), '')
          .trim();
    }

    Object? decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start == -1 || end <= start) {
        throw WastePhotoValidationException(
          'Format respons validasi foto tidak valid.',
        );
      }
      decoded = jsonDecode(text.substring(start, end + 1));
    }

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    throw WastePhotoValidationException(
      'Format respons validasi foto tidak valid.',
    );
  }
}

class WastePhotoValidationResult {
  const WastePhotoValidationResult({
    required this.isWaste,
    required this.matchesSelectedWaste,
    required this.detectedWasteName,
    required this.confidence,
    required this.reason,
  });

  factory WastePhotoValidationResult.fromJson(Map<String, dynamic> json) {
    final confidence = _text(json['confidence']).toLowerCase();

    return WastePhotoValidationResult(
      isWaste: json['is_waste'] == true,
      matchesSelectedWaste: json['matches_selected_waste'] == true,
      detectedWasteName: _text(json['detected_waste_name']),
      confidence: confidence.isEmpty ? 'low' : confidence,
      reason: _text(json['reason']),
    );
  }

  factory WastePhotoValidationResult.rejected(String reason) {
    return WastePhotoValidationResult(
      isWaste: false,
      matchesSelectedWaste: false,
      detectedWasteName: '',
      confidence: 'low',
      reason: reason,
    );
  }

  final bool isWaste;
  final bool matchesSelectedWaste;
  final String detectedWasteName;
  final String confidence;
  final String reason;

  bool get isAccepted {
    return isWaste && matchesSelectedWaste && confidence != 'low';
  }

  String warningMessage(String expectedWasteName) {
    final cleanReason = reason.trim();

    if (!isWaste) {
      return cleanReason.isEmpty
          ? 'Foto harus berisi sampah atau barang bekas yang terlihat jelas.'
          : cleanReason;
    }

    if (!matchesSelectedWaste) {
      final detected = detectedWasteName.trim();
      final detectedText = detected.isEmpty ? '' : ' Terdeteksi: $detected.';
      return 'Foto harus sesuai dengan jenis "$expectedWasteName" dari daftar admin.$detectedText';
    }

    if (confidence == 'low') {
      return 'Foto belum cukup jelas untuk memastikan jenis "$expectedWasteName". Ambil ulang dengan pencahayaan yang lebih baik.';
    }

    return cleanReason.isEmpty
        ? 'Foto belum memenuhi validasi sampah.'
        : cleanReason;
  }

  static String _text(Object? value) => value?.toString().trim() ?? '';
}

class WastePhotoValidationException implements Exception {
  const WastePhotoValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
