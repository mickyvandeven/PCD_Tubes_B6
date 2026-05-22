import 'dart:io';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

/// Model untuk hasil deteksi satu item makanan dari ML Kit
class DetectedFood {
  final String name;
  final double confidence;

  const DetectedFood({required this.name, required this.confidence});

  @override
  String toString() => 'DetectedFood(name: $name, confidence: $confidence)';
}

/// Service untuk mendeteksi makanan dari gambar menggunakan Google ML Kit
class MlService {
  // Set label yang dianggap "makanan" (kata kunci)
  static const _foodKeywords = <String>{
    'food', 'dish', 'meal', 'cuisine', 'rice', 'noodle', 'bread', 'meat',
    'chicken', 'beef', 'fish', 'vegetable', 'fruit', 'salad', 'soup', 'curry',
    'steak', 'burger', 'pizza', 'pasta', 'sandwich', 'snack', 'dessert',
    'cake', 'cookie', 'donut', 'chocolate', 'ice cream', 'egg', 'tofu',
    'tempeh', 'satay', 'rendang', 'nasi', 'mie', 'ayam', 'ikan', 'sayur',
    'buah', 'roti', 'daging', 'soto', 'gado', 'sate', 'ketoprak',
    'breakfast', 'lunch', 'dinner', 'plate', 'bowl', 'fast food', 'seafood',
    'shrimp', 'prawn', 'crab', 'lobster', 'squid', 'tuna', 'salmon',
    'pork', 'lamb', 'turkey', 'sausage', 'bacon', 'ham', 'kebab',
    'falafel', 'hummus', 'dumpling', 'sushi', 'ramen', 'pho',
    'pad thai', 'fried rice', 'biryani', 'paella', 'tapas',
    'corn', 'potato', 'carrot', 'broccoli', 'spinach', 'mushroom',
    'tomato', 'onion', 'garlic', 'pepper', 'cucumber', 'lettuce',
    'apple', 'banana', 'orange', 'mango', 'grape', 'strawberry',
    'watermelon', 'pineapple', 'avocado', 'lemon', 'lime',
    'milk', 'cheese', 'butter', 'yogurt', 'cream',
    'coffee', 'tea', 'juice', 'smoothie',
  };

  // Mapping nama ML Kit → nama makanan Indonesia yang lebih ramah
  static const _nameMapping = <String, String>{
    'fried rice': 'Nasi Goreng',
    'rice': 'Nasi Putih',
    'chicken': 'Ayam Goreng',
    'beef': 'Daging Sapi',
    'fish': 'Ikan Goreng',
    'noodle': 'Mie Goreng',
    'bread': 'Roti',
    'egg': 'Telur',
    'tofu': 'Tahu',
    'tempeh': 'Tempe',
    'salad': 'Salad',
    'soup': 'Sup',
    'curry': 'Kari',
    'burger': 'Burger',
    'pizza': 'Pizza',
    'pasta': 'Pasta',
    'sandwich': 'Sandwich',
    'cake': 'Kue',
    'vegetable': 'Sayuran',
    'fruit': 'Buah-buahan',
    'seafood': 'Seafood',
    'shrimp': 'Udang',
    'potato': 'Kentang',
    'corn': 'Jagung',
    'mushroom': 'Jamur',
    'sausage': 'Sosis',
    'steak': 'Steak',
  };

  /// Deteksi makanan dari file gambar.
  /// Mengembalikan daftar [DetectedFood] yang terdeteksi.
  Future<List<DetectedFood>> detectFoodsDetailed(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);

    final labeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.4),
    );

    try {
      final labels = await labeler.processImage(inputImage);

      // Filter hanya label yang berkaitan dengan makanan
      final foodLabels = labels.where((label) {
        final lower = label.label.toLowerCase();
        return _foodKeywords.any((kw) => lower.contains(kw));
      }).toList();

      // Jika tidak ada label makanan, ambil label teratas sebagai fallback
      final resultsSource =
          foodLabels.isNotEmpty ? foodLabels : labels.take(3).toList();

      final detected = resultsSource.map((label) {
        final lower = label.label.toLowerCase();
        // Coba temukan mapping nama yang lebih ramah
        String friendlyName = label.label;
        for (final entry in _nameMapping.entries) {
          if (lower.contains(entry.key)) {
            friendlyName = entry.value;
            break;
          }
        }
        return DetectedFood(name: friendlyName, confidence: label.confidence);
      }).toList();

      // Hilangkan duplikat berdasarkan nama
      final seen = <String>{};
      final unique = detected.where((d) => seen.add(d.name)).toList();

      return unique;
    } finally {
      labeler.close();
    }
  }

  /// Wrapper sederhana – hanya mengembalikan list nama makanan
  Future<List<String>> detectFoods(File imageFile) async {
    final detailed = await detectFoodsDetailed(imageFile);
    return detailed.map((d) => d.name).toList();
  }
}
