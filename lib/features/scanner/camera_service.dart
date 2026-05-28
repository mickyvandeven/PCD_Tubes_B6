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

      ResolutionPreset preset = ResolutionPreset.medium;
      switch (EnvConfig.cameraResolution.toLowerCase()) {
        case 'low':
          preset = ResolutionPreset.low;
          break;
        case 'high':
          preset = ResolutionPreset.high;
          break;
        case 'veryhigh':
          preset = ResolutionPreset.veryHigh;
          break;
        case 'max':
          preset = ResolutionPreset.max;
          break;
        case 'medium':
        default:
          preset = ResolutionPreset.medium;
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
