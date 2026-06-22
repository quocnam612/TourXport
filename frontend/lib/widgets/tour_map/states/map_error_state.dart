import 'package:flutter/material.dart';

class MapErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const MapErrorState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.grey, size: 48),
          const SizedBox(height: 16),
          Text(
            "Không thể tải lộ trình, vui lòng kiểm tra kết nối mạng.",
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Montserrat', color: Colors.white.withOpacity(0.7), fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text("Thử lại", style: TextStyle(fontFamily: 'Montserrat')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF7A),
              foregroundColor: const Color(0xFF0F1E1B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
