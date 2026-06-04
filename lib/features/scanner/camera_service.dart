import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/env_config.dart';

/// Layer 1: Camera Stream
/// Mengelola seluruh alur frame dari kamera perangkat (real-time) dan galeri.
class CameraService {
  CameraController? _controller;
  final ImagePicker _picker = ImagePicker();
  bool _isStreaming = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _controller != null && _controller!.value.isInitialized;
  bool get isStreaming => _isStreaming;

  /// Inisialisasi kamera belakang dengan resolusi dari EnvConfig
  Future<void> initialize() async {
    if (_controller != null) return;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception("Tidak ada kamera yang tersedia pada perangkat ini.");
      }

      // Pilih kamera belakang jika ada, atau kamera pertama
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // ANTI-LAG: untuk preview + stream real-time, JANGAN gunakan resolusi
      // maksimum. Resolusi tinggi membuat buffer frame besar sehingga konversi
      // YUV→RGB & inferensi jadi berat. Default kita batasi di 720p (high),
      // yang merupakan sweet-spot kualitas vs performa.
      ResolutionPreset preset = ResolutionPreset.high; // ~720p
      switch (EnvConfig.cameraResolution.toLowerCase()) {
        case 'low': // ~240p
          preset = ResolutionPreset.low;
          break;
        case 'medium': // ~480p
          preset = ResolutionPreset.medium;
          break;
        case 'high': // ~720p (disarankan)
          preset = ResolutionPreset.high;
          break;
        case 'veryhigh': // ~1080p (maksimal yang masih wajar untuk stream)
          preset = ResolutionPreset.veryHigh;
          break;
        // 'max' sengaja TIDAK dipetakan ke ResolutionPreset.max untuk live
        // stream agar tidak memicu lag berat. Dibatasi ke 1080p.
        case 'max':
          preset = ResolutionPreset.veryHigh;
          break;
        default:
          preset = ResolutionPreset.high;
      }

      _controller = CameraController(
        camera,
        preset,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid 
            ? ImageFormatGroup.yuv420 
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
    } catch (e) {
      debugPrint('CameraService.initialize error: $e');
      rethrow;
    }
  }

  /// Mulai stream dari kamera
  Future<void> startStream(Function(CameraImage imageFrame) onFrame) async {
    if (!isInitialized) await initialize();
    if (_isStreaming) return;

    try {
      await _controller!.startImageStream((CameraImage image) {
        onFrame(image);
      });
      _isStreaming = true;
    } catch (e) {
      debugPrint('CameraService.startStream error: $e');
    }
  }

  /// Hentikan stream kamera
  Future<void> stopStream() async {
    if (!isInitialized || !_isStreaming) return;
    
    try {
      await _controller!.stopImageStream();
      _isStreaming = false;
    } catch (e) {
      debugPrint('CameraService.stopStream error: $e');
    }
  }

  /// Membersihkan resource kamera untuk mencegah memory leak
  void dispose() {
    _controller?.dispose();
    _controller = null;
    _isStreaming = false;
  }

  // ─── Fitur Mode Statis / Galeri ──────────────────────────────────────────

  /// Ambil foto langsung dari kamera aktif
  Future<File?> takePicture() async {
    if (!isInitialized || _controller == null) return null;
    try {
      final XFile file = await _controller!.takePicture();
      return File(file.path);
    } catch (e) {
      debugPrint('CameraService.takePicture error: $e');
      return null;
    }
  }

  /// Pilih gambar dari galeri (menggunakan image_picker)
  Future<File?> pickFromGallery() async {
    try {
      final XFile? xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1280,
        maxHeight: 1280,
      );
      if (xFile == null) return null;
      return File(xFile.path);
    } catch (e) {
      debugPrint('CameraService.pickFromGallery error: $e');
      return null;
    }
  }
}
