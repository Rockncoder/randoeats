// Manual Hive type adapter for UserSettings and DistanceUnit

part of 'user_settings.dart';

/// Hive type adapter for [DistanceUnit].
class DistanceUnitAdapter extends TypeAdapter<DistanceUnit> {
  @override
  final int typeId = 6;

  @override
  DistanceUnit read(BinaryReader reader) {
    final index = reader.readByte();
    return DistanceUnit.values[index];
  }

  @override
  void write(BinaryWriter writer, DistanceUnit obj) {
    writer.writeByte(obj.index);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DistanceUnitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// Hive type adapter for [UserSettings].
class UserSettingsAdapter extends TypeAdapter<UserSettings> {
  @override
  final int typeId = 4;

  @override
  UserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettings(
      hideDaysAfterPick: fields[0] as int? ?? UserSettings.defaultHideDays,
      searchRadiusMeters: fields[1] as int? ?? UserSettings.defaultSearchRadius,
      includeOpenOnly: fields[2] as bool? ?? true,
      maxResults: fields[3] as int? ?? UserSettings.defaultMaxResults,
      distanceUnit: fields[4] as DistanceUnit? ?? DistanceUnit.miles,
      bannedCategories:
          (fields[5] as List<dynamic>?)?.cast<String>().toSet() ??
          const <String>{},
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.hideDaysAfterPick)
      ..writeByte(1)
      ..write(obj.searchRadiusMeters)
      ..writeByte(2)
      ..write(obj.includeOpenOnly)
      ..writeByte(3)
      ..write(obj.maxResults)
      ..writeByte(4)
      ..write(obj.distanceUnit)
      ..writeByte(5)
      ..write(obj.bannedCategories.toList());
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
