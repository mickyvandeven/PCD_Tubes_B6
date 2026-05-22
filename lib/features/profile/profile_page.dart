import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/fat_bottom_nav.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
    _SettingItem(icon: Icons.help_outline_rounded, title: 'Bantuan & FAQ'),
    _SettingItem(icon: Icons.logout_rounded, title: 'Logout', isLogout: true),
  ];

  void _logout(BuildContext context) => context.go('/splash');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F2),
      bottomNavigationBar: FatBottomNav(
        currentIndex: 2,
        onScanTap: () => context.push('/scanner'),
        onTap: (index) {
          if (index == 0)
            context.go('/home');
          else if (index == 1)
            context.go('/history');
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────
              _ProfileHeader(
                userName: _userName,
                userEmail: _userEmail,
                accentColor: _accentColor,
              ),
              const SizedBox(height: 28),

              // ── Stats ────────────────────────────────────────
              Text(
                'Statistik',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF1C3028),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: _stats
                    .map(
                      (stat) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: stat == _stats.last ? 0 : 12,
                          ),
                          child: _StatCard(
                            item: stat,
                            accentColor: _accentColor,
                            cardColor: _cardColor,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 28),

              // ── Settings ─────────────────────────────────────
              Text(
                'Pengaturan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF1C3028),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: _cardColor,
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
                  children: [
                    for (int i = 0; i < _settings.length; i++) ...[
                      _SettingCard(
                        item: _settings[i],
                        accentColor: _settings[i].isLogout
                            ? const Color(0xFFE53935)
                            : _accentColor,
                        cardColor: Colors.transparent,
                        onTap: _settings[i].isLogout
                            ? () => _logout(context)
                            : () {},
                      ),
                      if (i < _settings.length - 1)
                        const Divider(
                          height: 1,
                          indent: 72,
                          color: Color(0xFFD5EAD9),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Profile Header ────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.userName,
    required this.userEmail,
    required this.accentColor,
  });

  final String userName;
  final String userEmail;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [accentColor, const Color(0xFF48C78A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.30),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF1C3028),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userEmail,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF9AB5A5)),
              ),
            ],
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFEBF4E8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.edit_outlined, color: accentColor, size: 20),
        ),
      ],
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    color: item.isLogout
                        ? const Color(0xFFE53935)
                        : const Color(0xFF1C3028),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!item.isLogout)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9AB5A5),
                  size: 20,
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
  const _SettingItem({
    required this.icon,
    required this.title,
    this.isLogout = false,
  });

  final IconData icon;
  final String title;
  final bool isLogout;
}
