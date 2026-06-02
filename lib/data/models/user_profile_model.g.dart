// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 3;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      id: fields[0] as String,
      nama: fields[1] as String,
      email: fields[2] as String,
      jenisKelamin: fields[3] as String,
      usia: fields[4] as int,
      beratBadan: fields[5] as double,
      tinggiBadan: fields[6] as double,
      levelAktivitas: fields[7] as ActivityLevel,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nama)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.jenisKelamin)
      ..writeByte(4)
      ..write(obj.usia)
      ..writeByte(5)
      ..write(obj.beratBadan)
      ..writeByte(6)
      ..write(obj.tinggiBadan)
      ..writeByte(7)
      ..write(obj.levelAktivitas)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ActivityLevelAdapter extends TypeAdapter<ActivityLevel> {
  @override
  final int typeId = 2;

  @override
  ActivityLevel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ActivityLevel.sangatRingan;
      case 1:
        return ActivityLevel.ringan;
      case 2:
        return ActivityLevel.sedang;
      case 3:
        return ActivityLevel.aktif;
      case 4:
        return ActivityLevel.sangatAktif;
      default:
        return ActivityLevel.sangatRingan;
    }
  }

  @override
  void write(BinaryWriter writer, ActivityLevel obj) {
    switch (obj) {
      case ActivityLevel.sangatRingan:
        writer.writeByte(0);
        break;
      case ActivityLevel.ringan:
        writer.writeByte(1);
        break;
      case ActivityLevel.sedang:
        writer.writeByte(2);
        break;
      case ActivityLevel.aktif:
        writer.writeByte(3);
        break;
      case ActivityLevel.sangatAktif:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
