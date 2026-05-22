import '../models/scan_result_model.dart';

/// Database nutrisi lokal dummy
/// Format: nama_makanan → {defaultGram, fat (g per defaultGram), calories (kcal per defaultGram)}
const Map<String, Map<String, double>> nutritionDatabase = {
  // ─── Nasi & Karbohidrat ──────────────────────────────────────────────────
  'Nasi Putih': {'defaultGram': 100, 'fat': 0.3, 'calories': 130},
  'Nasi Goreng': {'defaultGram': 250, 'fat': 12.0, 'calories': 450},
  'Nasi Padang': {'defaultGram': 300, 'fat': 18.0, 'calories': 520},
  'Nasi Uduk': {'defaultGram': 200, 'fat': 8.0, 'calories': 380},
  'Mie Goreng': {'defaultGram': 200, 'fat': 10.0, 'calories': 380},
  'Mie Rebus': {'defaultGram': 200, 'fat': 5.0, 'calories': 300},
  'Roti': {'defaultGram': 60, 'fat': 2.0, 'calories': 160},
  'Roti Bakar': {'defaultGram': 80, 'fat': 5.0, 'calories': 220},

  // ─── Protein ─────────────────────────────────────────────────────────────
  'Ayam Goreng': {'defaultGram': 100, 'fat': 14.0, 'calories': 240},
  'Ayam Bakar': {'defaultGram': 100, 'fat': 7.0, 'calories': 185},
  'Daging Sapi': {'defaultGram': 100, 'fat': 15.0, 'calories': 250},
  'Ikan Goreng': {'defaultGram': 100, 'fat': 8.0, 'calories': 200},
  'Ikan Bakar': {'defaultGram': 100, 'fat': 4.0, 'calories': 155},
  'Telur Goreng': {'defaultGram': 60, 'fat': 7.0, 'calories': 95},
  'Telur Rebus': {'defaultGram': 60, 'fat': 5.0, 'calories': 78},
  'Tahu Goreng': {'defaultGram': 80, 'fat': 5.0, 'calories': 100},
  'Tempe Goreng': {'defaultGram': 80, 'fat': 6.0, 'calories': 160},
  'Udang': {'defaultGram': 100, 'fat': 1.5, 'calories': 100},

  // ─── Sayur & Salad ───────────────────────────────────────────────────────
  'Sayuran': {'defaultGram': 100, 'fat': 0.5, 'calories': 40},
  'Salad': {'defaultGram': 150, 'fat': 2.0, 'calories': 80},
  'Gado-Gado': {'defaultGram': 250, 'fat': 18.0, 'calories': 380},
  'Capcay': {'defaultGram': 200, 'fat': 4.0, 'calories': 130},
  'Sup Sayur': {'defaultGram': 250, 'fat': 2.0, 'calories': 80},
  'Soto Ayam': {'defaultGram': 300, 'fat': 8.0, 'calories': 220},

  // ─── Gorengan ────────────────────────────────────────────────────────────
  'Kentang Goreng': {'defaultGram': 100, 'fat': 13.0, 'calories': 310},
  'Bakwan': {'defaultGram': 60, 'fat': 8.0, 'calories': 180},
  'Risol': {'defaultGram': 60, 'fat': 7.0, 'calories': 150},

  // ─── Fast Food ───────────────────────────────────────────────────────────
  'Burger': {'defaultGram': 200, 'fat': 28.0, 'calories': 540},
  'Pizza': {'defaultGram': 150, 'fat': 15.0, 'calories': 400},
  'Steak': {'defaultGram': 200, 'fat': 22.0, 'calories': 460},
  'Pasta': {'defaultGram': 200, 'fat': 8.0, 'calories': 350},
  'Sandwich': {'defaultGram': 150, 'fat': 10.0, 'calories': 320},

  // ─── Buah ────────────────────────────────────────────────────────────────
  'Buah-buahan': {'defaultGram': 150, 'fat': 0.3, 'calories': 80},
  'Semangka': {'defaultGram': 200, 'fat': 0.2, 'calories': 60},
  'Pisang': {'defaultGram': 100, 'fat': 0.3, 'calories': 89},
  'Mangga': {'defaultGram': 150, 'fat': 0.4, 'calories': 100},
  'Apel': {'defaultGram': 150, 'fat': 0.2, 'calories': 78},

  // ─── Snack & Dessert ─────────────────────────────────────────────────────
  'Kue': {'defaultGram': 80, 'fat': 10.0, 'calories': 280},
  'Donat': {'defaultGram': 60, 'fat': 11.0, 'calories': 250},
  'Coklat': {'defaultGram': 40, 'fat': 14.0, 'calories': 210},
  'Es Krim': {'defaultGram': 100, 'fat': 8.0, 'calories': 210},

  // ─── Seafood ─────────────────────────────────────────────────────────────
  'Seafood': {'defaultGram': 150, 'fat': 5.0, 'calories': 180},
  'Cumi': {'defaultGram': 100, 'fat': 2.0, 'calories': 140},
  'Kepiting': {'defaultGram': 100, 'fat': 1.8, 'calories': 120},

  // ─── Default ─────────────────────────────────────────────────────────────
  'Makanan Tidak Dikenal': {'defaultGram': 100, 'fat': 5.0, 'calories': 150},
};

/// Service untuk menghitung nutrisi makanan
class NutritionService {
  /// Ambil data nutrisi dari database berdasarkan nama makanan.
  /// Jika tidak ditemukan, gunakan data default.
  Map<String, double> getNutrition(String foodName) {
    // Coba exact match dulu
    if (nutritionDatabase.containsKey(foodName)) {
      return nutritionDatabase[foodName]!;
    }

    // Coba partial match (case-insensitive)
    final lower = foodName.toLowerCase();
    for (final entry in nutritionDatabase.entries) {
      if (entry.key.toLowerCase().contains(lower) ||
          lower.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    // Fallback default
    return nutritionDatabase['Makanan Tidak Dikenal']!;
  }

  /// Hitung lemak berdasarkan gram yang diinput
  double calculateFat({
    required double gramInput,
    required double defaultGram,
    required double defaultFat,
  }) {
    return (gramInput / defaultGram) * defaultFat;
  }

  /// Hitung kalori berdasarkan gram yang diinput
  double calculateCalories({
    required double gramInput,
    required double defaultGram,
    required double defaultCalories,
  }) {
    return (gramInput / defaultGram) * defaultCalories;
  }

  /// Buat FoodItem dari nama makanan yang terdeteksi
  FoodItem createFoodItem(String name, {double? confidence}) {
    final nutrition = getNutrition(name);
    return FoodItem(
      name: name,
      grams: nutrition['defaultGram']!,
      defaultGrams: nutrition['defaultGram']!,
      defaultFat: nutrition['fat']!,
      defaultCalories: nutrition['calories']!,
      confidence: confidence ?? 1.0,
    );
  }

  /// Tentukan status lemak berdasarkan total fat
  FatStatus getFatStatus(double totalFat) {
    if (totalFat > 25) return FatStatus.high;
    if (totalFat >= 10) return FatStatus.medium;
    return FatStatus.low;
  }

  /// Semua nama makanan yang tersedia di database
  List<String> get allFoodNames => nutritionDatabase.keys.toList()..sort();
}
