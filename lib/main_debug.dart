import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:math';

void main() {
  runApp(const MaterialApp(home: ModelTestPage()));
}

class ModelTestPage extends StatefulWidget {
  const ModelTestPage({Key? key}) : super(key: key);
  @override
  State<ModelTestPage> createState() => _ModelTestPageState();
}

class _ModelTestPageState extends State<ModelTestPage> {
  String _log = 'Tekan tombol untuk mulai tes...';
  bool _running = false;

  Future<void> _runTest() async {
    setState(() { _running = true; _log = 'Loading model...\n'; });

    try {
      final interpreter = await Interpreter.fromAsset('assets/models/fatscan_v2.tflite');
      _addLog('✅ Model berhasil dimuat!');
      
      // Print tensor info
      final inputT = interpreter.getInputTensors().first;
      final outputT = interpreter.getOutputTensors().first;
      _addLog('INPUT: shape=${inputT.shape}, type=${inputT.type}');
      _addLog('OUTPUT: shape=${outputT.shape}, type=${outputT.type}');
      
      // Buat input dummy [1, 224, 224, 3] float32 — isi dengan nilai random (simulasi gambar)
      final rng = Random(42);
      var input = List.generate(
        1,
        (_) => List.generate(
          224,
          (_) => List.generate(
            224,
            (_) => [rng.nextDouble(), rng.nextDouble(), rng.nextDouble()],
          ),
        ),
      );
      _addLog('✅ Input tensor dibuat (random noise)');

      // Setup output [1, 33, 1029]
      final oShape = outputT.shape;
      var output = List.generate(
        oShape[0],
        (_) => List.generate(
          oShape[1],
          (_) => List.filled(oShape[2], 0.0),
        ),
      );
      _addLog('✅ Output buffer siap: ${oShape}');

      // Run inference
      _addLog('⏳ Running inference...');
      final sw = Stopwatch()..start();
      interpreter.run(input, output);
      sw.stop();
      _addLog('✅ Inference selesai dalam ${sw.elapsedMilliseconds}ms');

      // Analisis output — cari confidence tertinggi
      // Output format YOLOv8: [1][33][1029]
      // Row 0-3 = bbox (cx, cy, w, h)
      // Row 4-32 = class confidences (29 classes)
      final data = output[0]; // [33][1029]
      
      _addLog('\n--- Raw Output Sampling ---');
      // Cetak beberapa nilai dari row pertama
      _addLog('Row0 (cx) first 5: ${data[0].sublist(0, 5).map((v) => v.toStringAsFixed(3)).toList()}');
      _addLog('Row4 (class0) first 5: ${data[4].sublist(0, 5).map((v) => v.toStringAsFixed(4)).toList()}');
      
      // Cari deteksi dengan confidence tertinggi
      double maxConf = 0.0;
      int bestCol = -1;
      int bestClass = -1;
      
      for (int col = 0; col < oShape[2]; col++) {
        for (int c = 4; c < oShape[1]; c++) {
          double conf = data[c][col];
          if (conf > maxConf) {
            maxConf = conf;
            bestCol = col;
            bestClass = c - 4;
          }
        }
      }
      
      final labels = [
        'Apple', 'Ayam Goreng', 'Bakso', 'Banana', 'Burger', 'Capcay', 
        'Chocolate Chip Cookie', 'Donat', 'Ikan Goreng', 'Kentang Goreng', 
        'Kiwi', 'Mie Goreng', 'Nasi Goreng', 'Nasi Putih', 'Nugget', 'Pempek', 
        'Pineapples', 'Pizza', 'Rendang Sapi', 'Sate', 'Spaghetti', 'Steak', 
        'Strawberry', 'Tahu Goreng', 'Telur Goreng', 'Telur Rebus', 'Tempe Goreng', 
        'Terong Balado', 'Tumis Kangkung'
      ];
      
      String bestLabel = bestClass >= 0 && bestClass < labels.length ? labels[bestClass] : '?';
      _addLog('\n--- Hasil Analisis ---');
      _addLog('Max confidence: ${(maxConf * 100).toStringAsFixed(2)}%');
      _addLog('Best class: $bestLabel (classId=$bestClass, col=$bestCol)');
      
      // Hitung berapa deteksi di atas threshold 0.15
      int countAbove015 = 0;
      int countAbove005 = 0;
      for (int col = 0; col < oShape[2]; col++) {
        for (int c = 4; c < oShape[1]; c++) {
          if (data[c][col] > 0.15) countAbove015++;
          if (data[c][col] > 0.05) countAbove005++;
        }
      }
      _addLog('Detections > 15%: $countAbove015');
      _addLog('Detections > 5%: $countAbove005');
      
      if (maxConf < 0.01) {
        _addLog('\n⚠️ Semua confidence sangat rendah!');
        _addLog('Kemungkinan: Input normalization tidak sesuai.');
        _addLog('Coba tes tanpa normalisasi (0-255 range)...');
        
        // Tes tanpa normalisasi
        var input2 = List.generate(
          1,
          (_) => List.generate(
            224,
            (_) => List.generate(
              224,
              (_) => [rng.nextInt(256).toDouble(), rng.nextInt(256).toDouble(), rng.nextInt(256).toDouble()],
            ),
          ),
        );
        var output2 = List.generate(
          oShape[0],
          (_) => List.generate(
            oShape[1],
            (_) => List.filled(oShape[2], 0.0),
          ),
        );
        interpreter.run(input2, output2);
        
        double maxConf2 = 0.0;
        for (int col = 0; col < oShape[2]; col++) {
          for (int c = 4; c < oShape[1]; c++) {
            if (output2[0][c][col] > maxConf2) maxConf2 = output2[0][c][col];
          }
        }
        _addLog('Max conf (0-255 range): ${(maxConf2 * 100).toStringAsFixed(2)}%');
      }
      
      interpreter.close();
      _addLog('\n✅ Test selesai!');
    } catch (e, st) {
      _addLog('❌ ERROR: $e');
      _addLog('Stack: ${st.toString().split('\n').take(5).join('\n')}');
    }
    
    setState(() { _running = false; });
  }

  void _addLog(String msg) {
    setState(() { _log += '\n$msg'; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TFLite Model Test')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _running ? null : _runTest,
              child: Text(_running ? 'Running...' : 'Run Model Test'),
            ),
            const SizedBox(height: 16),
            Text(_log, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
