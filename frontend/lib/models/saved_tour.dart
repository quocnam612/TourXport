class SavedTour {
  final String id;
  final String title;
  final List<String> destinations;
  final int totalDays;
  final int totalNights;
  final double? estimatedCost;
  final DateTime? createdAt;

  SavedTour({
    required this.id,
    required this.title,
    required this.destinations,
    required this.totalDays,
    required this.totalNights,
    this.estimatedCost,
    this.createdAt,
  });

  factory SavedTour.fromJson(Map<String, dynamic> json) {
    double? cost;
    if (json['estimatedCost'] != null) {
      if (json['estimatedCost'] is Map) {
        cost = (json['estimatedCost']['total'] ?? json['estimatedCost']['amount'])?.toDouble();
      } else if (json['estimatedCost'] is num) {
        cost = json['estimatedCost'].toDouble();
      }
    }
    return SavedTour(
      id: json['_id'] ?? '',
      title: json['title'] ?? 'Lịch trình không tên',
      destinations: List<String>.from(json['destinations'] ?? []),
      totalDays: json['totalDays'] ?? 1,
      totalNights: json['totalNights'] ?? 0,
      estimatedCost: cost,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}
