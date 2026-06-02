import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/destination.dart';
import '../utils/navigation_helper.dart';
import 'map_location_card.dart';

class MapMobileView extends StatelessWidget {
  final Destination destination;
  final LatLng destLocation;
  final LatLng? userLocation;
  final LatLng fallbackStart;
  final int activeMobileTab;
  final bool showLocationCard;
  final String? manualStartLocationName;
  final String? gpsAddress;
  final MapController mapController;
  final Widget mapWidget;
  final Function(LatLng, double) onMoveCamera;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<bool> onCardToggle;

  const MapMobileView({
    super.key,
    required this.destination,
    required this.destLocation,
    required this.userLocation,
    required this.fallbackStart,
    required this.activeMobileTab,
    required this.showLocationCard,
    required this.manualStartLocationName,
    required this.gpsAddress,
    required this.mapController,
    required this.mapWidget,
    required this.onMoveCamera,
    required this.onTabChanged,
    required this.onCardToggle,
  });

  @override
  Widget build(BuildContext context) {
    String titleText = '';
    String subtitleText = '';
    String startPointText = '';
    String destPointText = destination.name;

    final String? fullAddress = manualStartLocationName ?? gpsAddress;
    if (fullAddress != null) {
      final split = NavigationHelper.splitAddress(fullAddress);
      startPointText = split['title']!;
    } else {
      startPointText = userLocation != null ? 'Vị trí của tôi' : 'Hà Nội (Mặc định)';
    }

    if (activeMobileTab == 0) {
      titleText = destination.name;
      subtitleText = 'Tỉnh/Thành: ${destination.province}';
    } else {
      if (fullAddress != null) {
        final split = NavigationHelper.splitAddress(fullAddress);
        titleText = split['title']!;
        subtitleText = split['subtitle']!;
      } else {
        titleText = userLocation != null ? 'Vị trí của tôi' : 'Hà Nội (Mặc định)';
        subtitleText = userLocation != null ? 'Đang xác định địa chỉ...' : '';
      }
    }

    return Stack(
      children: [
        mapWidget,
        // Thẻ thông tin địa điểm nổi ở dưới cùng màn hình điện thoại
        Positioned(
          bottom: 24,
          left: 20,
          right: 20,
          child: MapLocationCard(
            showLocationCard: showLocationCard,
            titleText: titleText,
            subtitleText: subtitleText,
            startPointText: startPointText,
            destPointText: destPointText,
            activeMobileTab: activeMobileTab,
            destLocation: destLocation,
            userLocation: userLocation,
            fallbackStart: fallbackStart,
            mapController: mapController,
            onMoveCamera: onMoveCamera,
            onTabChanged: onTabChanged,
            onCardToggle: onCardToggle,
          ),
        ),
      ],
    );
  }
}
