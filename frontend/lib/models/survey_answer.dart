/// Model chứa toàn bộ câu trả lời khảo sát sở thích du lịch.
class SurveyAnswer {
  // ── PHẦN 1: Mục tiêu chuyến đi ──

  /// Câu 1 – "Bạn muốn chuyến đi này mang lại cảm giác gì nhất?" (multi, max 3)
  List<String> travelFeelings;

  /// Câu 2 – "Bạn đi du lịch theo hình thức nào?" (single)
  String? groupType;

  /// Câu 3 – Sliders 0.0→1.0
  double sliderRelaxExplore;   // 0 = Nghỉ dưỡng, 1 = Khám phá
  double sliderQuietLively;    // 0 = Yên tĩnh,   1 = Sôi động
  double sliderPlannedFree;    // 0 = Kế hoạch,   1 = Tự do
  double sliderNatureCity;     // 0 = Thiên nhiên, 1 = Thành phố

  // ── PHẦN 2: Ngân sách & thời gian ──

  /// Câu 4 – Ngân sách (single)
  String? budget;

  /// Câu 5 – Thời gian đi (single)
  String? duration;

  /// Câu 6 – Thời điểm (single)
  String? timing;

  // ── PHẦN 3: Sở thích cá nhân ──

  /// Câu 7 – Hoạt động yêu thích (multi)
  List<String> activities;

  /// Câu 8 – Ưu tiên nơi ở (single)
  String? accommodationPriority;

  /// Câu 9 – Kiểu địa điểm (multi)
  List<String> placeTypes;

  // ── PHẦN 4: Mức độ trải nghiệm ──

  /// Câu 10 – Lịch trình (single)
  String? scheduleStyle;

  /// Câu 11 – Sẵn sàng di chuyển xa (single)
  String? travelDistance;

  /// Câu 12 – Thích thử điều mới (star 1–5)
  int adventureFood;     // Ăn món lạ
  int adventureExtreme;  // Trải nghiệm mạo hiểm
  int adventureHidden;   // Nơi ít người biết

  // ── PHẦN 5: Ràng buộc & ưu tiên ──

  /// Câu 13 – Muốn tránh (multi)
  List<String> avoidList;

  /// Câu 14 – Yêu cầu đặc biệt (multi)
  List<String> specialNeeds;

  // ── PHẦN 6: Cá nhân hóa ──

  /// Câu 15 – Ảnh cảm hứng (multi)
  List<String> inspirationImages;

  /// Câu 16 – Vibe / lifestyle (single)
  String? vibeStyle;

  SurveyAnswer({
    List<String>? travelFeelings,
    this.groupType,
    this.sliderRelaxExplore = 0.5,
    this.sliderQuietLively = 0.5,
    this.sliderPlannedFree = 0.5,
    this.sliderNatureCity = 0.5,
    this.budget,
    this.duration,
    this.timing,
    List<String>? activities,
    this.accommodationPriority,
    List<String>? placeTypes,
    this.scheduleStyle,
    this.travelDistance,
    this.adventureFood = 3,
    this.adventureExtreme = 3,
    this.adventureHidden = 3,
    List<String>? avoidList,
    List<String>? specialNeeds,
    List<String>? inspirationImages,
    this.vibeStyle,
  })  : travelFeelings = travelFeelings ?? [],
        activities = activities ?? [],
        placeTypes = placeTypes ?? [],
        avoidList = avoidList ?? [],
        specialNeeds = specialNeeds ?? [],
        inspirationImages = inspirationImages ?? [];

  /// Serialize cho backend / local storage.
  Map<String, dynamic> toJson() {
    return {
      'travel_feelings': travelFeelings,
      'group_type': groupType,
      'slider_relax_explore': sliderRelaxExplore,
      'slider_quiet_lively': sliderQuietLively,
      'slider_planned_free': sliderPlannedFree,
      'slider_nature_city': sliderNatureCity,
      'budget': budget,
      'duration': duration,
      'timing': timing,
      'activities': activities,
      'accommodation_priority': accommodationPriority,
      'place_types': placeTypes,
      'schedule_style': scheduleStyle,
      'travel_distance': travelDistance,
      'adventure_food': adventureFood,
      'adventure_extreme': adventureExtreme,
      'adventure_hidden': adventureHidden,
      'avoid_list': avoidList,
      'special_needs': specialNeeds,
      'inspiration_images': inspirationImages,
      'vibe_style': vibeStyle,
    };
  }
}
