import 'package:flutter/material.dart';

/// Slider với hai label ở hai đầu (ví dụ: "Nghỉ dưỡng" ↔ "Khám phá").
class SurveyDualSlider extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final IconData? leftIcon;
  final IconData? rightIcon;
  final double value;
  final ValueChanged<double> onChanged;

  const SurveyDualSlider({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    this.leftIcon,
    this.rightIcon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leftIcon != null) ...[
                    Icon(
                      leftIcon,
                      size: 16,
                      color: Color.lerp(
                        const Color(0xFFD4AF7A),
                        Colors.white.withOpacity(0.5),
                        value,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    leftLabel,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      fontWeight:
                          value < 0.4 ? FontWeight.w600 : FontWeight.w400,
                      color: Color.lerp(
                        const Color(0xFFD4AF7A),
                        Colors.white.withOpacity(0.5),
                        value,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    rightLabel,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      fontWeight:
                          value > 0.6 ? FontWeight.w600 : FontWeight.w400,
                      color: Color.lerp(
                        Colors.white.withOpacity(0.5),
                        const Color(0xFFD4AF7A),
                        value,
                      ),
                    ),
                  ),
                  if (rightIcon != null) ...[
                    const SizedBox(width: 6),
                    Icon(
                      rightIcon,
                      size: 16,
                      color: Color.lerp(
                        Colors.white.withOpacity(0.5),
                        const Color(0xFFD4AF7A),
                        value,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Slider
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              activeTrackColor: const Color(0xFFD4AF7A),
              inactiveTrackColor: Colors.white.withOpacity(0.12),
              thumbColor: const Color(0xFFD4AF7A),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayColor: const Color(0xFFD4AF7A).withOpacity(0.15),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
