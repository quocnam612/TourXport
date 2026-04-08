import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'sign_in.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          /// 🌄 Background
          Image.asset(
            'assets/images/halong.jpg',
            fit: BoxFit.cover,
          ),

          /// 🎨 Gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.4, 0.7, 1.0],
                colors: [
                  Color(0x22000000),
                  Color(0x11000000),
                  Color(0x88000000),
                  Color(0xCC000000),
                ],
              ),
            ),
          ),

          /// 📱 Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),

                /// 🔰 Logo + App Name
                Column(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 140,
                      height: 140,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),

                const Spacer(),

                /// 📍 Bottom Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      /// ✨ Title (FIXED đúng Figma)
                      Column(
                        children: const [
                          Text(
                            'KHÁM PHÁ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'VIỆT NAM',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                              shadows: [
                                Shadow(
                                  color: Color(0x88000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      /// 📄 Subtitle
                      const Text(
                        'Tìm điểm đến phù hợp cho bạn\nvới TourXport',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 40),

                      /// 🚀 Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignInScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonDark,
                            foregroundColor: AppColors.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'BẮT ĐẦU NGAY',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}