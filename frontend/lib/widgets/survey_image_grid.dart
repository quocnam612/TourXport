import 'package:flutter/material.dart';

/// Image item cho câu 15 — chọn ảnh cảm hứng.
class SurveyImageItem {
  final String label;
  final String assetPath;

  const SurveyImageItem({required this.label, required this.assetPath});
}

/// Grid hiển thị ảnh để chọn (multi-select).
class SurveyImageGrid extends StatelessWidget {
  final List<SurveyImageItem> items;
  final Set<String> selected; // set of labels
  final ValueChanged<Set<String>> onChanged;

  const SurveyImageGrid({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  void _toggleItem(String label) {
    final next = Set<String>.from(selected);
    if (next.contains(label)) {
      next.remove(label);
    } else {
      next.add(label);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = selected.contains(item.label);

        return GestureDetector(
          onTap: () => _toggleItem(item.label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFD4AF7A)
                    : Colors.white.withOpacity(0.12),
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFD4AF7A).withOpacity(0.25),
                        blurRadius: 16,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  Image.asset(
                    item.assetPath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF2A4A3E),
                      child: const Icon(Icons.image, color: Colors.white24),
                    ),
                  ),
                  // Dark gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(isSelected ? 0.7 : 0.55),
                        ],
                      ),
                    ),
                  ),
                  // Selection overlay
                  if (isSelected)
                    Container(
                      color: const Color(0xFFD4AF7A).withOpacity(0.10),
                    ),
                  // Check icon top-right
                  if (isSelected)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD4AF7A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  // Label at bottom
                  Positioned(
                    left: 6,
                    right: 6,
                    bottom: 8,
                    child: Text(
                      item.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? const Color(0xFFD4AF7A)
                            : Colors.white,
                        shadows: const [
                          Shadow(
                            color: Color(0xAA000000),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
