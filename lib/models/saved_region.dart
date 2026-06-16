import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:randoeats/models/spot_filters.dart';

part 'saved_region.g.dart';

/// A user-defined, named geographic region (a polygon) within which
/// restaurants are discovered.
///
/// The polygon is stored as a flattened list of coordinates
/// `[lat0, lng0, lat1, lng1, ...]` so the Hive adapter stays simple and the
/// model carries no dependency on any maps package. Use [vertices] to read the
/// polygon back as lat/lng pairs, or [SavedRegion.fromVertices] to build one.
@HiveType(typeId: 7)
class SavedRegion extends Equatable {
  /// Creates a [SavedRegion] from an already-flattened [points] list.
  const SavedRegion({
    required this.id,
    required this.name,
    required this.points,
    required this.createdAt,
    this.filters,
  });

  /// Creates a [SavedRegion] from polygon [vertices] (lat/lng pairs).
  factory SavedRegion.fromVertices({
    required String id,
    required String name,
    required List<({double lat, double lng})> vertices,
    required DateTime createdAt,
    SpotFilters? filters,
  }) {
    final flat = <double>[];
    for (final v in vertices) {
      flat
        ..add(v.lat)
        ..add(v.lng);
    }
    return SavedRegion(
      id: id,
      name: name,
      points: flat,
      createdAt: createdAt,
      filters: filters,
    );
  }

  /// Unique identifier (e.g. `millisecondsSinceEpoch` as a string).
  @HiveField(0)
  final String id;

  /// Human-friendly display name, e.g. "Orange Circle".
  @HiveField(1)
  final String name;

  /// Polygon vertices flattened as `[lat0, lng0, lat1, lng1, ...]`.
  @HiveField(2)
  final List<double> points;

  /// When this region was created.
  @HiveField(3)
  final DateTime createdAt;

  /// The filters saved with this Spot (the "what"); null = no filters.
  @HiveField(4)
  final SpotFilters? filters;

  /// The polygon vertices as lat/lng pairs.
  List<({double lat, double lng})> get vertices {
    final result = <({double lat, double lng})>[];
    for (var i = 0; i + 1 < points.length; i += 2) {
      result.add((lat: points[i], lng: points[i + 1]));
    }
    return result;
  }

  /// Returns a copy of this region with the given fields replaced.
  SavedRegion copyWith({
    String? id,
    String? name,
    List<double>? points,
    DateTime? createdAt,
    SpotFilters? filters,
  }) {
    return SavedRegion(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
      filters: filters ?? this.filters,
    );
  }

  @override
  List<Object?> get props => [id, name, points, createdAt, filters];
}
