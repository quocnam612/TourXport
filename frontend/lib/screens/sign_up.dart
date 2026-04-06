import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final s = screenW / 412;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // ── Overlay gradient (top: 107) — dùng gradient thay solid để bớt chìm
          Positioned(
            left: 0,
            right: 0,
            top: 107 * s,
            height: 832 * s,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1C302D).withOpacity(0.55),
                    const Color(0xFF1C302D).withOpacity(0.82),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
            ),
          ),

          // ── Scrollable content
          SingleChildScrollView(
            child: SizedBox(
              width: screenW,
              child: Stack(
                children: [
                  SizedBox(height: screenH),

                  // ── Title "Tạo tài khoản" (top: 123)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 123 * s,
                    child: Center(
                      child: Text(
                        'Tạo tài khoản',
                        style: TextStyle(
                          fontFamily: 'Numans',
                          fontWeight: FontWeight.w400,
                          fontSize: 35 * s,
                          letterSpacing: 0.175,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // ── Họ tên (top: 164)
                  Positioned(
                    left: 14 * s,
                    right: 14 * s,
                    top: 164 * s,
                    height: 79 * s,
                    child: _buildField(
                      label: 'Họ tên',
                      hint: 'Nguyen Van A',
                      controller: _nameController,
                      s: s,
                    ),
                  ),

                  // ── Số điện thoại (top: 261)
                  Positioned(
                    left: 16 * s,
                    right: 16 * s,
                    top: 261 * s,
                    height: 79 * s,
                    child: _buildField(
                      label: 'Số điện thoại',
                      hint: '0123456789',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      s: s,
                    ),
                  ),

                  // ── Địa chỉ Email (top: 358)
                  Positioned(
                    left: 16 * s,
                    right: 16 * s,
                    top: 358 * s,
                    height: 79 * s,
                    child: _buildField(
                      label: 'Địa chỉ Email',
                      hint: 'abc@gmail.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      s: s,
                    ),
                  ),

                  // ── Mật khẩu (top: 457)
                  Positioned(
                    left: 14 * s,
                    right: 14 * s,
                    top: 457 * s,
                    height: 79 * s,
                    child: _buildField(
                      label: 'Mật khẩu',
                      hint: 'abc123',
                      controller: _passwordController,
                      isPassword: true,
                      obscure: _obscurePassword,
                      onToggleObscure: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      s: s,
                    ),
                  ),

                  // ── Xác nhận mật khẩu (top: 555)
                  Positioned(
                    left: 16 * s,
                    right: 16 * s,
                    top: 555 * s,
                    height: 79 * s,
                    child: _buildField(
                      label: 'Xác nhận mật khẩu',
                      hint: 'abc123',
                      controller: _confirmController,
                      isPassword: true,
                      obscure: _obscureConfirm,
                      onToggleObscure: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      eyeOpen: true,
                      s: s,
                    ),
                  ),

                  // ── Terms text (top: 650)
                  Positioned(
                    left: 24 * s,
                    right: 24 * s,
                    top: 650 * s,
                    child: Text(
                      'Bằng việc tiếp tục, bạn đồng ý với Điều khoản dịch vụ của TourXport và Chính sách quyền riêng tư.',
                      style: TextStyle(
                        fontFamily: 'Numans',
                        fontWeight: FontWeight.w400,
                        fontSize: 12 * s,
                        letterSpacing: 0.12,
                        color: const Color(0xFFE8DDDD).withOpacity(0.85),
                        height: 14 / 12,
                      ),
                    ),
                  ),

                  // ── Đăng ký button (top: 694)
                  Positioned(
                    left: 14 * s,
                    right: 14 * s,
                    top: 694 * s,
                    height: 50 * s,
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Đăng ký',
                          style: TextStyle(
                            fontFamily: 'Numans',
                            fontWeight: FontWeight.w400,
                            fontSize: 24 * s,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Divider "Hoặc" (top: 759)
                  Positioned(
                    left: 16 * s,
                    right: 16 * s,
                    top: 759 * s,
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white.withOpacity(0.4),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10 * s),
                          child: Text(
                            'Hoặc',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                              fontSize: 15 * s,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white.withOpacity(0.4),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Social buttons (top: 802)
                  Positioned(
                    left: 10 * s,
                    right: 10 * s,
                    top: 802 * s,
                    height: 70 * s,
                    child: Row(
                      children: [
                        _buildSocialBtn(
                          label: 'Đăng kí với Google',
                          iconAsset: 'assets/icons/gg_logo.png',
                          s: s,
                        ),
                        SizedBox(width: 10 * s),
                        _buildSocialBtn(
                          label: 'Đăng kí với Facebook',
                          iconAsset: 'assets/icons/fb_logo.png',
                          s: s,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Input field widget
  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    bool obscure = true,
    bool eyeOpen = false,
    VoidCallback? onToggleObscure,
    TextInputType keyboardType = TextInputType.text,
    required double s,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Numans',
            fontWeight: FontWeight.w400,
            fontSize: 16 * s,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 6 * s),
        // Input box
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: TextField(
              controller: controller,
              obscureText: isPassword && obscure,
              keyboardType: keyboardType,

              /// 🔥 FIX 1: căn giữa vertical
              textAlignVertical: TextAlignVertical.center,

              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18 * s,
                color: Colors.white,
                height: 1.2, // 🔥 giúp cân đẹp hơn
              ),

              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18 * s,
                  color: Colors.white.withOpacity(0.5),
                  height: 1.2,
                ),

                /// 🔥 FIX 2: padding chuẩn
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20 * s,
                  vertical: 14 * s, // ⭐ QUAN TRỌNG NHẤT
                ),

                border: InputBorder.none,

                /// 🔥 FIX 3: icon không phá layout
                suffixIcon: isPassword
                    ? Padding(
                        padding: EdgeInsets.only(right: 8 * s),
                        child: IconButton(
                          icon: Icon(
                            obscure
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white.withOpacity(0.6),
                            size: 22 * s,
                          ),
                          onPressed: onToggleObscure,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Social button widget
  Widget _buildSocialBtn({
    required String label,
    required String iconAsset,
    required double s,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(iconAsset, width: 26 * s, height: 26 * s),
            SizedBox(height: 4 * s),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w300,
                fontSize: 13 * s,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}