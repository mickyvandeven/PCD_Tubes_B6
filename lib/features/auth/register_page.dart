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

/// Halaman Register — nama lengkap, email, password + konfirmasi,
/// dengan validasi real-time. Juga menyediakan Google & mode tamu.
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthController(),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  AuthController get _controller => context.read<AuthController>();

  void _snack(String message, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _onRegister() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final result = await _controller.registerWithEmail(
      fullName: _nameCtrl.text,
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );

    if (!mounted) return;
    if (result.success) {
      // Akun baru → lanjut ke setup profil dengan data awal.
      context.go('/profile-setup?edit=false', extra: result.googleData);
    } else if (result.message != null) {
      _snack(result.message!);
    }
  }

  Future<void> _onGoogle() async {
    final result = await _controller.signInWithGoogle();
    if (!result.success) {
      if (result.message != null) _snack(result.message!);
      return;
    }
    final googleData = result.googleData;
    if (googleData != null) {
      try {
        final existing =
            await MongoService().getUserByEmail(googleData['email'] as String);
        if (existing != null) {
          await HiveService().saveProfile(existing);
          if (mounted) context.go('/home');
          return;
        }
      } catch (_) {/* lanjut sebagai user baru */}
    }
    if (mounted) context.go('/profile-setup?edit=false', extra: googleData);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuthController>();
    final busy = controller.isBusy;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: busy ? null : () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Buat Akun Baru',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Daftar untuk mulai memantau asupan lemak harianmu.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 26),

                // ── Nama lengkap ──
                AuthTextField(
                  controller: _nameCtrl,
                  label: 'Nama Lengkap',
                  hint: 'Nama kamu',
                  icon: Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  enabled: !busy,
                  validator: AuthController.validateFullName,
                ),
                const SizedBox(height: 16),

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
                const SizedBox(height: 16),

                // ── Password ──
                AuthTextField(
                  controller: _passwordCtrl,
                  label: 'Password',
                  hint: 'Minimal 8 karakter',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  enabled: !busy,
                  validator: AuthController.validatePassword,
                  // Validasi ulang konfirmasi saat password berubah.
                  onChanged: (_) {
                    if (_confirmCtrl.text.isNotEmpty) {
                      _formKey.currentState?.validate();
                    }
                  },
                ),
                const SizedBox(height: 16),

                // ── Konfirmasi password ──
                AuthTextField(
                  controller: _confirmCtrl,
                  label: 'Konfirmasi Password',
                  hint: 'Ulangi password',
                  icon: Icons.lock_reset_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  enabled: !busy,
                  validator: (v) => AuthController.validateConfirmPassword(
                      v, _passwordCtrl.text),
                  onSubmitted: (_) => busy ? null : _onRegister(),
                ),
                const SizedBox(height: 26),

                // ── Tombol Register ──
                AuthPrimaryButton(
                  label: 'Daftar',
                  isLoading: controller.isLoading(AuthAction.emailRegister),
                  onPressed: _onRegister,
                ),
                const SizedBox(height: 22),

                const AuthDivider(),
                const SizedBox(height: 22),

                // ── Google ──
                GoogleSignInButton(
                  isLoading: controller.isLoading(AuthAction.google),
                  onPressed: _onGoogle,
                ),
                const SizedBox(height: 14),

                // ── Ke Login ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Sudah punya akun? ',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: busy
                          ? null
                          : () {
                              // Jika datang dari login, cukup pop; jika tidak,
                              // ganti ke /login.
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/login');
                              }
                            },
                      child: const Text(
                        'Masuk',
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
    );
  }
}
