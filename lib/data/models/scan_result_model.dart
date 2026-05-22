import 'package:hive/hive.dart';

part 'scan_result_model.g.dart';

// ─── FoodItem ────────────────────────────────────────────────────────────────

@HiveType(typeId: 0)
class FoodItem extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  double grams;

  @HiveField(2)
  final double defaultGrams;

  @HiveField(3)
  final double defaultFat;

  @HiveField(4)
  final double defaultCalories;

  @HiveField(5)
  final double confidence;

  FoodItem({
    required this.name,
    required this.grams,
    required this.defaultGrams,
    required this.defaultFat,
    required this.defaultCalories,
    this.confidence = 1.0,
  });

  /// Lemak dihitung proporsional terhadap gram yang diinput
  double get fat => (grams / defaultGrams) * defaultFat;

  /// Kalori dihitung proporsional terhadap gram yang diinput
  double get calories => (grams / defaultGrams) * defaultCalories;

  FoodItem copyWith({
    String? name,
    double? grams,
    double? defaultGrams,
    double? defaultFat,
    double? defaultCalories,
    double? confidence,
  }) {
    return FoodItem(
      name: name ?? this.name,
      grams: grams ?? this.grams,
      defaultGrams: defaultGrams ?? this.defaultGrams,
      defaultFat: defaultFat ?? this.defaultFat,
      defaultCalories: defaultCalories ?? this.defaultCalories,
      confidence: confidence ?? this.confidence,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'grams': grams,
    'defaultGrams': defaultGrams,
    'defaultFat': defaultFat,
    'defaultCalories': defaultCalories,
    'confidence': confidence,
  };

  factory FoodItem.fromMap(Map<String, dynamic> map) => FoodItem(
    name: map['name'] as String,
    grams: (map['grams'] as num).toDouble(),
    defaultGrams: (map['defaultGrams'] as num).toDouble(),
    defaultFat: (map['defaultFat'] as num).toDouble(),
    defaultCalories: (map['defaultCalories'] as num).toDouble(),
    confidence: (map['confidence'] as num? ?? 1.0).toDouble(),
  );
}

// ─── Fat Status ──────────────────────────────────────────────────────────────

enum FatStatus {
  low,    // < 10g
  medium, // 10g – 25g
  high,   // > 25g
}

extension FatStatusExt on FatStatus {
  String get label {
    switch (this) {
      case FatStatus.low:
        return 'LOW FAT';
      case FatStatus.medium:
        return 'MEDIUM FAT';
      case FatStatus.high:
        return 'HIGH FAT ⚠️';
    }
  }

  String get shortLabel {
    switch (this) {
      case FatStatus.low:
        return 'Low Fat';
      case FatStatus.medium:
        return 'Medium Fat';
      case FatStatus.high:
        return 'High Fat';
    }
  }
}

// ─── ScanResultModel ─────────────────────────────────────────────────────────

@HiveType(typeId: 1)
class ScanResultModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime tanggal;

  @HiveField(2)
  final String imagePath;

  @HiveField(3)
  List<FoodItem> foods;

  @HiveField(4)
  final String status;

  ScanResultModel({
    required this.id,
    required this.tanggal,
    required this.imagePath,
    required this.foods,
    required this.status,
  });

  double get totalFat =>
      foods.fold(0.0, (sum, item) => sum + item.fat);

  double get totalCalories =>
      foods.fold(0.0, (sum, item) => sum + item.calories);

  /// Legacy getter untuk kompatibilitas dengan home_page.dart
  double get fatPercentage => totalFat;

  FatStatus get fatStatus {
    if (totalFat > 25) return FatStatus.high;
    if (totalFat >= 10) return FatStatus.medium;
    return FatStatus.low;
  }

  ScanResultModel copyWith({
    String? id,
    DateTime? tanggal,
    String? imagePath,
    List<FoodItem>? foods,
    String? status,
  }) {
    return ScanResultModel(
      id: id ?? this.id,
      tanggal: tanggal ?? this.tanggal,
      imagePath: imagePath ?? this.imagePath,
      foods: foods ?? this.foods,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'tanggal': tanggal.toIso8601String(),
    'imagePath': imagePath,
    'foods': foods.map((f) => f.toMap()).toList(),
    'status': status,
  };

  factory ScanResultModel.fromMap(Map<String, dynamic> map) => ScanResultModel(
    id: map['id'] as String,
    tanggal: DateTime.parse(map['tanggal'] as String),
    imagePath: map['imagePath'] as String,
    foods: (map['foods'] as List)
        .map((f) => FoodItem.fromMap(f as Map<String, dynamic>))
        .toList(),
    status: map['status'] as String,
  );
}
