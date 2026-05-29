import 'dart:async';

import 'package:flutter/material.dart';

import '../services/chatbot_knowledge_base.dart';
import '../services/groq_service.dart';

class ChatMessage {
  ChatMessage({
    required this.text,
    required this.isBotMessage,
    required this.timestamp,
  });

  final String text;
  final bool isBotMessage;
  final DateTime timestamp;
}

class ChatbotViewModel extends ChangeNotifier {
  ChatbotViewModel() {
    _messages.add(
      ChatMessage(
        text: 'Halo! Saya Si Jajang. Ada yang bisa saya bantu hari ini?',
        isBotMessage: true,
        timestamp: DateTime.now(),
      ),
    );
    _initializeGroq();
  }

  static const int _localDailyRequestLimit = 1000;
  static const Duration _sendCooldown = Duration(seconds: 5);
  static const Duration _fallbackLimitDuration = Duration(seconds: 60);

  final TextEditingController messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final Map<String, String> _answerCache = {};
  final ChatbotKnowledgeBase _knowledgeBase = const ChatbotKnowledgeBase();

  GroqService? _groqService;
  Timer? _cooldownTimer;
  Timer? _limitCountdownTimer;
  bool _isLoading = false;
  bool _isCooldown = false;
  bool _isAiLimited = false;
  int _aiRequestsToday = 0;
  DateTime _usageDate = DateTime.now();
  DateTime? _retryAfterAt;
  bool _disposed = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isCooldown => _isCooldown;

  Future<void> sendMessage() async {
    final message = messageController.text.trim();

    if (message.isEmpty || _isLoading || _isCooldown) return;

    if (message.length > 300) {
      _addBotMessage(
        'Pertanyaan terlalu panjang. Coba ringkas maksimal 300 karakter ya.',
      );
      return;
    }

    _messages.add(
      ChatMessage(
        text: message,
        isBotMessage: false,
        timestamp: DateTime.now(),
      ),
    );
    messageController.clear();
    _setLoading(true);
    _startSendCooldown();

    final localAnswer = _getLocalFaqAnswer(message);
    if (localAnswer != null) {
      await Future.delayed(const Duration(milliseconds: 450));
      if (_disposed) return;

      _addBotMessage(localAnswer);
      _setLoading(false);
      return;
    }

    final normalizedMessage = _normalizeText(message);
    final recentConversationHistory = _buildRecentConversationHistory();
    final cacheKey = _buildCacheKey(
      normalizedMessage,
      recentConversationHistory,
    );

    if (_answerCache.containsKey(cacheKey)) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (_disposed) return;

      _addBotMessage(_answerCache[cacheKey]!);
      _setLoading(false);
      return;
    }

    if (_shouldBlockAiRequest()) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (_disposed) return;

      _addBotMessage(_getLimitMessage());
      _setLoading(false);
      return;
    }

    final groqService = _groqService;
    if (groqService == null) {
      _addBotMessage(
        'Maaf, terjadi kesalahan saat inisialisasi AI. Pastikan server GreenPoint aktif.',
      );
      _setLoading(false);
      return;
    }

    try {
      _markAiRequestUsed();

      final botResponse = await groqService.sendMessage(
        message,
        conversationHistory: recentConversationHistory,
      );
      if (_disposed) return;

      _answerCache[cacheKey] = botResponse;
      _addBotMessage(botResponse);
      _setLoading(false);
    } catch (e) {
      debugPrint('Error sending message with Groq: $e');
      if (_disposed) return;

      final isRateLimitError = e is GroqApiException
          ? e.isRateLimit
          : e.toString().contains('429');

      if (isRateLimitError) {
        _activateAiLimitFromError(e);
      }

      _addBotMessage(
        isRateLimitError
            ? _getLimitMessage()
            : 'Maaf, Si Jajang sedang sibuk atau koneksi bermasalah. Coba lagi sebentar ya.',
      );
      _setLoading(false);
    }
  }

  void _initializeGroq() {
    try {
      _groqService = GroqService();
    } catch (e) {
      debugPrint('Groq initialization error: $e');
      _messages.add(
        ChatMessage(
          text:
              'Maaf, terjadi kesalahan saat inisialisasi AI. Pastikan server GreenPoint aktif.',
          isBotMessage: true,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  String _normalizeText(String value) {
    return ChatbotKnowledgeBase.normalizeText(value);
  }

  String? _getLocalFaqAnswer(String question) {
    return _knowledgeBase.answerFor(question);
  }

  List<GroqChatTurn> _buildRecentConversationHistory() {
    if (_messages.length <= 1) {
      return const [];
    }

    final previousMessages = _messages.sublist(0, _messages.length - 1);
    final startIndex = previousMessages.length > 6
        ? previousMessages.length - 6
        : 0;

    return previousMessages.sublist(startIndex).map((message) {
      return GroqChatTurn(
        role: message.isBotMessage ? 'assistant' : 'user',
        content: message.text,
      );
    }).toList();
  }

  String _buildCacheKey(
    String normalizedMessage,
    List<GroqChatTurn> conversationHistory,
  ) {
    final contextKey = conversationHistory
        .map((turn) => '${turn.role}:${_normalizeText(turn.content)}')
        .join('|');

    return '$contextKey::$normalizedMessage';
  }

  void _resetDailyUsageIfNeeded() {
    final now = DateTime.now();
    final isDifferentDay =
        now.year != _usageDate.year ||
        now.month != _usageDate.month ||
        now.day != _usageDate.day;

    if (isDifferentDay) {
      _usageDate = now;
      _aiRequestsToday = 0;
      _isAiLimited = false;
      _retryAfterAt = null;
    }
  }

  int _getLimitWaitSeconds() {
    if (_retryAfterAt == null) return 0;

    final seconds = _retryAfterAt!.difference(DateTime.now()).inSeconds;
    return seconds > 0 ? seconds : 0;
  }

  bool _shouldBlockAiRequest() {
    _resetDailyUsageIfNeeded();

    if (_isAiLimited) {
      final waitSeconds = _getLimitWaitSeconds();

      if (waitSeconds > 0) return true;

      _isAiLimited = false;
      _retryAfterAt = null;
    }

    return _aiRequestsToday >= _localDailyRequestLimit;
  }

  void _markAiRequestUsed() {
    _resetDailyUsageIfNeeded();

    _aiRequestsToday++;
    if (_aiRequestsToday >= _localDailyRequestLimit) {
      _isAiLimited = true;
    }
    _notify();
  }

  void _startSendCooldown() {
    _isCooldown = true;
    _notify();

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(_sendCooldown, () {
      _isCooldown = false;
      _notify();
    });
  }

  void _activateAiLimitFromError(Object error) {
    var retrySeconds = _fallbackLimitDuration.inSeconds;

    if (error is GroqApiException && error.retryAfterSeconds != null) {
      retrySeconds = error.retryAfterSeconds!;
    } else {
      final errorText = error.toString();
      final retryMatches = [
        RegExp(r'try again in ([0-9.]+)s', caseSensitive: false),
        RegExp(r'retry in ([0-9.]+)s', caseSensitive: false),
        RegExp(r'Please try again in ([0-9.]+)s', caseSensitive: false),
      ];

      for (final regex in retryMatches) {
        final match = regex.firstMatch(errorText);
        if (match == null) continue;

        final value = double.tryParse(match.group(1) ?? '');
        if (value != null) {
          retrySeconds = value.ceil();
          break;
        }
      }
    }

    _isAiLimited = true;
    _retryAfterAt = DateTime.now().add(Duration(seconds: retrySeconds));
    _notify();

    _limitCountdownTimer?.cancel();
    _limitCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final waitSeconds = _getLimitWaitSeconds();

      if (waitSeconds <= 0) {
        timer.cancel();
        _isAiLimited = false;
        _retryAfterAt = null;
      }
      _notify();
    });
  }

  String _getLimitMessage() {
    final waitSeconds = _getLimitWaitSeconds();

    if (waitSeconds > 0) {
      return 'Maaf, AI Si Jajang sedang mencapai batas penggunaan sementara. Coba lagi sekitar $waitSeconds detik lagi ya.';
    }

    return 'Maaf, penggunaan AI hari ini sedang penuh. Coba lagi nanti atau gunakan pertanyaan umum yang bisa dijawab otomatis.';
  }

  void _addBotMessage(String text) {
    _messages.add(
      ChatMessage(text: text, isBotMessage: true, timestamp: DateTime.now()),
    );
    _notify();
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _cooldownTimer?.cancel();
    _limitCountdownTimer?.cancel();
    messageController.dispose();
    super.dispose();
  }
}
