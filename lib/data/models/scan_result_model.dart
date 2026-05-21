class ScanResultModel {
  final String id;
  final DateTime tanggal;
  final String imagePath;
  final double fatPercentage;
  final String status;

  const ScanResultModel({
    required this.id,
    required this.tanggal,
    required this.imagePath,
    required this.fatPercentage,
    required this.status,
  });

  ScanResultModel copyWith({
    String? id,
    DateTime? tanggal,
    String? imagePath,
    double? fatPercentage,
    String? status,
  }) {
    return ScanResultModel(
      id: id ?? this.id,
      tanggal: tanggal ?? this.tanggal,
      imagePath: imagePath ?? this.imagePath,
      fatPercentage: fatPercentage ?? this.fatPercentage,
      status: status ?? this.status,
    );
  }
}
