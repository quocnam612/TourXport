class AiTripRequest {
  final String destinations;
  final int totalDays;
  final int adults;
  final int children;
  final String budgetLevel;
  final List<String> interests;
  final String transportMode;
  final String pace;

  AiTripRequest({
    this.destinations = 'auto',
    required this.totalDays,
    this.adults = 1,
    this.children = 0,
    required this.budgetLevel,
    required this.interests,
    this.transportMode = 'auto',
    required this.pace,
  });

  Map<String, dynamic> toJson() {
    return {
      'destinations': destinations == 'auto' ? 'auto' : [destinations],
      'totalDays': totalDays,
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
