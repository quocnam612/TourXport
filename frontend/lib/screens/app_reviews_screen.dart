import 'dart:ui';
import 'package:flutter/material.dart';
import '../api/api.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class AppReview {
  final String id;
  final String username;
  final String? avatarUrl;
  final int rating;
  final String title;
  final String content;
  final DateTime? createdAt;

  AppReview({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.rating,
    required this.title,
    required this.content,
    this.createdAt,
  });

  factory AppReview.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] as Map<String, dynamic>?;
    final avatarMap = userMap?['avatar'] as Map<String, dynamic>?;
    return AppReview(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      username: userMap?['username'] ?? json['username'] ?? 'Ẩn danh',
      avatarUrl: avatarMap?['url'] as String?,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      title: json['title'] ?? '',
      content: json['text'] ?? json['content'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class AppReviewsScreen extends StatefulWidget {
  final String? authToken;

  const AppReviewsScreen({
    Key? key,
    required this.authToken,
  }) : super(key: key);

  @override
  State<AppReviewsScreen> createState() => _AppReviewsScreenState();
}

class _AppReviewsScreenState extends State<AppReviewsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _floatingController;

  List<AppReview> _allReviews = [];
  AppReview? _myReview;
  bool _isLoadingAll = true;
  bool _isLoadingMine = false;
  bool _isSubmitting = false;
  String? _loadError;

  // Form state
  int _selectedRating = 0;
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _contentCtrl = TextEditingController();

  bool get _isVi => Localizations.localeOf(context).languageCode == 'vi';
  bool get _isLoggedIn =>
      widget.authToken != null && widget.authToken!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _floatingController.dispose();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  // ─── Data Loading ─────────────────────────────────────────────────────────

  void _loadData() {
    _fetchAllReviews();
    if (_isLoggedIn) {
      setState(() => _isLoadingMine = true);
      _fetchMyReview();
    }
  }

  Future<void> _fetchAllReviews() async {
    setState(() {
      _isLoadingAll = true;
      _loadError = null;
    });
    try {
      final response = await apiGet('/app-reviews?limit=50').timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw Exception('Timeout'),
      );
      if (response.statusCode == 200) {
        final body = tryDecodeJsonObject(response.body);
        if (body != null && body['success'] == true) {
          final data = body['data'];
          if (data is List) {
            setState(() {
              _allReviews =
                  data.map((j) => AppReview.fromJson(j as Map<String, dynamic>)).toList();
            });
          }
        }
      } else {
        setState(() => _loadError = 'Không thể tải đánh giá');
      }
    } catch (e) {
      setState(() => _loadError = 'Lỗi kết nối');
    } finally {
      setState(() => _isLoadingAll = false);
    }
  }

  Future<void> _fetchMyReview() async {
    if (!_isLoggedIn) return;
    setState(() => _isLoadingMine = true);
    try {
      final response = await apiGet(
        '/app-reviews/my-reviews',
        token: widget.authToken,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = tryDecodeJsonObject(response.body);
        if (body != null && body['success'] == true) {
          final data = body['data'];
          if (data is List && data.isNotEmpty) {
            setState(() => _myReview = AppReview.fromJson(data.first as Map<String, dynamic>));
          } else {
            setState(() => _myReview = null);
          }
        }
      }
    } catch (_) {
      setState(() => _myReview = null);
    } finally {
      setState(() => _isLoadingMine = false);
    }
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      _showSnack(_isVi ? 'Vui lòng chọn số sao' : 'Please select a rating',
          isError: true);
      return;
    }
    if (_titleCtrl.text.trim().isEmpty) {
      _showSnack(_isVi ? 'Vui lòng nhập tiêu đề' : 'Please enter a title',
          isError: true);
      return;
    }
    if (_contentCtrl.text.trim().isEmpty) {
      _showSnack(
          _isVi ? 'Vui lòng nhập nội dung đánh giá' : 'Please enter your review',
          isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await apiPostJson(
        '/app-reviews',
        {
          'rating': _selectedRating,
          'title': _titleCtrl.text.trim(),
          'text': _contentCtrl.text.trim(),
        },
        token: widget.authToken,
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 201 || response.statusCode == 200) {
        _titleCtrl.clear();
        _contentCtrl.clear();
        setState(() => _selectedRating = 0);
        _showSnack(_isVi ? 'Đánh giá đã được gửi! 🎉' : 'Review submitted! 🎉');
        _fetchAllReviews();
        _fetchMyReview();
      } else {
        final body = tryDecodeJsonObject(response.body);
        final msg = body?['message'] ?? (_isVi ? 'Gửi thất bại' : 'Submission failed');
        _showSnack(msg.toString(), isError: true);
      }
    } catch (e) {
      _showSnack(_isVi ? 'Lỗi kết nối' : 'Connection error', isError: true);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Montserrat')),
      backgroundColor: isError ? const Color(0xFFE74C3C) : const Color(0xFF2ECC71),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1412),
      body: Stack(
        children: [
          // Background
          _buildBackground(),

          // Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: topPadding + 80)),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeController,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 32),

                        // Average rating summary
                        if (_allReviews.isNotEmpty) ...[
                          _buildRatingSummary(),
                          const SizedBox(height: 32),
                        ],

                        // My review / form
                        _buildSectionLabel(
                            _isVi ? 'Đánh giá của bạn' : 'Your Review'),
                        const SizedBox(height: 16),
                        _buildMyReviewSection(),
                        const SizedBox(height: 40),

                        // All reviews
                        _buildSectionLabel(
                            _isVi ? 'Cộng đồng đánh giá' : 'Community Reviews'),
                        const SizedBox(height: 16),
                        _buildAllReviewsSection(),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Back button
          Positioned(
            top: topPadding + 12,
            left: 20,
            child: _glassIconButton(Icons.arrow_back_ios_new_rounded,
                () => Navigator.pop(context)),
          ),
        ],
      ),
    );
  }

  // ─── Sections ────────────────────────────────────────────────────────────

  Widget _buildBackground() {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/halong.jpg', fit: BoxFit.cover),
          Container(
              decoration:
                  BoxDecoration(color: const Color(0xFF0F1412).withOpacity(0.82))),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    const Color(0xFFD4AF7A).withOpacity(0.12),
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _floatingController,
          builder: (_, __) => Transform.translate(
            offset: Offset(0, -4 * _floatingController.value),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF7A).withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFFD4AF7A).withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF7A).withOpacity(0.1),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: const Icon(Icons.rate_review_rounded,
                  color: Color(0xFFD4AF7A), size: 38),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _isVi ? 'Đánh Giá Ứng Dụng' : 'Rate Our App',
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _isVi
              ? 'Hãy chia sẻ trải nghiệm của bạn và đọc đánh giá từ cộng đồng du lịch.'
              : 'Share your experience and read reviews from our travel community.',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            color: Colors.white.withOpacity(0.55),
            height: 1.7,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSummary() {
    final avg = _allReviews.isEmpty
        ? 0.0
        : _allReviews.map((r) => r.rating).reduce((a, b) => a + b) /
            _allReviews.length;
    final avgStr = avg.toStringAsFixed(1);

    // Distribution per star
    final dist = List<int>.filled(6, 0);
    for (final r in _allReviews) {
      if (r.rating >= 1 && r.rating <= 5) dist[r.rating]++;
    }

    return _buildGlassCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Big score
          Column(
            children: [
              Text(
                avgStr,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFD4AF7A),
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < avg.round() ? Icons.star_rounded : Icons.star_border_rounded,
                    color: const Color(0xFFD4AF7A),
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_allReviews.length} ${_isVi ? 'đánh giá' : 'reviews'}',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.45),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          // Bar chart
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final count = dist[star];
                final fraction =
                    _allReviews.isEmpty ? 0.0 : count / _allReviews.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          color: Colors.white54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFD4AF7A), size: 12),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: fraction,
                            backgroundColor: Colors.white.withOpacity(0.08),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFD4AF7A)),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 20,
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.4),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyReviewSection() {
    if (!_isLoggedIn) {
      return _buildGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF7A).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    color: Color(0xFFD4AF7A), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _isVi
                      ? 'Vui lòng đăng nhập để gửi đánh giá'
                      : 'Please log in to submit a review',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoadingMine) {
      return _buildGlassCard(
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(Color(0xFFD4AF7A)),
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (_myReview != null) {
      return _buildExistingReviewCard(_myReview!);
    }

    return _buildReviewForm();
  }

  Widget _buildExistingReviewCard(AppReview review) {
    return _buildGlassCard(
      padding: const EdgeInsets.all(24),
      borderColor: const Color(0xFF2ECC71),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_circle_outline_rounded,
                    color: Color(0xFF2ECC71), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                _isVi ? 'Bạn đã đánh giá' : 'Your Review',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2ECC71),
                ),
              ),
              const Spacer(),
              _buildStarRow(review.rating, size: 16),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            review.title,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            review.content,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              color: Colors.white.withOpacity(0.65),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewForm() {
    return Column(
      children: [
        // Star rating picker
        _buildGlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                _isVi ? 'Xếp hạng của bạn' : 'Your Rating',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final filled = i < _selectedRating;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRating = i + 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        filled ? Icons.star_rounded : Icons.star_border_rounded,
                        color: filled
                            ? const Color(0xFFD4AF7A)
                            : Colors.white.withOpacity(0.25),
                        size: filled ? 44 : 38,
                      ),
                    ),
                  );
                }),
              ),
              if (_selectedRating > 0) ...[
                const SizedBox(height: 12),
                Text(
                  _ratingLabel(_selectedRating),
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    color: Color(0xFFD4AF7A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Title field
        _buildGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: TextField(
            controller: _titleCtrl,
            maxLength: 100,
            style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Montserrat',
                fontSize: 15),
            decoration: InputDecoration(
              hintText: _isVi ? 'Tiêu đề đánh giá...' : 'Review title...',
              hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontFamily: 'Montserrat'),
              border: InputBorder.none,
              counterStyle: TextStyle(
                  color: Colors.white.withOpacity(0.25),
                  fontFamily: 'Montserrat',
                  fontSize: 11),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Content field
        _buildGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: TextField(
            controller: _contentCtrl,
            maxLength: 1000,
            maxLines: 5,
            style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Montserrat',
                fontSize: 14),
            decoration: InputDecoration(
              hintText: _isVi
                  ? 'Chia sẻ trải nghiệm của bạn...'
                  : 'Share your experience...',
              hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontFamily: 'Montserrat'),
              border: InputBorder.none,
              counterStyle: TextStyle(
                  color: Colors.white.withOpacity(0.25),
                  fontFamily: 'Montserrat',
                  fontSize: 11),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Submit button
        _buildGoldButton(
          onPressed: _isSubmitting ? null : _submitReview,
          text: _isVi ? 'Gửi đánh giá' : 'Submit Review',
          icon: _isSubmitting ? null : Icons.send_rounded,
          isLoading: _isSubmitting,
        ),
      ],
    );
  }

  Widget _buildAllReviewsSection() {
    if (_isLoadingAll) {
      return _buildGlassCard(
        child: const Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(Color(0xFFD4AF7A)),
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (_loadError != null) {
      return _buildGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.cloud_off_rounded,
                  color: Colors.red.withOpacity(0.7), size: 44),
              const SizedBox(height: 12),
              Text(
                _loadError!,
                style: TextStyle(
                    color: Colors.red.withOpacity(0.7),
                    fontFamily: 'Montserrat',
                    fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _fetchAllReviews,
                child: Text(
                  _isVi ? 'Thử lại' : 'Retry',
                  style: const TextStyle(
                      color: Color(0xFFD4AF7A),
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700),
                ),
              )
            ],
          ),
        ),
      );
    }

    if (_allReviews.isEmpty) {
      return _buildGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.reviews_outlined,
                    color: Colors.white.withOpacity(0.2), size: 52),
                const SizedBox(height: 16),
                Text(
                  _isVi
                      ? 'Chưa có đánh giá nào.\nHãy là người đầu tiên!'
                      : 'No reviews yet.\nBe the first to review!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: _allReviews
          .map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildReviewCard(r),
              ))
          .toList(),
    );
  }

  Widget _buildReviewCard(AppReview review) {
    final initials = review.username.isNotEmpty
        ? review.username[0].toUpperCase()
        : '?';
    final timeAgo = _formatTime(review.createdAt);

    return _buildGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4AF7A), Color(0xFFB5956A)],
                  ),
                ),
                child: review.avatarUrl != null && review.avatarUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(review.avatarUrl!,
                            fit: BoxFit.cover))
                    : Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B2321),
                            fontSize: 18,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.username,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _buildStarRow(review.rating, size: 13),
                        const SizedBox(width: 8),
                        if (timeAgo.isNotEmpty)
                          Text(
                            timeAgo,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.35),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            review.title,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            review.content,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              color: Colors.white.withOpacity(0.6),
              height: 1.6,
            ),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String _ratingLabel(int rating) {
    if (_isVi) {
      switch (rating) {
        case 1: return 'Rất tệ 😞';
        case 2: return 'Không hài lòng 😐';
        case 3: return 'Bình thường 😊';
        case 4: return 'Hài lòng 😄';
        case 5: return 'Tuyệt vời! 🌟';
      }
    } else {
      switch (rating) {
        case 1: return 'Terrible 😞';
        case 2: return 'Not satisfied 😐';
        case 3: return 'Okay 😊';
        case 4: return 'Good 😄';
        case 5: return 'Amazing! 🌟';
      }
    }
    return '';
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) {
      return '${dt.day}/${dt.month}/${dt.year}';
    } else if (diff.inDays > 0) {
      return _isVi ? '${diff.inDays} ngày trước' : '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return _isVi ? '${diff.inHours} giờ trước' : '${diff.inHours}h ago';
    } else {
      return _isVi ? 'Vừa xong' : 'Just now';
    }
  }

  Widget _buildStarRow(int rating, {double size = 14}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star_rounded : Icons.star_border_rounded,
          color: const Color(0xFFD4AF7A),
          size: size,
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Color(0xFFD4AF7A),
        letterSpacing: 2.5,
      ),
    );
  }

  Widget _buildGlassCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    double borderOpacity = 0.12,
    Color? borderColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: borderColor?.withOpacity(0.5) ??
                  Colors.white.withOpacity(borderOpacity),
              width: borderColor != null ? 1.5 : 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGoldButton({
    required VoidCallback? onPressed,
    required String text,
    IconData? icon,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: onPressed == null
            ? const LinearGradient(
                colors: [Color(0xFF555555), Color(0xFF444444)])
            : const LinearGradient(
                colors: [Color(0xFFD4AF7A), Color(0xFFB5956A)]),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: const Color(0xFFD4AF7A).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Color(0xFF1B2321)),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: const Color(0xFF1B2321), size: 20),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B2321),
                      fontFamily: 'Montserrat',
                      letterSpacing: 0.4,
                    ),
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
