class AiTripRequest {
  final List<String> destinations;
  final int totalDays;
  final int totalNights;
  final int adults;
  final int children;
  final int budgetLevel;
  final List<String> interests;
  final String transportMode;
  final String pace;

  AiTripRequest({
    List<String>? destinations,
    required this.totalDays,
    required this.totalNights,
    this.adults = 1,
    this.children = 0,
    required this.budgetLevel,
    required this.interests,
    this.transportMode = 'auto',
    required this.pace,
  }) : destinations = destinations ?? [];

  Map<String, dynamic> toJson() {
    return {
      'destinations': destinations.isEmpty ? 'auto' : destinations,
      'totalDays': totalDays,
      'totalNights': totalNights,
      'travelers': {
        'adults': adults,
        'children': children,
      },
      'preferences': {
        'budgetLevel': budgetLevel,
        'interests': interests,
        'transportMode': transportMode,
        'pace': pace,
      },
    };
  }
}
