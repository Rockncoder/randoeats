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
      servesBeer: fields[11] as bool?,
      outdoorSeating: fields[12] as bool?,
      goodForGroups: fields[13] as bool?,
      hasParking: fields[14] as bool?,
      phoneNumber: fields[15] as String?,
      weekdayHours: (fields[16] as List?)?.cast<String>(),
      photoReferences: (fields[17] as List?)?.cast<String>() ?? const [],
    );
  }

  @override
  void write(BinaryWriter writer, Restaurant obj) {
    writer
      ..writeByte(18)
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
      ..write(obj.totalRatings)
      ..writeByte(11)
      ..write(obj.servesBeer)
      ..writeByte(12)
      ..write(obj.outdoorSeating)
      ..writeByte(13)
      ..write(obj.goodForGroups)
      ..writeByte(14)
      ..write(obj.hasParking)
      ..writeByte(15)
      ..write(obj.phoneNumber)
      ..writeByte(16)
      ..write(obj.weekdayHours)
      ..writeByte(17)
      ..write(obj.photoReferences);
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
