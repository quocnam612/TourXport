import 'dart:ui';
import 'package:flutter/material.dart';

class LocationExplanationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;

  const LocationExplanationDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = 'Đồng ý',
    this.cancelText = 'Bỏ qua',
  });

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
        title: Row(
          children: [
            const Icon(Icons.location_on_rounded, color: Color(0xFFD4AF7A), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          content,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            color: Colors.white70,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              cancelText,
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
            child: Text(
              confirmText,
              style: const TextStyle(
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
