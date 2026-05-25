import 'dart:math' as math;

import 'package:flutter/material.dart';

class GoogleAuthButton extends StatelessWidget {
  const GoogleAuthButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !isLoading;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled || isLoading ? 1 : 0.62,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F4285F4),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            ),
            child: InkWell(
              onTap: enabled ? onTap : null,
              child: SizedBox(
                height: 58,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE8EEF4)),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: _GoogleGLogo(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF202124),
                            fontSize: 14,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: isLoading
                            ? const SizedBox(
                                key: ValueKey('google-loading'),
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Color(0xFF4285F4),
                                ),
                              )
                            : const Icon(
                                Icons.arrow_forward_rounded,
                                key: ValueKey('google-arrow'),
                                color: Color(0xFF4285F4),
                                size: 20,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleGLogo extends StatelessWidget {
  const _GoogleGLogo();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GoogleGLogoPainter());
  }
}

class _GoogleGLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * 0.18;
    final rect =
        Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    void arc(Color color, double start, double sweep) {
      paint.color = color;
      canvas.drawArc(rect, start, sweep, false, paint);
    }

    arc(const Color(0xFFEA4335), math.pi * 1.16, math.pi * 0.52);
    arc(const Color(0xFFFBBC05), math.pi * 0.78, math.pi * 0.42);
    arc(const Color(0xFF34A853), math.pi * 0.36, math.pi * 0.42);
    arc(const Color(0xFF4285F4), math.pi * -0.08, math.pi * 0.52);

    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.square;

    final center = Offset(size.width * 0.52, size.height * 0.51);
    canvas.drawLine(center, Offset(size.width * 0.91, center.dy), bluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
