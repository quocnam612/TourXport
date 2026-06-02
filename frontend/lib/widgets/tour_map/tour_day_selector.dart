import 'package:flutter/material.dart';
import '../../models/ai_trip_response.dart';

class TourDaySelector extends StatelessWidget {
  final List<AiDailyItinerary> itinerary;
  final int selectedDayIndex;
  final ValueChanged<int> onDaySelected;

  const TourDaySelector({
    super.key,
    required this.itinerary,
    required this.selectedDayIndex,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itinerary.length + 1,
        itemBuilder: (context, index) {
          final isSelected = index - 1 == selectedDayIndex;
          final label = index == 0 ? "Tất cả" : "Ngày ${itinerary[index - 1].day}";
          return GestureDetector(
            onTap: () {
              if (!isSelected) {
                onDaySelected(index - 1);
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFD4AF7A) : Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFFD4AF7A) : Colors.white.withOpacity(0.2),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.black87 : Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
