// Manual Hive type adapter for UserSettings

part of 'user_settings.dart';

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
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.hideDaysAfterPick)
      ..writeByte(1)
      ..write(obj.searchRadiusMeters)
      ..writeByte(2)
      ..write(obj.includeOpenOnly);
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
