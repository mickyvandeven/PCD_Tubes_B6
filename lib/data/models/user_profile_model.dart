import 'package:hive/hive.dart';

part 'user_profile_model.g.dart';

/// Level aktivitas fisik pengguna
@HiveType(typeId: 2)
enum ActivityLevel {
  @HiveField(0)
  sangatRingan, // sedentary (1.2)

  @HiveField(1)
  ringan, // lightly active (1.375)

  @HiveField(2)
  sedang, // moderately active (1.55)

  @HiveField(3)
  aktif, // very active (1.725)

  @HiveField(4)
  sangatAktif, // super active (1.9)
}

extension ActivityLevelExt on ActivityLevel {
  String get label {
    switch (this) {
      case ActivityLevel.sangatRingan:
        return 'Sangat Ringan';
      case ActivityLevel.ringan:
        return 'Ringan';
      case ActivityLevel.sedang:
        return 'Sedang';
      case ActivityLevel.aktif:
        return 'Aktif';
      case ActivityLevel.sangatAktif:
        return 'Sangat Aktif';
    }
  }

  String get description {
    switch (this) {
      case ActivityLevel.sangatRingan:
        return 'Duduk sepanjang hari, kurang gerak';
      case ActivityLevel.ringan:
        return 'Olahraga ringan 1–3x seminggu';
      case ActivityLevel.sedang:
        return 'Olahraga sedang 3–5x seminggu';
      case ActivityLevel.aktif:
        return 'Olahraga berat 6–7x seminggu';
      case ActivityLevel.sangatAktif:
        return 'Atlet / kerja fisik berat setiap hari';
    }
  }

  double get factor {
    switch (this) {
      case ActivityLevel.sangatRingan:
        return 1.2;
      case ActivityLevel.ringan:
        return 1.375;
      case ActivityLevel.sedang:
        return 1.55;
      case ActivityLevel.aktif:
        return 1.725;
      case ActivityLevel.sangatAktif:
        return 1.9;
    }
  }
}

/// Model profil pengguna — tersimpan lokal via Hive
@HiveType(typeId: 3)
class UserProfile extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String nama;

  @HiveField(2)
  String email;

  @HiveField(3)
  String jenisKelamin; // 'pria' | 'wanita'

  @HiveField(4)
  int usia; // tahun

  @HiveField(5)
  double beratBadan; // kg

  @HiveField(6)
  double tinggiBadan; // cm

  @HiveField(7)
  ActivityLevel levelAktivitas;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.nama,
    this.email = '',
    required this.jenisKelamin,
    required this.usia,
    required this.beratBadan,
    required this.tinggiBadan,
    required this.levelAktivitas,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Kalkulasi Nutrisi ────────────────────────────────────────────

  /// BMR menggunakan rumus Mifflin-St Jeor
  double get bmr {
    final base = (10 * beratBadan) + (6.25 * tinggiBadan) - (5 * usia);
    return jenisKelamin == 'pria' ? base + 5 : base - 161;
  }

  /// Total Daily Energy Expenditure
  double get tdee => bmr * levelAktivitas.factor;

  /// Target lemak harian: 25% dari TDEE, dibagi 9 kcal/gram
  double get targetLemakHarian => (tdee * 0.25) / 9;

  /// Target kalori harian = TDEE
  double get targetKaloriHarian => tdee;

  // ── Serialisasi ───────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'id': id,
    'nama': nama,
    'email': email,
    'jenisKelamin': jenisKelamin,
    'usia': usia,
    'beratBadan': beratBadan,
    'tinggiBadan': tinggiBadan,
    'levelAktivitas': levelAktivitas.index,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    id: map['id'] as String,
    nama: map['nama'] as String,
    email: map['email'] as String? ?? '',
    jenisKelamin: map['jenisKelamin'] as String,
    usia: map['usia'] as int,
    beratBadan: (map['beratBadan'] as num).toDouble(),
    tinggiBadan: (map['tinggiBadan'] as num).toDouble(),
    levelAktivitas:
        ActivityLevel.values[map['levelAktivitas'] as int],
    createdAt: DateTime.parse(map['createdAt'] as String),
    updatedAt: DateTime.parse(map['updatedAt'] as String),
  );

  UserProfile copyWith({
    String? nama,
    String? email,
    String? jenisKelamin,
    int? usia,
    double? beratBadan,
    double? tinggiBadan,
    ActivityLevel? levelAktivitas,
  }) {
    return UserProfile(
      id: id,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      usia: usia ?? this.usia,
      beratBadan: beratBadan ?? this.beratBadan,
      tinggiBadan: tinggiBadan ?? this.tinggiBadan,
      levelAktivitas: levelAktivitas ?? this.levelAktivitas,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
