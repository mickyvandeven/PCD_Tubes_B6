import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/services/hive_service.dart';
import 'features/home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Hive untuk penyimpanan riwayat scan
  await HiveService.init();

  runApp(const FatScanApp());
}

class FatScanApp extends StatelessWidget {
  const FatScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<HiveService>(
      create: (_) => HiveService(),
      child: MaterialApp(
        title: 'FatScan – AI Food Fat Analyzer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0D1020),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF44F0D2),
            secondary: Color(0xFF2D79FF),
            surface: Color(0xFF1A1F37),
            error: Color(0xFFFF5C6B),
          ),
        ),
        home: const HomePage(),
      ),
    );
  }
}
