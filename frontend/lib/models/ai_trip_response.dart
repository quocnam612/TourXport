class AiTripResponse {
  final String status;
  final AiTripData data;

  AiTripResponse({required this.status, required this.data});

  factory AiTripResponse.fromJson(Map<String, dynamic> json) {
    return AiTripResponse(
      status: json['status'] ?? 'success',
      data: AiTripData.fromJson(json['data']),
    );
  }
}

class AiTripData {
  final bool isFromDb;
  final double totalEstimatedCost;
  final List<AiDailyItinerary> itinerary;

  AiTripData({
    required this.isFromDb,
    required this.totalEstimatedCost,
    required this.itinerary,
  });

  factory AiTripData.fromJson(Map<String, dynamic> json) {
    return AiTripData(
      isFromDb: json['isFromDb'] ?? false,
      totalEstimatedCost: (json['totalEstimatedCost'] as num).toDouble(),
      itinerary: (json['itinerary'] as List)
          .map((item) => AiDailyItinerary.fromJson(item))
          .toList(),
    );
  }
}

class AiDailyItinerary {
  final int day;
  final List<AiActivity> activities;

  AiDailyItinerary({required this.day, required this.activities});

  factory AiDailyItinerary.fromJson(Map<String, dynamic> json) {
    return AiDailyItinerary(
      day: json['day'] ?? 0,
      activities: (json['activities'] as List)
          .map((item) => AiActivity.fromJson(item))
          .toList(),
    );
  }
}

class AiActivity {
  final String timeSlot;
  final String rationale;
  final double estimatedCost;
  final String? placeId;
  final String? placeName;

  AiActivity({
    required this.timeSlot,
    required this.rationale,
    required this.estimatedCost,
    this.placeId,
    this.placeName,
  });

  factory AiActivity.fromJson(Map<String, dynamic> json) {
    return AiActivity(
      timeSlot: json['timeSlot'] ?? '',
      rationale: json['rationale'] ?? '',
      estimatedCost: (json['estimatedCost'] as num).toDouble(),
      placeId: json['placeId'],
      placeName: json['placeName'],
    );
  }
}
