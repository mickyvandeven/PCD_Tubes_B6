import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Layer 1: Frame Preprocessor
/// Mengonversi CameraImage dari stream kamera menjadi format Image 
/// (atau Float32List tensor) yang siap dimasukkan ke dalam model ML.
class FramePreprocessor {
  /// Mengonversi CameraImage menjadi format RGB / Tensor
  /// Fungsi ini berjalan di dalam Isolate agar tidak memblokir UI.
  static List<dynamic>? preprocess(CameraImage cameraImage, int inputSize) {
    try {
      img.Image? image;
      
      if (Platform.isAndroid) {
        // Konversi format YUV420 ke RGB (Android)
        if (cameraImage.format.group == ImageFormatGroup.yuv420) {
          image = _convertYUV420ToImage(cameraImage);
        }
      } else if (Platform.isIOS) {
        // Konversi BGRA8888 ke RGB (iOS)
        if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
          image = _convertBGRA8888ToImage(cameraImage);
        }
      }

      if (image == null) return null;

      // TODO: Implementasi resize dan normalisasi (misal dibagi 255.0) 
      // untuk Float32List tensor yang sebenarnya di sini.
      
      // Untuk versi mock, kita cukup kembalikan data palsu atau metadata image
      // agar tidak memperlambat kinerja tanpa tujuan.
      return [image.width, image.height]; 
    } catch (e) {
      debugPrint('Error preprocessing frame: $e');
      return null;
    }
  }

  // ─── Metode Internal Konversi Format Kamera ───────────────────────────────

  static img.Image _convertYUV420ToImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    
    // Skeleton: Biasanya kita menggunakan image.Plane untuk mengambil Y, U, V
    // Karena ini cukup berat jika dipanggil murni di Dart (tanpa ffi/package khusus),
    // sementara ini kita mereturn blank image berukuran sama.
    // Di produksi nyata, bisa menggunakan C++ (FFI) atau image.Image.fromBytes() khusus.
    
    return img.Image(width: width, height: height);
  }

  static img.Image _convertBGRA8888ToImage(CameraImage image) {
    return img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: image.planes[0].bytes.buffer,
      format: img.Format.uint8,
      order: img.ChannelOrder.bgra,
    );
  }
}
