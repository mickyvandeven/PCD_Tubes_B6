import 'package:hive_flutter/hive_flutter.dart';

import '../models/scan_result_model.dart';
import '../models/user_profile_model.dart';

/// Service untuk menyimpan dan membaca data lokal menggunakan Hive
class HiveService {
  static const _boxScanHistory = 'scan_history';
  static const _boxUserProfile = 'user_profile';
  static const _profileKey = 'current_user';

  static Box<ScanResultModel>? _scanBox;
  static Box<UserProfile>? _profileBox;

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
  }

  // ── Scan History ────────────────────────────────────────────────

  Box<ScanResultModel> get scanBox {
    assert(_scanBox != null && _scanBox!.isOpen, 'Scan box belum diinisialisasi!');
    return _scanBox!;
  }

  /// Simpan hasil scan
  Future<void> saveScan(ScanResultModel scan) async {
    await scanBox.put(scan.id, scan);
  }

  /// Ambil semua riwayat scan, diurutkan terbaru
  List<ScanResultModel> getAllScans() {
    final scans = scanBox.values.toList();
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
}
