import 'dart:isolate';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;

import 'frame_preprocessor.dart';

/// Pesan yang dikirim dari Main Thread ke Isolate
class InferenceRequest {
  final int width;
  final int height;
  // TODO: Di produksi nyata, kirim List<Uint8List> planes.bytes
  // final List<Uint8List> planes;
  InferenceRequest(this.width, this.height);
}

/// Pesan yang dikirim dari Isolate ke Main Thread
class InferenceResult {
  final List<dynamic> detections;
  InferenceResult(this.detections);
}

/// Layer 2: Inference Engine
/// Menggunakan Isolate.spawn untuk menjalankan model ML secara paralel
/// agar UI kamera tidak patah-patah (stuttering).
class InferenceService {
  Isolate? _isolate;
  SendPort? _sendPort;
  final ReceivePort _receivePort = ReceivePort();
  bool _isProcessing = false;
  
  Function(InferenceResult)? onResult;

  /// Inisialisasi Isolate dan siapkan komunikasi
  Future<void> init() async {
    _receivePort.listen((message) {
      if (message is SendPort) {
        // Menerima port dari isolate untuk bisa mengirim data ke sana
        _sendPort = message;
      } else if (message is InferenceResult) {
        // Menerima hasil deteksi
        _isProcessing = false;
        onResult?.call(message);
      }
    });

    try {
      _isolate = await Isolate.spawn(_isolateEntry, _receivePort.sendPort);
    } catch (e) {
      debugPrint('Error spawning isolate: $e');
    }
  }

  /// Eksekusi inferensi pada frame kamera
  void runInference(CameraImage image) {
    if (_sendPort == null || _isProcessing) return;
    
    // Cegah penumpukan frame jika Isolate masih memproses frame sebelumnya
    _isProcessing = true;
    
    // Kirim request ke Isolate
    _sendPort!.send(InferenceRequest(image.width, image.height));
  }

  void dispose() {
    _receivePort.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
  }

  // ─── Entry Point Isolate (Berjalan di Background Thread) ──────────────────
  
  static void _isolateEntry(SendPort mainSendPort) {
    final isolateReceivePort = ReceivePort();
    mainSendPort.send(isolateReceivePort.sendPort);
    
    // TODO: Inisialisasi model tflite_flutter.Interpreter di sini
    
    final random = math.Random();

    isolateReceivePort.listen((message) async {
      if (message is InferenceRequest) {
        // Simulasi Preprocessing (memakan waktu ~20ms)
        await Future.delayed(const Duration(milliseconds: 20));
        
        // Simulasi TFLite Inference (memakan waktu ~80ms)
        await Future.delayed(const Duration(milliseconds: 80));
        
        // MOCKUP HASIL DETEKSI AI
        // Mengembalikan koordinat acak dan label acak untuk simulasi
        final mockResults = [];
        
        // 30% chance untuk mendeteksi makanan (agar terlihat realistis)
        if (random.nextDouble() > 0.7) {
          final isSalad = random.nextBool();
          mockResults.add({
            'label': isSalad ? 'Salad Sayur' : 'Daging Sapi',
            'confidence': 0.85 + (random.nextDouble() * 0.1), // 85% - 95%
            'fat': isSalad ? 2.5 : 22.0,
            'calories': isSalad ? 120.0 : 450.0,
            'bbox': [
              0.2 + random.nextDouble() * 0.1, // left
              0.3 + random.nextDouble() * 0.1, // top
              0.7 + random.nextDouble() * 0.1, // right
              0.8 + random.nextDouble() * 0.1, // bottom
            ]
          });
        }

        // Kirim hasil kembali ke Main Thread
        mainSendPort.send(InferenceResult(mockResults));
      }
    });
  }
}
