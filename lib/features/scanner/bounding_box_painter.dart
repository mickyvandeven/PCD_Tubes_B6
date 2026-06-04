import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// CustomPainter untuk menggambar bounding box di atas preview kamera / gambar.
///
/// Box digambar dengan rounded corners dan label makanan yang mengikuti
/// posisi setiap item terdeteksi — mirip tampilan deteksi objek modern.
class BoundingBoxPainter extends CustomPainter {
  final List<dynamic> detections;

  BoundingBoxPainter({required this.detections});

  // Warna beda per deteksi agar mudah dibedakan.
  static const _colors = [
    Color(0xFF44F0D2), // cyan
    Color(0xFF2D79FF), // biru
    Color(0xFFFFC94D), // kuning
    Color(0xFFFF5C6B), // merah muda
    Color(0xFF8B5CF6), // ungu
    Color(0xFF10B981), // hijau
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (detections.isEmpty) return;

    for (int i = 0; i < detections.length; i++) {
      final detection = detections[i];
      final bbox = detection['bbox'] as List<double>;
      final color = _colors[i % _colors.length];

      // bbox format: [left, top, right, bottom] normalized 0.0 - 1.0
      final left = bbox[0] * size.width;
      final top = bbox[1] * size.height;
      final right = bbox[2] * size.width;
      final bottom = bbox[3] * size.height;

      final rect = RRect.fromLTRBR(left, top, right, bottom, const Radius.circular(8));

      // ── Bounding box (rounded, semi-transparent fill + solid stroke) ──
      final fillPaint = Paint()
        ..color = color.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rect, fillPaint);

      final strokePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawRRect(rect, strokePaint);

      // ── Corner accents (garis tebal di tiap sudut) ──
      _drawCorners(canvas, left, top, right, bottom, color);

      // ── Label (nama + confidence) ──
      final String label =
          '${detection['label']} ${(detection['confidence'] * 100).toStringAsFixed(0)}%';

      final textStyle = ui.TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      );
      final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textDirection: TextDirection.ltr,
        maxLines: 1,
      ))
        ..pushStyle(textStyle)
        ..addText(label);
      final paragraph = paragraphBuilder.build()
        ..layout(const ui.ParagraphConstraints(width: 300));

      final textWidth = paragraph.longestLine + 12;
      final textHeight = paragraph.height + 8;

      // Label box di atas bounding box
      final labelTop = (top - textHeight - 4).clamp(0.0, size.height - textHeight);
      final labelLeft = left.clamp(0.0, size.width - textWidth);

      final labelRect = RRect.fromLTRBR(
        labelLeft,
        labelTop,
        labelLeft + textWidth,
        labelTop + textHeight,
        const Radius.circular(6),
      );

      final labelBgPaint = Paint()..color = color.withValues(alpha: 0.85);
      canvas.drawRRect(labelRect, labelBgPaint);

      canvas.drawParagraph(paragraph, Offset(labelLeft + 6, labelTop + 4));
    }
  }

  void _drawCorners(
      Canvas canvas, double left, double top, double right, double bottom, Color color) {
    final cornerLength = ((right - left).abs() * 0.15).clamp(8.0, 20.0);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(Offset(left, top + cornerLength), Offset(left, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), paint);

    // Top-right
    canvas.drawLine(Offset(right - cornerLength, top), Offset(right, top), paint);
    canvas.drawLine(Offset(right, top), Offset(right, top + cornerLength), paint);

    // Bottom-left
    canvas.drawLine(Offset(left, bottom - cornerLength), Offset(left, bottom), paint);
    canvas.drawLine(Offset(left, bottom), Offset(left + cornerLength, bottom), paint);

    // Bottom-right
    canvas.drawLine(Offset(right - cornerLength, bottom), Offset(right, bottom), paint);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return oldDelegate.detections != detections;
  }
}
