// Manual Hive type adapter for VisitedPlace

part of 'visited_place.dart';

/// Hive type adapter for [VisitedPlace].
class VisitedPlaceAdapter extends TypeAdapter<VisitedPlace> {
  @override
  final int typeId = 5;

  @override
  VisitedPlace read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VisitedPlace(
      placeId: fields[0] as String,
      visitCount: fields[1] as int,
      lastVisitedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, VisitedPlace obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.placeId)
      ..writeByte(1)
      ..write(obj.visitCount)
      ..writeByte(2)
      ..write(obj.lastVisitedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisitedPlaceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
