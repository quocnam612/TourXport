import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class HelpSupportScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const HelpSupportScreen({
    super.key,
    required this.userData,
  });

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _floatingController;
  
  final TextEditingController _searchController = TextEditingController();
  final List<bool> _faqExpanded = List.generate(4, (_) => false);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F1412),
      body: Stack(
        children: [
          // 1. CINEMATIC SUPPORT HERO BACKGROUND
          _buildHeroBackground(),
          
          // Main Scrollable Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
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
                        
                        // 2. SMART HELP SEARCH SECTION
                        _buildSearchSection(),
                        const SizedBox(height: 40),
                        
                        // 4. LIVE SUPPORT / CONCIERGE SECTION (Featured)
                        _buildConciergeCard(),
                        const SizedBox(height: 40),

                        // 3. QUICK SUPPORT ACTIONS SECTION
                        _buildSectionLabel('Dịch vụ hỗ trợ'),
                        const SizedBox(height: 16),
                        _buildQuickActionsGrid(),
                        const SizedBox(height: 40),

                        // 5. FAQ SECTION
                        _buildSectionLabel('Câu hỏi thường gặp'),
                        const SizedBox(height: 16),
                        _buildFaqSection(),
                        const SizedBox(height: 40),

                        // 8. SUPPORT STATUS & HISTORY SECTION
                        _buildSectionLabel('Hoạt động gần đây'),
                        const SizedBox(height: 16),
                        _buildStatusHistoryCard(),
                        const SizedBox(height: 40),

                        // 6. REPORT ISSUE & 7. FEEDBACK SECTION
                        _buildFeedbackSection(),
                        const SizedBox(height: 48),

                        // 9. ACTION & EMOTIONAL FOOTER
                        _buildFooter(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Back Button
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
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/halong.jpg', fit: BoxFit.cover),
          Container(decoration: BoxDecoration(color: const Color(0xFF1B2321).withOpacity(0.78))),
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 150,
              decoration: BoxDecoration(gradient: RadialGradient(center: Alignment.topCenter, radius: 1.2, colors: [const Color(0xFFD4AF7A).withOpacity(0.10), Colors.transparent])),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientGlow(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildHeroHeaderContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -5 * _floatingController.value),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF7A).withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD4AF7A).withOpacity(0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF7A).withOpacity(0.1),
                      blurRadius: 30,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: const Icon(Icons.support_agent_rounded, color: Color(0xFFD4AF7A), size: 40),
              ),
            );
          },
        ),
        const SizedBox(height: 28),
        const Text(
          'Trợ Giúp & Hỗ Trợ',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 38,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Chúng tôi luôn ở đây để lắng nghe, thấu hiểu và đồng hành cùng bạn trong mọi khoảnh khắc của chuyến hành trình.',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 15,
            color: Colors.white.withOpacity(0.6),
            height: 1.7,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
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
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Color(0xFFD4AF7A),
        letterSpacing: 2.5,
      ),
    );
  }

  Widget _buildSearchSection() {
    return _buildGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Bạn cần chúng tôi giúp gì hôm nay?',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontWeight: FontWeight.w500),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFD4AF7A), size: 24),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildConciergeCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF7A).withOpacity(0.08),
            blurRadius: 40,
            spreadRadius: -10,
          )
        ],
      ),
      child: _buildGlassCard(
        padding: const EdgeInsets.all(28),
        borderOpacity: 0.2,
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD4AF7A).withOpacity(0.4), width: 2),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/logo.png'), // Placeholder for concierge avatar
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2ECC71),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1B2321), width: 2.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quản gia Cao cấp',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Montserrat'),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sẵn sàng hỗ trợ ngay lập tức',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Color(0xFFD4AF7A), size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'Thời gian phản hồi dự kiến: ~2 phút',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildGoldButton(
              onPressed: () {},
              text: 'Bắt đầu trò chuyện',
              icon: Icons.chat_bubble_outline_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    final actions = [
      {'title': 'Liên hệ hỗ trợ', 'icon': Icons.headset_mic_rounded},
      {'title': 'Báo cáo lỗi', 'icon': Icons.bug_report_rounded},
      {'title': 'Trung tâm trợ giúp', 'icon': Icons.auto_stories_rounded},
      {'title': 'Hướng dẫn sử dụng', 'icon': Icons.menu_book_rounded},
      {'title': 'Gửi phản hồi', 'icon': Icons.rate_review_rounded},
      {'title': 'Câu hỏi thường gặp', 'icon': Icons.quiz_rounded},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (context, index) {
        return _buildGlassCard(
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(actions[index]['icon'] as IconData, color: const Color(0xFFD4AF7A), size: 28),
                const SizedBox(height: 12),
                Text(
                  actions[index]['title'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Montserrat'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFaqSection() {
    final faqs = [
      {'q': 'Làm sao để đổi email?', 'a': 'Bạn có thể thay đổi email trong phần Cài đặt Tài khoản > Email. Chúng tôi sẽ gửi mã xác thực đến email mới của bạn.'},
      {'q': 'Cách bảo mật tài khoản?', 'a': 'Hãy kích hoạt xác thực 2 bước (2FA) và sử dụng mật khẩu mạnh kết hợp với FaceID hoặc vân tay để bảo vệ tối ưu.'},
      {'q': 'Tôi quên mật khẩu thì sao?', 'a': 'Tại màn hình đăng nhập, hãy chọn "Quên mật khẩu", chúng tôi sẽ gửi liên kết khôi phục qua email đã đăng ký.'},
      {'q': 'Làm sao để liên hệ hỗ trợ?', 'a': 'Bạn có thể chat trực tiếp với Quản gia cao cấp hoặc gửi email cho đội ngũ hỗ trợ 24/7 của chúng tôi.'},
    ];

    return Column(
      children: List.generate(faqs.length, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildGlassCard(
            padding: EdgeInsets.zero,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                onExpansionChanged: (val) => setState(() => _faqExpanded[index] = val),
                title: Text(
                  faqs[index]['q']!,
                  style: TextStyle(
                    color: _faqExpanded[index] ? const Color(0xFFD4AF7A) : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'Montserrat',
                  ),
                ),
                trailing: Icon(
                  _faqExpanded[index] ? Icons.remove_circle_outline_rounded : Icons.add_circle_outline_rounded,
                  color: _faqExpanded[index] ? const Color(0xFFD4AF7A) : Colors.white30,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: Text(
                      faqs[index]['a']!,
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatusHistoryCard() {
    return _buildGlassCard(
      child: Column(
        children: [
          _buildStatusItem('Yêu cầu hỗ trợ vé bay', 'Đang xử lý', const Color(0xFFF1C40F)),
          const Divider(color: Colors.white10, height: 24),
          _buildStatusItem('Báo cáo lỗi bản đồ', 'Đã giải quyết', const Color(0xFF2ECC71)),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String title, String status, Color statusColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.assignment_outlined, color: statusColor, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text('Cập nhật: 2 giờ trước', style: TextStyle(color: Colors.white30, fontSize: 11)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildFeedbackSection() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trải nghiệm của bạn?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Montserrat')),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEmojiBtn('😢'),
              _buildEmojiBtn('😐'),
              _buildEmojiBtn('😊'),
              _buildEmojiBtn('😍'),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: TextField(
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Chia sẻ cảm nhận hoặc ý tưởng của bạn...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Center(
          child: Text(
            'Hành trình của bạn là niềm cảm hứng của chúng tôi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 13, fontStyle: FontStyle.italic),
          ),
        ),
        const SizedBox(height: 24),
        _buildGoldButton(
          onPressed: () {},
          text: 'Liên hệ ngay',
          icon: Icons.phone_in_talk_rounded,
        ),
      ],
    );
  }

  // --- Helper Methods ---

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding, double borderOpacity = 0.12}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.32),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(borderOpacity), width: 1.2),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGoldButton({required VoidCallback onPressed, required String text, IconData? icon}) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFFD4AF7A), Color(0xFFB5956A)]),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF7A).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, color: const Color(0xFF1B2321), size: 20), const SizedBox(width: 10)],
            Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1B2321), letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiBtn(String emoji) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        alignment: Alignment.center,
        child: Text(emoji, style: const TextStyle(fontSize: 26)),
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
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
