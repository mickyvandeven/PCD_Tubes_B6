import 'dart:math';

class ResultParser {
  static final List<String> _labels = [
    'Apple', 'Ayam Goreng', 'Bakso', 'Banana', 'Burger', 'Capcay', 
    'Chocolate Chip Cookie', 'Donat', 'Ikan Goreng', 'Kentang Goreng', 
    'Kiwi', 'Mie Goreng', 'Nasi Goreng', 'Nasi Putih', 'Nugget', 'Pempek', 
    'Pineapples', 'Pizza', 'Rendang Sapi', 'Sate', 'Spaghetti', 'Steak', 
    'Strawberry', 'Tahu Goreng', 'Telur Goreng', 'Telur Rebus', 'Tempe Goreng', 
    'Terong Balado', 'Tumis Kangkung'
  ];

  static List<dynamic> parseYolo(List<dynamic> outputData, double confidenceThreshold) {
    if (outputData.isEmpty || outputData[0].isEmpty) return [];
    
    // YOLOv8 output biasanya: [1][classes + 4][anchors]
    final data = outputData[0] as List;
    final numRows = data.length; 
    final numCols = (data[0] as List).length; 

    List<Map<String, dynamic>> results = [];
    
    // Transpose and parse
    for (int col = 0; col < numCols; col++) {
      double maxClassConf = 0.0;
      int classId = -1;
      
      for (int c = 4; c < numRows; c++) {
        double conf = (data[c][col] as num).toDouble();
        if (conf > maxClassConf) {
          maxClassConf = conf;
          classId = c - 4;
        }
      }
      
      if (maxClassConf >= confidenceThreshold) {
        // format [cx, cy, w, h] — sudah dalam range 0.0 - 1.0 (normalized)
        double cx = (data[0][col] as num).toDouble();
        double cy = (data[1][col] as num).toDouble();
        double w = (data[2][col] as num).toDouble();
        double h = (data[3][col] as num).toDouble();
        
        double left = (cx - (w / 2)).clamp(0.0, 1.0);
        double top = (cy - (h / 2)).clamp(0.0, 1.0);
        double right = (cx + (w / 2)).clamp(0.0, 1.0);
        double bottom = (cy + (h / 2)).clamp(0.0, 1.0);
        
        String label = classId >= 0 && classId < _labels.length ? _labels[classId] : 'Makanan $classId';

        results.add({
          'label': label,
          'confidence': maxClassConf,
          'bbox': [left, top, right, bottom],
        });
      }
    }

    return _applyNMS(results, 0.45);
  }
  
  static List<dynamic> _applyNMS(List<Map<String, dynamic>> boxes, double iouThreshold) {
    if (boxes.isEmpty) return [];
    
    boxes.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));
    
    List<dynamic> finalBoxes = [];
    while (boxes.isNotEmpty) {
      final bestBox = boxes.removeAt(0);
      finalBoxes.add(bestBox);
      
      boxes.removeWhere((box) {
        double iou = _calculateIoU(bestBox['bbox'], box['bbox']);
        return iou >= iouThreshold && bestBox['label'] == box['label'];
      });
    }
    
    return finalBoxes;
  }
  
  static double _calculateIoU(List<double> boxA, List<double> boxB) {
    double xA = max(boxA[0], boxB[0]);
    double yA = max(boxA[1], boxB[1]);
    double xB = min(boxA[2], boxB[2]);
    double yB = min(boxA[3], boxB[3]);
    
    double interArea = max(0.0, xB - xA) * max(0.0, yB - yA);
    if (interArea == 0) return 0.0;
    
    double boxAArea = (boxA[2] - boxA[0]) * (boxA[3] - boxA[1]);
    double boxBArea = (boxB[2] - boxB[0]) * (boxB[3] - boxB[1]);
    
    return interArea / (boxAArea + boxBArea - interArea);
  }
}
