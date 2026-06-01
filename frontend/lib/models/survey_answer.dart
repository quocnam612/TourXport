/// Model chứa toàn bộ câu trả lời của 12 câu hỏi khảo sát sở thích du lịch mới.
class SurveyAnswer {
  static const int maxTripDays = 7;
  static const int maxTripNights = 7;
  static const int maxTravelers = 5;
  static const int minBudgetPerTravelerDay = 200000;
  static const int maxBudgetPerTravelerDay = 200000000;

  // ── PHẦN 1: Thông tin chuyến đi ──
  /// Ngày đi
  DateTime? startDate;
  /// Ngày về
  DateTime? endDate;
  /// (Mới) Danh sách tỉnh/thành muốn đến (có thể chọn nhiều)
  List<String> selectedDestinations;
  /// Số ngày dự định đi
  int? days;
  /// Số đêm dự định
  int? nights;
  /// Số người lớn
  int adults;
  /// Số trẻ em
  int children;
  /// Nhịp độ chuyến đi: 'fast', 'balanced', 'relaxed'
  String? pace;

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
    List<String>? selectedDestinations,
    this.days,
    this.nights,
    this.adults = 1,
    this.children = 0,
    this.pace,
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
  })  : selectedDestinations = selectedDestinations ?? [],
        activities = activities ?? [],
        dietaryRequirements = dietaryRequirements ?? [];

  /// Tính tổng số ngày dựa trên ngày đi và ngày về
  int get totalDays {
    if (days != null) return days!.clamp(1, maxTripDays).toInt();
    if (startDate == null || endDate == null) return 3;
    final diff = endDate!.difference(startDate!).inDays;
    return (diff + 1).clamp(1, maxTripDays).toInt();
  }

  /// Chuyển đổi dữ liệu sang định dạng JSON
  Map<String, dynamic> toJson() {
    final safeDays = days?.clamp(1, maxTripDays).toInt();
    final safeAdults = adults.clamp(1, maxTravelers).toInt();
    final safeChildren = children.clamp(0, maxTravelers - safeAdults).toInt();
    final budgetMin = safeAdults + safeChildren > 0
        ? (safeAdults + safeChildren) * (safeDays ?? totalDays) * minBudgetPerTravelerDay
        : minBudgetPerTravelerDay;
    final budgetMax = safeAdults + safeChildren > 0
        ? (safeAdults + safeChildren) * (safeDays ?? totalDays) * maxBudgetPerTravelerDay
        : maxBudgetPerTravelerDay;

    return {
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'selected_destinations': selectedDestinations,
      'days': safeDays,
      'nights': nights?.clamp(0, maxTripNights).toInt(),
      'adults': safeAdults,
      'children': safeChildren,
      'pace': pace,
      'budget_per_person': budgetPerPerson?.clamp(budgetMin, budgetMax).toDouble(),
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
