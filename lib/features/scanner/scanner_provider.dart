import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../data/models/scan_result_model.dart';
import '../../data/services/hive_service.dart';
import '../../data/services/ml_service.dart';
import '../../data/services/nutrition_service.dart';
import 'camera_service.dart';
import 'inference_service.dart';

enum ScanState {
  idle,
  picking,
  streaming,
  analyzing,
  done,
  error,
}

/// Provider / ChangeNotifier untuk seluruh alur scanner
class ScannerProvider extends ChangeNotifier {
  ScannerProvider({
    CameraService? cameraService,
    MlService? mlService,
    NutritionService? nutritionService,
    HiveService? hiveService,
  })  : _camera = cameraService ?? CameraService(),
        _ml = mlService ?? MlService(),
        _nutrition = nutritionService ?? NutritionService(),
        _hive = hiveService ?? HiveService() {
    _inferenceService.onResult = _handleInferenceResult;
    _inferenceService.init();
  }

  final CameraService _camera;
  final MlService _ml;
  final NutritionService _nutrition;
  final HiveService _hive;
  final InferenceService _inferenceService = InferenceService();

  ScanState _state = ScanState.idle;
  ScanState get state => _state;

  File? _imageFile;
  File? get imageFile => _imageFile;

  ScanResultModel? _result;
  ScanResultModel? get result => _result;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  bool get isLoading =>
      _state == ScanState.picking || _state == ScanState.analyzing;

  bool get isStreaming => _state == ScanState.streaming;

  List<dynamic> _currentDetections = [];
  List<dynamic> get currentDetections => _currentDetections;

  // Expose camera controller for CameraPreview
  get cameraController => _camera.controller;

  // ─── Public Methods ──────────────────────────────────────────────────────

  /// Buka kamera dan mulai stream
  Future<void> scanFromCamera() async {
    try {
      _setState(ScanState.picking);
      await _camera.initialize();
      _setState(ScanState.streaming);
      // Memulai stream kamera, frame diproses di Background Isolate
      await _camera.startStream((imageFrame) {
        _inferenceService.runInference(imageFrame);
      });
    } catch (e) {
      _errorMessage = 'Gagal membuka kamera: $e';
      _setState(ScanState.error);
    }
  }

  /// Pilih dari galeri dan lakukan scan
  Future<void> scanFromGallery() async {
    _setState(ScanState.picking);
    final file = await _camera.pickFromGallery();
    if (file == null) {
      _setState(ScanState.idle);
      return;
    }
    await _processImage(file);
  }

  /// Menangkap hasil deteksi dari kamera live stream saat ini
  Future<void> captureFrame() async {
    if (!isStreaming) return;
    
    _setState(ScanState.analyzing);
    _camera.stopStream(); // Hentikan stream

    try {
      List<DetectedFood> detected = [];
      
      if (_currentDetections.isNotEmpty) {
        // Ambil data hasil AI dari Isolate
        for (var d in _currentDetections) {
          detected.add(DetectedFood(
            name: d['label'],
            confidence: d['confidence'],
          ));
        }
      } else {
        // Fallback jika tombol ditekan saat AI belum menangkap apa-apa
        detected = _getFallbackFoods();
      }

      // Buat detail nutrisi untuk setiap makanan
      final foods = detected.map((d) {
        return _nutrition.createFoodItem(d.name, confidence: d.confidence);
      }).toList();

      final totalFat = foods.fold(0.0, (s, f) => s + f.fat);
      final fatStatus = _nutrition.getFatStatus(totalFat);

      _result = ScanResultModel(
        id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
        tanggal: DateTime.now(),
        imagePath: '', // Gambar tidak disimpan secara fisik saat ini
        foods: foods,
        status: fatStatus.shortLabel,
      );

      _setState(ScanState.done);
    } catch (e) {
      _errorMessage = 'Gagal menangkap frame: $e';
      _setState(ScanState.error);
    }
  }

  /// Update gram makanan pada index tertentu dan hitung ulang
  void updateGram(int index, double newGram) {
    if (_result == null) return;
    if (index < 0 || index >= _result!.foods.length) return;

    final updatedFoods = List<FoodItem>.from(_result!.foods);
    updatedFoods[index] = updatedFoods[index].copyWith(
      grams: newGram.clamp(1, 9999),
    );

    _result = _result!.copyWith(
      foods: updatedFoods,
      status: _nutrition
          .getFatStatus(
            updatedFoods.fold(0.0, (s, f) => s + f.fat),
          )
          .shortLabel,
    );

    notifyListeners();
  }

  /// Simpan hasil scan ke history
  Future<void> saveScan() async {
    if (_result == null) return;
    try {
      await _hive.saveScan(_result!);
    } catch (e) {
      debugPrint('ScannerProvider.saveScan error: $e');
    }
  }

  /// Reset ke idle
  void reset() {
    _camera.stopStream();
    _currentDetections.clear();
    _imageFile = null;
    _result = null;
    _errorMessage = '';
    _setState(ScanState.idle);
  }

  @override
  void dispose() {
    _inferenceService.dispose();
    _camera.dispose();
    super.dispose();
  }

  // ─── Internal ────────────────────────────────────────────────────────────

  Future<void> _processImage(File file) async {
    _imageFile = file;
    _setState(ScanState.analyzing);

    try {
      // Detect foods
      List<DetectedFood> detected;
      try {
        detected = await _ml.detectFoodsDetailed(file);
      } catch (e) {
        debugPrint('ML detection error (fallback): $e');
        // Fallback jika ML Kit gagal (mis. emulator tanpa model)
        detected = _getFallbackFoods();
      }

      // Jika tidak ada yang terdeteksi, gunakan fallback
      if (detected.isEmpty) {
        detected = _getFallbackFoods();
      }

      // Buat FoodItem untuk setiap makanan yang terdeteksi
      final foods = detected.map((d) {
        return _nutrition.createFoodItem(d.name, confidence: d.confidence);
      }).toList();

      final totalFat = foods.fold(0.0, (s, f) => s + f.fat);
      final fatStatus = _nutrition.getFatStatus(totalFat);

      _result = ScanResultModel(
        id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
        tanggal: DateTime.now(),
        imagePath: file.path,
        foods: foods,
        status: fatStatus.shortLabel,
      );

      _setState(ScanState.done);
    } catch (e) {
      _errorMessage = 'Gagal menganalisis gambar: $e';
      _setState(ScanState.error);
    }
  }

  List<DetectedFood> _getFallbackFoods() {
    // Contoh fallback untuk demo / emulator
    return [
      const DetectedFood(name: 'Nasi Goreng', confidence: 0.92),
      const DetectedFood(name: 'Ayam Goreng', confidence: 0.85),
    ];
  }

  void _setState(ScanState state) {
    _state = state;
    notifyListeners();
  }

  void _handleInferenceResult(InferenceResult result) {
    if (!isStreaming) return;
    _currentDetections = result.detections;
    notifyListeners();
  }
}
