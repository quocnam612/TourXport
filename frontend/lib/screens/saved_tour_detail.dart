import 'dart:ui';
import 'package:flutter/material.dart';

import '../models/ai_trip_response.dart';
import '../models/destination.dart';
import 'place_detail.dart';
import 'map_screen.dart';
import 'tour_route_map_screen.dart';
import '../api/api.dart';

class SavedTourDetailScreen extends StatelessWidget {
  final String tourTitle;
  final Map<String, dynamic> tourJson;

  const SavedTourDetailScreen({super.key, required this.tourTitle, required this.tourJson});

  @override
  Widget build(BuildContext context) {
    AiTripResponse? response;
    try {
      response = AiTripResponse.fromJson(tourJson);
    } catch (_) {
      response = null;
    }

    final itinerary = response?.data.itinerary ?? [];
    final meta = _TourMeta.fromJson(tourJson);

    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        // Background similar to AI result screen
        Image.asset('assets/images/login_bg.jpg', fit: BoxFit.cover),
        BackdropFilter(filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: Container(color: Colors.black.withOpacity(0.6))),
        SafeArea(
          child: response == null || itinerary.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildSummary(context),
                )
              : detailContent,
        ),
      ]),
    );
  }

  Widget _buildDetailContent(
    BuildContext context,
    List<AiDailyItinerary> itinerary,
    _TourMeta meta,
    bool isCompact,
  ) {
    return Column(
      children: [
        // Header
        Padding(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 20 : 24,
            isCompact ? 10 : 16,
            isCompact ? 20 : 24,
            isCompact ? 4 : 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _VisibilityBadge(
                    icon: meta.visibilityIcon,
                    compact: isCompact,
                  ),
                  SizedBox(width: isCompact ? 8 : 10),
                  Expanded(
                    child: Text(
                      tourTitle,
                      maxLines: isCompact ? 2 : null,
                      overflow: isCompact
                          ? TextOverflow.ellipsis
                          : TextOverflow.visible,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: isCompact ? 20 : 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: isCompact ? 1.25 : 1.2,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: isCompact ? 36 : 48,
                    height: isCompact ? 36 : 48,
                    child: IconButton(
                      icon: const Icon(Icons.share_rounded),
                      iconSize: isCompact ? 20 : 24,
                      color: Colors.white,
                      padding: EdgeInsets.zero,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              SizedBox(height: isCompact ? 4 : 8),
              Text(
                'Chi tiết lịch trình đã lưu',
                style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: isCompact ? 12 : 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.3),
              ),
              SizedBox(height: isCompact ? 10 : 16),
              _TripMetaGrid(meta: meta, compact: isCompact),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 16 : 20,
              isCompact ? 8 : 12,
              isCompact ? 16 : 20,
              12,
            ),
            itemCount: itinerary.length,
            itemBuilder: (context, i) {
              return _ItineraryDayCard(day: itinerary[i]);
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 20 : 24,
            8,
            isCompact ? 20 : 24,
            isCompact ? 14 : 20,
          ),
          child: Row(children: [
            // Trang chủ
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: () => Navigator.pop(context, 'go_to_explore'),
                child: Container(
                  height: isCompact ? 48 : 50,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white.withOpacity(0.2))),
                  child: const Center(
                      child: Icon(Icons.home_rounded, color: Colors.white, size: 22)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Bản đồ
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () {
                  AiTripResponse? response;
                  try {
                    response = AiTripResponse.fromJson(tourJson);
                  } catch (_) {}
                  if (response != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TourRouteMapScreen(tourData: response!),
                      ),
                    );
                  }
                },
                child: Container(
                  height: isCompact ? 48 : 50,
                  decoration: BoxDecoration(
                      color: const Color(0xFF2D6A4F),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF2D6A4F).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4)),
                      ]),
                  child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Bản đồ',
                            style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                        SizedBox(width: 6),
                        Icon(Icons.map_rounded, color: Colors.white, size: 18),
                      ]),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Đóng
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: isCompact ? 48 : 50,
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFD4AF7A), Color(0xFFB5956A)]),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFFD4AF7A).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4)),
                      ]),
                  child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Đóng',
                            style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ]),
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    final title = tourJson['title'] ?? tourTitle;
    final totalDays = tourJson['totalDays'] ?? tourJson['days']?.length ?? 0;
    final totalNights = tourJson['totalNights'] ?? 0;
    final destinations = tourJson['destinations'] is List ? (tourJson['destinations'] as List).join(', ') : '';
    final cost = _formatMoneyRange(tourJson['estimatedCost'] ?? tourJson['totalEstimatedCost']);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Thời gian: $totalDays ngày $totalNights đêm', style: TextStyle(color: Colors.white.withOpacity(0.8))),
          const SizedBox(height: 8),
          if (destinations.isNotEmpty) Text('Điểm đến: $destinations', style: TextStyle(color: Colors.white.withOpacity(0.7))),
          const SizedBox(height: 12),
          if (cost != null) Text('Chi phí dự tính: $cost', style: const TextStyle(color: Color(0xFFD4AF7A), fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF7A), foregroundColor: Colors.black),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

class _TourMeta {
  final String visibility;
  final IconData visibilityIcon;
  final String visibilityLabel;
  final double? totalDistanceMeters;
  final double? estimatedCost;
  final String? estimatedCostDisplay;
  final String pace;
  final String transportMode;
  final int adults;
  final int children;
  final int totalDays;
  final int totalNights;

  const _TourMeta({
    required this.visibility,
    required this.visibilityIcon,
    required this.visibilityLabel,
    required this.totalDistanceMeters,
    required this.estimatedCost,
    required this.estimatedCostDisplay,
    required this.pace,
    required this.transportMode,
    required this.adults,
    required this.children,
    required this.totalDays,
    required this.totalNights,
  });

  factory _TourMeta.fromJson(Map<String, dynamic> json) {
    final visibility = (json['visibility'] ?? json['privacy'] ?? 'public').toString();
    final travelers = json['travelers'] is Map ? Map<String, dynamic>.from(json['travelers']) : const <String, dynamic>{};
    final estimatedCost = _readDouble(json['estimatedCost']) ?? _readDouble(json['totalEstimatedCost']);
    final estimatedCostDisplay = _formatMoneyRange(json['estimatedCost'] ?? json['totalEstimatedCost']);
    final distanceMeters = _readDouble(json['totalDistanceMeters']) ?? _readDouble(json['distanceMeters']) ?? _readDouble(json['totalDistance']);
    final totalDays = _readInt(json['totalDays']) ?? _readInt(json['days']) ?? (json['itinerary'] is List ? (json['itinerary'] as List).length : 0);
    final totalNights = _readInt(json['totalNights']) ?? (totalDays > 0 ? (totalDays - 1).clamp(0, 999) : 0);

    return _TourMeta(
      visibility: visibility,
      visibilityIcon: _iconForVisibility(visibility),
      visibilityLabel: _labelForVisibility(visibility),
      totalDistanceMeters: distanceMeters,
      estimatedCost: estimatedCost,
      estimatedCostDisplay: estimatedCostDisplay,
      pace: (json['pace'] ?? json['preferences']?['pace'] ?? 'balanced').toString(),
      transportMode: (json['transportMode'] ?? json['preferences']?['transportMode'] ?? 'auto').toString(),
      adults: _readInt(travelers['adults']) ?? 0,
      children: _readInt(travelers['children']) ?? 0,
      totalDays: totalDays,
      totalNights: totalNights,
    );
  }

  static IconData _iconForVisibility(String value) {
    switch (value.toLowerCase()) {
      case 'private':
      case 'hidden':
        return Icons.lock_rounded;
      case 'protected':
      case 'shared':
        return Icons.groups_rounded;
      default:
        return Icons.public_rounded;
    }
  }

  static String _labelForVisibility(String value) {
    switch (value.toLowerCase()) {
      case 'private':
      case 'hidden':
        return 'Riêng tư';
      case 'protected':
      case 'shared':
        return 'Chia sẻ';
      default:
        return 'Công khai';
    }
  }
}

class _TripMetaGrid extends StatelessWidget {
  final _TourMeta meta;

  const _TripMetaGrid({required this.meta});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _MetaPill(
          icon: meta.visibilityIcon,
          label: meta.visibilityLabel,
          value: 'Hiển thị',
        ),
        _MetaPill(
          icon: Icons.straighten_rounded,
          label: meta.totalDistanceMeters != null
              ? _formatDistance(meta.totalDistanceMeters!)
              : 'Chưa có',
          value: 'Quãng đường',
        ),
        _MetaPill(
          icon: Icons.payments_rounded,
          label: meta.estimatedCostDisplay != null
              ? meta.estimatedCostDisplay!
              : 'Chưa có',
          value: 'Số tiền dự tính',
        ),
        _MetaPill(
          icon: _paceIcon(meta.pace),
          label: _paceLabel(meta.pace),
          value: 'Nhịp độ',
        ),
        _MetaPill(
          icon: _transportIcon(meta.transportMode),
          label: _transportLabel(meta.transportMode),
          value: 'Phương tiện',
        ),
        _MetaPill(
          icon: Icons.people_alt_rounded,
          label: '${meta.adults} lớn, ${meta.children} trẻ',
          value: 'Người đi',
        ),
        _MetaPill(
          icon: Icons.event_available_rounded,
          label: '${meta.totalDays} ngày ${meta.totalNights} đêm',
          value: 'Thời lượng',
        ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MetaPill({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFD4AF7A), size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VisibilityBadge extends StatelessWidget {
  final IconData icon;

  const _VisibilityBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF7A).withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD4AF7A).withOpacity(0.2)),
      ),
      child: Icon(icon, color: const Color(0xFFD4AF7A), size: 20),
    );
  }
}

double? _readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    final total = map['total'] ?? map['amount'] ?? map['value'] ?? map['max'] ?? map['min'];
    return _readDouble(total);
  }
  return null;
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String _formatDistance(double meters) {
  if (meters >= 1000) {
    final km = meters / 1000;
    return '${km.toStringAsFixed(km >= 10 ? 0 : 1)} km';
  }
  return '${meters.toStringAsFixed(0)} m';
}

String _formatMoney(double amount) {
  final raw = amount.toInt().toString();
  return '${raw.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')} đ';
}

String? _formatMoneyRange(dynamic value) {
  if (value == null) return null;

  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    final min = _readDouble(map['min'] ?? map['from'] ?? map['low']);
    final max = _readDouble(map['max'] ?? map['to'] ?? map['high']);

    if (min != null && max != null) {
      return '${_formatMoney(min)}-${_formatMoney(max)}';
    }
    if (min != null) {
      return _formatMoney(min);
    }
    if (max != null) {
      return _formatMoney(max);
    }
    return null;
  }

  final amount = _readDouble(value);
  if (amount == null) return null;
  return _formatMoney(amount);
}

String _paceLabel(String pace) {
  switch (pace.toLowerCase()) {
    case 'fast':
      return 'Nhanh';
    case 'balanced':
      return 'Cân bằng';
    case 'relaxed':
      return 'Thư giãn';
    default:
      return pace;
  }
}

IconData _paceIcon(String pace) {
  switch (pace.toLowerCase()) {
    case 'fast':
      return Icons.flash_on_rounded;
    case 'balanced':
      return Icons.balance_rounded;
    case 'relaxed':
      return Icons.spa_rounded;
    default:
      return Icons.speed_rounded;
  }
}

String _transportLabel(String transportMode) {
  switch (transportMode.toLowerCase()) {
    case 'car':
      return 'Ô tô';
    case 'motorbike':
      return 'Xe máy';
    case 'public':
      return 'Công cộng';
    case 'auto':
      return 'Tự động';
    default:
      return transportMode;
  }
}

IconData _transportIcon(String transportMode) {
  switch (transportMode.toLowerCase()) {
    case 'car':
      return Icons.directions_car_rounded;
    case 'motorbike':
      return Icons.two_wheeler_rounded;
    case 'public':
      return Icons.directions_bus_rounded;
    case 'auto':
      return Icons.auto_mode_rounded;
    default:
      return Icons.route_rounded;
  }
}

class _ItineraryDayCard extends StatelessWidget {
  final AiDailyItinerary day;
  const _ItineraryDayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFD4AF7A), borderRadius: BorderRadius.circular(12)),
                child: Text('Ngày ${day.day}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Divider(color: Colors.white.withOpacity(0.06))),
            ],
          ),
          const SizedBox(height: 12),
          ...day.activities.map((act) => _buildActivityItem(act)).toList(),
        ],
      ),
    );
  }

  Widget _buildActivityItem(AiActivity act) {
    return _ActivityCardTile(act: act);
  }

}

class _ActivityCardTile extends StatefulWidget {
  final AiActivity act;
  const _ActivityCardTile({required this.act});

  @override
  State<_ActivityCardTile> createState() => _ActivityCardTileState();
}

class _ActivityCardTileState extends State<_ActivityCardTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final act = widget.act;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
              onTap: () async {
                if (act.placeId != null && act.placeId!.isNotEmpty) {
                  // Try resolving to a real location document via sourceLocationId
                  final doc = await fetchLocationBySourceId(act.placeId!, sourceCollection: act.sourceCollection);
                  Destination dest;
                  if (doc != null) {
                    dest = Destination.fromJson(doc);
                  } else {
                    dest = Destination(
                      id: act.placeId,
                      name: act.placeName ?? 'Địa điểm',
                      province: '',
                      price: '0',
                      imagePath: '',
                      bgBlurPath: '',
                    );
                  }
                  if (!mounted) return;
                  Navigator.of(context).push(PageRouteBuilder(
                    pageBuilder: (_, __, ___) => PlaceDetailScreen(destination: dest, useSimpleTransition: true),
                    transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                  ));
                } else {
                  final dest = Destination(
                    id: null,
                    name: act.placeName ?? 'Địa điểm',
                    province: '',
                    price: '0',
                    imagePath: '',
                    bgBlurPath: '',
                  );
                  if (!mounted) return;
                  Navigator.of(context).push(PageRouteBuilder(
                    pageBuilder: (_, __, ___) => MapScreen(destination: dest),
                    transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                  ));
                }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _hover ? const Color(0xFFD4AF7A) : Colors.white.withOpacity(0.04), width: _hover ? 1.6 : 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFD4AF7A).withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(_getTimeSlotIcon(act.timeSlot), color: const Color(0xFFD4AF7A), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(act.timeSlot, style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.bold)),
                        if (act.estimatedCost > 0) Text('${act.estimatedCost.toInt()} đ', style: TextStyle(color: Colors.white.withOpacity(0.6))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(act.placeName ?? 'Địa điểm', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(act.rationale, style: TextStyle(color: Colors.white.withOpacity(0.7))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTimeSlotIcon(String slot) {
    if (slot.contains('Sáng')) return Icons.wb_sunny_rounded;
    if (slot.contains('Chiều')) return Icons.wb_cloudy_rounded;
    return Icons.nightlight_round;
  }
}
