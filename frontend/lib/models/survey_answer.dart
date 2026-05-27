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

  // ── AI Helpers ──

  /// Chuyển đổi chuỗi ngân sách sang số (VND)
  double parseAiBudget() {
    if (budget == null) return 5000000.0;
    switch (budget) {
      case 'Dưới 2 triệu': return 2000000.0;
      case 'Tối đa 3 triệu': return 3000000.0;
      case 'Tối đa 5 triệu': return 5000000.0;
      case 'Tối đa 10 triệu': return 10000000.0;
      case 'Tối đa 20 triệu': return 20000000.0;
      case 'Không giới hạn': return 40000000.0;
      default:
        final clean = budget!.replaceAll(RegExp(r'[^0-9]'), '');
        final number = double.tryParse(clean);
        if (number != null) {
          if (budget!.contains('triệu')) return number * 1000000.0;
          return number;
        }
        return 5000000.0;
    }
  }

  /// Chuyển đổi chuỗi thời gian sang số ngày
  int parseAiDurationDays() {
    if (duration == null) return 3;
    final clean = duration!.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 3;
  }

  /// Tổng hợp tất cả câu trả lời thành 1 chuỗi mô tả sở thích cho AI
  String toAiPreferencesString() {
    final buffer = StringBuffer();
    
    if (travelFeelings.isNotEmpty) {
      buffer.write("Cảm giác & phong cách chuyến đi: ${travelFeelings.join(', ')}. ");
    }
    if (groupType != null) {
      buffer.write("Đi du lịch theo hình thức: $groupType. ");
    }
    
    // Câu 3: Map thanh trượt thành từ khóa rõ ràng
    final relaxExploreText = sliderRelaxExplore <= 0.3 
        ? "thiên về nghỉ dưỡng" 
        : (sliderRelaxExplore >= 0.7 ? "thích khám phá, di chuyển nhiều" : "muốn cân bằng giữa nghỉ dưỡng và khám phá");
    
    final quietLivelyText = sliderQuietLively <= 0.3 
        ? "ưu tiên không gian yên tĩnh, thanh bình" 
        : (sliderQuietLively >= 0.7 ? "thích không khí sôi động, nhộn nhịp" : "thích sự yên tĩnh đan xen các hoạt động nhộn nhịp");

    final plannedFreeText = sliderPlannedFree <= 0.3 
        ? "cần lên kế hoạch rõ ràng, chi tiết" 
        : (sliderPlannedFree >= 0.7 ? "thích tự do trải nghiệm, ngẫu hứng" : "lên kế hoạch linh hoạt, có thể thay đổi");

    final natureCityText = sliderNatureCity <= 0.3 
        ? "yêu thích thiên nhiên hoang sơ, trong lành" 
        : (sliderNatureCity >= 0.7 ? "thích trải nghiệm đô thị, thành phố hiện đại" : "thích kết hợp cả thiên nhiên và phố thị");

    buffer.write("Đặc điểm mong muốn: $relaxExploreText, $quietLivelyText, $plannedFreeText, $natureCityText. ");

    if (activities.isNotEmpty) {
      buffer.write("Hoạt động yêu thích: ${activities.join(', ')}. ");
    }
    if (placeTypes.isNotEmpty) {
      buffer.write("Kiểu địa điểm mong muốn: ${placeTypes.join(', ')}. ");
    }
    if (vibeStyle != null) {
      buffer.write("Vibe phong cách: $vibeStyle. ");
    }

    // Câu 12: Thích thử điều mới (Star ratings 1-5)
    final foodPref = adventureFood >= 4 
        ? "rất thích trải nghiệm ẩm thực độc lạ, thử món ăn mới" 
        : (adventureFood <= 2 ? "ưu tiên món ăn quen thuộc, dễ ăn" : "sẵn sàng thử món ăn địa phương ở mức vừa phải");
    
    final extremePref = adventureExtreme >= 4 
        ? "thích trải nghiệm các hoạt động mạo hiểm phiêu lưu mạnh" 
        : (adventureExtreme <= 2 ? "chỉ muốn hoạt động an toàn, nhẹ nhàng" : "có thể tham gia hoạt động mạo hiểm nhẹ nhàng");

    final hiddenPref = adventureHidden >= 4 
        ? "thích khám phá những địa điểm ẩn giấu, hoang sơ ít người biết" 
        : (adventureHidden <= 2 ? "ưu tiên các địa điểm du lịch nổi tiếng, phổ biến" : "thích cả địa điểm nổi tiếng lẫn nơi hoang sơ");

    buffer.write("Mức độ trải nghiệm: $foodPref, $extremePref, $hiddenPref. ");

    if (avoidList.isNotEmpty) {
      buffer.write("Muốn tránh: ${avoidList.join(', ')}. ");
    }
    if (specialNeeds.isNotEmpty) {
      buffer.write("Yêu cầu đặc biệt: ${specialNeeds.join(', ')}. ");
    }
    
    // Câu 15: Gửi nhãn ảnh người dùng đã chọn
    if (inspirationImages.isNotEmpty) {
      buffer.write("Bức ảnh truyền cảm hứng muốn ghé thăm: ${inspirationImages.join(', ')}. ");
    }

    return buffer.toString().trim();
  }
}

