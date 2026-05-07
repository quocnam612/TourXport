import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/survey_answer.dart';
import '../models/destination.dart';

/// Kết quả khảo sát — hiển thị top destinations phù hợp.
class SurveyResultScreen extends StatefulWidget {
  final SurveyAnswer answer;
  const SurveyResultScreen({super.key, required this.answer});

  @override
  State<SurveyResultScreen> createState() => _SurveyResultScreenState();
}

class _SurveyResultScreenState extends State<SurveyResultScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final Animation<double> _fadeIn;
  late List<_ScoredDestination> _results;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeIn = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _results = _computeScores();
    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  // ── Scoring logic ──
  List<_ScoredDestination> _computeScores() {
    // Extended destination database for scoring
    final destinations = <_DestProfile>[
      _DestProfile(
        dest: sampleDestinations[0], // Hạ Long Bay
        tags: ['Biển', 'Du thuyền', 'Vịnh biển', 'Khám phá', 'Chụp ảnh'],
        bestTime: 'Tháng 4–10', budgetRange: '5–10 triệu',
        vibes: ['Phiêu lưu khám phá', 'Romantic'],
        activities: ['Lặn biển', 'Chụp ảnh', 'Tắm biển'],
        nature: 0.8, quiet: 0.5),
      _DestProfile(
        dest: sampleDestinations[1], // Hội An
        tags: ['Cổ kính / văn hóa', 'Chợ đêm', 'Phố cổ', 'Ẩm thực'],
        bestTime: 'Tháng 2–4', budgetRange: '2–5 triệu',
        vibes: ['Chill chữa lành', 'Romantic', 'Backpacker'],
        activities: ['Khám phá văn hóa', 'Đi chợ đêm', 'Thử món ăn địa phương', 'Chụp ảnh'],
        nature: 0.3, quiet: 0.6),
      _DestProfile(
        dest: sampleDestinations[2], // Đà Nẵng
        tags: ['Biển', 'Thành phố hiện đại', 'Bãi biển hoàng hôn'],
        bestTime: 'Tháng 5–8', budgetRange: '2–5 triệu',
        vibes: ['Tuổi trẻ năng động', 'Luxury lifestyle'],
        activities: ['Tắm biển', 'Cafe chill', 'Đi bar/pub', 'Chụp ảnh'],
        nature: 0.5, quiet: 0.3),
      _DestProfile(
        dest: sampleDestinations[3], // Phong Nha
        tags: ['Rừng', 'Núi', 'Rừng thông', 'Thiên nhiên'],
        bestTime: 'Tháng 4–8', budgetRange: 'Dưới 2 triệu',
        vibes: ['Phiêu lưu khám phá', 'Backpacker'],
        activities: ['Trekking', 'Camping', 'Khám phá văn hóa', 'Leo núi'],
        nature: 1.0, quiet: 0.8),
    ];

    final scored = destinations.map((profile) {
      double score = 0;
      final reasons = <String>[];
      final a = widget.answer;

      // Match place types (câu 9)
      final typeMatches = a.placeTypes
          .where((t) => profile.tags.contains(t)).length;
      if (typeMatches > 0) {
        score += typeMatches * 12;
        reasons.add('Phù hợp kiểu địa điểm bạn thích');
      }

      // Match activities (câu 7)
      final actMatches = a.activities
          .where((act) => profile.activities.contains(act)).length;
      if (actMatches > 0) {
        score += actMatches * 10;
        reasons.add('Có $actMatches hoạt động bạn yêu thích');
      }

      // Match vibe (câu 16)
      if (a.vibeStyle != null && profile.vibes.contains(a.vibeStyle)) {
        score += 15;
        reasons.add('Đúng vibe "${a.vibeStyle}"');
      }

      // Match feelings (câu 1)
      for (final f in a.travelFeelings) {
        if (profile.tags.contains(f)) {
          score += 8;
        }
      }
      if (a.travelFeelings.contains('Thiên nhiên') && profile.nature > 0.6) {
        score += 10;
        reasons.add('Gần gũi thiên nhiên');
      }
      if (a.travelFeelings.contains('Ẩm thực') && profile.tags.contains('Ẩm thực')) {
        score += 10;
        reasons.add('Thiên đường ẩm thực');
      }

      // Match budget (câu 4)
      if (a.budget != null && a.budget == profile.budgetRange) {
        score += 12;
        reasons.add('Phù hợp ngân sách');
      }

      // Slider nature-city (câu 3)
      final naturePref = 1.0 - a.sliderNatureCity;
      score += (1.0 - (naturePref - profile.nature).abs()) * 10;

      // Slider quiet-lively
      final quietPref = 1.0 - a.sliderQuietLively;
      score += (1.0 - (quietPref - profile.quiet).abs()) * 8;

      // Image inspiration (câu 15)
      final imgMatches = a.inspirationImages
          .where((img) => profile.tags.contains(img)).length;
      if (imgMatches > 0) {
        score += imgMatches * 8;
        reasons.add('Ảnh cảm hứng khớp');
      }

      // Clamp to 0–100
      final pct = (score / 1.0).clamp(0, 100).round();

      if (reasons.isEmpty) reasons.add('Điểm đến đáng khám phá');

      return _ScoredDestination(
        destination: profile.dest,
        matchPercent: pct,
        reasons: reasons.take(3).toList(),
        suggestedActivities: profile.activities.take(3).toList(),
        bestTime: profile.bestTime,
        estimatedBudget: profile.budgetRange,
      );
    }).toList();

    scored.sort((a, b) => b.matchPercent.compareTo(a.matchPercent));

    // Normalize: top = 95–98%, scale others
    if (scored.isNotEmpty) {
      final topRaw = scored.first.matchPercent;
      if (topRaw > 0) {
        final target = 92 + math.Random().nextInt(6); // 92–97
        for (var i = 0; i < scored.length; i++) {
          final normalized = (scored[i].matchPercent * target / topRaw).round().clamp(45, 99);
          scored[i] = _ScoredDestination(
            destination: scored[i].destination,
            matchPercent: normalized,
            reasons: scored[i].reasons,
            suggestedActivities: scored[i].suggestedActivities,
            bestTime: scored[i].bestTime,
            estimatedBudget: scored[i].estimatedBudget,
          );
        }
      }
    }

    return scored;
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
          child: FadeTransition(
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
              child: Text('Kết quả khảo sát',
                style: TextStyle(fontFamily: 'Montserrat', fontSize: 26,
                  fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 8),
          Text('Dựa trên sở thích của bạn, đây là những điểm đến phù hợp nhất!',
            style: TextStyle(fontFamily: 'Montserrat', fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.7), height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildResultList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      itemCount: _results.length,
      itemBuilder: (context, i) {
        return _ResultCard(
          result: _results[i],
          rank: i + 1,
          delay: Duration(milliseconds: 200 + i * 150),
        );
      },
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Row(children: [
        // Khảo sát lại
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.2))),
              child: const Center(
                child: Text('Khảo sát lại',
                  style: TextStyle(fontFamily: 'Montserrat', fontSize: 14,
                    fontWeight: FontWeight.w500, color: Colors.white))),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Khám phá ngay
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: () {
              Navigator.popUntil(context, (route) => route.isFirst);
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
                    blurRadius: 12, offset: const Offset(0, 4)),
                ]),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Khám phá ngay',
                    style: TextStyle(fontFamily: 'Montserrat', fontSize: 15,
                      fontWeight: FontWeight.w600, color: Colors.white)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Result card widget ──
class _ResultCard extends StatefulWidget {
  final _ScoredDestination result;
  final int rank;
  final Duration delay;

  const _ResultCard({
    required this.result,
    required this.rank,
    required this.delay,
  });

  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard>
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
      begin: const Offset(0, 0.15), end: Offset.zero,
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
    final r = widget.result;
    final rankColors = [
      const Color(0xFFD4AF7A), // Gold
      const Color(0xFFC0C0C0), // Silver
      const Color(0xFFCD7F32), // Bronze
      Colors.white.withOpacity(0.6),
    ];
    final color = rankColors[math.min(widget.rank - 1, rankColors.length - 1)];

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.rank == 1
                  ? const Color(0xFFD4AF7A).withOpacity(0.3)
                  : Colors.white.withOpacity(0.1)),
            boxShadow: widget.rank == 1
                ? [BoxShadow(
                    color: const Color(0xFFD4AF7A).withOpacity(0.08),
                    blurRadius: 20, spreadRadius: 0)]
                : null,
          ),
          child: Column(children: [
            // Image + overlay info
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: Stack(fit: StackFit.expand, children: [
                  Image.asset(r.destination.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF2A4A3E))),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ]))),
                  // Rank badge
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withOpacity(0.5))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.emoji_events_rounded,
                          color: color, size: 16),
                        const SizedBox(width: 4),
                        Text('#${widget.rank}',
                          style: TextStyle(fontFamily: 'Montserrat',
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: color)),
                      ]),
                    ),
                  ),
                  // Match percent
                  Positioned(
                    top: 12, right: 12,
                    child: _CircularPercent(percent: r.matchPercent)),
                  // Name + province
                  Positioned(
                    left: 14, right: 14, bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.destination.name,
                          style: const TextStyle(fontFamily: 'Montserrat',
                            fontSize: 20, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(r.destination.province,
                          style: TextStyle(fontFamily: 'Montserrat',
                            fontSize: 13, color: Colors.white.withOpacity(0.7))),
                      ])),
                ]),
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reasons
                  ...r.reasons.map((reason) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Icon(Icons.check_circle_rounded,
                        color: const Color(0xFFD4AF7A).withOpacity(0.8), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(reason,
                          style: TextStyle(fontFamily: 'Montserrat', fontSize: 13,
                            color: Colors.white.withOpacity(0.85)))),
                    ]))),
                  const SizedBox(height: 8),
                  // Tags row
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    _infoTag(Icons.calendar_today_rounded, r.bestTime),
                    _infoTag(Icons.payments_rounded, r.estimatedBudget),
                    ...r.suggestedActivities.map(
                      (a) => _infoTag(Icons.local_activity_rounded, a)),
                  ]),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _infoTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13,
          color: const Color(0xFFD4AF7A).withOpacity(0.7)),
        const SizedBox(width: 5),
        Text(text,
          style: TextStyle(fontFamily: 'Montserrat', fontSize: 11,
            color: Colors.white.withOpacity(0.7))),
      ]),
    );
  }
}

// ── Circular percentage indicator ──
class _CircularPercent extends StatefulWidget {
  final int percent;
  const _CircularPercent({required this.percent});

  @override
  State<_CircularPercent> createState() => _CircularPercentState();
}

class _CircularPercentState extends State<_CircularPercent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = Tween<double>(begin: 0, end: widget.percent / 100)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final val = (_anim.value * 100).round();
        return Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.5),
            border: Border.all(
              color: const Color(0xFFD4AF7A).withOpacity(0.3))),
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 44, height: 44,
              child: CircularProgressIndicator(
                value: _anim.value,
                strokeWidth: 3,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFD4AF7A)))),
            Text('$val%',
              style: const TextStyle(fontFamily: 'Montserrat', fontSize: 12,
                fontWeight: FontWeight.w700, color: Color(0xFFD4AF7A))),
          ]),
        );
      },
    );
  }
}

// ── Data classes ──
class _ScoredDestination {
  final Destination destination;
  final int matchPercent;
  final List<String> reasons;
  final List<String> suggestedActivities;
  final String bestTime;
  final String estimatedBudget;

  _ScoredDestination({
    required this.destination,
    required this.matchPercent,
    required this.reasons,
    required this.suggestedActivities,
    required this.bestTime,
    required this.estimatedBudget,
  });
}

class _DestProfile {
  final Destination dest;
  final List<String> tags;
  final String bestTime;
  final String budgetRange;
  final List<String> vibes;
  final List<String> activities;
  final double nature; // 0–1
  final double quiet;  // 0–1

  const _DestProfile({
    required this.dest,
    required this.tags,
    required this.bestTime,
    required this.budgetRange,
    required this.vibes,
    required this.activities,
    required this.nature,
    required this.quiet,
  });
}
