import 'package:flutter/material.dart';

import '../../widgets/fat_bottom_nav.dart';
import '../home/home_page.dart';
import '../history/history_page.dart';
import '../scanner/scanner_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF11162A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF11162A),
        foregroundColor: Colors.white,
        title: const Text('Profile'),
      ),
      body: const Center(
        child: Text(
          'Profile page placeholder',
          style: TextStyle(color: Colors.white70),
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
