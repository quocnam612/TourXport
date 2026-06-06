import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/auth_storage.dart';
import '../utils/auth_feedback.dart';

enum PinMode { setup, verify }

class PinLockScreen extends StatefulWidget {
  final PinMode mode;

  const PinLockScreen({super.key, this.mode = PinMode.verify});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _enteredPin = '';
  String? _setupFirstPin;
  String? _expectedPin;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpectedPin();
  }

  Future<void> _loadExpectedPin() async {
    if (widget.mode == PinMode.verify) {
      final pin = await AuthStorage.getAppPin();
      if (pin == null || pin.isEmpty) {
        // Should not happen, but if it does, just dismiss
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

  void _processPin() async {
    if (widget.mode == PinMode.verify) {
      if (_enteredPin == _expectedPin) {
        Navigator.pop(context, true); // Success
      } else {
        setState(() {
          _enteredPin = '';
        });
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
          // Save and pop
          await AuthStorage.setAppPin(_enteredPin);
          if (mounted) {
            showAuthSuccessToast(context, 'Thiết lập mã PIN thành công');
            Navigator.pop(context, true);
          }
        } else {
          setState(() {
            _setupFirstPin = null;
            _enteredPin = '';
          });
          showAuthErrorToast(context, 'Mã PIN xác nhận không khớp. Vui lòng nhập lại từ đầu.');
        }
      }
    }
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
            // Background
            Positioned.fill(
              child: Image.asset(
                'assets/images/background_image.png', // Replace with your standard background
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A1A2E)),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.black.withOpacity(0.5)),
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
                  Icon(Icons.lock_outline, size: 48, color: Colors.white.withOpacity(0.9)),
                  const SizedBox(height: 24),
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
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      bool isFilled = index < _enteredPin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled ? Colors.white : Colors.transparent,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  // Numpad
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        _buildNumRow(['1', '2', '3']),
                        const SizedBox(height: 24),
                        _buildNumRow(['4', '5', '6']),
                        const SizedBox(height: 24),
                        _buildNumRow(['7', '8', '9']),
                        const SizedBox(height: 24),
                        _buildNumRow(['', '0', 'delete']),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumRow(List<String> items) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: items.map((item) {
        if (item.isEmpty) return const SizedBox(width: 70, height: 70);
        if (item == 'delete') {
          return _buildButton(
            child: const Icon(Icons.backspace_outlined, color: Colors.white, size: 28),
            onTap: _onDeletePressed,
          );
        }
        return _buildButton(
          child: Text(
            item,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
          onTap: () => _onDigitPressed(item),
        );
      }).toList(),
    );
  }

  Widget _buildButton({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
