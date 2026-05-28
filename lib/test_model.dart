import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final interpreter = await Interpreter.fromAsset('assets/models/fatscan_v2.tflite');
    print('=== MODEL INPUTS ===');
    for (var tensor in interpreter.getInputTensors()) {
      print('Name: ${tensor.name}, Shape: ${tensor.shape}, Type: ${tensor.type}');
    }
    print('=== MODEL OUTPUTS ===');
    for (var tensor in interpreter.getOutputTensors()) {
      print('Name: ${tensor.name}, Shape: ${tensor.shape}, Type: ${tensor.type}');
    }
  } catch (e) {
    print('Error loading model: $e');
  }
}
