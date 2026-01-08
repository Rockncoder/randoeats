// Manual Hive type adapter for RecentPick

part of 'recent_pick.dart';

/// Hive type adapter for [RecentPick].
class RecentPickAdapter extends TypeAdapter<RecentPick> {
  @override
  final int typeId = 3;

  @override
  RecentPick read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecentPick(
      placeId: fields[0] as String,
      pickedAt: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, RecentPick obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.placeId)
      ..writeByte(1)
      ..write(obj.pickedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecentPickAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
