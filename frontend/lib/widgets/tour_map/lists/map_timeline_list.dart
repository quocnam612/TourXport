import 'package:flutter/material.dart';
import '../../../../models/ai_trip_response.dart';
import '../tour_activity_card.dart';

class MapTimelineList extends StatelessWidget {
  final List<AiDailyItinerary> itinerary;
  final AiActivity? focusedActivity;
  final Function(AiActivity) onActivityTapped;
  final bool isDesktop;

  const MapTimelineList({
    super.key,
    required this.itinerary,
    required this.focusedActivity,
    required this.onActivityTapped,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    if (itinerary.isEmpty) {
      return const Center(
        child: Text("Không có dữ liệu lịch trình.", style: TextStyle(color: Colors.white70, fontFamily: 'Montserrat')),
      );
    }
    
    // Flatten Data (Chỉ lưu Data, không lưu Widget)
    final List<dynamic> flattenedData = [];
    for (var day in itinerary) {
      flattenedData.add(day); // Lưu object Day
      flattenedData.addAll(day.activities); // Lưu danh sách Activities
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: flattenedData.length,
      itemBuilder: (context, index) {
        final item = flattenedData[index];
        
        // Render lười biếng (Lazy render) dựa trên kiểu dữ liệu
        if (item is AiDailyItinerary) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12, top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFD4AF7A).withOpacity(0.9), borderRadius: BorderRadius.circular(12)),
            child: Text('Ngày ${item.day}', style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
          );
        } else if (item is AiActivity) {
          return TourActivityCard(
            act: item,
            isSelected: focusedActivity == item,
            onTap: () => onActivityTapped(item),
            isDesktop: isDesktop,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
