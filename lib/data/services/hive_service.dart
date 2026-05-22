import 'package:hive_flutter/hive_flutter.dart';

import '../models/scan_result_model.dart';

/// Service untuk menyimpan dan membaca riwayat scan menggunakan Hive
class HiveService {
  static const _boxName = 'scan_history';

  static Box<ScanResultModel>? _box;

  /// Inisialisasi Hive - harus dipanggil sebelum runApp
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(FoodItemAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ScanResultModelAdapter());
    }

    _box = await Hive.openBox<ScanResultModel>(_boxName);
  }

  Box<ScanResultModel> get box {
    assert(_box != null && _box!.isOpen, 'Hive box belum diinisialisasi!');
    return _box!;
  }

  /// Simpan hasil scan
  Future<void> saveScan(ScanResultModel scan) async {
    await box.put(scan.id, scan);
  }

  /// Ambil semua riwayat scan, diurutkan terbaru
  List<ScanResultModel> getAllScans() {
    final scans = box.values.toList();
    scans.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    return scans;
  }

  /// Hapus scan berdasarkan id
  Future<void> deleteScan(String id) async {
    await box.delete(id);
  }

  /// Hapus semua riwayat
  Future<void> clearAll() async {
    await box.clear();
  }
}
