import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'data/services/hive_service.dart';
import 'data/services/mongo_service.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/history/history_page.dart';
import 'features/home/view/home_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/onboarding/profile_setup_page.dart';
import 'features/profile/profile_page.dart';
import 'features/profile/edit_profile_page.dart';
import 'features/scanner/scanner_page.dart';

import 'dart:ui';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tangkap semua error asinkron yang tidak tertangani (misal koneksi putus dari mongo_dart) agar aplikasi tidak crash
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[Global Error Handler] Tertangkap error: $error');
    return true; // Cegah aplikasi crash
  };

  // Muat konfigurasi dari .env
  await dotenv.load(fileName: ".env");

  // Inisialisasi Hive untuk penyimpanan riwayat scan & profil user
  await HiveService.init();

  // Inisialisasi MongoDB untuk sinkronisasi cloud (dijelankan di background tanpa await agar tidak white screen)
  MongoService().init();

  runApp(const FatScanApp());
}

class FatScanApp extends StatelessWidget {
  const FatScanApp({super.key});

  static final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        redirect: (_, __) {
          final hive = HiveService();
          // Belum ada sesi (login penuh / tamu) → mulai dari onboarding.
          if (!hive.hasSession) return '/onboarding';
          // Tamu boleh langsung ke home (akses terbatas, tanpa setup profil).
          if (hive.isGuest) return '/home';
          // Login penuh tapi belum isi profil → setup profil.
          if (!hive.hasProfile()) return '/profile-setup';
          return '/home';
        },
      ),
      GoRoute(path: '/splash', redirect: (_, __) => '/onboarding'),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (_, __) => const NoTransitionPage(child: OnboardingPage()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (_, __) => const NoTransitionPage(child: LoginPage()),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterPage(),
      ),
      GoRoute(
        path: '/profile-setup',
        pageBuilder: (_, state) {
          final isEdit = state.uri.queryParameters['edit'] == 'true';
          final googleData = state.extra as Map<String, dynamic>?;
          return NoTransitionPage(child: ProfileSetupPage(isEdit: isEdit, googleData: googleData));
        },
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (_, __) => const NoTransitionPage(child: HomePage()),
        redirect: (context, state) {
          final hive = HiveService();
          // Tanpa sesi sama sekali → kembali ke login.
          if (!hive.hasSession) return '/login';
          // Tamu boleh masuk home walau belum ada profil (akses terbatas).
          if (hive.isGuest) return null;
          // Login penuh tapi belum ada profil → setup profil dulu.
          if (!hive.hasProfile()) return '/profile-setup';
          return null;
        },
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
        path: '/edit-profile',
        pageBuilder: (_, __) => const NoTransitionPage(child: EditProfilePage()),
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
