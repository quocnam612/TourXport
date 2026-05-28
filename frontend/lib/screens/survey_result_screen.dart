import 'dart:ui';

import 'package:flutter/material.dart';

import '../api/api.dart';
import '../models/ai_trip_request.dart';
import '../models/ai_trip_response.dart';
import '../models/survey_answer.dart';

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
      final answer = widget.answer;

      // 1. Lấy ngân sách dưới dạng số nguyên VND làm budgetLevel
      int budgetLevel = 2000000;
      if (answer.budgetPerPerson != null) {
        budgetLevel = answer.budgetPerPerson!.toInt();
      }

      // 2. Map transportMode sang chuẩn API
      String transportMode = 'auto';
      switch (answer.transportMode) {
        case 'Xe máy':
          transportMode = 'motorbike';
          break;
        case 'Ô tô':
          transportMode = 'car';
          break;
        case 'Xe khách':
          transportMode = 'public';
          break;
        case 'Máy bay':
          transportMode = 'public';
          break;
        default:
          transportMode = 'auto';
      }

      // 3. Map mainGoal sang pace
      String pace = 'moderate';
      switch (answer.mainGoal) {
        case 'Nghỉ dưỡng':
          pace = 'relaxed';
          break;
        case 'Du lịch, khám phá':
          pace = 'moderate';
          break;
        case 'Công tác':
          pace = 'packed';
          break;
        default:
          pace = 'moderate';
      }

      // 4. Gom tất cả sở thích, đặc điểm để truyền vào Vector Search & prompt
      final List<String> interests = [];
      if (answer.activities.isNotEmpty) {
        interests.addAll(answer.activities);
      }
      if (answer.mainGoal != null) {
        interests.add("mục tiêu ${answer.mainGoal}");
      }
      if (answer.spendPriority != null) {
        interests.add("ưu tiên chi tiêu cho ${answer.spendPriority}");
      }
      if (answer.placeVibe != null) {
        interests.add("không gian địa điểm ${answer.placeVibe}");
      }
      if (answer.routePriority != null) {
        interests.add("ưu tiên di chuyển ${answer.routePriority}");
      }
      if (answer.accommodationType != null) {
        interests.add("loại hình lưu trú ${answer.accommodationType}");
      }
      if (answer.accommodationPriority != null) {
        interests.add("ưu tiên lưu trú ${answer.accommodationPriority}");
      }
      if (answer.dietaryRequirements.isNotEmpty) {
        interests.addAll(
            answer.dietaryRequirements.map((d) => "yêu cầu ăn uống $d"));
      }
      if (answer.diningStyle != null) {
        interests.add("phong cách quán ăn ${answer.diningStyle}");
      }

      if (interests.isEmpty) {
        interests.addAll(['văn hóa', 'cảnh đẹp']);
      }

      final request = AiTripRequest(
        destinations: answer.selectedDestination ?? 'auto',
        totalDays: answer.totalDays,
        adults: 1,
        children: 0,
        budgetLevel: budgetLevel,
        interests: interests,
        transportMode: transportMode,
        pace: pace,
      );

      final isGuest =
          widget.authToken == null || widget.authToken!.trim().isEmpty;

      final response = await (isGuest
          ? apiAiPostJson(
              '/api/trip/generate',
              request.toJson(),
            )
          : apiPostJson(
              '/tours',
              request.toJson(),
              token: widget.authToken,
            ));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = tryDecodeJsonObject(response.body);
        if (decoded != null) {
          final tripJson = isGuest ? decoded : decoded['data'];
          if (tripJson != null) {
            setState(() {
              _aiResponse = AiTripResponse.fromJson(tripJson);
              _isLoading = false;
            });
            _entranceCtrl.forward();
          } else {
            throw Exception('Dữ liệu phản hồi rỗng');
          }
        } else {
          throw Exception('Dữ liệu không hợp lệ');
        }
      } else {
        final errorData = tryDecodeJsonObject(response.body);
        String errMsg = 'Lỗi kết nối máy chủ';
        if (errorData != null) {
          final detail = errorData['detail'];
          if (detail is String) {
            errMsg = detail;
          } else if (detail is List) {
            errMsg = detail.map((e) {
              if (e is Map) {
                final loc =
                    e['loc'] is List ? (e['loc'] as List).join('.') : e['loc'];
                final msg = e['msg'];
                return "$loc: $msg";
              }
              return e.toString();
            }).join('\n');
          } else {
            errMsg = errorData['message'] ?? 'Lỗi kết nối máy chủ';
          }
        }
        throw Exception(errMsg);
      }
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome_rounded,
                color: Color(0xFFD4AF7A), size: 28),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Lịch trình AI đề xuất',
                  style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
              'Dựa trên sở thích của bạn, TourXport đã tạo ra một lịch trình cá nhân hóa!',
              style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.7),
                  height: 1.4)),
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
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Row(children: [
        // Trang chủ
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.2))),
              child: const Center(
                  child: Text('Trang chủ',
                      style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white))),
            ),
          ),
        ),
        const SizedBox(width: 12),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Lịch trình đã được lưu thành công vào tài khoản của bạn!'),
                    backgroundColor: Color(0xFF2D6A4F),
                  ),
                );
                Navigator.pop(context, 'go_to_saved_tours');
              }
            },
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFD4AF7A), Color(0xFFB5956A)]),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFD4AF7A).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ]),
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Lưu lịch trình',
                        style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 15,
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
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day Header
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF7A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Ngày ${widget.day.day}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Divider(
                          color: Colors.white.withOpacity(0.1), thickness: 1)),
                ],
              ),
              const SizedBox(height: 16),
              // Activities
              ...widget.day.activities.map((act) => _buildActivityItem(act)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(AiActivity act) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Slot Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF7A).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getTimeSlotIcon(act.timeSlot),
              color: const Color(0xFFD4AF7A),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(act.timeSlot,
                        style: TextStyle(
                            color: const Color(0xFFD4AF7A).withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    if (act.estimatedCost > 0)
                      Text('${act.estimatedCost.toInt()} đ',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(act.placeName ?? 'Địa điểm',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(act.rationale,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTimeSlotIcon(String slot) {
    if (slot.contains('Sáng')) return Icons.wb_sunny_rounded;
    if (slot.contains('Chiều')) return Icons.wb_cloudy_rounded;
    return Icons.nightlight_round;
  }
}
