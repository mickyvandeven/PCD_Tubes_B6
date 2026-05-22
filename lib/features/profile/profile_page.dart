import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/fat_bottom_nav.dart';
import '../home/home_page.dart';
import '../history/history_page.dart';
import '../scanner/scanner_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const Color _backgroundColor = Color(0xFF1A1A2E);
  static const Color _cardColor = Color(0xFF16213E);
  static const Color _accentColor = Color(0xFF00F5A0);

  static const String _userName = 'Ridho';
  static const String _userEmail = 'ridho@fatscan.app';
  static const List<_ProfileStat> _stats = [
    _ProfileStat(label: 'Total Scan', value: '4', icon: Icons.qr_code_scanner_rounded),
    _ProfileStat(label: 'Rata-rata Lemak', value: '8 g', icon: Icons.water_drop_outlined),
  ];

  static const List<_SettingItem> _settings = [
    _SettingItem(icon: Icons.language_rounded, title: 'Bahasa'),
    _SettingItem(icon: Icons.notifications_none_rounded, title: 'Notifikasi'),
    _SettingItem(icon: Icons.help_outline_rounded, title: 'Bantuan & FAQ'),
    _SettingItem(icon: Icons.logout_rounded, title: 'Logout'),
  ];

  void _logout(BuildContext context) {
    context.go('/splash');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF202544), Color(0xFF1A1A2E), Color(0xFF11162A)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _accentColor.withOpacity(0.16),
                        border: Border.all(color: _accentColor.withOpacity(0.45)),
                        boxShadow: [
                          BoxShadow(
                            color: _accentColor.withOpacity(0.12),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person_rounded, color: _accentColor, size: 34),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            _userName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _userEmail,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.72),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Stats',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      item: _stats[0],
                      accentColor: _accentColor,
                      cardColor: _cardColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      item: _stats[1],
                      accentColor: _accentColor,
                      cardColor: _cardColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ..._settings.map(
                (setting) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SettingCard(
                    item: setting,
                    accentColor: _accentColor,
                    cardColor: _cardColor,
                    onTap: setting.title == 'Logout' ? () => _logout(context) : null,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: const Color(0xFF10101B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: FatBottomNav(
        currentIndex: 2,
        onScanTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ScannerPage()));
        },
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          } else if (index == 1) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HistoryPage()),
            );
          }
        },
      ),
    );
  }
}

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
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: accentColor),
          ),
          const SizedBox(height: 14),
          Text(
            item.label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

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
                  color: accentColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: accentColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

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
