import 'greenpoint_api_service.dart';

class GroqService {
  Future<String> sendMessage(
    String userMessage, {
    List<GroqChatTurn> conversationHistory = const [],
  }) async {
    try {
      return await GreenPointApiService.sendChatbotMessage(
        message: userMessage,
        history: conversationHistory
            .where(
              (turn) =>
                  (turn.role == 'user' || turn.role == 'assistant') &&
                  turn.content.trim().isNotEmpty,
            )
            .map((turn) => {'role': turn.role, 'content': turn.content})
            .toList(),
      );
    } on GreenPointApiException catch (error) {
      throw GroqApiException(
        message: error.message,
        statusCode: error.statusCode ?? 503,
      );
    }
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
        lowerMessage.contains('limit exceeded') ||
        lowerMessage.contains('ramai dipakai');
  }

  @override
  String toString() {
    return 'GroqApiException(statusCode: $statusCode, message: $message)';
  }
}
