import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import '../api/api.dart';
import '../widgets/app_feedback_logo.dart';

class HelpSupportScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String? authToken;

  const HelpSupportScreen({
    super.key,
    required this.userData,
    this.authToken,
  });

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _floatingController;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final List<_GuideChatMessage> _chatMessages = [];
  late final String _chatSessionId;

  bool _isChatOpen = false;
  bool _isSendingMessage = false;
  String? _chatError;

  bool get _isVi => Localizations.localeOf(context).languageCode == 'vi';

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

    _chatSessionId = _generateUuidV4();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    _searchController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
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
                        _buildSectionLabel(
                            _isVi ? 'Dịch vụ hỗ trợ' : 'Support services'),
                        const SizedBox(height: 16),
                        _buildQuickActionsGrid(),
                        const SizedBox(height: 40),

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
            child: _glassIconButton(
                Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
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
          Container(
              decoration: BoxDecoration(
                  color: const Color(0xFF1B2321).withOpacity(0.78))),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                  gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.2,
                      colors: [
                    const Color(0xFFD4AF7A).withOpacity(0.10),
                    Colors.transparent
                  ])),
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
          animation: _floatingController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -5 * _floatingController.value),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF7A).withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFFD4AF7A).withOpacity(0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF7A).withOpacity(0.1),
                      blurRadius: 30,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: const Icon(Icons.support_agent_rounded,
                    color: Color(0xFFD4AF7A), size: 40),
              ),
            );
          },
        ),
        const SizedBox(height: 28),
        Text(
          _isVi ? 'Trợ Giúp & Hỗ Trợ' : 'Help & Support',
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 38,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isVi
              ? 'Chúng tôi luôn ở đây để lắng nghe, thấu hiểu và đồng hành cùng bạn trong mọi khoảnh khắc của chuyến hành trình.'
              : 'We are here to listen, understand, and support you throughout every step of your travel journey.',
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
          hintText: _isVi
              ? 'Bạn cần chúng tôi giúp gì hôm nay?'
              : 'How can we help you today?',
          hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontWeight: FontWeight.w500),
          prefixIcon: const Icon(Icons.search_rounded,
              color: Color(0xFFD4AF7A), size: 24),
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFD4AF7A).withOpacity(0.4),
                            width: 2),
                        image: const DecorationImage(
                          image: AssetImage(
                              'assets/images/logo.png'), // Placeholder for concierge avatar
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
                          border: Border.all(
                              color: const Color(0xFF1B2321), width: 2.5),
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
                      Text(
                        _isVi ? 'Quản gia Cao cấp' : 'Premium Concierge',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Montserrat'),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isVi
                            ? 'Sẵn sàng hỗ trợ ngay lập tức'
                            : 'Ready to support you right away',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _isChatOpen
                  ? _buildGuideChatBox()
                  : _buildGoldButton(
                      onPressed: _openGuideChat,
                      text: _isVi ? 'Bắt đầu trò chuyện' : 'Start chat',
                      icon: Icons.chat_bubble_outline_rounded,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openGuideChat() {
    setState(() {
      _isChatOpen = true;
      _chatError = null;
      if (_chatMessages.isEmpty) {
        _chatMessages.add(_GuideChatMessage(
          role: _GuideChatRole.assistant,
          content: _isVi
              ? 'Xin chào, mình là trợ lý TourXport. Bạn muốn được hướng dẫn phần nào trong ứng dụng?'
              : 'Hi, I am the TourXport assistant. Which part of the app would you like help with?',
        ));
      }
    });
    _scrollChatToBottom();
  }

  Future<void> _sendGuideMessage() async {
    final content = _chatController.text.trim();
    if (content.isEmpty || _isSendingMessage) return;

    setState(() {
      _chatController.clear();
      _chatError = null;
      _isSendingMessage = true;
      _chatMessages.add(_GuideChatMessage(
        role: _GuideChatRole.user,
        content: content,
      ));
    });
    _scrollChatToBottom();

    try {
      final response = await apiAiPostJson(
        '/api/chat/',
        {
          'session_id': _chatSessionId,
          'content': content,
        },
        token: widget.authToken,
        timeout: const Duration(seconds: 90),
      );
      final data = tryDecodeJsonObject(response.body);
      final reply = data?['reply']?.toString().trim();

      if (!mounted) return;
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          reply != null &&
          reply.isNotEmpty) {
        setState(() {
          _chatMessages.add(_GuideChatMessage(
            role: _GuideChatRole.assistant,
            content: reply,
          ));
        });
      } else {
        setState(() {
          _chatError = data?['message']?.toString() ??
              (_isVi
                  ? 'Không nhận được phản hồi từ trợ lý.'
                  : 'The assistant did not return a response.');
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _chatError = _isVi
            ? 'Không kết nối được AI backend. Vui lòng thử lại sau.'
            : 'Could not connect to the AI backend. Please try again later.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSendingMessage = false);
        _scrollChatToBottom();
      }
    }
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chatScrollController.hasClients) return;
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String _generateUuidV4() {
    final random = _createUuidRandom();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final text = bytes.map(hex).join();
    return '${text.substring(0, 8)}-'
        '${text.substring(8, 12)}-'
        '${text.substring(12, 16)}-'
        '${text.substring(16, 20)}-'
        '${text.substring(20)}';
  }

  Random _createUuidRandom() {
    try {
      return Random.secure();
    } catch (_) {
      return Random();
    }
  }

  Widget _buildGuideChatBox() {
    final viewportHeight = MediaQuery.of(context).size.height;
    final heightFactor = viewportHeight < 760 ? 0.28 : 0.34;
    final chatHeight = (viewportHeight * heightFactor).clamp(190.0, 460.0);

    return Column(
      key: const ValueKey<String>('guide_chat_box'),
      children: [
        Container(
          height: chatHeight,
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.18),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: ListView.builder(
            controller: _chatScrollController,
            physics: const BouncingScrollPhysics(),
            itemCount: _chatMessages.length + (_isSendingMessage ? 1 : 0),
            itemBuilder: (context, index) {
              if (_isSendingMessage && index == _chatMessages.length) {
                return _buildTypingBubble();
              }
              return _buildMessageBubble(_chatMessages[index]);
            },
          ),
        ),
        if (_chatError != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFFF6B6B), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _chatError!,
                  style: const TextStyle(
                    color: Color(0xFFFFB4B4),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _chatController,
                enabled: !_isSendingMessage,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendGuideMessage(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: _isVi ? 'Nhập câu hỏi...' : 'Ask a question...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Color(0xFFD4AF7A)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 54,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSendingMessage ? null : _sendGuideMessage,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: const Color(0xFFD4AF7A),
                  disabledBackgroundColor:
                      const Color(0xFFD4AF7A).withOpacity(0.45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  shadowColor: Colors.transparent,
                ),
                child: _isSendingMessage
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Color(0xFF1B2321),
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Color(0xFF1B2321),
                        size: 24,
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, right: 54),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _typingDot(0),
            const SizedBox(width: 5),
            _typingDot(1),
            const SizedBox(width: 5),
            _typingDot(2),
          ],
        ),
      ),
    );
  }

  Widget _typingDot(int index) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final opacity = 0.35 +
            (sin((_pulseController.value * 2 * pi) + index) + 1) * 0.25;
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF7A).withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(_GuideChatMessage message) {
    final isUser = message.role == _GuideChatRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 720),
        margin: EdgeInsets.only(
          bottom: 10,
          left: isUser ? 54 : 0,
          right: isUser ? 0 : 54,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFFD4AF7A)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 18),
          ),
          border: Border.all(
            color: isUser
                ? const Color(0xFFD4AF7A)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: isUser
            ? Text(
                message.content,
                style: const TextStyle(
                  color: Color(0xFF1B2321),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  height: 1.45,
                ),
              )
            : _buildMarkdownText(message.content),
      ),
    );
  }

  Widget _buildMarkdownText(String raw) {
    final normalized = raw.replaceAll('\r\n', '\n').trim();
    final lines = normalized.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines.length; i += 1) ...[
          _buildMarkdownLine(lines[i]),
          if (i != lines.length - 1) const SizedBox(height: 5),
        ],
      ],
    );
  }

  Widget _buildMarkdownLine(String line) {
    final trimmed = line.trimRight();
    final bulletMatch = RegExp(r'^[-*]\s+(.+)$').firstMatch(trimmed.trimLeft());
    final numberedMatch =
        RegExp(r'^\d+[.)]\s+(.+)$').firstMatch(trimmed.trimLeft());

    if (bulletMatch != null || numberedMatch != null) {
      final content = bulletMatch?.group(1) ?? numberedMatch!.group(1)!;
      final marker = bulletMatch != null ? '•' : '${trimmed.trimLeft().split(RegExp(r'\s+')).first}';
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Text(
              marker,
              style: TextStyle(
                color: Colors.white.withOpacity(0.72),
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ),
          Expanded(child: _buildInlineMarkdown(content)),
        ],
      );
    }

    if (trimmed.isEmpty) {
      return const SizedBox(height: 4);
    }
    return _buildInlineMarkdown(trimmed);
  }

  Widget _buildInlineMarkdown(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    var current = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > current) {
        spans.add(TextSpan(text: text.substring(current, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ));
      current = match.end;
    }
    if (current < text.length) {
      spans.add(TextSpan(text: text.substring(current)));
    }

    return SelectableText.rich(
      TextSpan(
        children: spans.isEmpty ? [TextSpan(text: text)] : spans,
        style: TextStyle(
          color: Colors.white.withOpacity(0.82),
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          height: 1.45,
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    final actions = [
      {
        'title': _isVi ? 'Liên hệ hỗ trợ' : 'Contact support',
        'icon': Icons.headset_mic_rounded,
        'route': '/contact'
      },
      {
        'title': _isVi ? 'Phản ánh' : 'Feedback',
        'icon': Icons.campaign_rounded,
        'route': '/report'
      },
      {
        'title': _isVi ? 'Chính sách quyền riêng tư' : 'Privacy policy',
        'icon': Icons.privacy_tip_outlined,
        'route': '/privacy'
      },
      {
        'title': _isVi ? 'Điều khoản dịch vụ' : 'Terms of service',
        'icon': Icons.article_outlined,
        'route': '/terms'
      },
      {
        'title': _isVi ? 'Hướng dẫn sử dụng' : 'User guide',
        'icon': Icons.menu_book_rounded,
        'route': '/intruction'
      },
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
        final route = actions[index]['route'] as String?;
        return _buildGlassCard(
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: route == null
                ? null
                : () {
                    if (route == '/report') {
                      Navigator.pushNamed(context, route,
                          arguments: widget.authToken);
                    } else {
                      Navigator.pushNamed(context, route);
                    }
                  },
            borderRadius: BorderRadius.circular(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                route == '/report'
                    ? const AppFeedbackLogo(size: 28)
                    : Icon(
                        actions[index]['icon'] as IconData,
                        color: const Color(0xFFD4AF7A),
                        size: 28,
                      ),
                const SizedBox(height: 12),
                Text(
                  actions[index]['title'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Montserrat'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Center(
          child: Text(
            _isVi
                ? 'Hành trình của bạn là niềm cảm hứng của chúng tôi.'
                : 'Your journey is our inspiration.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white38,
                fontSize: 13,
                fontStyle: FontStyle.italic),
          ),
        ),
        const SizedBox(height: 24),
        _buildGoldButton(
          onPressed: () => Navigator.pushNamed(context, '/contact'),
          text: _isVi ? 'Liên hệ ngay' : 'Contact now',
          icon: Icons.phone_in_talk_rounded,
        ),
      ],
    );
  }

  // --- Helper Methods ---

  Widget _buildGlassCard(
      {required Widget child,
      EdgeInsetsGeometry? padding,
      double borderOpacity = 0.12}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.32),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
                color: Colors.white.withOpacity(borderOpacity), width: 1.2),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGoldButton(
      {required VoidCallback onPressed, required String text, IconData? icon}) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
            colors: [Color(0xFFD4AF7A), Color(0xFFB5956A)]),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: const Color(0xFF1B2321), size: 20),
              const SizedBox(width: 10)
            ],
            Text(
              text,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B2321),
                  letterSpacing: 0.5),
            ),
          ],
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
              border:
                  Border.all(color: Colors.white.withOpacity(0.25), width: 1),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

enum _GuideChatRole { user, assistant }

class _GuideChatMessage {
  final _GuideChatRole role;
  final String content;

  const _GuideChatMessage({
    required this.role,
    required this.content,
  });
}
