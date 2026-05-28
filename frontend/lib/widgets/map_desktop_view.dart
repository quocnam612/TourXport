import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/destination.dart';

class MapDesktopView extends StatelessWidget {
  final Destination destination;
  final LatLng destLocation;
  final LatLng? userLocation;
  final LatLng fallbackStart;
  final List<LatLng> routePoints;
  final String startTitle;
  final String startSubtitle;
  final int activeMobileTab;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onFitMapBounds;
  final Function(LatLng, double) onMoveCamera;
  final Widget mapWidget;

  const MapDesktopView({
    super.key,
    required this.destination,
    required this.destLocation,
    required this.userLocation,
    required this.fallbackStart,
    required this.routePoints,
    required this.startTitle,
    required this.startSubtitle,
    required this.activeMobileTab,
    required this.onTabChanged,
    required this.onFitMapBounds,
    required this.onMoveCamera,
    required this.mapWidget,
  });

  Widget _buildDesktopLocationCard({
    required String header,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            header,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD4AF7A),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white60, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    color: Colors.white60,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool enabled,
    bool isActive = false,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Material(
        color: isActive 
            ? const Color(0xFFB5956A)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          hoverColor: isActive 
              ? const Color(0xFFB5956A).withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon, 
                  color: isActive ? Colors.white : const Color(0xFFD4AF7A), 
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Bảng điều khiển lộ trình bên trái (Width: 360)
        Container(
          width: 360,
          color: const Color(0xFF0F1E1B),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nút quay lại & Tiêu đề màn hình
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Bản đồ đường đi',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Summary Card hiển thị thông tin vị trí (Điểm đi / Điểm đến)
              if (activeMobileTab == 2) ...[
                _buildDesktopLocationCard(
                  header: 'ĐIỂM ĐI',
                  title: startTitle,
                  subtitle: startSubtitle,
                ),
                const SizedBox(height: 12),
                _buildDesktopLocationCard(
                  header: 'ĐIỂM ĐẾN',
                  title: destination.name,
                  subtitle: destination.province,
                ),
              ] else if (activeMobileTab == 1) ...[
                _buildDesktopLocationCard(
                  header: 'ĐIỂM ĐI',
                  title: startTitle,
                  subtitle: startSubtitle,
                ),
              ] else ...[
                _buildDesktopLocationCard(
                  header: 'ĐIỂM ĐẾN',
                  title: destination.name,
                  subtitle: destination.province,
                ),
              ],
              const SizedBox(height: 24),

              // Danh mục điều khiển bản đồ
              const Text(
                'ĐIỀU KHIỂN BẢN ĐỒ',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white54,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),

              // Các nút thao tác nhanh trên bản đồ
              _buildDesktopActionButton(
                icon: Icons.zoom_out_map_rounded,
                label: 'Xem toàn bộ đường đi',
                onTap: () {
                  onTabChanged(2);
                  onFitMapBounds();
                },
                enabled: routePoints.isNotEmpty,
                isActive: activeMobileTab == 2,
              ),
              const SizedBox(height: 10),
              _buildDesktopActionButton(
                icon: Icons.location_searching_rounded,
                label: 'Đến vị trí điểm đến',
                onTap: () {
                  onTabChanged(0);
                  onMoveCamera(destLocation, 14.5);
                },
                enabled: true,
                isActive: activeMobileTab == 0,
              ),
              const SizedBox(height: 10),
              _buildDesktopActionButton(
                icon: Icons.my_location_rounded,
                label: 'Đến vị trí của tôi',
                onTap: () {
                  onTabChanged(1);
                  final startLoc = userLocation ?? fallbackStart;
                  onMoveCamera(startLoc, 14.5);
                },
                enabled: true,
                isActive: activeMobileTab == 1,
              ),
              const Spacer(),

              // Thông báo trạng thái tuyến đường từ OSRM
              if (routePoints.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2D6A4F).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF2D6A4F), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tuyến đường tối ưu đã được tính toán từ OSRM.',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Phần bản đồ bên phải màn hình desktop
        Expanded(
          child: mapWidget,
        ),
      ],
    );
  }
}
