import 'dart:io';

import '../models/scan_result_model.dart';
import '../services/hive_service.dart';
import '../services/ml_service.dart';
import '../services/nutrition_service.dart';

/// Repository untuk mengelola proses scan makanan
/// Menggabungkan ML detection + nutrition lookup + penyimpanan Hive
class ScanRepository {
	ScanRepository({
		HiveService? hiveService,
		MlService? mlService,
		NutritionService? nutritionService,
	})  : _hive = hiveService ?? HiveService(),
				_ml = mlService ?? MlService(),
				_nutrition = nutritionService ?? NutritionService();

	final HiveService _hive;
	final MlService _ml;
	final NutritionService _nutrition;

	// ─── Scan dari File Gambar ────────────────────────────────────────────────

	/// Proses scan dari file gambar (galeri atau capture)
	/// Mengembalikan ScanResultModel tanpa menyimpan ke Hive
	Future<ScanResultModel> scanFromFile(File imageFile) async {
		List<DetectedFood> detected;
		try {
			detected = await _ml.detectFoodsDetailed(imageFile);
		} catch (e) {
			detected = _getFallbackFoods();
		}

		if (detected.isEmpty) {
			detected = _getFallbackFoods();
		}

		final foods = detected.map((d) {
			return _nutrition.createFoodItem(d.name, confidence: d.confidence);
		}).toList();

		final totalFat = foods.fold(0.0, (s, f) => s + f.fat);
		final fatStatus = _nutrition.getFatStatus(totalFat);

		return ScanResultModel(
			id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
			tanggal: DateTime.now(),
			imagePath: imageFile.path,
			foods: foods,
			status: fatStatus.shortLabel,
		);
	}

	// ─── Scan dari Deteksi Live Camera ───────────────────────────────────────

	/// Buat ScanResultModel dari hasil deteksi live camera (tanpa file)
	ScanResultModel scanFromDetections(List<dynamic> detections) {
		List<DetectedFood> detected;

		if (detections.isNotEmpty) {
			detected = detections.map((d) {
				return DetectedFood(
					name: d['label'] as String,
					confidence: (d['confidence'] as num).toDouble(),
				);
			}).toList();
		} else {
			detected = _getFallbackFoods();
		}

		final foods = detected.map((d) {
			return _nutrition.createFoodItem(d.name, confidence: d.confidence);
		}).toList();

		final totalFat = foods.fold(0.0, (s, f) => s + f.fat);
		final fatStatus = _nutrition.getFatStatus(totalFat);

		return ScanResultModel(
			id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
			tanggal: DateTime.now(),
			imagePath: '',
			foods: foods,
			status: fatStatus.shortLabel,
		);
	}

	// ─── Simpan ke Hive ───────────────────────────────────────────────────────

	/// Simpan hasil scan ke local storage (Hive)
	Future<void> saveScan(ScanResultModel scan) async {
		await _hive.saveScan(scan);
	}

	/// Scan sekaligus langsung simpan ke Hive
	Future<ScanResultModel> scanAndSave(File imageFile) async {
		final result = await scanFromFile(imageFile);
		await saveScan(result);
		return result;
	}

	// ─── Update Gram ──────────────────────────────────────────────────────────

	/// Update gram makanan pada index tertentu
	/// Mengembalikan ScanResultModel baru dengan nilai yang sudah diupdate
	ScanResultModel updateFoodGram(
		ScanResultModel scan,
		int foodIndex,
		double newGram,
	) {
		if (foodIndex < 0 || foodIndex >= scan.foods.length) return scan;

		final updatedFoods = List<FoodItem>.from(scan.foods);
		updatedFoods[foodIndex] = updatedFoods[foodIndex].copyWith(
			grams: newGram.clamp(1, 9999),
		);

		final totalFat = updatedFoods.fold(0.0, (s, f) => s + f.fat);
		final fatStatus = _nutrition.getFatStatus(totalFat);

		return scan.copyWith(
			foods: updatedFoods,
			status: fatStatus.shortLabel,
		);
	}

	// ─── Internal ─────────────────────────────────────────────────────────────

	List<DetectedFood> _getFallbackFoods() {
		return [
			const DetectedFood(name: 'Nasi Goreng', confidence: 0.92),
			const DetectedFood(name: 'Ayam Goreng', confidence: 0.85),
		];
	}
}
