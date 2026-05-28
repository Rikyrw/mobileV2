import 'package:flutter/material.dart';

import 'viewmodels/chatbot_view_model.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with SingleTickerProviderStateMixin {
  final ChatbotViewModel _viewModel = ChatbotViewModel();
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _dotController;

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
    _viewModel.addListener(_scrollToBottom);
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_scrollToBottom);
    _dotController.dispose();
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return ColoredBox(
          color: _background,
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: _buildMessageList()),
                    if (_viewModel.isLoading) _buildTypingIndicator(),
                    _buildInputBar(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: Container(
        decoration: const BoxDecoration(
          color: _surface,
          border: Border(bottom: BorderSide(color: _border, width: 1)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
            child: Row(
              children: [
                _HeaderButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: widget.onBack ?? () => Navigator.of(context).pop(),
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
                  child: Row(
                    children: [
                      Text(
                        'Si Jajang',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(width: 8),
                      _OnlineDot(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    final messages = _viewModel.messages;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isFirst =
            index == 0 ||
            messages[index - 1].isBotMessage != message.isBotMessage;

        return _MessageBubble(
          message: message,
          isFirst: isFirst,
          timeString: _formatTime(message.timestamp),
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
    final inputDisabled = _viewModel.isLoading || _viewModel.isCooldown;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _border, width: 1)),
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
                controller: _viewModel.messageController,
                enabled: !inputDisabled,
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _viewModel.sendMessage(),
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
            onTap: inputDisabled ? null : _viewModel.sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: inputDisabled
                    ? _primary.withValues(alpha: 0.45)
                    : _primary,
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

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap});

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
        child: Icon(icon, size: 18, color: _primary),
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
        mainAxisAlignment: isBot
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
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
              crossAxisAlignment: isBot
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 11,
                  ),
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
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: controller,
            builder: (_, _) {
              final delay = index * 0.33;
              final t = ((controller.value - delay) % 1.0).clamp(0.0, 1.0);
              final opacity = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.35, 1.0);

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
