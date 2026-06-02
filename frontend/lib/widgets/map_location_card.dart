import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapLocationCard extends StatelessWidget {
  final bool showLocationCard;
  final String titleText;
  final String subtitleText;
  final String startPointText;
  final String destPointText;
  final int activeMobileTab;
  final LatLng destLocation;
  final LatLng? userLocation;
  final LatLng fallbackStart;
  final MapController mapController;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<bool> onCardToggle;
  final Function(LatLng, double)? onMoveCamera; // Thêm callback điều khiển camera mượt mà

  const MapLocationCard({
    super.key,
    required this.showLocationCard,
    required this.titleText,
    required this.subtitleText,
    required this.startPointText,
    required this.destPointText,
    required this.activeMobileTab,
    required this.destLocation,
    required this.userLocation,
    required this.fallbackStart,
    required this.mapController,
    required this.onTabChanged,
    required this.onCardToggle,
    this.onMoveCamera,
  });

  Widget _buildMobileTabButton({
    required bool isActive,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? const Color(0xFFB5956A) : Colors.white.withValues(alpha: 0.08),
        foregroundColor: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
        elevation: 0,
        minimumSize: const Size(125, 42), // Đặt kích thước tối thiểu để hai nút to bằng nhau
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (showLocationCard) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Thanh kéo và nút đóng ở trên cùng
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => onCardToggle(false),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white.withValues(alpha: 0.4),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Nội dung chính
                    Row(
                      children: [
                        // Cột chữ bên trái
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                titleText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitleText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildMobileTabButton(
                              isActive: activeMobileTab == 0,
                              icon: Icons.location_searching_rounded,
                              label: 'Điểm đến',
                              onTap: () {
                                onTabChanged(0);
                                if (onMoveCamera != null) {
                                  onMoveCamera!(destLocation, 14.5);
                                } else {
                                  mapController.move(destLocation, 14.5);
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            _buildMobileTabButton(
                              isActive: activeMobileTab == 1,
                              icon: Icons.my_location_rounded,
                              label: 'Điểm đi',
                              onTap: () {
                                onTabChanged(1);
                                final startLoc = userLocation ?? fallbackStart;
                                if (onMoveCamera != null) {
                                  onMoveCamera!(startLoc, 14.5);
                                } else {
                                  mapController.move(startLoc, 14.5);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Pill thu gọn — nhấn để mở lại
      return GestureDetector(
        onTap: () => onCardToggle(true),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.70),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.13),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Cột icon bên trái giống Google Maps
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.my_location_rounded, color: Colors.lightBlueAccent, size: 14),
                      Container(
                        height: 10,
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 16),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Cột chữ hiển thị điểm đi và điểm đến
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          startPointText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFD4AF7A),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Container(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        Text(
                          destPointText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: Colors.white.withValues(alpha: 0.45),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}
