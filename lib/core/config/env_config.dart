import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get modelPath => dotenv.env['MODEL_PATH'] ?? 'assets/models/fatscan_v2.tflite';
  static double get confidenceThreshold => double.tryParse(dotenv.env['CONFIDENCE_THRESHOLD'] ?? '0.65') ?? 0.65;
  static int get inputSize => int.tryParse(dotenv.env['INPUT_SIZE'] ?? '224') ?? 224;
  static int get maxDetections => int.tryParse(dotenv.env['MAX_DETECTIONS'] ?? '5') ?? 5;
  static String get cameraResolution => dotenv.env['CAMERA_RESOLUTION'] ?? 'medium';
  static String get mongoDbAtlasUri => dotenv.env['MONGODB_ATLAS_URI'] ?? '';
}
