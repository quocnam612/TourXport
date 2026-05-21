class AiTripRequest {
  final double budget;
  final int durationDays;
  final String preferences;

  AiTripRequest({
    required this.budget,
    required this.durationDays,
    required this.preferences,
  });

  Map<String, dynamic> toJson() {
    return {
      'budget': budget,
      'duration_days': durationDays,
      'preferences': preferences,
    };
  }
}
