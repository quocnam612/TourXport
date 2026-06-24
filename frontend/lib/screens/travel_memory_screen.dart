import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/passport_models.dart';
import '../services/passport_service.dart';
import '../models/destination.dart';
import 'province_detail_screen.dart';

class TravelMemoryScreen extends StatefulWidget {
  final String placeName;
  final String fallbackImageUrl;
  final bool isNewUnlock;
  final Destination? destination;
  final List<Destination>? allDestinations;

  const TravelMemoryScreen({
    super.key,
    required this.placeName,
    required this.fallbackImageUrl,
    this.isNewUnlock = false,
    this.destination,
    this.allDestinations,
  });

  @override
  State<TravelMemoryScreen> createState() => _TravelMemoryScreenState();
}

class _TravelMemoryScreenState extends State<TravelMemoryScreen> {
  late TravelMemory _memory;
  bool _isEditing = false;
  
  late TextEditingController _noteController;
  late TextEditingController _tourController;
  late TextEditingController _dateController;
  late double _rating;
  late int _photoCount;
  late double _durationHours;
  late int _durationDays;
  late int _durationNights;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.isNewUnlock;
    final m = PassportService.instance.getMemory(widget.placeName);
    if (m != null) {
      _memory = m;
    } else {
      _memory = TravelMemory(
        destinationId: '',
        destinationName: widget.placeName,
        date: _formattedToday(),
        tourTitle: '',
        durationHours: 1.0,
        durationDays: 1,
        durationNights: 0,
        photoCount: 0,
        note: '',
        rating: 5.0,
        photoUrl: widget.fallbackImageUrl,
      );
    }

    _noteController = TextEditingController(text: widget.isNewUnlock ? '' : _memory.note);
    _tourController = TextEditingController(text: widget.isNewUnlock ? '' : _memory.tourTitle);
    _dateController = TextEditingController(text: _memory.date);
    _rating = widget.isNewUnlock ? 5.0 : _memory.rating;
    _photoCount = _memory.photoCount;
    _durationHours = _memory.durationHours;
    _durationDays = widget.isNewUnlock ? 1 : _memory.durationDays;
    _durationNights = widget.isNewUnlock ? 0 : _memory.durationNights;
  }

  String _formattedToday() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  @override
  void dispose() {
    _noteController.dispose();
    _tourController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updated = TravelMemory(
      destinationId: _memory.destinationId.isNotEmpty ? _memory.destinationId : (widget.destination?.id ?? ''),
      destinationName: _memory.destinationName,
      date: _dateController.text.trim(),
      tourTitle: _tourController.text.trim(),
      durationHours: _durationHours,
      durationDays: _durationDays,
      durationNights: _durationNights,
      photoCount: _photoCount,
      note: _noteController.text.trim(),
      rating: _rating,
      photoUrl: _memory.photoUrl.isNotEmpty ? _memory.photoUrl : widget.fallbackImageUrl,
    );

    final wasUnlocked = PassportService.instance.isUnlocked(widget.placeName);

    if (!wasUnlocked && widget.destination != null) {
      // 1. Thực hiện check-in để mở khóa chính thức trên hệ thống
      final result = await PassportService.instance.checkIn(
        widget.destination!,
        allDestinations: widget.allDestinations ?? [],
      );

      // 2. Ghi đè nhật ký trống bằng dữ liệu người dùng tự chỉnh sửa
      await PassportService.instance.saveMemory(widget.placeName, updated);

      if (mounted) {
        final List<String> badges = List<String>.from(result['badgesUnlocked'] ?? []);
        
        // 3. Hiển thị hộp thoại chúc mừng mở khóa thành công giống province_detail_screen
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return UnlockAnimationView(
              place: widget.destination!,
              badgesUnlocked: badges,
              onClose: () {
                Navigator.pop(context); // Đóng dialog chúc mừng
                setState(() {
                  _memory = updated;
                  _isEditing = false;
                });
              },
            );
          },
        );
      }
    } else {
      // Đã mở khóa trước đó: lưu chỉnh sửa bình thường
      await PassportService.instance.saveMemory(widget.placeName, updated);
      setState(() {
        _memory = updated;
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu kỷ niệm hành trình!'),
            backgroundColor: Color(0xFF2D6A4F),
          ),
        );
      }
    }
  }

  Widget _badgePill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imgUrl = _memory.photoUrl.isNotEmpty ? _memory.photoUrl : widget.fallbackImageUrl;
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    final unlockedList = PassportService.instance.getUnlockedNames().toList();
    final indexInPassport = unlockedList.contains(widget.placeName)
        ? (unlockedList.indexOf(widget.placeName) + 1)
        : (unlockedList.length + 1);

    return Scaffold(
      backgroundColor: const Color(0xFF0C1412),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          _isEditing ? 'Chỉnh sửa nhật ký' : 'Nhật ký hành trình',
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: Color(0xFFD4AF7A), size: 28),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Chỉnh sửa nhật ký',
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
              onPressed: () {
                final isUnlocked = PassportService.instance.isUnlocked(widget.placeName);
                if (!isUnlocked) {
                  Navigator.pop(context, true);
                } else {
                  setState(() {
                    _noteController.text = _memory.note;
                    _tourController.text = _memory.tourTitle;
                    _dateController.text = _memory.date;
                    _rating = _memory.rating;
                    _photoCount = _memory.photoCount;
                    _durationHours = _memory.durationHours;
                    _isEditing = false;
                  });
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.check_rounded, color: Color(0xFFD4AF7A)),
              onPressed: _save,
            ),
          ]
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background blurring
          if (imgUrl.isNotEmpty)
            Positioned.fill(
              child: Image.network(
                imgUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0E1A17)),
              ),
            ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(color: Colors.black.withOpacity(0.68)),
            ),
          ),

          // Main content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Container(
                constraints: BoxConstraints(maxWidth: isDesktop ? 600 : double.infinity),
                decoration: BoxDecoration(
                  color: const Color(0xFF070E0D).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFD4AF7A).withOpacity(0.25), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Photo Header
                      SizedBox(
                        height: 240,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            imgUrl.isNotEmpty
                                ? Destination.buildImage(imgUrl, fit: BoxFit.cover)
                                : Container(color: const Color(0xFF1B2E29)),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    const Color(0xFF070E0D).withOpacity(0.95),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 20,
                              bottom: 16,
                              right: 20,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFF2D6A4F),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Đã khám phá'.toUpperCase(),
                                        style: const TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFFD4AF7A),
                                          letterSpacing: 2.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    widget.placeName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Memory stats / details
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                // Cột 1: Ngày khám phá
                                Expanded(
                                  child: _buildStatItem(
                                    icon: Icons.calendar_today_rounded,
                                    label: 'Ngày khám phá',
                                    child: _isEditing
                                        ? SizedBox(
                                            width: 90,
                                            child: TextField(
                                              controller: _dateController,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(fontFamily: 'Montserrat', fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                                              decoration: const InputDecoration(
                                                isDense: true,
                                                contentPadding: EdgeInsets.symmetric(vertical: 4),
                                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                                                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF7A))),
                                              ),
                                            ),
                                          )
                                        : Text(
                                            _memory.date,
                                            style: const TextStyle(fontFamily: 'Montserrat', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                  ),
                                ),
                                // Cột 2: Đã khám phá
                                Expanded(
                                  child: _buildStatItem(
                                    icon: Icons.explore_rounded,
                                    label: 'Đã khám phá',
                                    child: Text(
                                      'Hành trình #${indexInPassport}',
                                      style: const TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                // Cột 3: Đánh giá
                                Expanded(
                                  child: _buildStatItem(
                                    icon: Icons.star_rounded,
                                    label: 'Đánh giá',
                                    child: _isEditing
                                        ? Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: List.generate(5, (index) {
                                              final starVal = index + 1;
                                              return GestureDetector(
                                                onTap: () => setState(() => _rating = starVal.toDouble()),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 1.0),
                                                  child: Icon(
                                                    Icons.star_rounded,
                                                    color: _rating >= starVal
                                                        ? const Color(0xFFD4AF7A)
                                                        : Colors.white24,
                                                    size: 14,
                                                  ),
                                                ),
                                              );
                                            }),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.star_rounded,
                                                color: Color(0xFFD4AF7A),
                                                size: 14,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                '${_rating.toStringAsFixed(1)}',
                                                style: const TextStyle(fontFamily: 'Montserrat', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Divider(color: Colors.white12),
                            ),

                            // Personal Notes (Diary notes)
                            const Text(
                              'CẢM NHẬN VỀ CHUYẾN ĐI',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white38,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: _isEditing
                                  ? TextField(
                                      controller: _noteController,
                                      maxLines: 4,
                                      style: const TextStyle(fontFamily: 'Montserrat', fontSize: 13, color: Colors.white, height: 1.5),
                                      decoration: const InputDecoration(
                                        hintText: 'Cảm nhận của bạn về chuyến đi...',
                                        hintStyle: TextStyle(color: Colors.white30),
                                        border: InputBorder.none,
                                      ),
                                    )
                                  : Text(
                                      _memory.note.isNotEmpty ? _memory.note : 'Không có ghi chú nào.',
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.85),
                                        height: 1.6,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFD4AF7A), size: 22),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Colors.white38,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
