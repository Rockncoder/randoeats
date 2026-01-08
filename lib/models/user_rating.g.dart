// Manual Hive type adapter for UserRating

part of 'user_rating.dart';

/// Hive type adapter for [UserRating].
class UserRatingAdapter extends TypeAdapter<UserRating> {
  @override
  final int typeId = 2;

  @override
  UserRating read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserRating(
      placeId: fields[0] as String,
      rating: fields[1] as RatingType,
      ratedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UserRating obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.placeId)
      ..writeByte(1)
      ..write(obj.rating)
      ..writeByte(2)
      ..write(obj.ratedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserRatingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
