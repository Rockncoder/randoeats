// Manual Hive type adapter for SavedRegion

part of 'saved_region.dart';

/// Hive type adapter for [SavedRegion].
class SavedRegionAdapter extends TypeAdapter<SavedRegion> {
  @override
  final int typeId = 7;

  @override
  SavedRegion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedRegion(
      id: fields[0] as String,
      name: fields[1] as String,
      points: (fields[2] as List).cast<double>(),
      createdAt: fields[3] as DateTime,
      filters: fields[4] as SpotFilters?,
    );
  }

  @override
  void write(BinaryWriter writer, SavedRegion obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.points)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.filters);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedRegionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
