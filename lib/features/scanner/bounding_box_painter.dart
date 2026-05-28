import 'package:flutter/material.dart';

/// Layer 3: UI Overlay
/// CustomPainter untuk menggambar bounding box di atas preview kamera.
class BoundingBoxPainter extends CustomPainter {
  final List<dynamic> detections;
  
  BoundingBoxPainter({required this.detections});

  @override
  void paint(Canvas canvas, Size size) {
    if (detections.isEmpty) return;

    final paintBox = Paint()
      ..color = const Color(0xFF44F0D2) // AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final paintTextBg = Paint()..color = const Color(0xFF44F0D2);

    for (var detection in detections) {
      final bbox = detection['bbox'] as List<double>;
      
      // bbox dalam format [left, top, right, bottom] relatif terhadap ukuran frame (0.0 - 1.0)
      final left = bbox[0] * size.width;
      final top = bbox[1] * size.height;
      final right = bbox[2] * size.width;
      final bottom = bbox[3] * size.height;

      final rect = Rect.fromLTRB(left, top, right, bottom);
      
      // Draw Bounding Box
      canvas.drawRect(rect, paintBox);

      // Draw Label Background
      final String label = '${detection['label']} ${(detection['confidence'] * 100).toStringAsFixed(0)}%';
      final textSpan = TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.black, // Text on primary
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
      
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Draw background for text
      canvas.drawRect(
        Rect.fromLTWH(
          left, 
          top - textPainter.height - 4, 
          textPainter.width + 8, 
          textPainter.height + 4
        ), 
        paintTextBg
      );

      // Draw Text
      textPainter.paint(canvas, Offset(left + 4, top - textPainter.height - 2));
    }
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    // Selalu repaint jika ada deteksi baru yang masuk dari Stream
    return true; 
  }
}
