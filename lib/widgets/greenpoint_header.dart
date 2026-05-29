import 'package:flutter/material.dart';

class GreenPointHeader extends StatelessWidget {
  const GreenPointHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.metaText,
    this.avatarText,
    this.leading,
    this.trailing,
    this.avatarSize = 66,
    this.padding = const EdgeInsetsDirectional.fromSTEB(20, 40, 24, 22),
    this.contentAlignment = CrossAxisAlignment.start,
    this.textAlign = TextAlign.start,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final String? metaText;
  final String? avatarText;
  final Widget? leading;
  final Widget? trailing;
  final double avatarSize;
  final EdgeInsetsGeometry padding;
  final CrossAxisAlignment contentAlignment;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Color(0xFF315A39)),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: 18,
            child: Icon(
              Icons.eco_rounded,
              size: 118,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Positioned(
            right: 54,
            bottom: -12,
            child: Icon(
              Icons.recycling_rounded,
              size: 72,
              color: Colors.white.withValues(alpha: 0.055),
            ),
          ),
          Padding(
            padding: padding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 12)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: contentAlignment,
                    children: [
                      if (eyebrow != null && eyebrow!.isNotEmpty) ...[
                        Text(
                          eyebrow!,
                          textAlign: textAlign,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFDCEBDE),
                            fontSize: 14,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        title,
                        textAlign: textAlign,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle!,
                          textAlign: textAlign,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFE8F5E9),
                            fontSize: 12,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (metaText != null && metaText!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          metaText!,
                          textAlign: textAlign,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFDCEBDE),
                            fontSize: 11,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (avatarText != null && avatarText!.trim().isNotEmpty) ...[
                  const SizedBox(width: 18),
                  GreenPointHeaderAvatar(text: avatarText!, size: avatarSize),
                ],
                if (trailing != null) ...[const SizedBox(width: 10), trailing!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GreenPointHeaderAvatar extends StatelessWidget {
  const GreenPointHeaderAvatar({super.key, required this.text, this.size = 66});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size * 0.27),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initialsFromName(text),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.30,
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class GreenPointHeaderIconButton extends StatelessWidget {
  const GreenPointHeaderIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 22),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

String initialsFromName(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return 'GP';
  if (words.length == 1) {
    return words.first.substring(0, 1).toUpperCase();
  }
  return '${words.first.substring(0, 1)}${words.last.substring(0, 1)}'
      .toUpperCase();
}
