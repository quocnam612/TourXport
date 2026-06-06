import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class MapLocationService {
  static Future<bool> handleLocationPermission({
    required Future<bool> Function() onEnableService,
    required Future<bool> Function() onPermissionDenied,
    required Future<bool> Function() onPermissionPermanentlyDenied,
  }) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (await onEnableService()) {
        await Geolocator.openLocationSettings();
      }
      return false; // Người dùng cần thời gian để bật trong Cài đặt, sau khi quay lại app sẽ check tiếp
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (await onPermissionDenied()) {
        permission = await Geolocator.requestPermission();
      } else {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (await onPermissionPermanentlyDenied()) {
        await Geolocator.openAppSettings();
      }
      return false; // Người dùng cần cấp quyền trong Cài đặt app
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
