// Manual Hive type adapter for RatingType

part of 'rating_type.dart';

/// Hive type adapter for [RatingType].
class RatingTypeAdapter extends TypeAdapter<RatingType> {
  @override
  final int typeId = 1;

  @override
  RatingType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RatingType.thumbsUp;
      case 1:
        return RatingType.thumbsDown;
      default:
        return RatingType.thumbsUp;
    }
  }

  @override
  void write(BinaryWriter writer, RatingType obj) {
    switch (obj) {
      case RatingType.thumbsUp:
        writer.writeByte(0);
      case RatingType.thumbsDown:
        writer.writeByte(1);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RatingTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
