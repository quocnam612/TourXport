class TravelMemory {
  final String destinationId;
  final String destinationName;
  final String date;
  final String tourTitle;
  final double durationHours;
  final int durationDays;
  final int durationNights;
  final int photoCount;
  final String note;
  final double rating;
  final String photoUrl;
  final List<String> photoUrls;

  TravelMemory({
    required this.destinationId,
    required this.destinationName,
    required this.date,
    required this.tourTitle,
    required this.durationHours,
    this.durationDays = 3,
    this.durationNights = 2,
    required this.photoCount,
    required this.note,
    required this.rating,
    required this.photoUrl,
    this.photoUrls = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'destinationId': destinationId,
      'destinationName': destinationName,
      'date': date,
      'tourTitle': tourTitle,
      'durationHours': durationHours,
      'durationDays': durationDays,
      'durationNights': durationNights,
      'photoCount': photoCount,
      'note': note,
      'rating': rating,
      'photoUrl': photoUrl,
      'photoUrls': photoUrls,
    };
  }

  factory TravelMemory.fromJson(Map<String, dynamic> json) {
    final rawUrls = json['photoUrls'];
    List<String> urls = [];
    if (rawUrls is List) {
      urls = rawUrls.map((e) => e.toString()).toList();
    }
    return TravelMemory(
      destinationId: json['destinationId'] ?? '',
      destinationName: json['destinationName'] ?? '',
      date: json['date'] ?? '',
      tourTitle: json['tourTitle'] ?? '',
      durationHours: (json['durationHours'] as num?)?.toDouble() ?? 1.0,
      durationDays: json['durationDays'] as int? ?? 3,
      durationNights: json['durationNights'] as int? ?? 2,
      photoCount: json['photoCount'] as int? ?? 0,
      note: json['note'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      photoUrl: json['photoUrl'] ?? '',
      photoUrls: urls,
    );
  }
}

class PassportBadge {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final bool isEarned;

  PassportBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    this.isEarned = false,
  });

  PassportBadge copyWith({bool? isEarned}) {
    return PassportBadge(
      id: id,
      title: title,
      description: description,
      iconName: iconName,
      isEarned: isEarned ?? this.isEarned,
    );
  }
}
