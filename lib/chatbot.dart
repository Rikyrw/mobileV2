import 'package:flutter/material.dart';
import 'package:mob_2/services/gemini_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Halo! Saya Si Jajang. Ada yang bisa saya bantu hari ini?',
      isBotMessage: true,
      timestamp: DateTime.now(),
    ),
  ];

  bool _isLoading = false;
  bool _isCooldown = false;
  static const Duration _sendCooldown = Duration(seconds: 2);
  late GeminiService _geminiService;
  late AnimationController _dotController;

  // Simple elegant color tokens
  static const Color _primary = Color(0xFF2D5A3D);
  static const Color _primarySoft = Color(0xFFEAF3ED);
  static const Color _background = Color(0xFFF7F8F7);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE4E8E4);
  static const Color _text = Color(0xFF17211B);
  static const Color _textMuted = Color(0xFF7A867E);

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _initializeGemini();
  }

  @override
  void dispose() {
    _dotController.dispose();
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _initializeGemini() {
    try {
      _geminiService = GeminiService();
    } catch (e) {
      debugPrint('Gemini initialization error: $e');
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text:
                'Maaf, terjadi kesalahan saat inisialisasi AI. Pastikan API key Gemini sudah diatur.',
            isBotMessage: true,
            timestamp: DateTime.now(),
          ));
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }


  String _normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String? _getLocalFaqAnswer(String question) {
    final q = _normalizeText(question);

    final List<Map<String, dynamic>> faqData = [
      {
        'keywords': ['halo', 'hai', 'hello', 'hi'],
        'answer': 'Halo! Saya Si Jajang. Ada yang bisa saya bantu hari ini?',
      },
      {
        'keywords': ['green point', 'greenpoint', 'aplikasi ini', 'tentang aplikasi'],
        'answer':
            'Green Point adalah aplikasi yang membantu pengguna mendapatkan informasi dan layanan dengan lebih praktis.',
      },
      {
        'keywords': ['cara pakai', 'cara menggunakan', 'gunakan aplikasi', 'tutorial'],
        'answer':
            'Cara pakainya mudah. Ketik pertanyaan atau kebutuhan kamu di kolom pesan, lalu Si Jajang akan membantu menjawab.',
      },
      {
        'keywords': ['fitur', 'menu', 'fungsi'],
        'answer':
            'Fitur utama aplikasi ini adalah chatbot AI, informasi layanan, dan bantuan pengguna secara cepat.',
      },
      {
        'keywords': ['terima kasih', 'makasih', 'thanks', 'thank you'],
        'answer': 'Sama-sama! Senang bisa membantu kamu.',
      },
      {
        'keywords': ['error', 'gagal', 'tidak bisa', 'bug', 'masalah'],
        'answer':
            'Maaf kalau ada kendala. Coba tutup lalu buka ulang aplikasi. Jika masih bermasalah, silakan hubungi admin atau pengembang aplikasi.',
      },
    ];

    for (final item in faqData) {
      final keywords = item['keywords'] as List<String>;
      final isMatch = keywords.any((keyword) => q.contains(keyword));

      if (isMatch) {
        return item['answer'] as String;
      }
    }

    return null;
  }

  void _startSendCooldown() {
    setState(() {
      _isCooldown = true;
    });

    Future.delayed(_sendCooldown, () {
      if (mounted) {
        setState(() {
          _isCooldown = false;
        });
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();

    // Mencegah pesan kosong, spam klik, dan request bertumpuk.
    if (message.isEmpty || _isLoading || _isCooldown) return;

    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isBotMessage: false,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
      _isLoading = true;
    });

    _startSendCooldown();
    _scrollToBottom();

    // Cek FAQ lokal dulu. Kalau cocok, tidak perlu request ke Gemini.
    final localAnswer = _getLocalFaqAnswer(message);

    if (localAnswer != null) {
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: localAnswer,
            isBotMessage: true,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }

      return;
    }

    try {
      final botResponse = await _geminiService
          .sendMessage(message)
          .timeout(const Duration(seconds: 25));

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: botResponse,
            isBotMessage: true,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error sending message: $e');

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text:
                'Maaf, Si Jajang sedang sibuk atau koneksi bermasalah. Coba lagi sebentar ya.',
            isBotMessage: true,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (_isLoading) _buildTypingIndicator(),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: Container(
        decoration: const BoxDecoration(
          color: _surface,
          border: Border(
            bottom: BorderSide(color: _border, width: 1),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
            child: Row(
              children: [
                _HeaderButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),

                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _primarySoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: _primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Si Jajang',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 3),
                      Row(
                        children: [
                          _OnlineDot(),
                          SizedBox(width: 6),
                          Text(
                            'Online',
                            style: TextStyle(
                              color: _textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tombol titik tiga sengaja dihapus.
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isFirst = index == 0 ||
            _messages[index - 1].isBotMessage != msg.isBotMessage;

        return _MessageBubble(
          message: msg,
          isFirst: isFirst,
          timeString: _formatTime(msg.timestamp),
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: _primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: _TypingDots(controller: _dotController),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(
          top: BorderSide(color: _border, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _border),
              ),
              child: TextField(
                controller: _messageController,
                enabled: !_isLoading && !_isCooldown,
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: const TextStyle(
                  fontSize: 14,
                  color: _text,
                  height: 1.45,
                ),
                decoration: const InputDecoration(
                  hintText: 'Tulis pesan...',
                  hintStyle: TextStyle(
                    color: _textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: (_isLoading || _isCooldown) ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (_isLoading || _isCooldown) ? _primary.withOpacity(0.45) : _primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  static const Color _background = Color(0xFFF7F8F7);
  static const Color _border = Color(0xFFE4E8E4);
  static const Color _primary = Color(0xFF2D5A3D);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Icon(
          icon,
          size: 18,
          color: _primary,
        ),
      ),
    );
  }
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: Color(0xFF37B26C),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isFirst,
    required this.timeString,
  });

  final ChatMessage message;
  final bool isFirst;
  final String timeString;

  static const Color _primary = Color(0xFF2D5A3D);
  static const Color _primarySoft = Color(0xFFEAF3ED);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE4E8E4);
  static const Color _text = Color(0xFF17211B);
  static const Color _textMuted = Color(0xFF7A867E);

  @override
  Widget build(BuildContext context) {
    final isBot = message.isBotMessage;

    return Padding(
      padding: EdgeInsets.only(bottom: isFirst ? 14 : 7),
      child: Row(
        mainAxisAlignment:
            isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isBot) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: _primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                  decoration: BoxDecoration(
                    color: isBot ? _surface : _primary,
                    borderRadius: BorderRadius.circular(18),
                    border: isBot ? Border.all(color: _border) : null,
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isBot ? _text : Colors.white,
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeString,
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (!isBot) ...[
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingDots extends StatelessWidget {
  const _TypingDots({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: controller,
            builder: (_, __) {
              final delay = i * 0.33;
              final t = ((controller.value - delay) % 1.0).clamp(0.0, 1.0);
              final opacity =
                  (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.35, 1.0);

              return Opacity(
                opacity: opacity,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2D5A3D),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

// ─── Model ────────────────────────────────────────────────────────────────────

class ChatMessage {
  final String text;
  final bool isBotMessage;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isBotMessage,
    required this.timestamp,
    //a
  });
}
