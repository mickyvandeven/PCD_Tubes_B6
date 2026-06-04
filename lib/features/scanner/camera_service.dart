import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/env_config.dart';

/// Layer 1: Camera Service
///
/// Mengelola kamera perangkat dengan dua mode:
/// 1. **Preview Only** (default) — kamera menyala, preview berjalan mulus
///    tanpa image stream. Ini sama lancarnya dengan buka kamera biasa / QRIS.
/// 2. **Periodic Capture** — untuk inferensi ML, secara periodik mengambil
///    gambar via `takePicture()` di background, tanpa menggunakan
///    `startImageStream` yang membebani UI thread.
///
/// Kenapa TIDAK pakai startImageStream?
/// → Plugin camera mengirim 30 callback/detik ke UI thread, masing-masing
///   membawa data frame berukuran besar. Ini menyebabkan jank/patah-patah
///   di preview meskipun pemrosesan sudah di isolate. Pendekatan periodic
///   capture menghindari masalah ini sepenuhnya.
class CameraService {
  CameraController? _controller;
  final ImagePicker _picker = ImagePicker();
  bool _isStreaming = false;
  Timer? _captureTimer;

  CameraController? get controller => _controller;
  bool get isInitialized =>
      _controller != null && _controller!.value.isInitialized;
  bool get isStreaming => _isStreaming;

  /// Inisialisasi kamera belakang. Preview langsung lancar setelah ini.
  Future<void> initialize() async {
    if (_controller != null) return;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception("Tidak ada kamera yang tersedia pada perangkat ini.");
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // Resolusi preview. Untuk preview lancar, 720p sudah ideal.
      ResolutionPreset preset = ResolutionPreset.high;
      switch (EnvConfig.cameraResolution.toLowerCase()) {
        case 'low':
          preset = ResolutionPreset.low;
          break;
        case 'medium':
          preset = ResolutionPreset.medium;
          break;
        case 'high':
          preset = ResolutionPreset.high;
          break;
        case 'veryhigh':
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
        // Tidak perlu set imageFormatGroup karena kita tidak pakai
        // startImageStream lagi.
      );

      await _controller!.initialize();

      // Optimasi: set flash off dan focus mode continuous untuk performa.
      try {
        await _controller!.setFlashMode(FlashMode.off);
        await _controller!.setFocusMode(FocusMode.auto);
      } catch (_) {
        // Abaikan jika device tidak support.
      }
    } catch (e) {
      debugPrint('CameraService.initialize error: $e');
      rethrow;
    }
  }

  /// Mulai inferensi periodik. Mengambil gambar setiap [interval] dan
  /// memanggil [onCapture] dengan path file-nya.
  ///
  /// Preview kamera tetap berjalan mulus karena TIDAK menggunakan
  /// `startImageStream`. Capture dilakukan via `takePicture()` yang berjalan
  /// di native thread terpisah.
  Future<void> startPeriodicCapture({
    required Future<void> Function(String filePath) onCapture,
    Duration interval = const Duration(milliseconds: 1500),
  }) async {
    if (!isInitialized) await initialize();
    if (_isStreaming) return;

    _isStreaming = true;

    // Tunggu sebentar agar preview render stabil sebelum mulai capture.
    await Future<void>.delayed(const Duration(milliseconds: 500));

    bool isCapturing = false;

    _captureTimer = Timer.periodic(interval, (timer) async {
      if (!_isStreaming || isCapturing) return;
      if (_controller == null || !_controller!.value.isInitialized) return;

      isCapturing = true;
      try {
        final xFile = await _controller!.takePicture();
        await onCapture(xFile.path);
        // Hapus file temp setelah diproses agar tidak menumpuk.
        try {
          await File(xFile.path).delete();
        } catch (_) {}
      } catch (e) {
        debugPrint('CameraService.periodicCapture error: $e');
      } finally {
        isCapturing = false;
      }
    });
  }

  /// Mulai stream kamera klasik (fallback jika periodic capture tidak cocok).
  /// PERINGATAN: Ini bisa menyebabkan jank di UI thread pada device mid-range.
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

  /// Hentikan stream/capture kamera
  Future<void> stopStream() async {
    _captureTimer?.cancel();
    _captureTimer = null;

    if (!isInitialized || !_isStreaming) {
      _isStreaming = false;
      return;
    }

    try {
      // Coba stop image stream (jika sedang aktif dalam mode stream klasik)
      if (_controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
    } catch (_) {}

    _isStreaming = false;
  }

  /// Membersihkan resource kamera untuk mencegah memory leak
  void dispose() {
    _captureTimer?.cancel();
    _captureTimer = null;
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
