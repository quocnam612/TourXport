/// Model chứa toàn bộ câu trả lời của 12 câu hỏi khảo sát sở thích du lịch mới.
class SurveyAnswer {
  // ── PHẦN 1: Thông tin chuyến đi ──
  /// Ngày đi
  DateTime? startDate;
  /// Ngày về
  DateTime? endDate;
  /// Mục tiêu chính của chuyến đi: 'Nghỉ dưỡng', 'Du lịch, khám phá', 'Công tác'
  String? mainGoal;
  /// Điểm đến muốn du lịch (tỉnh/thành phố)
  String? selectedDestination;

  // ── PHẦN 2: Ngân sách & chi tiêu ──
  /// Mức ngân sách mong muốn (VNĐ/người)
  double? budgetPerPerson;
  /// Ưu tiên chi tiêu nhiều hơn cho: 'Khách sạn', 'Ăn uống', 'Trải nghiệm', 'Di chuyển'
  String? spendPriority;

  // ── PHẦN 3: Sở thích & trải nghiệm ──
  /// Hoạt động yêu thích (nhiều lựa chọn): 'Ngắm cảnh', 'Chụp ảnh', 'Khám phá văn hóa', 'Ăn uống địa phương', 'Cà phê chill', 'Chợ đêm', 'Thiên nhiên/sông nước'
  List<String> activities;
  /// Loại địa điểm yêu thích: 'Đông vui', 'Yên tĩnh', 'Thiên nhiên', 'Mang tính văn hóa/tâm linh'
  String? placeVibe;

  // ── PHẦN 4: Phương tiện & di chuyển ──
  /// Phương tiện di chuyển: 'Xe máy', 'Ô tô', 'Xe khách', 'Máy bay'
  String? transportMode;
  /// Ưu tiên di chuyển: 'Tuyến đường đẹp', 'Di chuyển nhanh', 'Ít đổi phương tiện'
  String? routePriority;

  // ── PHẦN 5: Lưu trú ──
  /// Loại hình lưu trú: 'Khách sạn', 'Homestay', 'Resort', 'Nhà nghỉ'
  String? accommodationType;
  /// Ưu tiên lưu trú: 'Gần trung tâm', 'View đẹp', 'Giá rẻ', 'Yên tĩnh'
  String? accommodationPriority;

  // ── PHẦN 6: Ăn uống ──
  /// Yêu cầu ăn uống đặc biệt (nhiều lựa chọn): 'Ăn chay', 'Không ăn hải sản', 'Không ăn cay', 'Dị ứng thực phẩm'
  List<String> dietaryRequirements;
  /// Phong cách ăn uống ưa thích: 'Quán local', 'Nhà hàng nổi tiếng', 'Quán view đẹp', 'Quán bình dân'
  String? diningStyle;

  SurveyAnswer({
    this.startDate,
    this.endDate,
    this.mainGoal,
    this.selectedDestination,
    this.budgetPerPerson,
    this.spendPriority,
    List<String>? activities,
    this.placeVibe,
    this.transportMode,
    this.routePriority,
    this.accommodationType,
    this.accommodationPriority,
    List<String>? dietaryRequirements,
    this.diningStyle,
  })  : activities = activities ?? [],
        dietaryRequirements = dietaryRequirements ?? [];

  /// Tính tổng số ngày dựa trên ngày đi và ngày về
  int get totalDays {
    if (startDate == null || endDate == null) return 3;
    final diff = endDate!.difference(startDate!).inDays;
    return diff + 1;
  }

  /// Chuyển đổi dữ liệu sang định dạng JSON
  Map<String, dynamic> toJson() {
    return {
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'main_goal': mainGoal,
      'selected_destination': selectedDestination,
      'budget_per_person': budgetPerPerson,
      'spend_priority': spendPriority,
      'activities': activities,
      'place_vibe': placeVibe,
      'transport_mode': transportMode,
      'route_priority': routePriority,
      'accommodation_type': accommodationType,
      'accommodation_priority': accommodationPriority,
      'dietary_requirements': dietaryRequirements,
      'dining_style': diningStyle,
    };
  }
}
