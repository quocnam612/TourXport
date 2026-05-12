import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LanguageSettingsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const LanguageSettingsScreen({
    super.key,
    required this.userData,
  });

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  
  String _selectedLanguage = 'vi';
  String _tempSelectedLanguage = 'vi';
  bool _autoDetect = true;
  String _region = 'Việt Nam';
  String _dateFormat = 'DD/MM/YYYY';
  String _timeFormat = '24 giờ';

  final List<Map<String, String>> _languages = [
    {'code': 'vi', 'name': 'Tiếng Việt', 'native': 'Tiếng Việt', 'flag': '🇻🇳', 'region': 'Việt Nam'},
    {'code': 'en', 'name': 'Tiếng Anh', 'native': 'English', 'flag': '🇺🇸', 'region': 'United States'},
    {'code': 'fr', 'name': 'Tiếng Pháp', 'native': 'Français', 'flag': '🇫🇷', 'region': 'France'},
    {'code': 'de', 'name': 'Tiếng Đức', 'native': 'Deutsch', 'flag': '🇩🇪', 'region': 'Germany'},
    {'code': 'ja', 'name': 'Tiếng Nhật', 'native': '日本語', 'flag': '🇯🇵', 'region': 'Japan'},
    {'code': 'ko', 'name': 'Tiếng Hàn', 'native': '한국어', 'flag': '🇰🇷', 'region': 'Korea'},
    {'code': 'zh', 'name': 'Tiếng Trung', 'native': '中文', 'flag': '🇨🇳', 'region': 'China'},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _applyLanguage() {
    setState(() {
      _selectedLanguage = _tempSelectedLanguage;
    });
    
    _showSuccessToast();
  }

  void _showSuccessToast() {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 50,
        left: 20,
        right: 20,
        child: FadeTransition(
          opacity: _fadeController,
          child: Material(
            color: Colors.transparent,
            child: _buildSuccessToast(),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () => overlayEntry.remove());
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F1412),
      body: Stack(
        children: [
          // 1. HERO LANGUAGE HEADER & BACKGROUND
          _buildHeroBackground(),
          
          // Main Scrollable Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 140)),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeController,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroHeaderContent(),
                        const SizedBox(height: 32),
                        
                        // 2. CURRENT LANGUAGE SECTION
                        _buildSectionLabel('Ngôn ngữ hiện tại'),
                        const SizedBox(height: 12),
                        _buildCurrentLanguageCard(),
                        const SizedBox(height: 32),
                        
                        // 3. LANGUAGE SELECTION SECTION
                        _buildSectionLabel('Chọn ngôn ngữ'),
                        const SizedBox(height: 12),
                        _buildLanguageSelectionCard(),
                        const SizedBox(height: 32),

                        // 4. LANGUAGE PREVIEW SECTION
                        _buildSectionLabel('Xem trước giao diện'),
                        const SizedBox(height: 12),
                        _buildPreviewCard(),
                        const SizedBox(height: 32),

                        // 5. REGION & FORMAT SECTION
                        _buildSectionLabel('Vùng & Định dạng'),
                        const SizedBox(height: 12),
                        _buildRegionFormatCard(),
                        const SizedBox(height: 32),

                        // 6. AUTO LANGUAGE DETECTION SECTION
                        _buildAutoDetectCard(),
                        const SizedBox(height: 48),

                        // 7. ACTION AREA
                        _buildActionButtons(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Navigation Overlay (Top)
          Positioned(
            top: topPadding + 12,
            left: 20,
            child: _glassIconButton(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
          ),
        ],
      ),
    );
  }

  // --- UI Components ---

  Widget _buildHeroBackground() {
    final String coverUrl = widget.userData['coverUrl'] ?? '';
    final screenW = MediaQuery.of(context).size.width;
    
    return Container(
      height: 500,
      width: screenW,
      child: Stack(
        fit: StackFit.expand,
        children: [
          coverUrl.isNotEmpty
              ? Image.network(coverUrl, fit: BoxFit.cover)
              : Image.asset(
                  'assets/images/phongnhakebang.jpg',
                  fit: BoxFit.cover,
                ),
          // Cinematic Dark Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  const Color(0xFF1B2321).withOpacity(0.4),
                  const Color(0xFF1B2321).withOpacity(0.85),
                  const Color(0xFF1B2321),
                ],
                stops: const [0.0, 0.4, 0.8, 1.0],
              ),
            ),
          ),
          // Moving Light Reflection Shimmer
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1.0 + _shimmerController.value * 2, -1.0),
                    end: Alignment(-1.0 + _shimmerController.value * 2 + 1.0, 1.0),
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.03),
                      Colors.transparent,
                    ],
                    stops: const [0.3, 0.5, 0.7],
                  ),
                ),
              );
            },
          ),
          // Top Ambient Glow
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: [
                    const Color(0xFFD4AF7A).withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeaderContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF7A).withOpacity(0.1 + (_pulseController.value * 0.1)),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4AF7A).withOpacity(0.2 + (_pulseController.value * 0.2))),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF7A).withOpacity(0.1 * _pulseController.value),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: child,
            );
          },
          child: const Icon(Icons.language_rounded, color: Color(0xFFD4AF7A), size: 36),
        ),
        const SizedBox(height: 24),
        const Text(
          'Ngôn Ngữ',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Cá nhân hóa trải nghiệm đa ngôn ngữ của bạn trên hành trình khám phá vẻ đẹp Việt Nam.',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 15,
            color: Colors.white.withOpacity(0.65),
            height: 1.6,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: Color(0xFFD4AF7A),
        letterSpacing: 2.0,
      ),
    );
  }

  Widget _buildCurrentLanguageCard() {
    final current = _languages.firstWhere((l) => l['code'] == _selectedLanguage);

    return _buildGlassCard(
      child: Row(
        children: [
          _buildGlowingBadge(current['flag']!),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  current['native']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Khu vực: ${current['region']}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2ECC71).withOpacity(0.4)),
            ),
            child: const Text(
              'ĐANG DÙNG',
              style: TextStyle(
                color: Color(0xFF2ECC71),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelectionCard() {
    return _buildGlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm ngôn ngữ...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.5), size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          
          // Language List
          SizedBox(
            height: 320,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              itemCount: _languages.length,
              physics: const BouncingScrollPhysics(),
              separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
              itemBuilder: (context, index) {
                final lang = _languages[index];
                final isSelected = _tempSelectedLanguage == lang['code'];
                
                return AnimatedScale(
                  scale: isSelected ? 1.02 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: InkWell(
                    onTap: () => setState(() => _tempSelectedLanguage = lang['code']!),
                    borderRadius: BorderRadius.circular(16),
                    splashColor: const Color(0xFFD4AF7A).withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang['native']!,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                                Text(
                                  lang['name']!,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 12,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: Color(0xFFD4AF7A), size: 24)
                          else
                            Icon(Icons.circle_outlined, color: Colors.white.withOpacity(0.15), size: 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    final lang = _languages.firstWhere((l) => l['code'] == _tempSelectedLanguage);
    
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF7A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.remove_red_eye_rounded, color: Color(0xFFD4AF7A), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Giao diện (${lang['native']})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Mock UI Preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                _buildMockMenuItem(Icons.map_rounded, _getTranslation('Khám phá')),
                const SizedBox(height: 12),
                _buildMockMenuItem(Icons.bookmark_rounded, _getTranslation('Đã lưu')),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFD4AF7A), Color(0xFFB5956A)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _getTranslation('Đặt ngay'),
                          style: const TextStyle(color: Color(0xFF1B2321), fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                      ),
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

  Widget _buildRegionFormatCard() {
    return _buildGlassCard(
      child: Column(
        children: [
          _buildFormatRow('Vùng', _region, Icons.public_rounded),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white10, height: 1),
          ),
          _buildFormatRow('Định dạng ngày', _dateFormat, Icons.calendar_today_rounded),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white10, height: 1),
          ),
          _buildFormatRow('Định dạng giờ', _timeFormat, Icons.access_time_rounded),
        ],
      ),
    );
  }

  Widget _buildAutoDetectCard() {
    return _buildGlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2D6A4F).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF2D6A4F), size: 22),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tự động nhận diện',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                SizedBox(height: 2),
                Text(
                  'Dựa trên vị trí và hệ thống',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: _autoDetect,
            onChanged: (val) => setState(() => _autoDetect = val),
            activeColor: const Color(0xFFD4AF7A),
            activeTrackColor: const Color(0xFFD4AF7A).withOpacity(0.3),
            inactiveThumbColor: Colors.white24,
            inactiveTrackColor: Colors.white10,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFFD4AF7A), Color(0xFFB5956A)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF7A).withOpacity(0.35),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _applyLanguage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text(
              'Áp dụng thay đổi',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1B2321), letterSpacing: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Hủy bỏ',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 14),
          ),
        ),
      ],
    );
  }

  // --- Helper Methods ---

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 40,
                offset: const Offset(0, 20),
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlowingBadge(String emoji) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFFD4AF7A).withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 28)),
        ),
      ),
    );
  }

  Widget _buildFormatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.4), size: 20),
        const SizedBox(width: 16),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white.withOpacity(0.2), size: 20),
      ],
    );
  }

  Widget _buildMockMenuItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.6), size: 18),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
        const Spacer(),
        Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.2), size: 18),
      ],
    );
  }

  Widget _buildSuccessToast() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF2ECC71).withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'Cập nhật ngôn ngữ thành công!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  String _getTranslation(String text) {
    if (_tempSelectedLanguage == 'vi') return text;
    // Simple mock translation for preview
    final maps = {
      'Khám phá': {'en': 'Explore', 'ja': '探索', 'ko': '탐험', 'fr': 'Explorer', 'de': 'Erkunden', 'zh': '探索'},
      'Đã lưu': {'en': 'Saved', 'ja': '保存済み', 'ko': '저장됨', 'fr': 'Enregistré', 'de': 'Gespeichert', 'zh': '已保存'},
      'Đặt ngay': {'en': 'Book Now', 'ja': '今すぐ予約', 'ko': '지금 예약', 'fr': 'Réserver', 'de': 'Buchen', 'zh': '立即预订'},
    };
    return maps[text]?[_tempSelectedLanguage] ?? text;
  }
}
