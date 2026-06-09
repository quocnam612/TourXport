import 'dart:ui';
import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../api/api.dart';
import '../widgets/app_feedback_logo.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class AppFeedback {
  final String id;
  final String username;
  final String? avatarUrl;
  final String reportType;
  final String title;
  final String content;
  final int helpfulVotes;
  final List<String> upvotedBy;
  final bool isUpvoted;
  final String adminReply;
  final List<String> imageUrls;
  final DateTime? createdAt;

  AppFeedback({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.reportType,
    required this.title,
    required this.content,
    required this.helpfulVotes,
    required this.upvotedBy,
    required this.isUpvoted,
    required this.adminReply,
    required this.imageUrls,
    this.createdAt,
  });

  factory AppFeedback.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] as Map<String, dynamic>?;
    final avatarMap = userMap?['avatar'] as Map<String, dynamic>?;
    final images = <String>[];
    final upvotedBy = <String>[];
    final rawImages = json['images'];
    if (rawImages is List) {
      for (final item in rawImages) {
        if (item is Map && item['url'] is String && (item['url'] as String).isNotEmpty) {
          images.add(item['url'] as String);
        }
      }
    }
    final rawUpvotedBy = json['upvotedBy'];
    if (rawUpvotedBy is List) {
      for (final item in rawUpvotedBy) {
        final id = item.toString();
        if (id.isNotEmpty) upvotedBy.add(id);
      }
    }

    return AppFeedback(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      username: userMap?['username'] ?? json['username'] ?? 'Ẩn danh',
      avatarUrl: avatarMap?['url'] as String?,
      reportType: json['reportType']?.toString() ?? 'other',
      title: json['title'] ?? '',
      content: json['text'] ?? json['content'] ?? '',
      helpfulVotes: (json['helpful_votes'] as num?)?.toInt() ?? 0,
      upvotedBy: upvotedBy,
      isUpvoted: json['isUpvoted'] == true,
      adminReply: json['adminReply']?.toString() ?? '',
      imageUrls: images,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  bool isUpvotedBy(String? userId) =>
      isUpvoted || (userId != null && upvotedBy.contains(userId));

  AppFeedback copyWith({
    int? helpfulVotes,
    List<String>? upvotedBy,
    bool? isUpvoted,
  }) {
    return AppFeedback(
      id: id,
      username: username,
      avatarUrl: avatarUrl,
      reportType: reportType,
      title: title,
      content: content,
      helpfulVotes: helpfulVotes ?? this.helpfulVotes,
      upvotedBy: upvotedBy ?? this.upvotedBy,
      isUpvoted: isUpvoted ?? this.isUpvoted,
      adminReply: adminReply,
      imageUrls: imageUrls,
      createdAt: createdAt,
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

  List<AppFeedback> _allReviews = [];
  AppFeedback? _myReview;
  bool _isLoadingAll = true;
  bool _isLoadingMine = false;
  bool _isSubmitting = false;
  String? _loadError;

  // Form state
  String _selectedReportType = 'bug';
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _contentCtrl = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<XFile> _pickedImages = [];

  bool get _isVi => Localizations.localeOf(context).languageCode == 'vi';
  bool get _isLoggedIn =>
      widget.authToken != null && widget.authToken!.trim().isNotEmpty;
  String? get _currentUserId => _userIdFromToken(widget.authToken);
  List<String> get _reportTypeOptions =>
      const ['bug', 'suggestion', 'inaccuracy', 'review', 'other'];

  String? _userIdFromToken(String? token) {
    final parts = token?.split('.');
    if (parts == null || parts.length < 2) return null;

    try {
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final decoded = jsonDecode(payload);
      if (decoded is Map && decoded['id'] != null) {
        return decoded['id'].toString();
      }
    } catch (_) {}

    return null;
  }

  AppFeedback _withCurrentVoteState(AppFeedback feedback) {
    final userId = _currentUserId;
    if (userId == null) return feedback;

    return feedback.copyWith(
      isUpvoted: feedback.isUpvotedBy(userId),
    );
  }

  void _replaceFeedback(AppFeedback feedback) {
    _allReviews = _allReviews
        .map((item) => item.id == feedback.id ? feedback : item)
        .toList();
    if (_myReview?.id == feedback.id) _myReview = feedback;
  }

  AppFeedback _toggledFeedback(AppFeedback feedback) {
    final userId = _currentUserId;
    final wasUpvoted = feedback.isUpvotedBy(userId);
    final nextUpvotedBy = List<String>.from(feedback.upvotedBy);

    if (userId != null) {
      if (wasUpvoted) {
        nextUpvotedBy.removeWhere((id) => id == userId);
      } else if (!nextUpvotedBy.contains(userId)) {
        nextUpvotedBy.add(userId);
      }
    }

    return feedback.copyWith(
      helpfulVotes: wasUpvoted
          ? (feedback.helpfulVotes > 0 ? feedback.helpfulVotes - 1 : 0)
          : feedback.helpfulVotes + 1,
      upvotedBy: nextUpvotedBy,
      isUpvoted: !wasUpvoted,
    );
  }

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
      final response = await apiGet('/reports?limit=50').timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw Exception('Timeout'),
      );
      if (response.statusCode == 200) {
        final body = tryDecodeJsonObject(response.body);
        if (body != null && body['success'] == true) {
          final data = body['data'];
          if (data is List) {
            setState(() {
              _allReviews = data
                  .map((j) => _withCurrentVoteState(
                      AppFeedback.fromJson(j as Map<String, dynamic>)))
                  .toList();
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
        '/reports/my-reports',
        token: widget.authToken,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = tryDecodeJsonObject(response.body);
        if (body != null && body['success'] == true) {
          final data = body['data'];
          if (data is List && data.isNotEmpty) {
            setState(() => _myReview = _withCurrentVoteState(
                AppFeedback.fromJson(data.first as Map<String, dynamic>)));
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
      http.Response response;
      final fields = {
        'reportType': _selectedReportType,
        'title': _titleCtrl.text.trim(),
        'text': _contentCtrl.text.trim(),
      };

      if (_pickedImages.isEmpty) {
        response = await apiPostJson(
          '/reports/my-reports',
          fields,
          token: widget.authToken,
        ).timeout(const Duration(seconds: 12));
      } else {
        final files = <http.MultipartFile>[];
        for (final image in _pickedImages) {
          final bytes = await image.readAsBytes();
          files.add(http.MultipartFile.fromBytes(
            'images',
            bytes,
            filename: image.name,
            contentType: _mediaTypeForFileName(image.name),
          ));
        }
        final streamedResponse = await apiPostMultipart(
          '/reports/my-reports',
          fields: fields,
          files: files,
          token: widget.authToken,
        ).timeout(const Duration(seconds: 20));
        response = await http.Response.fromStream(streamedResponse);
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        _titleCtrl.clear();
        _contentCtrl.clear();
        setState(() {
          _selectedReportType = 'bug';
          _pickedImages.clear();
        });
        _showSnack(_isVi ? 'Phản ánh đã được gửi! 🎉' : 'Report submitted! 🎉');
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

  MediaType _mediaTypeForFileName(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (ext == 'jpg' || ext == 'jpeg') return MediaType('image', 'jpeg');
    if (ext == 'png') return MediaType('image', 'png');
    if (ext == 'webp') return MediaType('image', 'webp');
    return MediaType('application', 'octet-stream');
  }

  Future<void> _pickImage() async {
    if (_pickedImages.length >= 5) {
      _showSnack(_isVi ? 'Chỉ được tải lên tối đa 5 ảnh' : 'Maximum 5 images',
          isError: true);
      return;
    }

    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() => _pickedImages.add(image));
  }

  void _removePickedImage(int index) {
    setState(() => _pickedImages.removeAt(index));
  }

  Future<void> _upvoteFeedback(AppFeedback feedback) async {
    if (!_isLoggedIn) {
      _showSnack(_isVi ? 'Vui lòng đăng nhập để upvote' : 'Please log in to upvote',
          isError: true);
      return;
    }

    final previous = feedback;
    final optimistic = _toggledFeedback(feedback);
    setState(() => _replaceFeedback(optimistic));

    try {
      final response = await apiGet(
        '/reports/upvote?reportId=${Uri.encodeComponent(feedback.id)}',
        token: widget.authToken,
      ).timeout(const Duration(seconds: 10));

      final body = tryDecodeJsonObject(response.body);
      if (response.statusCode == 200 && body?['success'] == true) {
        final updated = _withCurrentVoteState(
          AppFeedback.fromJson(body!['data'] as Map<String, dynamic>),
        );
        setState(() => _replaceFeedback(updated));
      } else {
        setState(() => _replaceFeedback(previous));
        _showSnack(
          (body?['message'] ?? (_isVi ? 'Không thể upvote' : 'Unable to upvote')).toString(),
          isError: true,
        );
      }
    } catch (_) {
      setState(() => _replaceFeedback(previous));
      _showSnack(_isVi ? 'Lỗi kết nối' : 'Connection error', isError: true);
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

                        // Submit feedback
                        _buildSectionLabel(
                            _isVi ? 'Gửi phản ánh' : 'Submit Feedback'),
                        const SizedBox(height: 16),
                        _buildSubmitSection(),
                        const SizedBox(height: 40),

                        if (_isLoggedIn || _isLoadingMine || _myReview != null) ...[
                          _buildSectionLabel(
                              _isVi ? 'Phản ánh của bạn' : 'Your Feedback'),
                          const SizedBox(height: 16),
                          _buildMyReviewSection(),
                          const SizedBox(height: 40),
                        ],

                        // All feedback
                        _buildSectionLabel(
                            _isVi ? 'Phản ánh cộng đồng' : 'Community Feedback'),
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
              child: const AppFeedbackLogo(size: 38),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _isVi ? 'Phản Ánh Ứng Dụng' : 'App Feedback',
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
              ? 'Hãy chia sẻ phản ánh của bạn để giúp chúng tôi cải thiện ứng dụng tốt hơn.'
              : 'Share your feedback to help us improve the app for everyone.',
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

  Widget _buildSubmitSection() {
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
                      ? 'Vui lòng đăng nhập để gửi phản ánh'
                      : 'Please log in to submit feedback',
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

    return _buildReviewForm();
  }

  Widget _buildMyReviewSection() {
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
      return _buildExistingFeedbackCard(_myReview!);
    }

    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Text(
            _isVi
                ? 'Bạn chưa gửi phản ánh nào.'
                : 'You have not submitted feedback yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: Colors.white.withOpacity(0.45),
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExistingFeedbackCard(AppFeedback feedback) {
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
                _isVi ? 'Bạn đã phản ánh' : 'Your Feedback',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2ECC71),
                ),
              ),
              const Spacer(),
              _buildTypeChip(feedback.reportType),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            feedback.title,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            feedback.content,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 13,
              color: Colors.white.withOpacity(0.65),
              height: 1.6,
            ),
          ),
          if (feedback.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildImageStrip(feedback.imageUrls),
          ],
          if (feedback.adminReply.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildAdminReply(feedback.adminReply),
          ],
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: _buildUpvoteButton(feedback),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewForm() {
    return Column(
      children: [
        _buildGlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isVi ? 'Loại phản ánh' : 'Report Type',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedReportType,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1A211E),
                    borderRadius: BorderRadius.circular(16),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFFD4AF7A),
                    ),
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedReportType = value);
                      }
                    },
                    items: _reportTypeOptions.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(
                          _reportTypeLabel(type),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
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
              hintText: _isVi ? 'Tiêu đề phản ánh...' : 'Report title...',
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
                  ? 'Mô tả lỗi, góp ý hoặc nội dung bạn muốn phản ánh...'
                  : 'Describe the issue, suggestion, or feedback...',
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
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _isVi
                ? 'Hình ảnh đính kèm (Tối đa 5 ảnh)'
                : 'Attachments (Maximum 5 photos)',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white.withOpacity(0.46),
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildImagePickerSection(),
        const SizedBox(height: 24),

        // Submit button
        _buildGoldButton(
          onPressed: _isSubmitting ? null : _submitReview,
          text: _isVi ? 'Gửi phản ánh' : 'Submit Feedback',
          icon: _isSubmitting ? null : Icons.send_rounded,
          isLoading: _isSubmitting,
        ),
      ],
    );
  }

  Widget _buildImagePickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _pickedImages.length + 1,
            itemBuilder: (context, index) {
              if (index == _pickedImages.length) {
                if (_pickedImages.length >= 5) {
                  return const SizedBox.shrink();
                }
                return GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 90,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFD4AF7A).withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_photo_alternate_rounded,
                          color: Color(0xFFD4AF7A),
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isVi ? 'Thêm ảnh' : 'Add photo',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD4AF7A),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final img = _pickedImages[index];
              return Container(
                width: 90,
                margin: const EdgeInsets.only(right: 10),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: kIsWeb
                            ? Image.network(img.path, fit: BoxFit.cover)
                            : Image.file(File(img.path), fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removePickedImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (_pickedImages.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _isVi
                ? '${_pickedImages.length}/5 ảnh đã chọn'
                : '${_pickedImages.length}/5 photos selected',
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: Colors.white.withOpacity(0.45),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
                      ? 'Chưa có phản ánh nào.\nHãy là người đầu tiên!'
                      : 'No feedback yet.\nBe the first to share!',
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
                child: _buildFeedbackCard(r),
              ))
          .toList(),
    );
  }

  Widget _buildFeedbackCard(AppFeedback review) {
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
                        _buildTypeChip(review.reportType),
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
              _buildUpvoteButton(review),
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
          if (review.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildImageStrip(review.imageUrls),
          ],
          if (review.adminReply.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildAdminReply(review.adminReply),
          ],
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

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

  String _reportTypeLabel(String type) {
    switch (type) {
      case 'bug':
        return _isVi ? 'Báo lỗi hệ thống' : 'System bug';
      case 'suggestion':
        return _isVi ? 'Góp ý & Đề xuất tính năng' : 'Suggestion & feature request';
      case 'inaccuracy':
        return _isVi ? 'Sai lệch thông tin' : 'Information inaccuracy';
      case 'review':
        return _isVi ? 'Đánh giá trải nghiệm' : 'Experience review';
      default:
        return _isVi ? 'Khác' : 'Other';
    }
  }

  Widget _buildTypeChip(String type) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF7A).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4AF7A).withOpacity(0.25)),
      ),
      child: Text(
        _reportTypeLabel(type),
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 10,
          color: Color(0xFFD4AF7A),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildUpvoteButton(AppFeedback feedback) {
    final isUpvoted = feedback.isUpvotedBy(_currentUserId);

    return GestureDetector(
      onTap: () => _upvoteFeedback(feedback),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isUpvoted
              ? const Color(0xFFD4AF7A).withOpacity(0.16)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUpvoted
                ? const Color(0xFFD4AF7A).withOpacity(0.55)
                : Colors.white.withOpacity(0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isUpvoted
                  ? Icons.thumb_up_alt_rounded
                  : Icons.thumb_up_alt_outlined,
              color: isUpvoted
                  ? const Color(0xFFD4AF7A)
                  : Colors.white.withOpacity(0.52),
              size: 15,
            ),
            const SizedBox(width: 5),
            Text(
              '${feedback.helpfulVotes}',
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: isUpvoted ? const Color(0xFFD4AF7A) : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageStrip(List<String> images) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              images[index],
              width: 86,
              height: 86,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 86,
                height: 86,
                color: Colors.white.withOpacity(0.08),
                child: const Icon(Icons.broken_image_outlined,
                    color: Colors.white38),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdminReply(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF7A).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF7A).withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              width: 34,
              height: 34,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TourXport',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: Color(0xFFD4AF7A),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
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
