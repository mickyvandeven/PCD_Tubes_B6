import 'package:flutter/material.dart';

/// Palet warna FatScan — tema putih susu + hijau kesehatan.
abstract final class AppColors {
  // ── Latar & Permukaan ──────────────────────────────────────
  static const Color background = Color(0xFFF5F8F2); // putih susu hijau
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEBF4E8); // hijau sangat muda
  static const Color card = Color(0xFFFFFFFF);

  // ── Hijau Utama ────────────────────────────────────────────
  static const Color primary = Color(0xFF2D7A4F); // hijau tua
  static const Color primaryLight = Color(0xFF48A970); // hijau sedang
  static const Color primaryContainer = Color(0xFFD0EDE0); // hijau pucat
  static const Color secondary = Color(0xFF5BB88A); // hijau muda

  // ── Aksen & Gradien ────────────────────────────────────────
  static const Color accent = Color(0xFF00C875); // hijau cerah
  static const List<Color> primaryGradient = [
    Color(0xFF2D7A4F),
    Color(0xFF48C78A),
  ];
  static const List<Color> accentGradient = [
    Color(0xFF00C875),
    Color(0xFF2D7A4F),
  ];

  // ── Teks ──────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1C3028);
  static const Color textSecondary = Color(0xFF4D7060);
  static const Color textHint = Color(0xFF9AB5A5);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Border & Divider ──────────────────────────────────────
  static const Color border = Color(0xFFC8E2D0);
  static const Color divider = Color(0xFFD5EAD9);

  // ── Status ────────────────────────────────────────────────
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFF9A825);
  static const Color success = Color(0xFF43A047);
  static const Color info = Color(0xFF1E88E5);

  // ── Lain-lain ─────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color cardShadow = Color(0x142D7A4F); // bayangan hijau
  static const Color overlay = Color(0x80000000);

  // ── Fat Level Tags ────────────────────────────────────────
  static const Color fatLow = Color(0xFF43A047); // hijau
  static const Color fatMedium = Color(0xFFF9A825); // kuning
  static const Color fatHigh = Color(0xFFE53935); // merah
}
