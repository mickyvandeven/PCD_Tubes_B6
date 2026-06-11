import 'package:flutter/foundation.dart';

import 'auth_service.dart';

/// Aksi mana yang sedang memproses — dipakai untuk menampilkan spinner di
/// tombol yang tepat dan mencegah double-submit.
enum AuthAction { none, emailLogin, emailRegister, google, guest }

/// AuthController — menjembatani UI dengan [AuthService].
///
/// UI hanya membaca state (loading/error) dan memanggil method di sini;
/// seluruh logika autentikasi tetap di service. Controller TIDAK melakukan
/// navigasi — ia mengembalikan [AuthResult] agar widget yang punya
/// `BuildContext` yang menentukan rute (pemisahan tanggung jawab).
class AuthController extends ChangeNotifier {
  AuthController({AuthService? authService})
      : _auth = authService ?? AuthService();

  final AuthService _auth;

  AuthAction _action = AuthAction.none;
  AuthAction get action => _action;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// True bila ada operasi auth apa pun yang sedang berjalan.
  bool get isBusy => _action != AuthAction.none;

  bool isLoading(AuthAction a) => _action == a;

  // ── Validator (dipakai juga untuk validasi real-time di form) ──────

  static String? validateEmail(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Email tidak boleh kosong';
    final emailRegex = RegExp(r'^[\w.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!emailRegex.hasMatch(v)) return 'Format email tidak valid';
    return null;
  }

  static String? validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password tidak boleh kosong';
    if (v.length < 6) return 'Password minimal 6 karakter';
    return null;
  }

  static String? validateFullName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Nama lengkap tidak boleh kosong';
    if (v.length < 3) return 'Nama terlalu pendek';
    return null;
  }

  static String? validateConfirmPassword(String? value, String original) {
    if ((value ?? '').isEmpty) return 'Konfirmasi password kamu';
    if (value != original) return 'Password tidak cocok';
    return null;
  }

  // ── Aksi ──────────────────────────────────────────────────────────

  Future<AuthResult> loginWithEmail({
    required String email,
    required String password,
  }) {
    return _run(
      AuthAction.emailLogin,
      () => _auth.loginWithEmail(email: email, password: password),
    );
  }

  Future<AuthResult> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) {
    return _run(
      AuthAction.emailRegister,
      () => _auth.registerWithEmail(
        fullName: fullName,
        email: email,
        password: password,
      ),
    );
  }

  Future<AuthResult> signInWithGoogle() {
    return _run(AuthAction.google, () => _auth.signInWithGoogle());
  }

  Future<AuthResult> continueAsGuest() {
    return _run(AuthAction.guest, () => _auth.continueAsGuest());
  }

  Future<AuthResult> sendPasswordReset(String email) {
    return _run(AuthAction.none, () => _auth.sendPasswordReset(email),
        notify: false);
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Wrapper umum: set loading → jalankan → tangani error → reset loading.
  /// Mencegah double-submit lewat pengecekan [isBusy].
  Future<AuthResult> _run(
    AuthAction action,
    Future<AuthResult> Function() task, {
    bool notify = true,
  }) async {
    if (isBusy) return AuthResult.cancelled();

    _errorMessage = null;
    if (notify) {
      _action = action;
      notifyListeners();
    }

    try {
      final result = await task();
      if (!result.success && result.message != null) {
        _errorMessage = result.message;
      }
      return result;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan. Coba lagi.';
      return AuthResult.failure(_errorMessage!);
    } finally {
      _action = AuthAction.none;
      if (notify) notifyListeners();
    }
  }
}
