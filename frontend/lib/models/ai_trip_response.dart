class AiTripResponse {
  final String status;
  final AiTripData data;

  AiTripResponse({required this.status, required this.data});

  factory AiTripResponse.fromJson(Map<String, dynamic> json) {
    // If it's a wrapped response containing the 'data' key (e.g. from Node.js backend)
    if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      return AiTripResponse(
        status: json['status'] ?? 'success',
        data: AiTripData.fromJson(json['data']),
      );
    }
    // If it's a direct response from the AI backend (FastAPI)
    return AiTripResponse(
      status: 'success',
      data: AiTripData.fromJson(json),
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
    // Determine total estimated cost
    double cost = 0.0;
    if (json['totalEstimatedCost'] != null) {
      cost = (json['totalEstimatedCost'] as num).toDouble();
    } else if (json['estimatedCost'] != null) {
      cost = (json['estimatedCost']['max'] as num?)?.toDouble() ?? 
             (json['estimatedCost']['min'] as num?)?.toDouble() ?? 0.0;
    }

    // Determine itinerary
    List<AiDailyItinerary> list = [];
    if (json['itinerary'] != null) {
      list = (json['itinerary'] as List)
          .map((item) => AiDailyItinerary.fromJson(item))
          .toList();
    } else if (json['days'] != null) {
      list = (json['days'] as List)
          .map((item) => AiDailyItinerary.fromJson(item))
          .toList();
    }

    return AiTripData(
      isFromDb: json['isFromDb'] ?? false,
      totalEstimatedCost: cost,
      itinerary: list,
    );
  }
}

class AiDailyItinerary {
  final int day;
  final List<AiActivity> activities;

  AiDailyItinerary({required this.day, required this.activities});

  factory AiDailyItinerary.fromJson(Map<String, dynamic> json) {
    List<AiActivity> acts = [];
    if (json['activities'] != null) {
      acts = (json['activities'] as List)
          .map((item) => AiActivity.fromJson(item))
          .toList();
    } else if (json['items'] != null) {
      acts = (json['items'] as List)
          .map((item) => AiActivity.fromJson(item))
          .toList();
    }

    return AiDailyItinerary(
      day: json['day'] ?? json['dayNumber'] ?? 0,
      activities: acts,
    );
  }
}

class AiActivity {
  final String timeSlot;
  final String rationale;
  final double estimatedCost;
  final String? placeId;
  final String? placeName;
  final String? sourceCollection;
  final double? latitude;
  final double? longitude;

  AiActivity({
    required this.timeSlot,
    required this.rationale,
    required this.estimatedCost,
    this.placeId,
    this.placeName,
    this.sourceCollection,
    this.latitude,
    this.longitude,
  });

  factory AiActivity.fromJson(Map<String, dynamic> json) {
    String slot = json['timeSlot'] ?? '';
    if (slot.isEmpty && json['startTime'] != null && json['endTime'] != null) {
      slot = "${json['startTime']} - ${json['endTime']}";
    }

    double cost = 0.0;
    if (json['estimatedCost'] != null) {
      if (json['estimatedCost'] is Map) {
        cost = (json['estimatedCost']['max'] as num?)?.toDouble() ?? 
               (json['estimatedCost']['min'] as num?)?.toDouble() ?? 0.0;
      } else {
        cost = (json['estimatedCost'] as num).toDouble();
      }
    }

    double? lat;
    double? lng;
    final location = json['location'];
    if (location is Map &&
        location['coordinates'] is List &&
        location['coordinates'].length >= 2) {
      final coordinates = location['coordinates'] as List;
      final first = coordinates[0];
      final second = coordinates[1];
      if (first is num && second is num) {
        lng = first.toDouble();
        lat = second.toDouble();
      }
    } else {
      final latValue = json['latitude'];
      final lngValue = json['longitude'];
      if (latValue is num && lngValue is num) {
        lat = latValue.toDouble();
        lng = lngValue.toDouble();
      }
    }

    return AiActivity(
      timeSlot: slot,
      rationale: json['rationale'] ?? json['notes'] ?? '',
      estimatedCost: cost,
      placeId: json['placeId'] ?? json['source']?['id'],
      placeName: json['placeName'] ?? json['title'] ?? 'Địa điểm',
      // support several possible field names in the AI/backend JSON: 'collection' or 'sourceCollection'
      sourceCollection: json['source']?['collection'] ??
          json['source']?['sourceCollection'] ??
          json['sourceCollection'] ??
          json['collection'],
      latitude: lat,
      longitude: lng,
    );
  }
}
