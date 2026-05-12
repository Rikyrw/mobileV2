import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GroqService {
  static final String _apiKey = dotenv.env['GROQ_API_KEY'] ?? '';

  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  static const String _model = 'llama-3.1-8b-instant';

  Future<String> sendMessage(String userMessage) async {
    if (_apiKey.trim().isEmpty) {
      throw GroqApiException(
        message: 'GROQ_API_KEY tidak ditemukan di file .env',
        statusCode: 401,
      );
    }

    final response = await http
        .post(
          Uri.parse(_baseUrl),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              {
                'role': 'system',
                'content': """
Kamu adalah Si Jajang, chatbot resmi aplikasi Green Point.

ATURAN UTAMA:
1. Kamu hanya boleh menjawab pertanyaan yang berhubungan dengan aplikasi Green Point.
2. Topik yang boleh dijawab:
   - pengenalan aplikasi Green Point
   - fitur aplikasi
   - cara menggunakan aplikasi
   - cara kerja aplikasi
   - setor sampah
   - pengelolaan sampah
   - poin, reward, atau e-money jika ada dalam aplikasi
   - pembayaran layanan seperti PLN, pulsa, atau layanan digital yang ada di aplikasi
   - bantuan penggunaan menu aplikasi
   - kendala atau error aplikasi
   - informasi umum yang masih berkaitan langsung dengan aplikasi
3. Jika pengguna bertanya di luar konteks aplikasi, jangan jawab pertanyaan tersebut.
4. Untuk pertanyaan di luar konteks, balas persis dengan kalimat ini:
   Maaf, Si Jajang hanya bisa membantu seputar aplikasi Green Point, fitur, cara penggunaan, dan layanan yang tersedia di dalam aplikasi.
5. Jangan membahas politik, pelajaran umum, hiburan, coding umum, kesehatan, percintaan, atau topik lain yang tidak berhubungan dengan aplikasi Green Point.
6. Jawab dengan bahasa Indonesia yang singkat, jelas, sopan, dan mudah dipahami.
7. Jangan mengarang fitur yang tidak jelas. Jika informasi tidak tersedia, arahkan pengguna untuk menghubungi admin Green Point.

Contoh:
User: Siapa presiden Indonesia?
Jawaban: Maaf, Si Jajang hanya bisa membantu seputar aplikasi Green Point, fitur, cara penggunaan, dan layanan yang tersedia di dalam aplikasi.

User: Cara pakai aplikasi Green Point?
Jawaban: Jelaskan cara penggunaan aplikasi Green Point secara singkat.

User: Kenapa tombol setor sampah tidak bisa dipencet?
Jawaban: Berikan langkah pengecekan sederhana yang berkaitan dengan aplikasi.
""",
              },
              {
                'role': 'user',
                'content': userMessage,
              },
            ],
            'temperature': 0.2,
            'max_tokens': 350,
          }),
        )
        .timeout(const Duration(seconds: 30));

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final choices = decoded?['choices'] as List?;

      if (choices == null || choices.isEmpty) {
        throw GroqApiException(
          message: 'Respons Groq kosong.',
          statusCode: response.statusCode,
        );
      }

      final content = choices.first['message']?['content'];

      if (content == null || content.toString().trim().isEmpty) {
        throw GroqApiException(
          message: 'Jawaban Groq kosong.',
          statusCode: response.statusCode,
        );
      }

      return content.toString().trim();
    }

    final errorMessage =
        decoded?['error']?['message']?.toString() ?? response.body;

    final retryAfterHeader = response.headers['retry-after'];
    final retryAfterSeconds = int.tryParse(retryAfterHeader ?? '');

    throw GroqApiException(
      message: errorMessage,
      statusCode: response.statusCode,
      retryAfterSeconds: retryAfterSeconds,
    );
  }
}

class GroqApiException implements Exception {
  final String message;
  final int statusCode;
  final int? retryAfterSeconds;

  GroqApiException({
    required this.message,
    required this.statusCode,
    this.retryAfterSeconds,
  });

  bool get isRateLimit {
    final lowerMessage = message.toLowerCase();

    return statusCode == 429 ||
        lowerMessage.contains('rate limit') ||
        lowerMessage.contains('too many requests') ||
        lowerMessage.contains('quota') ||
        lowerMessage.contains('limit exceeded');
  }

  @override
  String toString() {
    return 'GroqApiException(statusCode: $statusCode, message: $message)';
  }
}
