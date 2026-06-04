import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../data/services/hive_service.dart';
import '../../data/services/mongo_service.dart';

/// Hasil sebuah operasi autentikasi.
///
/// Memisahkan "berhasil/gagal" dari pesan error agar lapisan UI tidak perlu
/// tahu detail implementasi (Firebase / REST API / mock).
class AuthResult {
  const AuthResult._({
    required this.success,
    this.message,
    this.googleData,
    this.isNewUser = false,
  });

  /// Operasi berhasil.
  factory AuthResult.success({
    Map<String, dynamic>? googleData,
    bool isNewUser = false,
  }) =>
      AuthResult._(success: true, googleData: googleData, isNewUser: isNewUser);

  /// Operasi gagal dengan pesan yang bisa ditampilkan ke user.
  factory AuthResult.failure(String message) =>
      AuthResult._(success: false, message: message);

  /// User membatalkan (mis. menutup dialog Google). Bukan error sebenarnya.
  factory AuthResult.cancelled() => const AuthResult._(success: false);

  final bool success;
  final String? message;

  /// Data akun Google (nama, email, dll) bila login via Google.
  final Map<String, dynamic>? googleData;

  /// True bila akun belum pernah terdaftar (perlu lanjut ke setup profil).
  final bool isNewUser;
}

/// AuthService — lapisan logika autentikasi.
///
/// SEMUA logika email/password di sini masih berupa **mock/placeholder**.
/// Ganti isi method `_mock*` dengan panggilan nyata ke `firebase_auth` atau
/// REST API backend-mu tanpa perlu mengubah UI maupun controller.
class AuthService {
  AuthService({HiveService? hiveService, GoogleSignIn? googleSignIn})
      : _hive = hiveService ?? HiveService(),
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final HiveService _hive;
  final GoogleSignIn _googleSignIn;

  /// Simulasi latensi jaringan agar loading state terlihat realistis.
  static const _mockNetworkDelay = Duration(milliseconds: 900);

  // ── Email / Password ──────────────────────────────────────────────

  /// Login dengan email & password.
  ///
  /// Verifikasi kredensial di MongoDB. Jika email belum terdaftar atau
  /// password salah, kembalikan pesan error yang sesuai.
  Future<AuthResult> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Verifikasi email + password di database.
      try {
        final verified =
            await MongoService().verifyLogin(email.trim(), password);
        if (verified == null) {
          // Cek apakah email ada tapi password salah, atau email tidak ada.
          final exists = await MongoService().getUserByEmail(email.trim());
          if (exists == null) {
            return AuthResult.failure(
              'Akun dengan email ini belum terdaftar. Silakan daftar terlebih dahulu.',
            );
          } else {
            return AuthResult.failure('Password salah. Coba lagi.');
          }
        }

        // Kredensial valid → simpan profil lokal & tandai login.
        await _hive.saveProfile(verified);

        // Download riwayat scan milik user ini dari cloud ke lokal.
        try {
          final history = await MongoService().getHistoryByUserId(verified.id);
          for (final scan in history) {
            await _hive.saveScan(scan.copyWith(userId: verified.id));
          }
        } catch (_) {
          // Abaikan; data lokal sudah cukup untuk lanjut.
        }
      } on Exception catch (e) {
        debugPrint('loginWithEmail DB check error: $e');
        return AuthResult.failure(
          'Tidak bisa menghubungi server. Periksa koneksi internet kamu.',
        );
      }

      await _hive.setLoggedIn(email.trim());
      return AuthResult.success();
    } catch (e) {
      debugPrint('AuthService.loginWithEmail error: $e');
      return AuthResult.failure('Gagal masuk. Periksa email & password kamu.');
    }
  }

  /// Registrasi akun baru dengan email & password.
  ///
  /// Membuat user di MongoDB dengan password ter-hash. Jika email sudah
  /// terdaftar, kembalikan error.
  Future<AuthResult> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      // Daftarkan user ke MongoDB.
      try {
        final userId = DateTime.now().millisecondsSinceEpoch.toString();
        final registered = await MongoService().registerUser(
          id: userId,
          email: email.trim(),
          password: password,
          nama: fullName.trim(),
        );

        if (!registered) {
          return AuthResult.failure(
            'Email sudah terdaftar. Silakan masuk atau gunakan email lain.',
          );
        }
      } on Exception catch (e) {
        debugPrint('registerWithEmail DB error: $e');
        return AuthResult.failure(
          'Tidak bisa menghubungi server. Periksa koneksi internet kamu.',
        );
      }

      await _hive.setLoggedIn(email.trim());
      return AuthResult.success(
        googleData: {
          'nama': fullName.trim(),
          'email': email.trim(),
        },
        isNewUser: true,
      );
    } catch (e) {
      debugPrint('AuthService.registerWithEmail error: $e');
      return AuthResult.failure('Gagal membuat akun. Coba lagi nanti.');
    }
  }

  /// Kirim email reset password.
  ///
  /// TODO(backend): ganti dengan
  /// `FirebaseAuth.instance.sendPasswordResetEmail(email: email)`.
  Future<AuthResult> sendPasswordReset(String email) async {
    try {
      await Future<void>.delayed(_mockNetworkDelay);
      return AuthResult.success();
    } catch (e) {
      return AuthResult.failure('Gagal mengirim email reset.');
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────────

  /// Login menggunakan akun Google.
  ///
  /// Mengembalikan [AuthResult.googleData] berisi profil Google agar halaman
  /// pemanggil bisa mengarahkan user baru ke setup profil.
  Future<AuthResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      // User menutup pop-up Google.
      if (account == null) return AuthResult.cancelled();

      await _hive.setLoggedIn(account.email);

      return AuthResult.success(
        googleData: {
          'nama': account.displayName ?? '',
          'email': account.email,
          'googleId': account.id,
          'photoUrl': account.photoUrl ?? '',
        },
        // Tanpa backend kita tidak tahu user lama/baru, jadi serahkan ke
        // pemanggil (mis. cek MongoService) untuk memutuskan.
        isNewUser: true,
      );
    } catch (e) {
      debugPrint('AuthService.signInWithGoogle error: $e');
      return AuthResult.failure('Login Google gagal: $e');
    }
  }

  // ── Mode Tamu ─────────────────────────────────────────────────────

  /// Lewati autentikasi — masuk sebagai tamu dengan akses terbatas.
  Future<AuthResult> continueAsGuest() async {
    try {
      await _hive.setGuest();
      return AuthResult.success();
    } catch (e) {
      return AuthResult.failure('Gagal masuk sebagai tamu.');
    }
  }

  // ── Logout ────────────────────────────────────────────────────────

  /// Keluar dari akun (Google + sesi lokal + data scan lokal).
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Abaikan; mungkin user tidak login via Google.
    }
    // Bersihkan data lokal scan agar user berikutnya tidak melihatnya.
    await _hive.clearAllScans();
    await _hive.clearSession();
    await _hive.deleteProfile();
  }
}
