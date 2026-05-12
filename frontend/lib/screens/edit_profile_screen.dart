import 'dart:ui';
import 'package:flutter/material.dart';
import 'email_settings_screen.dart';
import 'phone_settings_screen.dart';
import '../api/api.dart';
import '../models/destination.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String authToken;

  const EditProfileScreen({
    super.key,
    required this.userData,
    required this.authToken,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> with TickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  
  String _gender = 'Nam';
  DateTime? _birthday;
  String _travelStyle = 'Sang trọng';
  final List<String> _selectedInterests = ['Nhiếp ảnh', 'Sang trọng', 'Văn hóa'];
  
  bool _isLoading = false;
  late AnimationController _scrollController;
  late AnimationController _fadeController;

  final List<String> _travelStyles = [
    'Phiêu lưu', 'Sang trọng', 'Phượt', 'Thiên nhiên', 'Nhiếp ảnh', 'Văn hóa', 'Du lịch một mình'
  ];

  final List<String> _interestOptions = [
    'Núi non', 'Biển đảo', 'Leo núi', 'Cắm trại', 'Ẩm thực', 'Cà phê', 'Nhiếp ảnh', 'Khám phá'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name'] ?? '');
    _usernameController = TextEditingController(text: widget.userData['username'] ?? 'traveler_2025');
    _bioController = TextEditingController(text: widget.userData['bio'] ?? 'Khám phá thế giới qua những điểm đến sang trọng.');
    _emailController = TextEditingController(text: widget.userData['email'] ?? '');
    _phoneController = TextEditingController(text: widget.userData['phone'] ?? '');
    
    _scrollController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    
    _birthday = DateTime(1995, 8, 15);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    
    try {
      final response = await apiPutJson(
        '/auth/profile',
        {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'bio': _bioController.text.trim(),
        },
        token: widget.authToken,
      );

      if (response.statusCode == 200) {
        if (mounted) {
          _showSuccessOverlay();
        }
      }
    } catch (e) {
      _showSnackBar('Lỗi kết nối máy chủ');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessOverlay() {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) => Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF7A),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF7A).withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Cập nhật thành công',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // After 2 seconds, close dialog AND screen
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // Pop the dialog first if it's still showing
        Navigator.of(context, rootNavigator: true).pop();
        // Then pop the edit screen
        Navigator.of(context).pop(true);
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Montserrat')),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2A4A3E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F1412),
      body: Stack(
        children: [
          // Background Hero Image
          _buildHeroBackground(),
          
          // Main Scrollable Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeController,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    child: Column(
                      children: [
                        _buildProfileHeaderInfo(),
                        const SizedBox(height: 32),
                        _buildSectionHeader('Thông tin cơ bản'),
                        const SizedBox(height: 16),
                        _buildBasicInfoCard(),
                        const SizedBox(height: 32),
                        _buildSectionHeader('Phong cách du lịch'),
                        const SizedBox(height: 16),
                        _buildTravelStyleCard(),
                        const SizedBox(height: 32),
                        _buildSectionHeader('Sở thích khám phá'),
                        const SizedBox(height: 16),
                        _buildInterestsCard(),
                        const SizedBox(height: 32),
                        _buildSectionHeader('Liên kết mạng xã hội'),
                        const SizedBox(height: 16),
                        _buildSocialLinksCard(),
                        const SizedBox(height: 48),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // EXACT SAME TOP ACTION BAR POSITION AS PROFILE
          Positioned(
            top: topPadding + 12,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _glassIconButton(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
              ],
            ),
          ),
          
          // Sticky Bottom Gradient for depth
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, const Color(0xFF0F1412).withOpacity(0.8)],
                ),
              ),
            ),
          ),
        ],
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
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBackground() {
    final String coverUrl = widget.userData['coverUrl'] ?? '';
    final screenW = MediaQuery.of(context).size.width;
    
    return Container(
      height: 440,
      width: screenW,
      child: Stack(
        fit: StackFit.expand,
        children: [
          coverUrl.isNotEmpty
              ? Image.network(coverUrl, fit: BoxFit.cover)
              : Image.asset(
                  'assets/images/ha_long_bay_sailing.jpg',
                  fit: BoxFit.cover,
                ),
          // Layered Atmospheric Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  const Color(0xFF1B2321).withOpacity(0.4),
                  const Color(0xFF1B2321).withOpacity(0.9),
                  const Color(0xFF1B2321),
                ],
                stops: const [0.0, 0.4, 0.85, 1.0],
              ),
            ),
          ),
          // Soft Top Ambient Glow
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
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

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Avatar with glowing ring
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFD4AF7A), Color(0xFFB5956A), Color(0xFFD4AF7A)],
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F1412),
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(widget.userData['avatarUrl'] ?? 'https://i.pravatar.cc/300'),
                  ),
                ),
              ),
              Positioned(
                bottom: 5,
                right: MediaQuery.of(context).size.width / 2 - 60,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF7A),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF0F1412), width: 3),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeaderInfo() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Text(
          _nameController.text,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            _bioController.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF7A),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoCard() {
    return _buildGlassCard(
      child: Column(
        children: [
          _buildPremiumTextField(
            controller: _nameController,
            label: 'Tên người dùng',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 20),
          _buildPremiumTextField(
            controller: _bioController,
            label: 'Tiểu sử',
            icon: Icons.auto_awesome_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSelectorTile(
                  label: 'Ngày sinh',
                  value: '${_birthday!.day}/${_birthday!.month}/${_birthday!.year}',
                  icon: Icons.calendar_month_outlined,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _birthday!,
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFFD4AF7A),
                            onPrimary: Colors.black,
                            surface: Color(0xFF1B2321),
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (date != null) setState(() => _birthday = date);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSelectorTile(
                  label: 'Giới tính',
                  value: _gender,
                  icon: Icons.wc_rounded,
                  onTap: () {
                    setState(() => _gender = _gender == 'Nam' ? 'Nữ' : 'Nam');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildReadOnlyField(
            label: 'Email',
            value: widget.userData['email'] ?? 'Chưa thiết lập',
            icon: Icons.alternate_email_rounded,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmailSettingsScreen(
                    userData: widget.userData,
                    authToken: widget.authToken,
                  ),
                ),
              );
              if (result == true) {
                // Refresh if needed
              }
            },
          ),
          const SizedBox(height: 20),
          _buildReadOnlyField(
            label: 'Số điện thoại',
            value: widget.userData['phone'] ?? 'Chưa thiết lập',
            icon: Icons.phone_android_rounded,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PhoneSettingsScreen(
                    userData: widget.userData,
                    authToken: widget.authToken,
                  ),
                ),
              );
              if (result == true) {
                // Refresh if needed
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.7), size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFD4AF7A), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildTravelStyleCard() {
    return _buildGlassCard(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _travelStyles.map((style) => _buildChoiceChip(
          label: style,
          isSelected: _travelStyle == style,
          onSelected: (val) => setState(() => _travelStyle = style),
        )).toList(),
      ),
    );
  }

  Widget _buildInterestsCard() {
    return _buildGlassCard(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _interestOptions.map((interest) => _buildInterestChip(
          label: interest,
          isSelected: _selectedInterests.contains(interest),
          onTap: () {
            setState(() {
              if (_selectedInterests.contains(interest)) {
                _selectedInterests.remove(interest);
              } else {
                _selectedInterests.add(interest);
              }
            });
          },
        )).toList(),
      ),
    );
  }

  Widget _buildSocialLinksCard() {
    return _buildGlassCard(
      child: Column(
        children: [
          _buildSocialInput(assetPath: 'assets/icons/ins_logo.png', label: 'Instagram', hint: 'travel_lover_25', color: const Color(0xFFE1306C), padding: 2.0),
          const SizedBox(height: 16),
          _buildSocialInput(assetPath: 'assets/icons/tt_logo.png', label: 'TikTok', hint: '@traveler_vlog', color: Colors.white, padding: 0.0),
          const SizedBox(height: 16),
          _buildSocialInput(assetPath: 'assets/icons/x_logo.png', label: 'X (Twitter)', hint: '@travel_x_2025', color: Colors.white, padding: 2.0),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF7A),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 20,
              shadowColor: const Color(0xFFD4AF7A).withOpacity(0.4),
            ),
            child: _isLoading 
              ? const CircularProgressIndicator(color: Colors.black)
              : const Text(
                  'LƯU THAY ĐỔI',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'HỦY BỎ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }

  // UI Components
  Widget _buildGlassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          floatingLabelStyle: const TextStyle(color: Color(0xFFD4AF7A), fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSelectorTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(icon, color: Colors.white.withOpacity(0.7), size: 16),
                const SizedBox(width: 8),
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip({required String label, required bool isSelected, required Function(bool) onSelected}) {
    return GestureDetector(
      onTap: () => onSelected(!isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF7A) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            fontSize: 13,
            fontFamily: 'Montserrat',
          ),
        ),
      ),
    );
  }

  Widget _buildInterestChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF7A) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected ? [
            BoxShadow(color: const Color(0xFFD4AF7A).withOpacity(0.2), blurRadius: 10)
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white.withOpacity(0.5),
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialInput({
    IconData? icon,
    String? assetPath,
    required String label,
    required String hint,
    required Color color,
    double padding = 0,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: assetPath != null
              ? Image.asset(assetPath, fit: BoxFit.contain)
              : Icon(icon, color: color, size: 40 - (padding * 2)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
              Text(hint, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Icon(Icons.link_rounded, color: Colors.white.withOpacity(0.3), size: 18),
      ],
    );
  }
}
