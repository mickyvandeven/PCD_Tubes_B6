import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'data/services/hive_service.dart';
import 'features/history/history_page.dart';
import 'features/home/view/home_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/profile/profile_page.dart';
import 'features/scanner/scanner_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Muat konfigurasi dari .env
  await dotenv.load(fileName: ".env");

  // Inisialisasi Hive untuk penyimpanan riwayat scan
  await HiveService.init();

  runApp(const FatScanApp());
}

class FatScanApp extends StatelessWidget {
  const FatScanApp({super.key});

  static final GoRouter _router = GoRouter(
    initialLocation: '/onboarding',
    routes: <RouteBase>[
      GoRoute(path: '/', redirect: (_, __) => '/onboarding'),
      GoRoute(path: '/splash', redirect: (_, __) => '/onboarding'),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (_, __) => const NoTransitionPage(child: OnboardingPage()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (_, __) => const NoTransitionPage(child: HomePage()),
      ),
      GoRoute(
        path: '/history',
        pageBuilder: (_, __) => const NoTransitionPage(child: HistoryPage()),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (_, __) => const NoTransitionPage(child: ProfilePage()),
      ),
      GoRoute(
        path: '/scanner',
        pageBuilder: (_, __) => const NoTransitionPage(child: ScannerPage()),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Provider<HiveService>(
      create: (_) => HiveService(),
      child: MaterialApp.router(
        title: 'FatScan',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
