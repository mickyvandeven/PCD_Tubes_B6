import 'dart:async';
import 'dart:io';
import 'dart:isolate';
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

/// InferenceService
///
/// Menjalankan seluruh pipeline berat (konversi YUV→RGB, resize, dan
/// `Interpreter.run`) di dalam **background isolate** agar UI thread tetap
/// bebas. Tanpa ini, preview kamera akan tersendat (ngelag) karena setiap
/// frame memblokir thread render.
///
/// Tambahan optimasi anti-lag:
/// - Throttle frame: maksimal ~5 FPS untuk inferensi (tidak memproses 30 FPS).
/// - Backpressure: frame baru hanya dikirim bila isolate sedang idle.
class InferenceService {
  Isolate? _isolate;
  SendPort? _workerSendPort;
  ReceivePort? _receivePort;

  bool _isReady = false;
  bool _isBusy = false;

  /// Batasi laju inferensi. 200ms ≈ 5 FPS. Model ML tidak perlu 30 FPS.
  static const Duration _minFrameInterval = Duration(milliseconds: 200);
  DateTime _lastFrameTime = DateTime.fromMillisecondsSinceEpoch(0);

  Function(InferenceResult)? onResult;

  // Untuk inferensi sekali jalan (galeri) yang butuh nilai balik.
  final Map<int, Completer<List<dynamic>>> _fileRequests = {};
  int _fileRequestId = 0;

  bool get isReady => _isReady;

  Future<void> init() async {
    if (_isReady) return;
    try {
      // Muat byte model DI MAIN ISOLATE (punya akses rootBundle), lalu kirim
      // ke worker. Dengan begitu worker tidak perlu binary-messenger token.
      final modelData =
          await rootBundle.load('assets/models/fatscan_v2.tflite');
      final modelBytes = modelData.buffer
          .asUint8List(modelData.offsetInBytes, modelData.lengthInBytes);

      _receivePort = ReceivePort();
      final readyCompleter = Completer<void>();

      _receivePort!.listen((message) {
        if (message is SendPort) {
          // Handshake: worker mengirim port perintahnya.
          _workerSendPort = message;
          if (!readyCompleter.isCompleted) readyCompleter.complete();
        } else if (message is _StreamResult) {
          _isBusy = false; // Lepas backpressure, siap frame berikutnya.
          onResult?.call(InferenceResult(message.detections));
        } else if (message is _FileResult) {
          _fileRequests.remove(message.id)?.complete(message.detections);
        }
      });

      _isolate = await Isolate.spawn(
        _workerEntry,
        _WorkerInit(_receivePort!.sendPort, modelBytes),
      );

      await readyCompleter.future;
      _isReady = true;
      debugPrint('✅ InferenceService ready (background isolate)');
    } catch (e) {
      debugPrint('❌ InferenceService init error: $e');
      _isReady = false;
    }
  }

  /// Dipanggil dari stream kamera (30 FPS). Sangat ringan: hanya menyalin
  /// byte plane lalu mengirim ke isolate. Frame di-drop bila terlalu cepat
  /// atau isolate masih sibuk.
  void runInference(CameraImage image, [int rotation = 0]) {
    if (!_isReady || _workerSendPort == null || _isBusy) return;

    final now = DateTime.now();
    if (now.difference(_lastFrameTime) < _minFrameInterval) return;
    _lastFrameTime = now;
    _isBusy = true;

    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    _workerSendPort!.send(
      _FramePayload(
        planes: image.planes.map((p) => p.bytes).toList(),
        bytesPerRow: image.planes.map((p) => p.bytesPerRow).toList(),
        width: image.width,
        height: image.height,
        isIOS: isIOS,
      ),
    );
  }

  /// Inferensi sekali jalan dari file (galeri). Tetap di isolate agar decode
  /// gambar besar tidak menahan UI thread.
  Future<List<dynamic>> runInferenceOnFile(String filePath) async {
    if (!_isReady) await init(); // Pastikan worker siap (mis. dipanggil cepat).
    if (!_isReady || _workerSendPort == null) return [];
    try {
      final bytes = await File(filePath).readAsBytes();
      final id = _fileRequestId++;
      final completer = Completer<List<dynamic>>();
      _fileRequests[id] = completer;
      _workerSendPort!.send(_FilePayload(id, bytes));
      return await completer.future
          .timeout(const Duration(seconds: 10), onTimeout: () => []);
    } catch (e) {
      debugPrint('runInferenceOnFile error: $e');
      return [];
    }
  }

  void dispose() {
    try {
      _workerSendPort?.send(_kClose);
    } catch (_) {}
    _receivePort?.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _workerSendPort = null;
    _receivePort = null;
    _isReady = false;
    _isBusy = false;
    _fileRequests.clear();
  }
}

// ─── Protokol pesan isolate ───────────────────────────────────────────────

const String _kClose = '__close__';

class _WorkerInit {
  final SendPort sendPort;
  final Uint8List modelBytes;
  _WorkerInit(this.sendPort, this.modelBytes);
}

class _FramePayload {
  final List<Uint8List> planes;
  final List<int> bytesPerRow;
  final int width;
  final int height;
  final bool isIOS;
  _FramePayload({
    required this.planes,
    required this.bytesPerRow,
    required this.width,
    required this.height,
    required this.isIOS,
  });
}

class _StreamResult {
  final List<dynamic> detections;
  _StreamResult(this.detections);
}

class _FilePayload {
  final int id;
  final Uint8List bytes;
  _FilePayload(this.id, this.bytes);
}

class _FileResult {
  final int id;
  final List<dynamic> detections;
  _FileResult(this.id, this.detections);
}

// ─── Entry point background isolate ───────────────────────────────────────
//
// Berjalan di thread terpisah. Memuat interpreter dari buffer model, lalu
// memproses setiap frame/file yang dikirim main isolate.
void _workerEntry(_WorkerInit init) {
  late final Interpreter interpreter;
  try {
    interpreter = Interpreter.fromBuffer(
      init.modelBytes,
      options: InterpreterOptions()..threads = 2,
    );
  } catch (e) {
    // Beri tahu main isolate bahwa worker gagal (kirim hasil kosong).
    init.sendPort.send(_StreamResult(const []));
    return;
  }

  final inputTensor = interpreter.getInputTensors().first;
  final isQuantized = inputTensor.type == TensorType.uint8 ||
      inputTensor.type == TensorType.int8;
  final outputShape = interpreter.getOutputTensors().first.shape;

  List<List<List<double>>> makeOutputBuffer() => List.generate(
        outputShape[0],
        (_) => List.generate(
          outputShape[1],
          (_) => List.filled(outputShape[2], 0.0),
        ),
      );

  List<dynamic> runOnImage(img.Image image) {
    final input = FramePreprocessor.imageToTensor(image, 224, isQuantized);
    final output = makeOutputBuffer();
    interpreter.run(input, output);
    return ResultParser.parseYolo(output, 0.40);
  }

  final port = ReceivePort();
  init.sendPort.send(port.sendPort); // Handshake.

  port.listen((msg) {
    if (msg is _FramePayload) {
      try {
        img.Image? colorImage = FramePreprocessor.convertBytesToImage(
          msg.planes,
          msg.bytesPerRow,
          msg.width,
          msg.height,
          msg.isIOS,
        );
        if (colorImage == null) {
          init.sendPort.send(_StreamResult(const []));
          return;
        }
        // Android stream landscape → putar 90° agar sesuai orientasi portrait.
        if (!msg.isIOS) {
          colorImage = img.copyRotate(colorImage, angle: 90);
        }
        init.sendPort.send(_StreamResult(runOnImage(colorImage)));
      } catch (_) {
        init.sendPort.send(_StreamResult(const []));
      }
    } else if (msg is _FilePayload) {
      try {
        final image = img.decodeImage(msg.bytes);
        if (image == null) {
          init.sendPort.send(_FileResult(msg.id, const []));
          return;
        }
        init.sendPort.send(_FileResult(msg.id, runOnImage(image)));
      } catch (_) {
        init.sendPort.send(_FileResult(msg.id, const []));
      }
    } else if (msg == _kClose) {
      interpreter.close();
      port.close();
    }
  });
}
