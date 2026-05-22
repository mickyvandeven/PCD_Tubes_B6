import 'dart:math' as math;
import 'package:flutter/material.dart';

// ── Inline Loader ─────────────────────────────────────────────────────────────

class CustomLoader extends StatefulWidget {
  const CustomLoader({
    super.key,
    this.size = 48,
    this.strokeWidth = 4,
    this.label,
    this.color,
  });

  final double size;
  final double strokeWidth;
  final String? label;
  final Color? color;

  @override
  State<CustomLoader> createState() => _CustomLoaderState();
}

class _CustomLoaderState extends State<CustomLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? const Color(0xFF2D7A4F);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            return Transform.rotate(
              angle: _controller.value * 2 * math.pi,
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _ArcPainter(
                  color: color,
                  strokeWidth: widget.strokeWidth,
                ),
              ),
            );
          },
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 14),
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4D7060),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

// ── Arc Painter ───────────────────────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.color, required this.strokeWidth});
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track (latar hijau muda)
    final trackPaint = Paint()
      ..color = const Color(0xFFD0EDE0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Arc utama dengan gradient
    final arcPaint = Paint()
      ..shader = SweepGradient(
        colors: [color.withOpacity(0.0), color],
        startAngle: 0,
        endAngle: math.pi * 1.6,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 1.6,
      false,
      arcPaint,
    );

    // Titik putih di ujung arc
    final dotAngle = -math.pi / 2 + math.pi * 1.6;
    final dotOffset = Offset(
      center.dx + radius * math.cos(dotAngle),
      center.dy + radius * math.sin(dotAngle),
    );
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotOffset, strokeWidth / 2, dotPaint);
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

// ── Full-screen Overlay Loader ────────────────────────────────────────────────

class CustomLoaderOverlay extends StatelessWidget {
  const CustomLoaderOverlay({
    super.key,
    this.label,
    this.barrierColor = const Color(0x80000000),
  });

  final String? label;
  final Color barrierColor;

  /// Tampilkan overlay di atas halaman saat ini.
  static void show(BuildContext context, {String? label}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => CustomLoaderOverlay(label: label),
    );
  }

  /// Tutup overlay.
  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D7A4F).withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: CustomLoader(size: 52, strokeWidth: 4.5, label: label),
      ),
    );
  }
}
