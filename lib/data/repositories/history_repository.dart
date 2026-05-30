import '../models/scan_result_model.dart';
import '../services/hive_service.dart';

/// Repository untuk mengelola riwayat scan
/// Lapisan abstraksi antara UI dan HiveService
class HistoryRepository {
	HistoryRepository({HiveService? hiveService})
			: _hive = hiveService ?? HiveService();

	final HiveService _hive;

	// ─── Read ──────────────────────────────────────────────────────────────────

	/// Ambil semua riwayat scan, diurutkan dari terbaru
	List<ScanResultModel> getAllHistory() {
		return _hive.getAllScans();
	}

	/// Ambil riwayat scan hari ini saja
	List<ScanResultModel> getTodayHistory() {
		final now = DateTime.now();
		return _hive.getAllScans().where((scan) {
			return scan.tanggal.year == now.year &&
					scan.tanggal.month == now.month &&
					scan.tanggal.day == now.day;
		}).toList();
	}

	/// Ambil riwayat scan dalam 7 hari terakhir
	List<ScanResultModel> getWeeklyHistory() {
		final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
		return _hive.getAllScans().where((scan) {
			return scan.tanggal.isAfter(sevenDaysAgo);
		}).toList();
	}

	/// Ambil scan terbaru (1 data terakhir)
	ScanResultModel? getLatestScan() {
		final all = _hive.getAllScans();
		return all.isEmpty ? null : all.first;
	}

	/// Ambil jumlah total scan
	int getTotalScanCount() {
		return _hive.getAllScans().length;
	}

	// ─── Statistik ─────────────────────────────────────────────────────────────

	/// Hitung rata-rata lemak harian dalam 7 hari terakhir
	/// Mengembalikan list 7 nilai (index 0 = 6 hari lalu, index 6 = hari ini)
	List<double> getWeeklyFatAverage() {
		final result = List<double>.filled(7, 0.0);
		final today = DateTime.now();

		for (int i = 0; i < 7; i++) {
			final targetDate = today.subtract(Duration(days: 6 - i));
			final scansOnDay = _hive.getAllScans().where((scan) {
				return scan.tanggal.year == targetDate.year &&
						scan.tanggal.month == targetDate.month &&
						scan.tanggal.day == targetDate.day;
			}).toList();

			if (scansOnDay.isNotEmpty) {
				final totalFat =
						scansOnDay.fold(0.0, (sum, scan) => sum + scan.totalFat);
				result[i] = totalFat;
			}
		}

		return result;
	}

	/// Hitung total lemak hari ini
	double getTodayTotalFat() {
		return getTodayHistory().fold(0.0, (sum, scan) => sum + scan.totalFat);
	}

	/// Hitung rata-rata lemak per scan (semua waktu)
	double getAverageFatPerScan() {
		final all = _hive.getAllScans();
		if (all.isEmpty) return 0.0;
		final total = all.fold(0.0, (sum, scan) => sum + scan.totalFat);
		return total / all.length;
	}

	/// Hitung jumlah scan hari ini
	int getTodayScanCount() {
		return getTodayHistory().length;
	}

	// ─── Write ─────────────────────────────────────────────────────────────────

	/// Simpan hasil scan baru
	Future<void> saveScan(ScanResultModel scan) async {
		await _hive.saveScan(scan);
	}

	/// Hapus scan berdasarkan id
	Future<void> deleteScan(String id) async {
		await _hive.deleteScan(id);
	}

	/// Hapus seluruh riwayat scan
	Future<void> clearAllHistory() async {
		await _hive.clearAll();
	}
}
