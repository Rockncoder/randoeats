// Manual Hive type adapter for Restaurant

part of 'restaurant.dart';

/// Hive type adapter for [Restaurant].
class RestaurantAdapter extends TypeAdapter<Restaurant> {
  @override
  final int typeId = 0;

  @override
  Restaurant read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Restaurant(
      placeId: fields[0] as String,
      name: fields[1] as String,
      address: fields[2] as String,
      latitude: fields[3] as double,
      longitude: fields[4] as double,
      rating: fields[5] as double?,
      priceLevel: fields[6] as String?,
      types: (fields[7] as List?)?.cast<String>() ?? [],
      photoReference: fields[8] as String?,
      isOpen: fields[9] as bool?,
      totalRatings: fields[10] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Restaurant obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.placeId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(3)
      ..write(obj.latitude)
      ..writeByte(4)
      ..write(obj.longitude)
      ..writeByte(5)
      ..write(obj.rating)
      ..writeByte(6)
      ..write(obj.priceLevel)
      ..writeByte(7)
      ..write(obj.types)
      ..writeByte(8)
      ..write(obj.photoReference)
      ..writeByte(9)
      ..write(obj.isOpen)
      ..writeByte(10)
      ..write(obj.totalRatings);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RestaurantAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
