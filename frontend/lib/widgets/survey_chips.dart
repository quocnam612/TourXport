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

  String _translateOption(String label) {
    final translations = {
      // Nhịp độ (Pace)
      'Nhanh': 'Fast',
      'Cân bằng': 'Balanced',
      'Thư giãn': 'Relaxed',

      // Phương tiện (Transport)
      'Xe máy': 'Motorbike',
      'Ô tô': 'Car',
      'Xe khách': 'Coach Bus',
      'Máy bay': 'Airplane',
      'Tự động': 'Auto',

      // Ưu tiên chi tiêu
      'Khách sạn': 'Hotel',
      'Ăn uống': 'Dining',
      'Trải nghiệm': 'Experience',
      'Di chuyển': 'Transportation',

      // Phong cách địa điểm
      'Đông vui': 'Lively/Crowded',
      'Yên tĩnh': 'Quiet/Peaceful',
      'Thiên nhiên': 'Nature/Scenic',
      'Mang tính văn hóa/tâm linh': 'Cultural/Spiritual',

      // Hoạt động
      'Ngắm cảnh': 'Sightseeing',
      'Chụp ảnh': 'Photography',
      'Khám phá văn hóa': 'Cultural Discovery',
      'Ăn uống địa phương': 'Local Food Tasting',
      'Cà phê chill': 'Cafe Chill',
      'Chợ đêm': 'Night Market',
      'Thiên nhiên/sông nước': 'Nature/Waterways',

      // Ưu tiên tuyến đường
      'Tuyến đường đẹp': 'Scenic Route',
      'Di chuyển nhanh': 'Fast Route',
      'Ít đổi phương tiện': 'Direct/Fewest Transfers',

      // Loại hình lưu trú
      'Homestay': 'Homestay',
      'Resort': 'Resort',
      'Nhà nghỉ': 'Motel/Inn',

      // Ưu tiên chỗ ở
      'Gần trung tâm': 'Near City Center',
      'View đẹp': 'Beautiful View',
      'Giá rẻ': 'Budget-friendly',

      // Ăn uống đặc biệt
      'Ăn chay': 'Vegetarian',
      'Không ăn hải sản': 'No Seafood',
      'Không ăn cay': 'Not Spicy',
      'Dị ứng thực phẩm': 'Food Allergies',

      // Phong cách quán ăn
      'Quán local': 'Local Eatery',
      'Nhà hàng nổi tiếng': 'Famous Restaurant',
      'Quán view đẹp': 'Scenic Restaurant',
      'Quán bình dân': 'Budget Diner',

      // Các tỉnh thành
      'Tuyên Quang': 'Tuyen Quang',
      'Cao Bằng': 'Cao Bang',
      'Lai Châu': 'Lai Chau',
      'Lào Cai': 'Lao Cai',
      'Thái Nguyên': 'Thai Nguyen',
      'Điện Biên': 'Dien Bien',
      'Lạng Sơn': 'Lang Son',
      'Sơn La': 'Son La',
      'Phú Thọ': 'Phu Tho',
      'TP. Hà Nội': 'Hanoi City',
      'TP. Hải Phòng': 'Haiphong City',
      'Bắc Ninh': 'Bac Ninh',
      'Quảng Ninh': 'Quang Ninh',
      'Hưng Yên': 'Hung Yen',
      'Ninh Bình': 'Ninh Binh',
      'Thanh Hóa': 'Thanh Hoa',
      'Nghệ An': 'Nghe An',
      'Hà Tĩnh': 'Ha Tinh',
      'Quảng Trị': 'Quang Tri',
      'TP. Huế': 'Hue City',
      'TP. Đà Nẵng': 'Danang City',
      'Quảng Ngãi': 'Quang Ngai',
      'Gia Lai': 'Gia Lai',
      'Đắk Lắk': 'Dak Lak',
      'Khánh Hòa': 'Khanh Hoa',
      'Lâm Đồng': 'Lam Dong',
      'Đồng Nai': 'Dong Nai',
      'Tây Ninh': 'Tay Ninh',
      'TP. Hồ Chí Minh': 'Ho Chi Minh City',
      'Đồng Tháp': 'Dong Thap',
      'An Giang': 'An Giang',
      'Vĩnh Long': 'Vinh Long',
      'TP. Cần Thơ': 'Can Tho City',
      'Cà Mau': 'Ca Mau',
    };

    return translations[label] ?? label;
  }

  @override
  Widget build(BuildContext context) {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((label) {
        final displayLabel = isVi ? label : _translateOption(label);
        return SurveyChip(
          label: displayLabel,
          isSelected: selected.contains(label),
          onTap: () => _handleTap(label),
          icon: icons?[label],
        );
      }).toList(),
    );
  }
}
