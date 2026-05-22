import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/no_transition_route.dart';
import '../../widgets/fat_bottom_nav.dart';
import '../home/view/home_page.dart';
import '../history/history_page.dart';
import '../scanner/scanner_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // ── Warna tema putih susu + hijau ─────────────────────────
  static const Color _cardColor = Color(0xFFFFFFFF);
  static const Color _accentColor = Color(0xFF2D7A4F);

  static const String _userName = 'Ridho';
  static const String _userEmail = 'ridho@fatscan.app';

  static const List<_ProfileStat> _stats = [
    _ProfileStat(
      label: 'Total Scan',
      value: '4',
      icon: Icons.qr_code_scanner_rounded,
    ),
    _ProfileStat(
      label: 'Rata-rata Lemak',
      value: '8 g',
      icon: Icons.water_drop_outlined,
    ),
  ];

  static const List<_SettingItem> _settings = [
    _SettingItem(icon: Icons.language_rounded, title: 'Bahasa'),
    _SettingItem(icon: Icons.notifications_none_rounded, title: 'Notifikasi'),
    _SettingItem(icon: Icons.help_outline_rounded, title: 'Bantuan & FAQ'),
    _SettingItem(icon: Icons.logout_rounded, title: 'Logout'),
  ];

  void _logout(BuildContext context) => context.go('/splash');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F8F2),
        foregroundColor: const Color(0xFF1C3028),
        title: const Text('Profile'),
      ),
      body: const Center(
        child: Text(
          'Profile page placeholder',
          style: TextStyle(color: Color(0xFF4D7060)),
        ),
      ),
      bottomNavigationBar: FatBottomNav(
        currentIndex: 2,
        onScanTap: () {
          Navigator.of(
            context,
          ).push(NoTransitionRoute(builder: (_) => const ScannerPage()));
        },
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacement(
              NoTransitionRoute(builder: (_) => const HomePage()),
            );
          } else if (index == 1) {
            Navigator.of(context).pushReplacement(
              NoTransitionRoute(builder: (_) => const HistoryPage()),
            );
          }
        },
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.item,
    required this.accentColor,
    required this.cardColor,
  });

  final _ProfileStat item;
  final Color accentColor;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFC8E2D0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x142D7A4F),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: accentColor),
          ),
          const SizedBox(height: 14),
          Text(
            item.label,
            style: const TextStyle(
              color: Color(0xFF4D7060),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.value,
            style: const TextStyle(
              color: Color(0xFF1C3028),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Setting Card ──────────────────────────────────────────────────────────────

class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.item,
    required this.accentColor,
    required this.cardColor,
    this.onTap,
  });

  final _SettingItem item;
  final Color accentColor;
  final Color cardColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: accentColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    color: Color(0xFF1C3028),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9AB5A5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data Models ───────────────────────────────────────────────────────────────

class _ProfileStat {
  const _ProfileStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _SettingItem {
  const _SettingItem({required this.icon, required this.title});

  final IconData icon;
  final String title;
}
