// Manual Hive type adapter for SpotFilters

part of 'spot_filters.dart';

/// Hive type adapter for [SpotFilters].
class SpotFiltersAdapter extends TypeAdapter<SpotFilters> {
  @override
  final int typeId = 8;

  @override
  SpotFilters read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SpotFilters(
      cuisines: (fields[0] as List?)?.cast<String>().toSet() ?? const {},
      servesBeer: fields[1] as bool? ?? false,
      outdoorSeating: fields[2] as bool? ?? false,
      goodForGroups: fields[3] as bool? ?? false,
      hasParking: fields[4] as bool? ?? false,
      openNow: fields[5] as bool? ?? false,
      minRating: fields[6] as double?,
      priceLevels: (fields[7] as List?)?.cast<int>().toSet() ?? const {},
      servesWine: fields[8] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, SpotFilters obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.cuisines.toList())
      ..writeByte(1)
      ..write(obj.servesBeer)
      ..writeByte(2)
      ..write(obj.outdoorSeating)
      ..writeByte(3)
      ..write(obj.goodForGroups)
      ..writeByte(4)
      ..write(obj.hasParking)
      ..writeByte(5)
      ..write(obj.openNow)
      ..writeByte(6)
      ..write(obj.minRating)
      ..writeByte(7)
      ..write(obj.priceLevels.toList())
      ..writeByte(8)
      ..write(obj.servesWine);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpotFiltersAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
