import 'package:flutter/material.dart';
import '../../models/ai_trip_response.dart';
import '../../utils/tour_map_utils.dart';

class TourActivityCard extends StatefulWidget {
  final AiActivity act;
  final VoidCallback? onTap;
  final bool isHighlighted;
  final bool isSelected;
  final Color? markerColor;
  final bool isDesktop;

  const TourActivityCard({
    super.key,
    required this.act,
    this.onTap,
    this.isHighlighted = true,
    this.isSelected = false,
    this.markerColor,
    this.isDesktop = true,
  });

  @override
  State<TourActivityCard> createState() => _TourActivityCardState();
}

class _TourActivityCardState extends State<TourActivityCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: widget.isHighlighted ? 1.0 : 0.3,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: const EdgeInsets.only(bottom: 12),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (widget.isSelected || _hover) ? const Color(0xFFD4AF7A) : Colors.white.withOpacity(0.04),
                width: (widget.isSelected || _hover) ? 1.6 : 1,
              ),
              boxShadow: _hover ? [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
              ] : null,
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 18, top: 12, right: 12, bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFD4AF7A).withOpacity(0.12), shape: BoxShape.circle),
                        child: Icon(TourMapUtils.getTimeSlotIcon(widget.act.timeSlot), color: const Color(0xFFD4AF7A), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(widget.act.timeSlot, style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.bold, fontFamily: 'Montserrat'))),
                                if (widget.isDesktop && widget.act.estimatedCost > 0)
                                  Text('${widget.act.estimatedCost.toInt()} đ', style: TextStyle(color: Colors.white.withOpacity(0.6), fontFamily: 'Montserrat')),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(widget.act.placeName ?? 'Địa điểm', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Montserrat')),
                            if (widget.isDesktop) ...[
                              const SizedBox(height: 6),
                              Text(widget.act.rationale, style: TextStyle(color: Colors.white.withOpacity(0.7), fontFamily: 'Montserrat')),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.markerColor != null)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 6,
                      color: widget.markerColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
