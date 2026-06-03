import 'dart:ui';

import 'package:flutter/material.dart';

import '../api/api.dart';
import '../l10n/app_localizations.dart';
import '../models/ai_trip_request.dart';
import '../models/ai_trip_response.dart';
import '../models/survey_answer.dart';
import '../models/destination.dart';
import '../widgets/weather_widget.dart';
import 'place_detail.dart';
import 'map_screen.dart';
import 'tour_route_map_screen.dart';

/// Kết quả khảo sát — hiển thị lịch trình AI gợi ý.
class SurveyResultScreen extends StatefulWidget {
  final SurveyAnswer answer;
  final String? authToken;
  const SurveyResultScreen({super.key, required this.answer, this.authToken});

  @override
  State<SurveyResultScreen> createState() => _SurveyResultScreenState();
}

class _SurveyResultScreenState extends State<SurveyResultScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final Animation<double> _fadeIn;

  bool _isLoading = true;
  String? _errorMessage;
  AiTripResponse? _aiResponse;
  Map<String, dynamic>? _tourPayload;
  String? _createdTourId;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeIn = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _fetchAiTrip();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  // ── AI Fetching logic ──
  Future<void> _fetchAiTrip() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final answer = widget.answer;

      final int totalDays = answer.totalDays;
      final int totalTravelers = answer.adults + answer.children;
      final int minBudget = totalTravelers * totalDays * 200000;
      final int maxBudget = totalTravelers * totalDays * 200000000;
      final int budgetLevel = (answer.budgetPerPerson?.toInt() ?? minBudget)
          .clamp(minBudget, maxBudget)
          .toInt();

      int totalNights;
      if (answer.nights != null) {
        totalNights = answer.nights!;
      } else if (answer.days != null) {
        totalNights = (answer.days! - 1) >= 0 ? (answer.days! - 1) : 0;
      } else {
        totalNights = (totalDays - 1) >= 0 ? (totalDays - 1) : 0;
      }

      final req = AiTripRequest(
        destinations: answer.selectedDestinations,
        totalDays: totalDays,
        totalNights: totalNights,
        adults: answer.adults,
        children: answer.children,
        budgetLevel: budgetLevel,
        interests: answer.activities,
        transportMode: answer.transportMode ?? 'auto',
        pace: answer.pace ?? 'balanced',
      );

      // Use backend `/tours` endpoint (not AI backend) to create/generate tour
      final resp = await apiPostJson('/tours', req.toJson(), token: widget.authToken);
      final data = tryDecodeJsonObject(resp.body) ?? {};

      if (resp.statusCode != 200 && resp.statusCode != 201) {
        final msg = (data['detail'] ?? data['message'] ?? 'Server error');
        throw Exception(msg);
      }

      // Backend may wrap the tour/ai response under `data`.
      final payload = (data['data'] is Map<String, dynamic>) ? data['data'] as Map<String, dynamic> : data;

      setState(() {
        try {
          _aiResponse = AiTripResponse.fromJson(payload);
        } catch (_) {
          _aiResponse = null;
        }
        _tourPayload = payload;
        _isLoading = false;
        // extract created tour id if present
        String? created;
        if (data['data'] is Map<String, dynamic>) {
          final m = data['data'] as Map<String, dynamic>;
          created = m['_id'] ?? m['id'] ?? m['_uid'];
        }
        created ??= data['_id'] ?? data['id'];
        _createdTourId = created?.toString();
      });
      // Start entrance animation so FadeTransition becomes visible
      if (mounted) _entranceCtrl.forward();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        // BG
        Image.asset('assets/images/login_bg.jpg', fit: BoxFit.cover),
        BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(color: Colors.black.withOpacity(0.6))),
        SafeArea(
          child: _isLoading
              ? _buildLoading()
              : _errorMessage != null
                  ? _buildError()
                  : FadeTransition(
                      opacity: _fadeIn,
                      child: Column(children: [
                        _buildHeader(),
                        Expanded(child: _buildResultList()),
                        _buildButtons(),
                      ]),
                    ),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    final isVi = AppLocalizations.of(context)!.localeName == 'vi';
    final isCompact = MediaQuery.of(context).size.width < 600;
    final payload = _tourPayload ?? const <String, dynamic>{};
    final meta = _ResultTourMeta.fromPayload(payload, widget.answer);
    final title = (payload['title'] ?? payload['name'])?.toString().trim();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 20 : 24,
        isCompact ? 10 : 16,
        isCompact ? 20 : 24,
        isCompact ? 4 : 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _VisibilityBadge(icon: meta.visibilityIcon, compact: isCompact),
            SizedBox(width: isCompact ? 8 : 10),
            Expanded(
              child: Text(
                  title != null && title.isNotEmpty
                      ? title
                      : (isVi ? 'Lịch trình AI đề xuất' : 'AI suggested itinerary'),
                  maxLines: isCompact ? 2 : null,
                  overflow: isCompact ? TextOverflow.ellipsis : TextOverflow.visible,
                  style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: isCompact ? 20 : 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: isCompact ? 1.25 : 1.2)),
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
          ]),
          SizedBox(height: isCompact ? 4 : 8),
          Text(
              isVi
                  ? 'Dựa trên sở thích của bạn, TourXport đã tạo ra một lịch trình cá nhân hóa!'
                  : 'Based on your preferences, TourXport created a personalized itinerary.',
              style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: isCompact ? 12 : 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.7),
                  height: isCompact ? 1.3 : 1.4)),
          SizedBox(height: isCompact ? 10 : 16),
          _TripMetaGrid(meta: meta, compact: isCompact),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFFD4AF7A)),
          const SizedBox(height: 24),
          const Text('AI đang thiết kế lịch trình cho bạn...',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Quá trình này có thể mất vài giây',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 64),
            const SizedBox(height: 24),
            Text('Đã có lỗi xảy ra',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(_errorMessage ?? 'Không thể kết nối với AI Backend',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6), fontSize: 14)),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _fetchAiTrip();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF7A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Thử lại',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultList() {
    final itinerary = _aiResponse?.data.itinerary ?? [];
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      itemCount: itinerary.length,
      itemBuilder: (context, i) {
        return _ItineraryDayCard(
          day: itinerary[i],
          delay: Duration(milliseconds: 200 + i * 150),
        );
      },
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(children: [
        // Trang chủ (Rút gọn thành Icon)
        Expanded(
          flex: 1,
          child: GestureDetector(
            onTap: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: Container(
              height: 50,
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
        // Xem bản đồ
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: () {
              if (_aiResponse != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TourRouteMapScreen(tourData: _aiResponse!),
                  ),
                );
              }
            },
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                  color: const Color(0xFF2D6A4F), // Màu xanh map-like
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
        // Lưu lịch trình
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: () {
              final isGuest =
                  widget.authToken == null || widget.authToken!.trim().isEmpty;
                    if (isGuest) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Vui lòng đăng nhập để sử dụng tính năng lưu lịch trình'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    } else {
                      // Try to add the created tour to user's saved tours
                      if (_createdTourId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Không có ID lịch trình để lưu'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      } else {
                        () async {
                          try {
                            final resp = await apiPostJson(
                              '/auth/profile/saved-tours',
                              {'tourId': _createdTourId},
                              token: widget.authToken,
                            );
                            if (resp.statusCode == 200) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Lịch trình đã được lưu thành công vào tài khoản của bạn!'),
                                  backgroundColor: Color(0xFF2D6A4F),
                                ),
                              );
                              Navigator.pop(context, 'go_to_saved_tours');
                            } else {
                              final err = tryDecodeJsonObject(resp.body);
                              final msg = err?['message'] ?? 'Lưu lịch trình thất bại';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(msg),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Lỗi kết nối máy chủ'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }();
                      }
                    }
            },
            child: Container(
              height: 50,
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
                    Text('Lưu lại',
                        style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                    SizedBox(width: 6),
                    Icon(Icons.bookmark_add_rounded,
                        color: Colors.white, size: 18),
                  ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Itinerary day card widget ──
class _ItineraryDayCard extends StatefulWidget {
  final AiDailyItinerary day;
  final Duration delay;

  const _ItineraryDayCard({
    required this.day,
    required this.delay,
  });

  @override
  State<_ItineraryDayCard> createState() => _ItineraryDayCardState();
}

class _ItineraryDayCardState extends State<_ItineraryDayCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVi = AppLocalizations.of(context)!.localeName == 'vi';
    double? lat;
    double? lon;
    String? placeName;

    for (final act in widget.day.activities) {
      if (_hasValidLocation(act)) {
        lat = act.latitude;
        lon = act.longitude;
        placeName = act.placeName;
        break;
      }
    }

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day Header
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF7A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(isVi ? 'Ngày ${widget.day.day}' : 'Day ${widget.day.day}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                  if (lat != null && lon != null) ...[
                    const SizedBox(width: 8),
                    WeatherWidget(
                      lat: lat,
                      lon: lon,
                      label: placeName,
                      compact: true,
                    ),
                  ],
                  const SizedBox(width: 12),
                  Expanded(
                      child: Divider(
                          color: Colors.white.withOpacity(0.06), thickness: 1)),
                ],
              ),
              const SizedBox(height: 12),
              // Activities
              ...widget.day.activities.map((act) => _ActivityCardTile(act: act)),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasValidLocation(AiActivity act) {
    final lat = act.latitude;
    final lng = act.longitude;

    return lat != null &&
        lng != null &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180 &&
        !(lat == 0.0 && lng == 0.0);
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
    final canOpenLocation = _hasValidLocation(act);

    return MouseRegion(
      cursor: canOpenLocation
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) {
        if (canOpenLocation) {
          setState(() => _hover = true);
        }
      },
      onExit: (_) {
        if (canOpenLocation) {
          setState(() => _hover = false);
        }
      },
      child: GestureDetector(
        onTap: canOpenLocation ? () => _openActivity(act) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: canOpenLocation && _hover
                  ? const Color(0xFFD4AF7A)
                  : Colors.white.withOpacity(0.04),
              width: canOpenLocation && _hover ? 1.6 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF7A).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getTimeSlotIcon(act.timeSlot),
                  color: const Color(0xFFD4AF7A),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _translateTimeSlot(act.timeSlot, context),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (act.estimatedCost > 0)
                          Text(
                            '${act.estimatedCost.toInt()} đ',
                            style: TextStyle(color: Colors.white.withOpacity(0.6)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      act.placeName ??
                          (AppLocalizations.of(context)!.localeName == 'vi'
                              ? 'Địa điểm'
                              : 'Location'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      act.rationale,
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openActivity(AiActivity act) async {
    if (!_hasValidLocation(act)) return;

    if (act.placeId != null && act.placeId!.isNotEmpty) {
      final doc = await fetchLocationBySourceId(
        act.placeId!,
        sourceCollection: act.sourceCollection,
      );

      final dest = doc != null
          ? Destination.fromJson(doc)
          : Destination(
              id: act.placeId,
              name: act.placeName ?? 'Địa điểm',
              province: '',
              price: '0',
              imagePath: '',
              bgBlurPath: '',
              latitude: act.latitude!,
              longitude: act.longitude!,
            );

      if (!mounted) return;
      Navigator.of(context).push(PageRouteBuilder(
        pageBuilder: (_, __, ___) => PlaceDetailScreen(
          destination: dest,
          useSimpleTransition: true,
        ),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ));
      return;
    }

    final dest = Destination(
      id: null,
      name: act.placeName ?? 'Địa điểm',
      province: '',
      price: '0',
      imagePath: '',
      bgBlurPath: '',
      latitude: act.latitude!,
      longitude: act.longitude!,
    );

    if (!mounted) return;
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, __, ___) => MapScreen(destination: dest),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
    ));
  }

  bool _hasValidLocation(AiActivity act) {
    final lat = act.latitude;
    final lng = act.longitude;

    return lat != null &&
        lng != null &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180 &&
        !(lat == 0.0 && lng == 0.0);
  }

  IconData _getTimeSlotIcon(String slot) {
    if (slot.contains('Sáng')) return Icons.wb_sunny_rounded;
    if (slot.contains('Chiều')) return Icons.wb_cloudy_rounded;
    return Icons.nightlight_round;
  }

  String _translateTimeSlot(String slot, BuildContext context) {
    final isVi = AppLocalizations.of(context)!.localeName == 'vi';
    if (isVi) return slot;
    if (slot.contains('Sáng')) return 'Morning';
    if (slot.contains('Chiều')) return 'Afternoon';
    if (slot.contains('Tối')) return 'Evening';
    return slot;
  }
}

class _ResultTourMeta {
  final String visibility;
  final IconData visibilityIcon;
  final double? totalDistanceMeters;
  final dynamic estimatedCost;
  final String pace;
  final String transportMode;
  final int adults;
  final int children;
  final int totalDays;
  final int totalNights;

  const _ResultTourMeta({
    required this.visibility,
    required this.visibilityIcon,
    required this.totalDistanceMeters,
    required this.estimatedCost,
    required this.pace,
    required this.transportMode,
    required this.adults,
    required this.children,
    required this.totalDays,
    required this.totalNights,
  });

  factory _ResultTourMeta.fromPayload(
    Map<String, dynamic> payload,
    SurveyAnswer answer,
  ) {
    final travelers = payload['travelers'] is Map
        ? Map<String, dynamic>.from(payload['travelers'])
        : const <String, dynamic>{};
    final visibility = (payload['visibility'] ?? payload['privacy'] ?? 'private').toString();
    final totalDays = _readInt(payload['totalDays']) ?? answer.totalDays;
    final totalNights = _readInt(payload['totalNights']) ??
        answer.nights ??
        (totalDays > 0 ? (totalDays - 1).clamp(0, 999).toInt() : 0);

    return _ResultTourMeta(
      visibility: visibility,
      visibilityIcon: _iconForVisibility(visibility),
      totalDistanceMeters: _readDouble(payload['totalDistanceMeters']) ??
          _readDouble(payload['distanceMeters']) ??
          _readDouble(payload['totalDistance']),
      estimatedCost: payload['estimatedCost'] ?? payload['totalEstimatedCost'],
      pace: (payload['pace'] ?? payload['preferences']?['pace'] ?? answer.pace ?? 'balanced').toString(),
      transportMode: (payload['transportMode'] ??
              payload['preferences']?['transportMode'] ??
              answer.transportMode ??
              'auto')
          .toString(),
      adults: _readInt(travelers['adults']) ?? answer.adults,
      children: _readInt(travelers['children']) ?? answer.children,
      totalDays: totalDays,
      totalNights: totalNights,
    );
  }
}

class _TripMetaGrid extends StatelessWidget {
  final _ResultTourMeta meta;
  final bool compact;

  const _TripMetaGrid({required this.meta, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final isVi = AppLocalizations.of(context)!.localeName == 'vi';
    final pills = [
      _MetaPill(
        icon: meta.visibilityIcon,
        label: _translateVisibility(meta.visibility, context),
        value: isVi ? 'Hiển thị' : 'Visibility',
        compact: compact,
      ),
      _MetaPill(
        icon: Icons.straighten_rounded,
        label: meta.totalDistanceMeters != null
            ? _formatDistance(meta.totalDistanceMeters!)
            : (isVi ? 'Chưa có' : 'N/A'),
        value: isVi ? 'Quãng đường' : 'Distance',
        compact: compact,
      ),
      _MetaPill(
        icon: Icons.payments_rounded,
        label: _formatMoneyRange(meta.estimatedCost, context) ?? (isVi ? 'Chưa có' : 'N/A'),
        value: isVi ? 'Số tiền dự tính' : 'Estimated Cost',
        compact: compact,
      ),
      _MetaPill(
        icon: _paceIcon(meta.pace),
        label: _paceLabel(meta.pace, context),
        value: isVi ? 'Nhịp độ' : 'Pace',
        compact: compact,
      ),
      _MetaPill(
        icon: _transportIcon(meta.transportMode),
        label: _transportLabel(meta.transportMode, context),
        value: isVi ? 'Phương tiện' : 'Transport',
        compact: compact,
      ),
      _MetaPill(
        icon: Icons.people_alt_rounded,
        label: isVi
            ? '${meta.adults} lớn, ${meta.children} trẻ'
            : '${meta.adults} adults, ${meta.children} kids',
        value: isVi ? 'Người đi' : 'Travelers',
        compact: compact,
      ),
      _MetaPill(
        icon: Icons.event_available_rounded,
        label: isVi
            ? '${meta.totalDays} ngày ${meta.totalNights} đêm'
            : '${meta.totalDays} days ${meta.totalNights} nights',
        value: isVi ? 'Thời lượng' : 'Duration',
        compact: compact,
      ),
    ];

    if (compact) {
      return SizedBox(
        height: 54,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: pills.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, index) => pills[index],
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: pills,
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool compact;

  const _MetaPill({
    required this.icon,
    required this.value,
    required this.label,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFD4AF7A), size: compact ? 15 : 18),
          SizedBox(width: compact ? 8 : 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ).copyWith(fontSize: compact ? 11 : 12),
              ),
              SizedBox(height: compact ? 1 : 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: compact ? 10 : 11,
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
  final bool compact;

  const _VisibilityBadge({required this.icon, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 8 : 10),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF7A).withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD4AF7A).withOpacity(0.2)),
      ),
      child: Icon(icon, color: const Color(0xFFD4AF7A), size: compact ? 17 : 20),
    );
  }
}

IconData _iconForVisibility(String value) {
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

String _translateVisibility(String value, BuildContext context) {
  final isVi = AppLocalizations.of(context)!.localeName == 'vi';
  switch (value.toLowerCase()) {
    case 'private':
    case 'hidden':
      return isVi ? 'Riêng tư' : 'Private';
    case 'protected':
    case 'shared':
      return isVi ? 'Chia sẻ' : 'Shared';
    default:
      return isVi ? 'Công khai' : 'Public';
  }
}

double? _readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    return _readDouble(map['total'] ?? map['amount'] ?? map['value'] ?? map['max'] ?? map['min']);
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

String _formatMoney(double amount, BuildContext context) {
  final isVi = AppLocalizations.of(context)!.localeName == 'vi';
  final raw = amount.toInt().toString();
  final formatted = raw.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.');
  return isVi ? '$formatted đ' : '$formatted VND';
}

String? _formatMoneyRange(dynamic value, BuildContext context) {
  if (value == null) return null;

  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    final min = _readDouble(map['min'] ?? map['from'] ?? map['low']);
    final max = _readDouble(map['max'] ?? map['to'] ?? map['high']);

    if (min != null && max != null) {
      return '${_formatMoney(min, context)}-${_formatMoney(max, context)}';
    }
    if (min != null) return _formatMoney(min, context);
    if (max != null) return _formatMoney(max, context);
    return null;
  }

  final amount = _readDouble(value);
  if (amount == null) return null;
  return _formatMoney(amount, context);
}

String _paceLabel(String pace, BuildContext context) {
  final isVi = AppLocalizations.of(context)!.localeName == 'vi';
  switch (pace.toLowerCase()) {
    case 'fast':
      return isVi ? 'Nhanh' : 'Fast';
    case 'balanced':
      return isVi ? 'Cân bằng' : 'Balanced';
    case 'relaxed':
      return isVi ? 'Thư giãn' : 'Relaxed';
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

String _transportLabel(String transportMode, BuildContext context) {
  final isVi = AppLocalizations.of(context)!.localeName == 'vi';
  switch (transportMode.toLowerCase()) {
    case 'car':
      return isVi ? 'Ô tô' : 'Car';
    case 'motorbike':
      return isVi ? 'Xe máy' : 'Motorbike';
    case 'public':
      return isVi ? 'Công cộng' : 'Public';
    case 'auto':
      return isVi ? 'Tự động' : 'Auto';
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
