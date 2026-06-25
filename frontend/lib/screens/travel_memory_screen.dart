import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final List<String>? initialPhotos;

  const TravelMemoryScreen({
    super.key,
    required this.placeName,
    required this.fallbackImageUrl,
    this.isNewUnlock = false,
    this.destination,
    this.allDestinations,
    this.initialPhotos,
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
  late List<String> _photoUrls;
  late double _durationHours;
  late int _durationDays;
  late int _durationNights;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.isNewUnlock;
    final m = PassportService.instance.getMemory(widget.placeName);
    List<String> startingUrls = [];
    if (m != null) {
      _memory = m;
      startingUrls = List<String>.from(m.photoUrls);
      if (startingUrls.isEmpty &&
          m.photoUrl.isNotEmpty &&
          m.photoUrl != widget.fallbackImageUrl &&
          !m.photoUrl.startsWith('assets/')) {
        startingUrls.add(m.photoUrl);
      }
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
        photoUrls: widget.initialPhotos ?? [],
      );
      startingUrls = List<String>.from(widget.initialPhotos ?? []);
    }

    _noteController = TextEditingController(text: widget.isNewUnlock ? '' : _memory.note);
    _tourController = TextEditingController(text: widget.isNewUnlock ? '' : _memory.tourTitle);
    _dateController = TextEditingController(text: _memory.date);
    _rating = widget.isNewUnlock ? 5.0 : _memory.rating;
    _photoUrls = startingUrls;
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

  Future<void> _pickMorePhotos() async {
    try {
      final picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 90,
      );
      if (images.isNotEmpty) {
        for (var img in images) {
          final bytes = await img.readAsBytes();
          final base64Str = 'data:image/png;base64,${base64.encode(bytes)}';
          setState(() {
            _photoUrls.add(base64Str);
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking extra photos: $e');
    }
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
      photoCount: _photoUrls.length,
      note: _noteController.text.trim(),
      rating: _rating,
      photoUrl: _photoUrls.isNotEmpty ? _photoUrls.first : widget.fallbackImageUrl,
      photoUrls: _photoUrls,
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

  Widget _buildPhotoCollection(bool isEditing) {
    if (_photoUrls.isEmpty) {
      return Container(
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: GestureDetector(
          onTap: _pickMorePhotos,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFD4AF7A).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_a_photo_rounded,
                  color: const Color(0xFFD4AF7A).withOpacity(0.8),
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  'Chưa có ảnh hành trình',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nhấp để chọn ảnh từ thư viện',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 200,
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                child: Destination.buildImage(_photoUrls.first, fit: BoxFit.cover),
              ),
            ),
          ),
          ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: _photoUrls.length + (isEditing ? 1 : 0),
            itemBuilder: (context, index) {
              if (isEditing && index == _photoUrls.length) {
                return GestureDetector(
                  onTap: _pickMorePhotos,
                  child: Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFD4AF7A).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_photo_alternate_rounded,
                          color: Color(0xFFD4AF7A),
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Thêm ảnh',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final photo = _photoUrls[index];

              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Destination.buildImage(photo, fit: BoxFit.cover),
                      if (isEditing)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _photoUrls.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Ảnh #${index + 1}',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalInfoCard(int indexInPassport) {
    final mainImage = _photoUrls.isNotEmpty ? _photoUrls.first : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13221E).withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4AF7A).withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.04),
              border: Border.all(color: const Color(0xFFD4AF7A), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF7A).withOpacity(0.2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: mainImage.isNotEmpty
                  ? Destination.buildImage(mainImage, fit: BoxFit.cover)
                  : Icon(
                      Icons.image_outlined,
                      color: const Color(0xFFD4AF7A).withOpacity(0.6),
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: Color(0xFFD4AF7A), size: 14),
                    const SizedBox(width: 8),
                    const Text(
                      'Ngày khám phá: ',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 11,
                        color: Colors.white60,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: _isEditing
                          ? SizedBox(
                              height: 24,
                              child: TextField(
                                controller: _dateController,
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFFD4AF7A)),
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              _memory.date,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.explore_rounded, color: Color(0xFFD4AF7A), size: 14),
                    const SizedBox(width: 8),
                    const Text(
                      'Hành trình: ',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 11,
                        color: Colors.white60,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '#$indexInPassport',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFD4AF7A), size: 14),
                    const SizedBox(width: 8),
                    const Text(
                      'Đánh giá: ',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 11,
                        color: Colors.white60,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    _isEditing
                        ? Row(
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFD4AF7A),
                                size: 12,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainImage = _photoUrls.isNotEmpty ? _photoUrls.first : '';
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
                    _photoUrls = List<String>.from(_memory.photoUrls);
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
          if (mainImage.isNotEmpty)
            Positioned.fill(
              child: Destination.buildImage(
                mainImage,
                fit: BoxFit.cover,
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
                      // Place Title & Exploration Badge Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
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
                            const SizedBox(height: 8),
                            Text(
                              widget.placeName,
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

                      // Image Collection Slider with stack effects
                      _buildPhotoCollection(_isEditing),

                      // Horizontal Info Card (compact horizontal card with Exploration Date, Journey #, and Rating)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: _buildHorizontalInfoCard(indexInPassport),
                      ),

                      // Memory notes / details
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
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
}
