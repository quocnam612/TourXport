import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../utils/auth_storage.dart';
import '../utils/auth_feedback.dart';
import '../widgets/pin_numpad.dart';
import 'landing_page.dart';

enum PinMode { setup, verify }

class PinLockScreen extends StatefulWidget {
  final PinMode mode;

  const PinLockScreen({super.key, this.mode = PinMode.verify});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  String? _setupFirstPin;
  String? _expectedPin;
  bool _isLoading = true;
  String? _userName;
  
  // Biometrics
  final LocalAuthentication auth = LocalAuthentication();
  bool _canCheckBiometrics = false;

  // Shake animation
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnimation = Tween<double>(begin: 0, end: 24)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _shakeController.reset();
        }
      });
      
    _checkBiometrics();
    _loadExpectedPin();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final name = await AuthStorage.getUserName();
    if (mounted) {
      setState(() {
        _userName = name;
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    if (widget.mode == PinMode.verify) {
      bool canCheck = await auth.canCheckBiometrics;
      bool isSupported = await auth.isDeviceSupported();
      if (mounted) {
        setState(() {
          _canCheckBiometrics = canCheck || isSupported;
        });
      }
      
      if (_canCheckBiometrics) {
        _authenticateBiometrics();
      }
    }
  }

  Future<void> _authenticateBiometrics() async {
    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Xác thực để truy cập ứng dụng',
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );
      if (authenticated && mounted) {
        Navigator.pop(context, true); // Success
      }
    } catch (e) {
      debugPrint('Lỗi xác thực sinh trắc học: $e');
    }
  }

  Future<void> _loadExpectedPin() async {
    if (widget.mode == PinMode.verify) {
      final pin = await AuthStorage.getAppPin();
      if (pin == null || pin.isEmpty) {
        if (mounted) Navigator.pop(context, true);
        return;
      }
      _expectedPin = pin;
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onDigitPressed(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
      });
      
      if (_enteredPin.length == 4) {
        Future.delayed(const Duration(milliseconds: 200), _processPin);
      }
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _triggerError() {
    HapticFeedback.vibrate();
    _shakeController.forward();
    setState(() {
      _enteredPin = '';
    });
  }

  void _processPin() async {
    if (widget.mode == PinMode.verify) {
      if (_enteredPin == _expectedPin) {
        Navigator.pop(context, true); // Success
      } else {
        _triggerError();
        showAuthErrorToast(context, 'Mã PIN không đúng, vui lòng thử lại.');
      }
    } else if (widget.mode == PinMode.setup) {
      if (_setupFirstPin == null) {
        setState(() {
          _setupFirstPin = _enteredPin;
          _enteredPin = '';
        });
      } else {
        if (_enteredPin == _setupFirstPin) {
          await AuthStorage.setAppPin(_enteredPin);
          if (mounted) {
            showAuthSuccessToast(context, 'Thiết lập mã PIN thành công');
            Navigator.pop(context, true);
          }
        } else {
          _triggerError();
          setState(() {
            _setupFirstPin = null;
          });
          showAuthErrorToast(context, 'Mã PIN xác nhận không khớp. Vui lòng nhập lại từ đầu.');
        }
      }
    }
  }

  void _showForgotPinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Quên mã PIN?', style: TextStyle(color: Colors.white, fontFamily: 'Montserrat')),
        content: const Text(
          'Để thiết lập lại mã PIN, bạn cần đăng xuất và đăng nhập lại. Ứng dụng sẽ xóa mã PIN cũ.',
          style: TextStyle(color: Colors.white70, fontFamily: 'Montserrat'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthStorage.removeAppPin(); // Xóa mã PIN hiện tại
              await AuthStorage.clearSession(); // Đăng xuất
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LandingPage()),
                  (route) => false,
                );
              }
            },
            child: const Text('Đồng ý', style: TextStyle(color: Color(0xFFD4AF7A))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    String title = 'Nhập mã PIN';
    if (widget.mode == PinMode.setup) {
      title = _setupFirstPin == null ? 'Tạo mã PIN mới' : 'Xác nhận lại mã PIN';
    }

    return WillPopScope(
      onWillPop: () async => widget.mode == PinMode.setup,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/background_image.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A1A2E)),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(color: Colors.black.withOpacity(0.6)),
              ),
            ),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.mode == PinMode.setup)
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                    ),
                  const Spacer(),
                  if (_userName != null) ...[
                    const CircleAvatar(
                      radius: 32,
                      backgroundColor: Color(0xFFD4AF7A),
                      child: Icon(Icons.person, size: 36, color: Color(0xFF1B2321)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Xin chào, $_userName',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    Icon(Icons.lock_outline, size: 48, color: Colors.white.withOpacity(0.9)),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Dots with Shake Animation
                  AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      final offset = sin(_shakeAnimation.value * pi) * 10;
                      return Transform.translate(
                        offset: Offset(offset, 0),
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        bool isFilled = index < _enteredPin.length;
                        bool isError = _shakeController.isAnimating;
                        Color dotColor = isError ? Colors.redAccent : Colors.white;
                        
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFilled ? dotColor : Colors.transparent,
                            border: Border.all(color: dotColor, width: 2),
                          ),
                        );
                      }),
                    ),
                  ),
                  const Spacer(),
                  // Numpad Widget
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: PinNumpad(
                      onDigitPressed: _onDigitPressed,
                      onDeletePressed: _onDeletePressed,
                      onBiometricsPressed: _authenticateBiometrics,
                      showBiometrics: _canCheckBiometrics,
                    ),
                  ),
                  const Spacer(),
                  if (widget.mode == PinMode.verify)
                    TextButton(
                      onPressed: _showForgotPinDialog,
                      child: const Text(
                        'Quên mã PIN?',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          color: Colors.white70,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  if (widget.mode == PinMode.setup) const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
