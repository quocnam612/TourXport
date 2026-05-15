import 'package:flutter/material.dart';

/// Chip option widget dùng cho cả single-select và multi-select.
///
/// [isSelected] trạng thái hiện tại.
/// [onTap] callback khi tap.
/// [icon] icon tùy chọn hiển thị trước label.
class SurveyChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const SurveyChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFD4AF7A).withOpacity(0.18)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD4AF7A)
                : Colors.white.withOpacity(0.18),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFD4AF7A).withOpacity(0.15),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? const Color(0xFFD4AF7A)
                    : Colors.white.withOpacity(0.7),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? const Color(0xFFD4AF7A) : Colors.white,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.check_rounded,
                size: 16,
                color: Color(0xFFD4AF7A),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Wrap layout cho danh sách chips.
///
/// [options] danh sách label.
/// [selected] set các label đã chọn.
/// [onChanged] callback trả về set mới.
/// [maxSelections] giới hạn multi-select (null = unlimited, 1 = single).
/// [icons] map label → icon (optional).
class SurveyChipGroup extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final int? maxSelections;
  final Map<String, IconData>? icons;

  const SurveyChipGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.maxSelections,
    this.icons,
  });

  bool get _isSingle => maxSelections == 1;

  void _handleTap(String label) {
    final next = Set<String>.from(selected);

    if (_isSingle) {
      // Single select: toggle or switch
      if (next.contains(label)) {
        next.remove(label);
      } else {
        next
          ..clear()
          ..add(label);
      }
    } else {
      if (next.contains(label)) {
        next.remove(label);
      } else {
        if (maxSelections != null && next.length >= maxSelections!) return;
        next.add(label);
      }
    }

    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((label) {
        return SurveyChip(
          label: label,
          isSelected: selected.contains(label),
          onTap: () => _handleTap(label),
          icon: icons?[label],
        );
      }).toList(),
    );
  }
}
