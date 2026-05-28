import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ModelDebugger extends StatefulWidget {
  const ModelDebugger({Key? key}) : super(key: key);

  @override
  State<ModelDebugger> createState() => _ModelDebuggerState();
}

class _ModelDebuggerState extends State<ModelDebugger> {
  String info = "Memuat model...";

  @override
  void initState() {
    super.initState();
    _checkModel();
  }

  Future<void> _checkModel() async {
    try {
      final interpreter = await Interpreter.fromAsset('assets/models/fatscan_v2.tflite');
      String out = "=== MODEL TENSORS ===\n";
      out += "INPUTS:\n";
      for (var t in interpreter.getInputTensors()) {
        out += "Name: ${t.name}\nShape: ${t.shape}\nType: ${t.type}\n\n";
      }
      out += "OUTPUTS:\n";
      for (var t in interpreter.getOutputTensors()) {
        out += "Name: ${t.name}\nShape: ${t.shape}\nType: ${t.type}\n\n";
      }
      setState(() {
        info = out;
      });
    } catch (e) {
      setState(() {
        info = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Model Debugger')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(info, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
