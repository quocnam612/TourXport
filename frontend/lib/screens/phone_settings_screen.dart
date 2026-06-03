import 'dart:ui';
import 'package:flutter/material.dart';

import '../api/api.dart';

class PhoneSettingsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String authToken;

  const PhoneSettingsScreen({
    super.key,
    required this.userData,
    required this.authToken,
  });

  @override
  State<PhoneSettingsScreen> createState() => _PhoneSettingsScreenState();
}

class _PhoneSettingsScreenState extends State<PhoneSettingsScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late TextEditingController _phoneController;
  bool _isSaving = false;

  bool get _isVi => Localizations.localeOf(context).languageCode == 'vi';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    final currentPhone = widget.userData['phone'];
    _phoneController = TextEditingController(text: currentPhone is String ? currentPhone : '');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Montserrat')),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFFD4AF7A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _savePhone() async {
    final phone = _phoneController.text.trim();

    if (_isSaving) return;

    if (phone.isEmpty) {
      _showToast(_isVi ? 'Vui lòng nhập số điện thoại.' : 'Please enter your phone number.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final response = await apiPutJson(
        '/auth/profile',
        {'phone': phone},
        token: widget.authToken,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showToast(_isVi ? 'Cập nhật số điện thoại thành công!' : 'Phone number updated successfully!');
        Navigator.pop(context, true);
        return;
      }

      final data = tryDecodeJsonObject(response.body);
      final message = data?['message'] as String?;
      _showToast(message ?? (_isVi ? 'Cập nhật số điện thoại thất bại.' : 'Failed to update phone number.'), isError: true);
    } catch (error) {
      if (!mounted) return;
      _showToast(_isVi ? 'Không kết nối được server. ($error)' : 'Could not connect to the server. ($error)', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1412),
      body: Stack(
        children: [
          _buildHeroBackground(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverAppBar(expandedHeight: 140, backgroundColor: Colors.transparent, elevation: 0, automaticallyImplyLeading: false),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeController,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroHeaderContent(),
                        const SizedBox(height: 32),
                        _buildSectionLabel(_isVi ? 'Số điện thoại' : 'Phone number'),
                        const SizedBox(height: 12),
                        _buildPhoneInputCard(),
                        const SizedBox(height: 48),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: topPadding + 12,
            left: 20,
            child: _glassIconButton(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBackground() {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/halong.jpg', fit: BoxFit.cover),
          Container(decoration: BoxDecoration(color: const Color(0xFF1B2321).withOpacity(0.78))),
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
        ScaleTransition(
          scale: _fadeController,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF7A).withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4AF7A).withOpacity(0.3)),
            ),
            child: const Icon(Icons.phone_android_rounded, color: Color(0xFFD4AF7A), size: 32),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _isVi ? 'Số Điện Thoại' : 'Phone Number',
          style: const TextStyle(fontFamily: 'Montserrat', fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
        ),
        const SizedBox(height: 8),
        Text(
          _isVi ? 'Cập nhật số điện thoại cho tài khoản của bạn' : 'Update the phone number for your account',
          style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, color: Colors.white.withOpacity(0.6), height: 1.5),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(fontFamily: 'Montserrat', fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFD4AF7A), letterSpacing: 1.5),
    );
  }

  Widget _buildPhoneInputCard() {
    return _buildGlassCard(
      child: TextField(
        controller: _phoneController,
        autofocus: true,
        keyboardType: TextInputType.phone,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Montserrat', fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: _isVi ? 'Nhập số điện thoại' : 'Enter phone number',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontFamily: 'Montserrat'),
          prefixIcon: const Icon(Icons.phone_android_rounded, color: Color(0xFFD4AF7A), size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(colors: [Color(0xFFD4AF7A), Color(0xFFB5956A)]),
            boxShadow: [BoxShadow(color: const Color(0xFFD4AF7A).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: ElevatedButton(
            onPressed: _isSaving ? null : _savePhone,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            child: _isSaving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF1B2321)))
                : Text(_isVi ? 'Lưu thay đổi' : 'Save changes', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1B2321))),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_isVi ? 'Hủy bỏ' : 'Cancel', style: TextStyle(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.32),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
          ),
          child: child,
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
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
