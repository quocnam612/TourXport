import 'package:flutter/material.dart';
import 'sign_up.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _useEmail = true;
  bool _obscurePassword = true;
  final _inputController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
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

          // ── Dark overlay panel (top: 227)
          Positioned(
            left: 0,
            right: 0,
            top: 227 * s,
            height: 712 * s,
            child: Container(
              decoration: BoxDecoration(
                // FIX: giảm opacity từ 0.72 → 0.60 để bớt tối,
                // thêm gradient để phần trên thoáng hơn
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1C302D).withOpacity(0.55),
                    const Color(0xFF1C302D).withOpacity(0.80),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
            ),
          ),

          SingleChildScrollView(
            child: SizedBox(
              height: screenH,
              child: Stack(
                children: [

                  // ── Title "Đăng nhập" (top: 248)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 248 * s,
                    child: Center(
                      child: Text(
                        'Đăng nhập',
                        style: TextStyle(
                          fontFamily: 'Numans',
                          fontWeight: FontWeight.w400,
                          fontSize: 35 * s,
                          letterSpacing: 0.35,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // ── Tab: Điện thoại / Email (top: 305)
                  Positioned(
                    left: 16 * s,
                    right: 16 * s,
                    top: 305 * s,
                    height: 50 * s,
                    child: Stack(
                      children: [
                        // Nền tối
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(40),
                            ),
                          ),
                        ),
                        // Pill trắng active
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 200),
                          left: _useEmail ? (380 * s / 2) + 5 : 5,
                          top: 5,
                          width: (380 * s / 2) - 5,
                          height: 40 * s,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 4,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Điện thoại label
                        Positioned(
                          left: 0,
                          width: 380 * s / 2,
                          top: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: () => setState(() => _useEmail = false),
                            child: Center(
                              child: Text(
                                'Điện thoại',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18 * s,
                                  color: _useEmail
                                      ? Colors.white
                                      : const Color(0xFF1C302D),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Email label
                        Positioned(
                          left: 380 * s / 2,
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: () => setState(() => _useEmail = true),
                            child: Center(
                              child: Text(
                                'Email',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18 * s,
                                  color: _useEmail
                                      ? const Color(0xFF1C302D)
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Email / Phone field (top: 376)
                  // FIX: tăng bgOpacity lên 0.18 (trước là 0.05) để field rõ hơn
                  Positioned(
                    left: 16 * s,
                    right: 16 * s,
                    top: 376 * s,
                    height: 79 * s,
                    child: _buildField(
                      label: _useEmail ? 'Địa chỉ Email' : 'Số điện thoại',
                      hint: _useEmail ? 'abc@gmail.com' : '0123456789',
                      controller: _inputController,
                      keyboardType: _useEmail
                          ? TextInputType.emailAddress
                          : TextInputType.phone,
                      bgOpacity: 0.18,
                      s: s,
                    ),
                  ),

                  // ── Password field (top: 469)
                  // FIX: tăng bgOpacity lên 0.18 đồng nhất với email field
                  Positioned(
                    left: 16 * s,
                    right: 16 * s,
                    top: 469 * s,
                    height: 79 * s,
                    child: _buildField(
                      label: 'Mật khẩu',
                      hint: '123abc',
                      controller: _passwordController,
                      isPassword: true,
                      bgOpacity: 0.18,
                      s: s,
                    ),
                  ),

                  // ── Tiếp tục button (top: 581)
                  Positioned(
                    left: 17 * s,
                    right: 17 * s,
                    top: 581 * s,
                    height: 50 * s,
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(40),
                          // FIX: thêm border mờ để nổi bật hơn
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Tiếp tục',
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

                  // ── Divider "Đăng nhập bằng" (top: 648)
                  Positioned(
                    left: 16 * s,
                    right: 16 * s,
                    top: 648 * s,
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
                            'Đăng nhập bằng',
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

                  // ── Social buttons (top: 691)
                  Positioned(
                    left: 16 * s,
                    right: 16 * s,
                    top: 691 * s,
                    height: 70 * s,
                    child: Row(
                      children: [
                        _buildSocialBtn(
                          label: 'Tiếp tục với Google',
                          iconAsset: 'assets/icons/gg_logo.png',
                          s: s,
                        ),
                        SizedBox(width: 10 * s),
                        _buildSocialBtn(
                          label: 'Tiếp tục với Facebook',
                          iconAsset: 'assets/icons/fb_logo.png',
                          s: s,
                        ),
                      ],
                    ),
                  ),

                  // ── "Bạn chưa có tài khoản?" (top: 782)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 782 * s,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Bạn chưa có tài khoản? ',
                          style: TextStyle(
                            fontFamily: 'Numans',
                            fontWeight: FontWeight.w400,
                            fontSize: 15 * s,
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignUpScreen(),
                            ),
                          ),
                          child: Text(
                            'Đăng ký',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 15 * s,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Tagline (top: 833)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 833 * s,
                    child: Text(
                      '"Hạnh phúc không phải là điểm đến\nmà là cả một hành trình."',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Numans',
                        fontWeight: FontWeight.w400,
                        fontSize: 14 * s,
                        letterSpacing: 0.1 * 14,
                        color: Colors.white.withOpacity(0.75),
                        height: 16 / 14,
                        fontStyle: FontStyle.italic,
                      ),
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
    TextInputType keyboardType = TextInputType.text,
    required double bgOpacity,
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
              // FIX: dùng màu trắng rõ hơn + thêm border để field nổi
              color: Colors.white.withOpacity(bgOpacity),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: TextField(
              controller: controller,
              obscureText: isPassword && _obscurePassword,
              keyboardType: keyboardType,

              /// 🔥 FIX 1: căn giữa theo chiều dọc
              textAlignVertical: TextAlignVertical.center,

              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18 * s,
                color: Colors.white,
              ),

              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18 * s,
                  color: Colors.white.withOpacity(0.5),
                ),

                /// 🔥 FIX 2: padding chuẩn để center
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20 * s,
                  vertical: 14 * s, // ⭐ QUAN TRỌNG
                ),

                border: InputBorder.none,

                /// 🔥 FIX 3: giữ icon không phá layout
                suffixIcon: isPassword
                    ? Padding(
                        padding: EdgeInsets.only(right: 8 * s),
                        child: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white.withOpacity(0.6),
                            size: 22 * s,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
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
          // FIX: tăng opacity lên 0.15 để nút social rõ hơn
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