import 'package:flutter/material.dart';

class PulsingLocationMarker extends StatefulWidget {
  final Color baseColor;

  const PulsingLocationMarker({super.key, required this.baseColor});

  @override
  State<PulsingLocationMarker> createState() => _PulsingLocationMarkerState();
}

class _PulsingLocationMarkerState extends State<PulsingLocationMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.5, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing radar ring
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.baseColor, width: 2),
                    color: widget.baseColor.withOpacity(0.3),
                  ),
                ),
              ),
            );
          },
        ),
        // Solid center dot
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: widget.baseColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.baseColor.withOpacity(0.6),
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ],
    );
  }
}
