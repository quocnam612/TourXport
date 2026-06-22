import 'package:flutter/material.dart';

class AppFeedbackLogo extends StatelessWidget {
  final double size;

  const AppFeedbackLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: _AppFeedbackLogoPainter()),
    );
  }
}

class _AppFeedbackLogoPainter extends CustomPainter {
  const _AppFeedbackLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 38;
    final bubblePaint = Paint()
      ..color = const Color(0xFFD4AF7A)
      ..style = PaintingStyle.fill;
    final cutoutPaint = Paint()
      ..color = const Color(0xFF1B2321)
      ..style = PaintingStyle.fill;

    final bubble = Path()
      ..moveTo(8 * scale, 8 * scale)
      ..quadraticBezierTo(8 * scale, 5 * scale, 11 * scale, 5 * scale)
      ..lineTo(31 * scale, 5 * scale)
      ..quadraticBezierTo(34 * scale, 5 * scale, 34 * scale, 8 * scale)
      ..lineTo(34 * scale, 26 * scale)
      ..quadraticBezierTo(34 * scale, 29 * scale, 31 * scale, 29 * scale)
      ..lineTo(17 * scale, 29 * scale)
      ..lineTo(7 * scale, 35 * scale)
      ..lineTo(10 * scale, 29 * scale)
      ..quadraticBezierTo(7 * scale, 28 * scale, 7 * scale, 25 * scale)
      ..lineTo(7 * scale, 8 * scale)
      ..close();

    canvas.drawPath(bubble, bubblePaint);

    final pencil = Path()
      ..moveTo(14.5 * scale, 22.5 * scale)
      ..lineTo(13 * scale, 18.5 * scale)
      ..lineTo(23.5 * scale, 8 * scale)
      ..lineTo(27 * scale, 11.5 * scale)
      ..lineTo(16.5 * scale, 22 * scale)
      ..close();
    canvas.drawPath(pencil, cutoutPaint);

    final tip = Path()
      ..moveTo(13 * scale, 18.5 * scale)
      ..lineTo(11.5 * scale, 24 * scale)
      ..lineTo(16.5 * scale, 22 * scale)
      ..close();
    canvas.drawPath(tip, cutoutPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF1B2321)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(19 * scale, 22.5 * scale),
      Offset(29 * scale, 22.5 * scale),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AppFeedbackLogoPainter oldDelegate) => false;
}
