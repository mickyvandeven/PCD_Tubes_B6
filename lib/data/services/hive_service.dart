import 'package:hive_flutter/hive_flutter.dart';

import '../models/scan_result_model.dart';
import '../models/user_profile_model.dart';

/// Service untuk menyimpan dan membaca data lokal menggunakan Hive
class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();
  static const _boxScanHistory = 'scan_history';
  static const _boxUserProfile = 'user_profile';
  static const _boxAppSettings = 'app_settings';
  static const _profileKey = 'current_user';

  // ── Kunci status autentikasi ──────────────────────────────────────
  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyIsGuest = 'is_guest';
  static const _keyAuthEmail = 'auth_email';

  static Box<ScanResultModel>? _scanBox;
  static Box<UserProfile>? _profileBox;
  static Box? _settingsBox;

  /// Inisialisasi Hive — harus dipanggil sebelum runApp
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters scan
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(FoodItemAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ScanResultModelAdapter());
    }

    // Register adapters user profile
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ActivityLevelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(UserProfileAdapter());
    }

    // Buka boxes
    _scanBox = await Hive.openBox<ScanResultModel>(_boxScanHistory);
    _profileBox = await Hive.openBox<UserProfile>(_boxUserProfile);
    _settingsBox = await Hive.openBox(_boxAppSettings);
  }

  // ── Scan History ────────────────────────────────────────────────

  Box<ScanResultModel> get scanBox {
    assert(_scanBox != null && _scanBox!.isOpen, 'Scan box belum diinisialisasi!');
    return _scanBox!;
  }

  /// ID user yang sedang login (diambil dari profil lokal).
  /// Digunakan untuk memfilter data scan agar tiap user hanya lihat datanya.
  String get _currentUserId => getProfile()?.id ?? '';

  /// Simpan hasil scan (otomatis dikaitkan dengan user yang sedang login)
  Future<void> saveScan(ScanResultModel scan) async {
    // Pastikan scan punya userId sebelum disimpan.
    final scanWithUser = scan.userId.isNotEmpty
        ? scan
        : scan.copyWith(userId: _currentUserId);
    await scanBox.put(scanWithUser.id, scanWithUser);
  }

  /// Ambil semua riwayat scan MILIK USER SAAT INI, diurutkan terbaru.
  /// Data user lain tidak akan tampil.
  List<ScanResultModel> getAllScans() {
    final userId = _currentUserId;
    final scans = scanBox.values.where((scan) {
      // Scan lama tanpa userId (backward-compat) akan muncul untuk semua user.
      // Scan baru hanya muncul untuk pemiliknya.
      return scan.userId.isEmpty || scan.userId == userId;
    }).toList();
    scans.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    return scans;
  }

  /// Ambil scan hari ini saja
  List<ScanResultModel> getTodayScans() {
    final now = DateTime.now();
    return getAllScans().where((scan) {
      return scan.tanggal.year == now.year &&
          scan.tanggal.month == now.month &&
          scan.tanggal.day == now.day;
    }).toList();
  }

  /// Total lemak yang dikonsumsi hari ini
  double getTodayTotalFat() {
    return getTodayScans().fold(0.0, (sum, scan) => sum + scan.totalFat);
  }

  /// Total scan hari ini
  int getTodayScanCount() => getTodayScans().length;

  /// Rata-rata lemak dari semua scan
  double getAverageFat() {
    final all = getAllScans();
    if (all.isEmpty) return 0.0;
    final total = all.fold(0.0, (sum, scan) => sum + scan.totalFat);
    return total / all.length;
  }

  /// Hapus scan berdasarkan id
  Future<void> deleteScan(String id) async {
    await scanBox.delete(id);
  }

  /// Hapus semua riwayat scan
  Future<void> clearAllScans() async {
    await scanBox.clear();
  }

  // ── User Profile ─────────────────────────────────────────────────

  Box<UserProfile> get profileBox {
    assert(_profileBox != null && _profileBox!.isOpen, 'Profile box belum diinisialisasi!');
    return _profileBox!;
  }

  /// Cek apakah profil sudah ada
  bool hasProfile() => profileBox.containsKey(_profileKey);

  /// Simpan profil user
  Future<void> saveProfile(UserProfile profile) async {
    await profileBox.put(_profileKey, profile);
  }

  /// Ambil profil user (null jika belum diisi)
  UserProfile? getProfile() => profileBox.get(_profileKey);

  /// Hapus profil (untuk logout / reset)
  Future<void> deleteProfile() async {
    await profileBox.delete(_profileKey);
  }

  // ── Status Autentikasi & Mode Tamu ───────────────────────────────

  Box get settingsBox {
    assert(_settingsBox != null && _settingsBox!.isOpen,
        'Settings box belum diinisialisasi!');
    return _settingsBox!;
  }

  /// True jika user sudah login lewat email/Google.
  bool get isLoggedIn => settingsBox.get(_keyIsLoggedIn, defaultValue: false) as bool;

  /// True jika user memilih "Lewati" (mode tamu, akses terbatas).
  bool get isGuest => settingsBox.get(_keyIsGuest, defaultValue: false) as bool;

  /// True jika user boleh masuk ke aplikasi (login penuh ATAU tamu).
  bool get hasSession => isLoggedIn || isGuest;

  /// Email akun yang sedang aktif (kosong untuk tamu).
  String get authEmail => settingsBox.get(_keyAuthEmail, defaultValue: '') as String;

  /// Tandai user sudah login penuh.
  Future<void> setLoggedIn(String email) async {
    await settingsBox.putAll({
      _keyIsLoggedIn: true,
      _keyIsGuest: false,
      _keyAuthEmail: email,
    });
  }

  /// Tandai user masuk sebagai tamu (akses terbatas).
  Future<void> setGuest() async {
    await settingsBox.putAll({
      _keyIsLoggedIn: false,
      _keyIsGuest: true,
      _keyAuthEmail: '',
    });
  }

  /// Bersihkan seluruh status sesi (dipakai saat logout).
  Future<void> clearSession() async {
    await settingsBox.deleteAll([_keyIsLoggedIn, _keyIsGuest, _keyAuthEmail]);
  }
}
