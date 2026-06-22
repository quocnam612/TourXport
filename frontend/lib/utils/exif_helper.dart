import 'package:exif/exif.dart';

class ExifHelper {
  /// Extracts GPS coordinates (Latitude, Longitude) from image bytes.
  /// Returns a Map with 'latitude' and 'longitude' as double, or null if not found or error.
  static Future<Map<String, double>?> getLatLngFromImageBytes(List<int> bytes) async {
    try {
      final tags = await readExifFromBytes(bytes);
      if (tags.isEmpty) return null;

      final latTag = tags['GPS GPSLatitude'];
      final latRefTag = tags['GPS GPSLatitudeRef'];
      final lngTag = tags['GPS GPSLongitude'];
      final lngRefTag = tags['GPS GPSLongitudeRef'];

      if (latTag == null || latRefTag == null || lngTag == null || lngRefTag == null) {
        return null;
      }

      final latRef = latRefTag.printable.trim();
      final lngRef = lngRefTag.printable.trim();

      final latitude = _parseDmsToDecimal(latTag.values, latRef);
      final longitude = _parseDmsToDecimal(lngTag.values, lngRef);

      if (latitude == null || longitude == null) {
        return null;
      }

      return {
        'latitude': latitude,
        'longitude': longitude,
      };
    } catch (_) {
      return null;
    }
  }

  static double _ratioToDouble(dynamic value) {
    if (value is num) return value.toDouble();
    
    // In the exif package, values can be Ratio objects or strings representing them.
    // We convert it to a string and split by '/' to parse the numerator and denominator.
    final str = value.toString().trim();
    final parts = str.split('/');
    if (parts.length == 2) {
      final numVal = double.tryParse(parts[0].trim());
      final denVal = double.tryParse(parts[1].trim());
      if (numVal != null && denVal != null && denVal != 0) {
        return numVal / denVal;
      }
    }
    return double.tryParse(str) ?? 0.0;
  }

  static double? _parseDmsToDecimal(dynamic tagsList, String ref) {
    if (tagsList == null || tagsList is! List || tagsList.isEmpty) return null;
    try {
      double degrees = _ratioToDouble(tagsList[0]);
      double minutes = tagsList.length > 1 ? _ratioToDouble(tagsList[1]) : 0.0;
      double seconds = tagsList.length > 2 ? _ratioToDouble(tagsList[2]) : 0.0;

      double decimal = degrees + (minutes / 60.0) + (seconds / 3600.0);
      if (ref.toUpperCase() == 'S' || ref.toUpperCase() == 'W') {
        decimal = -decimal;
      }
      return decimal;
    } catch (_) {
      return null;
    }
  }
}
