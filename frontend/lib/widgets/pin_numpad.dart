import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinNumpad extends StatelessWidget {
  final Function(String) onDigitPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback onBiometricsPressed;
  final bool showBiometrics;

  const PinNumpad({
    super.key,
    required this.onDigitPressed,
    required this.onDeletePressed,
    required this.onBiometricsPressed,
    this.showBiometrics = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildNumRow(['1', '2', '3']),
        const SizedBox(height: 24),
        _buildNumRow(['4', '5', '6']),
        const SizedBox(height: 24),
        _buildNumRow(['7', '8', '9']),
        const SizedBox(height: 24),
        _buildNumRow(['biometrics', '0', 'delete']),
      ],
    );
  }

  Widget _buildNumRow(List<String> items) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: items.map((item) {
        if (item == 'biometrics') {
          if (!showBiometrics) return const SizedBox(width: 70, height: 70);
          return _buildButton(
            child: const Icon(Icons.fingerprint, color: Colors.white, size: 36),
            onTap: onBiometricsPressed,
          );
        }
        if (item == 'delete') {
          return _buildButton(
            child: const Icon(Icons.backspace_outlined, color: Colors.white, size: 28),
            onTap: () {
              HapticFeedback.lightImpact();
              onDeletePressed();
            },
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
          onTap: () {
            HapticFeedback.lightImpact();
            onDigitPressed(item);
          },
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
