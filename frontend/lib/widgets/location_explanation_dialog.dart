import 'dart:ui';
import 'package:flutter/material.dart';

class LocationExplanationDialog extends StatelessWidget {
  const LocationExplanationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: AlertDialog(
        backgroundColor: const Color(0xFF0F1E1B).withValues(alpha: 0.9), // Xanh đen đồng bộ app
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.12), // Viền kính mờ
            width: 1.5,
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.location_on_rounded, color: Color(0xFFD4AF7A), size: 28),
            SizedBox(width: 12),
            Text(
              'Dịch vụ vị trí',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: const Text(
          'TourXport cần quyền vị trí của bạn để định vị và tính toán tuyến đường đi tối ưu nhất đến điểm du lịch.',
          style: TextStyle(
            fontFamily: 'Montserrat',
            color: Colors.white70,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Bỏ qua',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF7A), // Màu vàng gold sang trọng
              foregroundColor: const Color(0xFF0F1E1B), // Chữ tối màu tương phản tốt
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
            ),
            child: const Text(
              'Đồng ý',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
