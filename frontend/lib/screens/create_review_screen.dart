import 'dart:ui';

import 'package:flutter/material.dart';

import '../api/api.dart';

class CreateReviewScreen extends StatefulWidget {
  final String locationId;
  final String type; // e.g. "PlaceDB" | "HotelDB" | "RestaurantDB"
  final String? authToken;
  final String? locationName;

  const CreateReviewScreen({
    super.key,
    required this.locationId,
    required this.type,
    this.authToken,
    this.locationName,
  });

  @override
  State<CreateReviewScreen> createState() => _CreateReviewScreenState();
}

class _CreateReviewScreenState extends State<CreateReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _textCtrl = TextEditingController();
  int _rating = 4;
  DateTime? _travelDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _travelDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD4AF7A),
              onPrimary: Colors.black,
              surface: Color(0xFF17211F),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF0F1412),
          ),
          child: child!,
        );
      },
    );
    if (!mounted || picked == null) return;
    setState(() => _travelDate = picked);
  }

  String _formatTravelMonth(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.authToken == null || widget.authToken!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vui lòng đăng nhập để đăng review'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    setState(() => _isSubmitting = true);

    final body = {
      'locationId': widget.locationId,
      'type': widget.type,
      'rating': _rating,
      'travel_date': _travelDate != null ? _formatTravelMonth(_travelDate!) : null,
      'title': _titleCtrl.text.trim(),
      'text': _textCtrl.text.trim(),
    }..removeWhere((key, value) => value == null);

    try {
      final resp = await apiPostJson('/reviews/my-reviews', body, token: widget.authToken);
      if (!mounted) return;
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Đăng review thành công'),
          backgroundColor: Color(0xFF2D6A4F),
        ));
        Navigator.of(context).pop(true);
      } else {
        final err = tryDecodeJsonObject(resp.body);
        final msg = (err?['message'] ?? 'Đăng review thất bại').toString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: Colors.redAccent,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Lỗi kết nối máy chủ'),
        backgroundColor: Colors.redAccent,
      ));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1412),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/login_bg.jpg', fit: BoxFit.cover),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(color: Colors.black.withOpacity(0.68)),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 22),
                          _buildGlassPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionLabel('Điểm đánh giá'),
                                const SizedBox(height: 12),
                                _buildRatingStars(),
                                const SizedBox(height: 22),
                                _sectionLabel('Tháng đi'),
                                const SizedBox(height: 10),
                                _buildDatePickerField(),
                                const SizedBox(height: 22),
                                _sectionLabel('Nội dung nhận xét'),
                                const SizedBox(height: 10),
                                _buildTextField(
                                  controller: _titleCtrl,
                                  label: 'Tiêu đề',
                                  icon: Icons.title_rounded,
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                          ? 'Vui lòng nhập tiêu đề'
                                          : null,
                                ),
                                const SizedBox(height: 14),
                                _buildTextField(
                                  controller: _textCtrl,
                                  label: 'Chia sẻ trải nghiệm của bạn',
                                  icon: Icons.notes_rounded,
                                  minLines: 6,
                                  maxLines: 10,
                                  keyboardType: TextInputType.multiline,
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                          ? 'Vui lòng nhập nội dung'
                                          : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildSubmitButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          _circleButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).pop(false),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Viết nhận xét',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF7A).withOpacity(0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFD4AF7A).withOpacity(0.28)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.rate_review_rounded, color: Color(0xFFD4AF7A), size: 16),
              SizedBox(width: 6),
              Text(
                'TourXport review',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFD4AF7A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          widget.locationName ?? 'Địa điểm này',
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Chia sẻ trải nghiệm thực tế để giúp người khác lên kế hoạch tốt hơn.',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.68),
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassPanel({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildRatingStars() {
    return Row(
      children: [
        ...List.generate(5, (index) {
          final value = index + 1;
          final isSelected = value <= _rating;
          return GestureDetector(
            onTap: () => setState(() => _rating = value),
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                color: const Color(0xFFFFB74D),
                size: 34,
              ),
            ),
          );
        }),
        const SizedBox(width: 8),
        Text(
          '$_rating/5',
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField() {
    final hasDate = _travelDate != null;
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: Color(0xFFD4AF7A), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasDate ? _formatTravelMonth(_travelDate!) : 'Chọn tháng đi',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: hasDate ? Colors.white : Colors.white.withOpacity(0.48),
                ),
              ),
            ),
            Icon(Icons.expand_more_rounded, color: Colors.white.withOpacity(0.55)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      cursorColor: const Color(0xFFD4AF7A),
      style: const TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 13,
          color: Colors.white.withOpacity(0.52),
        ),
        prefixIcon: Icon(icon, color: const Color(0xFFD4AF7A), size: 20),
        filled: true,
        fillColor: Colors.black.withOpacity(0.22),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD4AF7A), width: 1.3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD4AF7A),
          disabledBackgroundColor: Colors.white.withOpacity(0.14),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 19),
                  SizedBox(width: 8),
                  Text(
                    'Gửi nhận xét',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Colors.white.withOpacity(0.46),
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.24),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
