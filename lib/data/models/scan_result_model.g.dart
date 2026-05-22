// lib/data/models/scan_result_model.g.dart
// GENERATED CODE - DO NOT MODIFY BY HAND
// Dibuat manual karena tidak menjalankan build_runner
// Ini stub agar kode dapat dikompilasi tanpa code generation

part of 'scan_result_model.dart';

// ─── FoodItem Adapter ────────────────────────────────────────────────────────

class FoodItemAdapter extends TypeAdapter<FoodItem> {
  @override
  final int typeId = 0;

  @override
  FoodItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FoodItem(
      name: fields[0] as String,
      grams: (fields[1] as num).toDouble(),
      defaultGrams: (fields[2] as num).toDouble(),
      defaultFat: (fields[3] as num).toDouble(),
      defaultCalories: (fields[4] as num).toDouble(),
      confidence: (fields[5] as num? ?? 1.0).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, FoodItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.grams)
      ..writeByte(2)
      ..write(obj.defaultGrams)
      ..writeByte(3)
      ..write(obj.defaultFat)
      ..writeByte(4)
      ..write(obj.defaultCalories)
      ..writeByte(5)
      ..write(obj.confidence);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// ─── ScanResultModel Adapter ─────────────────────────────────────────────────

class ScanResultModelAdapter extends TypeAdapter<ScanResultModel> {
  @override
  final int typeId = 1;

  @override
  ScanResultModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScanResultModel(
      id: fields[0] as String,
      tanggal: fields[1] as DateTime,
      imagePath: fields[2] as String,
      foods: (fields[3] as List).cast<FoodItem>(),
      status: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ScanResultModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tanggal)
      ..writeByte(2)
      ..write(obj.imagePath)
      ..writeByte(3)
      ..write(obj.foods)
      ..writeByte(4)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanResultModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
