import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class MapLocationService {
  static Future<bool> handleLocationPermission(Future<bool> Function() showExplanationDialog) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (await showExplanationDialog()) {
        await Geolocator.openLocationSettings();
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
      }
    }

    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (await showExplanationDialog()) {
        permission = await Geolocator.requestPermission();
      }
    }

    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  static Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint("Không lấy được vị trí GPS: $e");
      return null;
    }
  }

  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }
}
