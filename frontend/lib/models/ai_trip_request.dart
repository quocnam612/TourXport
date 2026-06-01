class AiTripRequest {
  static const int maxTripDays = 7;
  static const int maxTripNights = 7;
  static const int maxTravelers = 5;
  static const int minBudgetPerTravelerDay = 200000;
  static const int maxBudgetPerTravelerDay = 200000000;

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
    final safeTotalDays = totalDays.clamp(1, maxTripDays).toInt();
    final safeTotalNights = totalNights.clamp(0, maxTripNights).toInt();
    final safeAdults = adults.clamp(1, maxTravelers).toInt();
    final safeChildren = children.clamp(0, maxTravelers - safeAdults).toInt();
    final totalTravelers = safeAdults + safeChildren;
    final minBudget = totalTravelers * safeTotalDays * minBudgetPerTravelerDay;
    final maxBudget = totalTravelers * safeTotalDays * maxBudgetPerTravelerDay;
    final safeBudgetLevel = budgetLevel.clamp(minBudget, maxBudget).toInt();

    return {
      'destinations': destinations.isEmpty ? 'auto' : destinations,
      'totalDays': safeTotalDays,
      'totalNights': safeTotalNights,
      'travelers': {
        'adults': safeAdults,
        'children': safeChildren,
      },
      'preferences': {
        'budgetLevel': safeBudgetLevel,
        'interests': interests,
        'transportMode': transportMode,
        'pace': pace,
      },
    };
  }
}
