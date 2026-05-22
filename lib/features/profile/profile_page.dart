import 'package:flutter/material.dart';

import '../../core/router/no_transition_route.dart';

import '../../widgets/fat_bottom_nav.dart';
import '../home/view/home_page.dart';
import '../history/history_page.dart';
import '../scanner/scanner_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
