import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  late final GenerativeModel _model;
  late final ChatSession _chat;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY tidak ditemukan di file .env');
    }

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
        'Kamu adalah asisten digital Green Point, sebuah aplikasi pengelolaan sampah dan layanan digital. '
        'Bantu pengguna dengan informasi seputar setor sampah, e-money, pembayaran PLN, isi pulsa, '
        'dan layanan lainnya di aplikasi Green Point. '
        'Jawab dengan ramah, singkat, dan dalam Bahasa Indonesia.',
      ),
    );

    _chat = _model.startChat();
  }

  Future<String> sendMessage(String message) async {
    final response = await _chat.sendMessage(Content.text(message));
    return response.text ?? 'Maaf, saya tidak dapat memberikan respons saat ini.';
  }
}