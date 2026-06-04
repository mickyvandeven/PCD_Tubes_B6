import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile_model.dart';
import '../models/scan_result_model.dart';

class MongoService {
  static final MongoService _instance = MongoService._internal();
  factory MongoService() => _instance;
  MongoService._internal();

  Db? _db;
  bool get isConnected => _db?.state == State.open;

  /// Hash password menggunakan SHA-256. Sederhana dan cukup untuk MVP.
  /// Pada production, gunakan bcrypt atau Argon2 di sisi backend.
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<void> init() async {
    try {
      final uri = dotenv.env['MONGODB_ATLAS_URI'];
      if (uri == null || uri.isEmpty) {
        debugPrint('MongoDB URI not found in .env');
        return;
      }

      _db = await Db.create(uri);
      await _db!.open();
      debugPrint('MongoDB Atlas Connected successfully!');
    } catch (e) {
      debugPrint('Error connecting to MongoDB: $e');
    }
  }

  Future<void> syncUserProfile(UserProfile profile, {String? password}) async {
    if (!isConnected) return;
    try {
      final usersCollection = _db!.collection('users');
      
      final doc = <String, dynamic>{
        '_id': profile.id,
        'nama': profile.nama,
        'email': profile.email.isNotEmpty ? profile.email : 'default@email.com',
        'jenisKelamin': profile.jenisKelamin,
        'usia': profile.usia,
        'beratBadan': profile.beratBadan,
        'tinggiBadan': profile.tinggiBadan,
        'levelAktivitas': profile.levelAktivitas.index,
        'createdAt': profile.createdAt,
        'updatedAt': profile.updatedAt,
      };

      // Jika password diberikan (registrasi awal), simpan hash-nya.
      if (password != null && password.isNotEmpty) {
        doc['passwordHash'] = hashPassword(password);
      }

      // Update if exists, insert if not (upsert)
      await usersCollection.update(
        where.eq('_id', profile.id),
        doc,
        upsert: true,
      );
      debugPrint('UserProfile synced to Atlas');
    } catch (e) {
      debugPrint('Failed to sync UserProfile: $e');
    }
  }

  /// Registrasi user baru dengan email & password (hashed).
  /// Mengembalikan true jika berhasil, false jika email sudah terdaftar.
  Future<bool> registerUser({
    required String id,
    required String email,
    required String password,
    required String nama,
  }) async {
    if (!isConnected) throw Exception('Tidak terhubung ke database');
    try {
      final usersCollection = _db!.collection('users');
      
      // Cek duplikasi email
      final existing = await usersCollection.findOne(where.eq('email', email));
      if (existing != null) return false; // Email sudah terdaftar

      await usersCollection.insertOne({
        '_id': id,
        'nama': nama,
        'email': email,
        'passwordHash': hashPassword(password),
        'jenisKelamin': 'pria',
        'usia': 22,
        'beratBadan': 65.0,
        'tinggiBadan': 165.0,
        'levelAktivitas': 2,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });
      debugPrint('User registered in Atlas');
      return true;
    } catch (e) {
      debugPrint('registerUser error: $e');
      throw Exception('Gagal mendaftarkan akun: $e');
    }
  }

  /// Verifikasi email + password. Mengembalikan UserProfile jika valid,
  /// null jika password salah atau user tidak ditemukan.
  Future<UserProfile?> verifyLogin(String email, String password) async {
    if (!isConnected) throw Exception('Tidak terhubung ke database');
    try {
      final usersCollection = _db!.collection('users');
      final result = await usersCollection.findOne(where.eq('email', email));
      
      if (result == null) return null; // User tidak ditemukan

      final storedHash = result['passwordHash'] as String?;
      if (storedHash == null || storedHash.isEmpty) {
        // User lama tanpa password (misal login via Google sebelumnya).
        return null;
      }

      // Bandingkan hash
      if (storedHash != hashPassword(password)) {
        return null; // Password salah
      }

      return UserProfile(
        id: result['_id'] as String,
        nama: result['nama'] as String,
        email: result['email'] as String,
        jenisKelamin: result['jenisKelamin'] as String,
        usia: result['usia'] as int,
        beratBadan: (result['beratBadan'] as num).toDouble(),
        tinggiBadan: (result['tinggiBadan'] as num).toDouble(),
        levelAktivitas: ActivityLevel.values[result['levelAktivitas'] as int],
        createdAt: DateTime.parse(result['createdAt'].toString()),
        updatedAt: DateTime.parse(result['updatedAt'].toString()),
      );
    } catch (e) {
      debugPrint('verifyLogin error: $e');
      throw Exception('Koneksi ke database gagal: $e');
    }
  }

  Future<void> syncScanResult(ScanResultModel scan, String userId) async {
    if (!isConnected) return;
    try {
      final scansCollection = _db!.collection('scan_results');
      
      final foodsList = scan.foods.map((f) => {
        'name': f.name,
        'grams': f.grams,
        'calories': f.calories,
        'fat': f.fat,
        'defaultGrams': f.defaultGrams,
        'defaultFat': f.defaultFat,
        'defaultCalories': f.defaultCalories,
        'confidence': f.confidence,
      }).toList();

      await scansCollection.update(
        where.eq('_id', scan.id),
        {
          '_id': scan.id,
          'userId': userId,
          'tanggal': scan.tanggal,
          'imagePath': scan.imagePath,
          'status': scan.status,
          'foods': foodsList,
        },
        upsert: true,
      );
      debugPrint('ScanResult synced to Atlas');
    } catch (e) {
      debugPrint('Failed to sync ScanResult: $e');
      throw Exception('Gagal sinkronisasi data ke cloud');
    }
  }

  Future<void> deleteScan(String scanId) async {
    if (!isConnected) return;
    try {
      final scansCollection = _db!.collection('scan_results');
      await scansCollection.remove(where.eq('_id', scanId));
      debugPrint('ScanResult deleted from Atlas');
    } catch (e) {
      debugPrint('Failed to delete ScanResult: $e');
    }
  }

  Future<UserProfile?> getUserByEmail(String email) async {
    if (!isConnected) throw Exception('Tidak terhubung ke database');
    try {
      final usersCollection = _db!.collection('users');
      final result = await usersCollection.findOne(where.eq('email', email));
      
      if (result != null) {
        return UserProfile(
          id: result['_id'] as String,
          nama: result['nama'] as String,
          email: result['email'] as String,
          jenisKelamin: result['jenisKelamin'] as String,
          usia: result['usia'] as int,
          beratBadan: (result['beratBadan'] as num).toDouble(),
          tinggiBadan: (result['tinggiBadan'] as num).toDouble(),
          levelAktivitas: ActivityLevel.values[result['levelAktivitas'] as int],
          createdAt: DateTime.parse(result['createdAt'].toString()),
          updatedAt: DateTime.parse(result['updatedAt'].toString()),
        );
      }
    } catch (e) {
      debugPrint('Error getting user by email: $e');
      throw Exception('Koneksi ke database gagal: $e');
    }
    return null;
  }

  Future<List<ScanResultModel>> getHistoryByUserId(String userId) async {
    if (!isConnected) return [];
    try {
      final scansCollection = _db!.collection('scan_results');
      final results = await scansCollection.find(where.eq('userId', userId)).toList();
      
      return results.map((result) {
        final foodsData = result['foods'] as List<dynamic>;
        final foodsList = foodsData.map((f) => FoodItem(
          name: f['name'] as String,
          grams: (f['grams'] as num).toDouble(),
          calories: (f['calories'] as num?)?.toDouble(),
          fat: (f['fat'] as num?)?.toDouble(),
          defaultGrams: (f['defaultGrams'] as num?)?.toDouble() ?? 100.0,
          defaultFat: (f['defaultFat'] as num?)?.toDouble() ?? 0.0,
          defaultCalories: (f['defaultCalories'] as num?)?.toDouble() ?? 0.0,
          confidence: (f['confidence'] as num?)?.toDouble() ?? 1.0,
        )).toList();

        return ScanResultModel(
          id: result['_id'] as String,
          tanggal: DateTime.parse(result['tanggal'].toString()),
          imagePath: result['imagePath'] as String,
          foods: foodsList,
          status: result['status'] as String,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting history: $e');
      return [];
    }
  }

  Future<void> close() async {
    if (isConnected) {
      await _db!.close();
    }
  }
}
