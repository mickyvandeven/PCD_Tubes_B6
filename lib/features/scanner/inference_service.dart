import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'frame_preprocessor.dart';
import 'result_parser.dart';

class InferenceResult {
  final List<dynamic> detections;
  InferenceResult(this.detections);
}

/// InferenceService — Jalankan model TFLite langsung di main thread
/// untuk debugging. Setelah terbukti jalan, bisa dipindah ke Isolate.
class InferenceService {
  Interpreter? _interpreter;
  bool _isProcessing = false;
  bool _isReady = false;
  
  Function(InferenceResult)? onResult;

  Future<void> init() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/fatscan_v2.tflite');
      
      debugPrint('=== MODEL LOADED ===');
      for (var t in _interpreter!.getInputTensors()) {
        debugPrint('INPUT -> Name: ${t.name}, Shape: ${t.shape}, Type: ${t.type}');
      }
      for (var t in _interpreter!.getOutputTensors()) {
        debugPrint('OUTPUT -> Name: ${t.name}, Shape: ${t.shape}, Type: ${t.type}');
      }
      
      _isReady = true;
    } catch (e) {
      debugPrint('❌ Error loading model: $e');
      _isReady = false;
    }
  }

  void runInference(CameraImage image, [int rotation = 0]) {
    if (!_isReady || _interpreter == null || _isProcessing) return;
    _isProcessing = true;
    
    try {
      // 1. Konversi YUV420/BGRA ke RGB Image penuh warna!
      final planes = image.planes.map((p) => p.bytes).toList();
      final bytesPerRow = image.planes.map((p) => p.bytesPerRow).toList();
      final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
      
      img.Image? colorImage = FramePreprocessor.convertBytesToImage(
        planes, bytesPerRow, image.width, image.height, isIOS
      );
      
      if (colorImage == null) {
        _isProcessing = false;
        return;
      }
      
      // 2. Rotate 90 derajat jika di Android (portrait)
      if (!isIOS) {
        colorImage = img.copyRotate(colorImage, angle: 90);
      }
      
      // 3. Buat tensor input menggunakan FramePreprocessor
      final inputTensor = _interpreter!.getInputTensors().first;
      final isQuantized = inputTensor.type == TensorType.uint8 || inputTensor.type == TensorType.int8;
      
      var inputData = FramePreprocessor.imageToTensor(colorImage, 224, isQuantized);
      
      // 5. Setup output buffer [1, 33, 1029]
      final outputTensor = _interpreter!.getOutputTensors().first;
      final outputShape = outputTensor.shape; // [1, 33, 1029]
      
      var outputData = List.generate(
        outputShape[0],
        (_) => List.generate(
          outputShape[1],
          (_) => List.filled(outputShape[2], 0.0),
        ),
      );
      
      // 6. Run!
      _interpreter!.run(inputData, outputData);
      
      // 7. Parse (Naikkan threshold ke 40% agar tidak asal tebak)
      final detections = ResultParser.parseYolo(outputData, 0.40);
      
      debugPrint('🔍 Detections: ${detections.length}');
      for (var d in detections) {
        debugPrint('  -> ${d['label']} (${(d['confidence'] * 100).toStringAsFixed(1)}%)');
      }
      
      onResult?.call(InferenceResult(detections));
    } catch (e) {
      debugPrint('❌ Inference error: $e');
      onResult?.call(InferenceResult([]));
    } finally {
      _isProcessing = false;
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isReady = false;
  }
}
