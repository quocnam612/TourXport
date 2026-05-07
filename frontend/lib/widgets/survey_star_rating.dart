import 'package:flutter/material.dart';

/// Star rating widget 1–5 với label mô tả.
class SurveyStarRating extends StatelessWidget {
  final String label;
  final int value; // 1–5
  final ValueChanged<int> onChanged;

  const SurveyStarRating({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  static const _descriptions = [
    'Không thích',
    'Ít hứng thú',
    'Bình thường',
    'Khá thích',
    'Rất thích!',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Stars
              ...List.generate(5, (i) {
                final starIndex = i + 1;
                final isActive = starIndex <= value;
                return GestureDetector(
                  onTap: () => onChanged(starIndex),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: AnimatedScale(
                      scale: isActive ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isActive ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 32,
                        color: isActive
                            ? const Color(0xFFD4AF7A)
                            : Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 10),
              // Description text
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    value >= 1 && value <= 5
                        ? _descriptions[value - 1]
                        : '',
                    key: ValueKey<int>(value),
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFFD4AF7A).withOpacity(0.8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
