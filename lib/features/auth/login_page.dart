import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/services/hive_service.dart';
import '../../data/services/mongo_service.dart';
import 'auth_controller.dart';
import 'widgets/auth_primary_button.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/google_sign_in_button.dart';

/// Halaman Login — email/password, Google Sign-In, dan mode tamu.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthController(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  AuthController get _controller => context.read<AuthController>();

  // ── Navigasi setelah berhasil ────────────────────────────────────
  // Pengguna baru / belum punya profil → setup profil dulu; selebihnya home.
  void _goAfterAuth({Map<String, dynamic>? googleData}) {
    if (!mounted) return;
    final hasProfile = HiveService().hasProfile();
    if (hasProfile) {
      context.go('/home');
    } else {
      context.go('/profile-setup?edit=false', extra: googleData);
    }
  }

  void _snack(String message, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  // ── Handlers ──────────────────────────────────────────────────────

  Future<void> _onLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final result = await _controller.loginWithEmail(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );

    if (result.success) {
      _goAfterAuth();
    } else if (result.message != null) {
      // Jika pesan mengandung "belum terdaftar", tampilkan alert dialog
      // khusus yang mengarahkan user ke halaman registrasi.
      if (result.message!.contains('belum terdaftar')) {
        _showNotRegisteredDialog();
      } else {
        _snack(result.message!);
      }
    }
  }

  void _showNotRegisteredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: AppColors.surface,
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.warning.withValues(alpha: 0.12),
          ),
          child: const Icon(
            Icons.person_off_rounded,
            color: AppColors.warning,
            size: 28,
          ),
        ),
        title: const Text(
          'Akun Belum Terdaftar',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'Email yang kamu masukkan belum terdaftar di FatScan. '
          'Silakan daftar terlebih dahulu untuk membuat akun baru.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.push('/register');
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Daftar Sekarang',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
  }

  Future<void> _onGoogle() async {
    final result = await _controller.signInWithGoogle();
    if (!result.success) {
      if (result.message != null) _snack(result.message!);
      return; // dibatalkan / gagal
    }

    final googleData = result.googleData;
    // Cek apakah akun sudah terdaftar di cloud → tarik profil & langsung home.
    if (googleData != null) {
      try {
        final existing =
            await MongoService().getUserByEmail(googleData['email'] as String);
        if (existing != null) {
          await HiveService().saveProfile(existing);
          _goAfterAuth();
          return;
        }
      } catch (_) {
        // Abaikan error koneksi; lanjut sebagai user baru.
      }
    }
    _goAfterAuth(googleData: googleData);
  }

  Future<void> _onForgotPassword() async {
    final emailError = AuthController.validateEmail(_emailCtrl.text);
    if (emailError != null) {
      _snack('Isi email yang valid dulu untuk reset password.');
      return;
    }
    await _controller.sendPasswordReset(_emailCtrl.text);
    _snack('Link reset password dikirim ke ${_emailCtrl.text.trim()}',
        error: false);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();
    final busy = controller.isBusy;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _AuthLogo(),
                  const SizedBox(height: 28),
                  const Text(
                    'Selamat Datang 👋',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Masuk untuk melanjutkan analisis lemak makananmu.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Email ──
                  AuthTextField(
                    controller: _emailCtrl,
                    label: 'Email',
                    hint: 'nama@email.com',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enabled: !busy,
                    validator: AuthController.validateEmail,
                  ),
                  const SizedBox(height: 18),

                  // ── Password ──
                  AuthTextField(
                    controller: _passwordCtrl,
                    label: 'Password',
                    hint: 'Masukkan password',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    enabled: !busy,
                    validator: AuthController.validatePassword,
                    onSubmitted: (_) => busy ? null : _onLogin(),
                  ),
                  const SizedBox(height: 8),

                  // ── Lupa password ──
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: busy ? null : _onForgotPassword,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      child: const Text(
                        'Lupa Password?',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Tombol Login ──
                  AuthPrimaryButton(
                    label: 'Masuk',
                    isLoading: controller.isLoading(AuthAction.emailLogin),
                    onPressed: _onLogin,
                  ),
                  const SizedBox(height: 22),

                  const AuthDivider(),
                  const SizedBox(height: 22),

                  // ── Google ──
                  GoogleSignInButton(
                    isLoading: controller.isLoading(AuthAction.google),
                    onPressed: _onGoogle,
                  ),
                  const SizedBox(height: 18),

                  // ── Ke Register ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Belum punya akun? ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: busy ? null : () => context.push('/register'),
                        child: const Text(
                          'Daftar',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo lingkaran bergradien untuk header layar auth.
class _AuthLogo extends StatelessWidget {
  const _AuthLogo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: AppColors.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(
          Icons.restaurant_rounded,
          color: Colors.white,
          size: 38,
        ),
      ),
    );
  }
}
