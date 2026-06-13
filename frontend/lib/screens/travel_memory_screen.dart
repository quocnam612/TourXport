import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/passport_models.dart';
import '../services/passport_service.dart';
import '../models/destination.dart';

class TravelMemoryScreen extends StatefulWidget {
  final String placeName;
  final String fallbackImageUrl;

  const TravelMemoryScreen({
    super.key,
    required this.placeName,
    required this.fallbackImageUrl,
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
    final m = PassportService.instance.getMemory(widget.placeName);
    if (m != null) {
      _memory = m;
    } else {
      _memory = TravelMemory(
        destinationId: '',
        destinationName: widget.placeName,
        date: _formattedToday(),
        tourTitle: 'Tự do khám phá',
        durationHours: 2.0,
        durationDays: 3,
        durationNights: 2,
        photoCount: 0,
        note: 'Hãy viết cảm nghĩ của bạn về chuyến đi này...',
        rating: 5.0,
        photoUrl: widget.fallbackImageUrl,
      );
    }

    _noteController = TextEditingController(text: _memory.note);
    _tourController = TextEditingController(text: _memory.tourTitle);
    _dateController = TextEditingController(text: _memory.date);
    _rating = _memory.rating;
    _photoCount = _memory.photoCount;
    _durationHours = _memory.durationHours;
    _durationDays = _memory.durationDays;
    _durationNights = _memory.durationNights;
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
      destinationId: _memory.destinationId,
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

  @override
  Widget build(BuildContext context) {
    final imgUrl = _memory.photoUrl.isNotEmpty ? _memory.photoUrl : widget.fallbackImageUrl;
    final isDesktop = MediaQuery.of(context).size.width >= 800;

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
                setState(() {
                  _noteController.text = _memory.note;
                  _tourController.text = _memory.tourTitle;
                  _dateController.text = _memory.date;
                  _rating = _memory.rating;
                  _photoCount = _memory.photoCount;
                  _durationHours = _memory.durationHours;
                  _isEditing = false;
                });
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
                            // 3-Column stats row (Strava / Wrapped style)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(
                                  icon: Icons.calendar_today_rounded,
                                  label: 'Ngày khám phá',
                                  child: _isEditing
                                      ? SizedBox(
                                          width: 100,
                                          child: TextField(
                                            controller: _dateController,
                                            style: const TextStyle(fontFamily: 'Montserrat', fontSize: 13, color: Colors.white),
                                            decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                                          ),
                                        )
                                      : Text(
                                          _memory.date,
                                          style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                ),
                                _buildStatItem(
                                  icon: Icons.camera_alt_rounded,
                                  label: 'Số ảnh chụp',
                                  child: _isEditing
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove, color: Colors.white54, size: 16),
                                              onPressed: () {
                                                if (_photoCount > 0) setState(() => _photoCount--);
                                              },
                                              constraints: const BoxConstraints(),
                                              padding: EdgeInsets.zero,
                                            ),
                                            Text('$_photoCount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                            IconButton(
                                              icon: const Icon(Icons.add, color: Colors.white54, size: 16),
                                              onPressed: () => setState(() => _photoCount++),
                                              constraints: const BoxConstraints(),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ],
                                        )
                                      : Text(
                                          '${_memory.photoCount} ảnh',
                                          style: const TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                ),
                                _buildStatItem(
                                  icon: Icons.timer_rounded,
                                  label: 'Thời gian đi',
                                  child: _isEditing
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove, color: Colors.white54, size: 14),
                                              onPressed: () {
                                                if (_durationDays > 1) {
                                                  setState(() {
                                                    _durationDays--;
                                                    if (_durationNights >= _durationDays) {
                                                      _durationNights = (_durationDays - 1).clamp(0, 99);
                                                    }
                                                  });
                                                }
                                              },
                                              constraints: const BoxConstraints(),
                                              padding: EdgeInsets.zero,
                                            ),
                                            Text('${_durationDays}N', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                            IconButton(
                                              icon: const Icon(Icons.add, color: Colors.white54, size: 14),
                                              onPressed: () {
                                                setState(() {
                                                  _durationDays++;
                                                  _durationNights = _durationDays - 1;
                                                });
                                              },
                                              constraints: const BoxConstraints(),
                                              padding: EdgeInsets.zero,
                                            ),
                                            const SizedBox(width: 4),
                                            IconButton(
                                              icon: const Icon(Icons.remove, color: Colors.white54, size: 14),
                                              onPressed: () {
                                                if (_durationNights > 0) {
                                                  setState(() => _durationNights--);
                                                }
                                              },
                                              constraints: const BoxConstraints(),
                                              padding: EdgeInsets.zero,
                                            ),
                                            Text('${_durationNights}Đ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                            IconButton(
                                              icon: const Icon(Icons.add, color: Colors.white54, size: 14),
                                              onPressed: () {
                                                if (_durationNights < _durationDays) {
                                                  setState(() => _durationNights++);
                                                }
                                              },
                                              constraints: const BoxConstraints(),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ],
                                        )
                                      : Text(
                                          '${_memory.durationDays} ngày ${_memory.durationNights} đêm',
                                          style: const TextStyle(fontFamily: 'Montserrat', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                ),
                              ],
                            ),
                            
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Divider(color: Colors.white12),
                            ),

                            // Tour Name
                            const Text(
                              'TOUR ĐÃ THAM GIA',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white38,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _isEditing
                                ? TextField(
                                    controller: _tourController,
                                    style: const TextStyle(fontFamily: 'Montserrat', fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      hintText: 'Nhập tên tour hành trình...',
                                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                      isDense: true,
                                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF7A))),
                                    ),
                                  )
                                : Text(
                                    _memory.tourTitle,
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFD4AF7A),
                                    ),
                                  ),
                            
                            const SizedBox(height: 24),

                            // Rating Section
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'ĐÁNH GIÁ CHUYẾN ĐI',
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white38,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    _isEditing
                                        ? Row(
                                            children: List.generate(5, (index) {
                                              final starVal = index + 1;
                                              return GestureDetector(
                                                onTap: () => setState(() => _rating = starVal.toDouble()),
                                                child: Icon(
                                                  Icons.star_rounded,
                                                  color: _rating >= starVal
                                                      ? const Color(0xFFD4AF7A)
                                                      : Colors.white24,
                                                  size: 28,
                                                ),
                                              );
                                            }),
                                          )
                                        : Row(
                                            children: [
                                              ...List.generate(5, (index) {
                                                final starVal = index + 1;
                                                return Icon(
                                                  Icons.star_rounded,
                                                  color: _memory.rating >= starVal
                                                      ? const Color(0xFFD4AF7A)
                                                      : Colors.white12,
                                                  size: 20,
                                                );
                                              }),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${_memory.rating}/5.0',
                                                style: const TextStyle(
                                                  fontFamily: 'Montserrat',
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Personal Notes (Diary notes)
                            const Text(
                              'GHI CHÚ CÁ NHÂN',
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
