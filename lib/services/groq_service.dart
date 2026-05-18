import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GroqService {
  static final String _apiKey = dotenv.env['GROQ_API_KEY'] ?? '';

  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  static const String _model = 'llama-3.1-8b-instant';

  Future<String> sendMessage(
    String userMessage, {
    List<GroqChatTurn> conversationHistory = const [],
  }) async {
    if (_apiKey.trim().isEmpty) {
      throw GroqApiException(
        message: 'GROQ_API_KEY tidak ditemukan di file .env',
        statusCode: 401,
      );
    }

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': """
Kamu adalah Si Jajang, chatbot resmi aplikasi Green Point.

KONTEKS APLIKASI YANG BENAR:
- Halaman awal memiliki tombol "Masuk" dan "Daftar".
- Alur daftar: pengguna menekan "Daftar", mengisi Nama Lengkap, Username, Email, Alamat, Nomor Telepon, Password minimal 8 karakter, dan Confirm Password, lalu menekan "Daftar". Pengguna juga bisa memilih "Daftar dengan Google". Jika berhasil, pengguna diarahkan ke dashboard.
- Alur masuk: pengguna menekan "Masuk", mengisi Email atau Username dan Password, lalu menekan "Masuk". Pengguna juga bisa memilih "Masuk dengan Google".
- Dashboard menampilkan akses ke Setor Sampah, E-Money, PLN, Pulsa, serta navigasi bawah Home, Transaksi, Chat AI, Riwayat, dan Profil.
- Alur Setor Sampah: dari dashboard pilih "Transaksi Setor Sampah", tekan "+ Tambah Jenis Sampah", pilih jenis sampah, isi berat minimal 1 kg, tambahkan foto untuk setiap jenis yang dipilih, tekan "Hitung Total", lalu "Ajukan Setor Sampah".
- Alur E-Money: dari dashboard pilih "E-Money", isi No Tujuan, pilih kategori nominal, pilih layanan seperti GoPay atau DANA, lalu tekan "Proses". Saldo harus mencukupi.
- Alur PLN: dari dashboard pilih "PLN", isi No Meter/Token, pilih nominal, lalu tekan "Beli Token".
- Alur Pulsa: dari dashboard pilih "Pulsa", isi nomor telepon, pilih operator, pilih nominal, lalu tekan "Beli Pulsa".
- Menu "Transaksi" menampilkan transaksi PPOB dan bisa difilter berdasarkan periode tanggal.
- Menu "Riwayat" menampilkan riwayat setor sampah dan bisa difilter berdasarkan periode tanggal.
- Menu "Profil" menampilkan data pengguna, tombol "Perbarui Profil", dan tombol keluar/logout.

ATURAN UTAMA:
1. Jawab pertanyaan yang berhubungan dengan aplikasi Green Point sesuai alur yang benar-benar tersedia di aplikasi.
2. Jika pengguna bertanya dengan rujukan seperti "caranya", "yang tadi", "itu", atau kalimat lanjutan, gunakan riwayat percakapan untuk memahami konteksnya.
3. Topik yang boleh dijawab:
   - pengenalan aplikasi Green Point
   - pendaftaran akun dan login
   - fitur aplikasi
   - cara menggunakan aplikasi
   - setor sampah
   - E-Money
   - pembelian token PLN
   - pembelian pulsa
   - transaksi PPOB
   - riwayat setor sampah
   - profil pengguna
   - kendala atau error aplikasi
4. Jika pengguna bertanya di luar konteks aplikasi, jangan jawab pertanyaan tersebut.
5. Untuk pertanyaan di luar konteks, balas persis dengan kalimat ini:
   Maaf, Si Jajang hanya bisa membantu seputar aplikasi Green Point, fitur, cara penggunaan, dan layanan yang tersedia di dalam aplikasi.
6. Jangan membahas politik, pelajaran umum, hiburan, coding umum, kesehatan, percintaan, atau topik lain yang tidak berhubungan dengan aplikasi Green Point.
7. Jawab dengan bahasa Indonesia yang singkat, jelas, sopan, dan mudah dipahami.
8. Jangan mengarang fitur yang tidak tersedia. Jika informasi tidak ada di konteks aplikasi, katakan belum tersedia atau arahkan pengguna menghubungi admin Green Point.

Contoh:
User: Cara daftar akun Green Point?
Jawaban: Jelaskan langkah pendaftaran akun sesuai flow aplikasi.

User: Cara setor sampah?
Jawaban: Jelaskan langkah setor sampah sesuai flow aplikasi.

User: Siapa presiden Indonesia?
Jawaban: Maaf, Si Jajang hanya bisa membantu seputar aplikasi Green Point, fitur, cara penggunaan, dan layanan yang tersedia di dalam aplikasi.
""",
      },
      ...conversationHistory
          .where(
            (turn) =>
                (turn.role == 'user' || turn.role == 'assistant') &&
                turn.content.trim().isNotEmpty,
          )
          .map((turn) => {'role': turn.role, 'content': turn.content}),
      {'role': 'user', 'content': userMessage},
    ];

    final response = await http
        .post(
          Uri.parse(_baseUrl),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': _model,
            'messages': messages,
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

class GroqChatTurn {
  final String role;
  final String content;

  const GroqChatTurn({required this.role, required this.content});
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
