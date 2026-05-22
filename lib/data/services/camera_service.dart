import 'dart:io';
import 'package:image_picker/image_picker.dart';

/// Service untuk mengambil gambar dari kamera atau galeri
class CameraService {
  final ImagePicker _picker = ImagePicker();

  /// Ambil foto dari kamera
  Future<File?> takePhoto() async {
    try {
      final XFile? xFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1280,
        maxHeight: 1280,
      );
      if (xFile == null) return null;
      return File(xFile.path);
    } catch (e) {
      // ignore: avoid_print
      print('CameraService.takePhoto error: $e');
      return null;
    }
  }

  /// Pilih gambar dari galeri
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
      // ignore: avoid_print
      print('CameraService.pickFromGallery error: $e');
      return null;
    }
  }
}
