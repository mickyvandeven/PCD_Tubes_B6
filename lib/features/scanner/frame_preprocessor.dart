import 'dart:typed_data';
import 'package:image/image.dart' as img;

class FramePreprocessor {
  /// Konversi plane bytes dari kamera ke img.Image (FULL COLOR)
  static img.Image? convertBytesToImage(List<Uint8List> planes, List<int> bytesPerRow, int width, int height, bool isIOS) {
    try {
      if (isIOS) {
        return img.Image.fromBytes(
          width: width,
          height: height,
          bytes: planes[0].buffer,
          rowStride: bytesPerRow[0],
          format: img.Format.uint8,
          order: img.ChannelOrder.bgra,
        );
      } else {
        // YUV420 to RGB (Android) - Konversi warna penuh!
        // Plane 0 = Y (luminance, full resolution)
        // Plane 1 = U (Cb, half resolution)
        // Plane 2 = V (Cr, half resolution)
        final yPlane = planes[0];
        final uPlane = planes[1];
        final vPlane = planes[2];
        final yRowStride = bytesPerRow[0];
        final uvRowStride = bytesPerRow[1];
        // pixelStride untuk UV plane (biasanya 2 untuk interleaved, 1 untuk planar)
        // Karena kita tidak punya info pixelStride, asumsikan interleaved (2)
        // yang umum untuk Android CameraX
        const uvPixelStride = 2;

        final image = img.Image(width: width, height: height);
        
        for (int y = 0; y < height; y++) {
          for (int x = 0; x < width; x++) {
            final yValue = yPlane[y * yRowStride + x];
            final uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;
            
            // Pastikan index tidak melebihi batas array
            if (uvIndex >= uPlane.length || uvIndex >= vPlane.length) continue;
            
            final uValue = uPlane[uvIndex];
            final vValue = vPlane[uvIndex];
            
            // YUV to RGB conversion formula
            int r = (yValue + 1.370705 * (vValue - 128)).round().clamp(0, 255);
            int g = (yValue - 0.337633 * (uValue - 128) - 0.698001 * (vValue - 128)).round().clamp(0, 255);
            int b = (yValue + 1.732446 * (uValue - 128)).round().clamp(0, 255);
            
            image.setPixelRgb(x, y, r, g, b);
          }
        }
        return image;
      }
    } catch (e) {
      return null;
    }
  }

  /// Konversi img.Image ke Tensor Input [1, inputSize, inputSize, 3]
  static dynamic imageToTensor(img.Image image, int inputSize, bool isQuantized) {
    // Resize image
    final resized = img.copyResize(image, width: inputSize, height: inputSize);
    
      if (isQuantized) {
      // Uint8 / Int8
      var input = List.generate(
        1,
        (_) => List.generate(
          inputSize,
          (y) => List.generate(
            inputSize,
            (x) {
              final pixel = resized.getPixel(x, y);
              if (resized.numChannels == 1) {
                return [pixel.r.toInt(), pixel.r.toInt(), pixel.r.toInt()];
              } else {
                return [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
              }
            },
          ),
        ),
      );
      return input;
    } else {
      // Float32
      var input = List.generate(
        1,
        (_) => List.generate(
          inputSize,
          (y) => List.generate(
            inputSize,
            (x) {
              final pixel = resized.getPixel(x, y);
              if (resized.numChannels == 1) {
                // Jika grayscale (YUV Android plane 0), duplikat channel luminance ke RGB
                return [
                  (pixel.r / 255.0),
                  (pixel.r / 255.0),
                  (pixel.r / 255.0)
                ];
              } else {
                return [
                  (pixel.r / 255.0),
                  (pixel.g / 255.0),
                  (pixel.b / 255.0)
                ];
              }
            },
          ),
        ),
      );
      return input;
    }
  }
}
