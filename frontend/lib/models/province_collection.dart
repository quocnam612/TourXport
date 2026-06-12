import 'destination.dart';

/// Represents a group of places within a single district/city inside a province.
class DistrictGroup {
  final String name;
  final List<Destination> places;
  final int visitedCount;

  const DistrictGroup({
    required this.name,
    required this.places,
    this.visitedCount = 0,
  });

  bool get isUnlocked => visitedCount > 0;

  /// The "hero" place used as the representative image for this district.
  Destination? get heroPlace {
    // Prefer a place with a real image and the highest score.
    final withImage = places.where((p) => p.hasImage == true).toList();
    if (withImage.isNotEmpty) {
      withImage.sort((a, b) =>
          (b.totalScore ?? 0).compareTo(a.totalScore ?? 0));
      return withImage.first;
    }
    return places.isNotEmpty ? places.first : null;
  }
}

/// Represents a province collection card.
class ProvinceCollection {
  final String name;
  final String? imageUrl;
  final int totalPlaces;
  final int visitedPlaces;
  final List<DistrictGroup> districts;

  const ProvinceCollection({
    required this.name,
    this.imageUrl,
    this.totalPlaces = 0,
    this.visitedPlaces = 0,
    this.districts = const [],
  });

  bool get isUnlocked => visitedPlaces > 0;

  double get progress =>
      totalPlaces > 0 ? visitedPlaces / totalPlaces : 0.0;

  int get unlockedDistricts =>
      districts.where((d) => d.isUnlocked).length;
}
