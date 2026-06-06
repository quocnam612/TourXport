import 'package:flutter/material.dart';

class AuthContinueButton extends StatelessWidget {
  final bool isLoading;
  final bool isSuccess;
  final bool isError;
  final VoidCallback? onLogin;
  final double s;

  const AuthContinueButton({
    super.key,
    required this.isLoading,
    required this.isSuccess,
    required this.isError,
    required this.onLogin,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onLogin,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50 * s,
        decoration: BoxDecoration(
          color: isSuccess
              ? Colors.green
              : (isError ? Colors.red.withOpacity(0.8) : Colors.black.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: isSuccess
            ? const Icon(Icons.check, color: Colors.white, size: 28)
            : (isError
                ? const Icon(Icons.close, color: Colors.white, size: 28)
                : (isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        'Tiếp tục',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w500,
                          fontSize: 24 * s,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 0.5,
                        ),
                      ))),
      ),
    );
  }
}
