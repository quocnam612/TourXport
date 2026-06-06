import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final bool obscurePassword;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final void Function()? onEditingComplete;
  final double s;
  final FocusNode? focusNode;
  final Animation<double>? shakeAnimation;
  final bool capsLockOn;
  final VoidCallback? onToggleObscure;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.obscurePassword = true,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.inputFormatters,
    this.onEditingComplete,
    required this.s,
    this.focusNode,
    this.shakeAnimation,
    this.capsLockOn = false,
    this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w400,
            fontSize: 16 * s,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 6 * s),
        // Input box
        Container(
          height: 50 * s,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: isPassword && obscurePassword,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            inputFormatters: inputFormatters,
            onEditingComplete: onEditingComplete,
            textAlignVertical: TextAlignVertical.center,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18 * s,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18 * s,
                color: Colors.white.withOpacity(0.5),
              ),
              contentPadding: EdgeInsets.only(
                left: 20 * s,
                right: 20 * s,
                top: 12 * s,
                bottom: 16 * s,
              ),
              border: InputBorder.none,
              suffixIcon: isPassword
                  ? Padding(
                      padding: EdgeInsets.only(right: 8 * s),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (capsLockOn)
                            Padding(
                              padding: EdgeInsets.only(right: 4 * s),
                              child: Tooltip(
                                message: 'Caps Lock đang bật',
                                child: Icon(Icons.keyboard_capslock, color: Colors.amber, size: 20 * s),
                              ),
                            ),
                          IconButton(
                            focusNode: FocusNode(skipTraversal: true),
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: child,
                                );
                              },
                              child: Icon(
                                obscurePassword ? Icons.visibility_off : Icons.visibility,
                                key: ValueKey<bool>(obscurePassword),
                                color: Colors.white.withOpacity(0.6),
                                size: 22 * s,
                              ),
                            ),
                            onPressed: onToggleObscure,
                          ),
                        ],
                      ),
                    )
                  : ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller,
                      builder: (context, value, _) {
                        return value.text.isNotEmpty
                            ? IconButton(
                                focusNode: FocusNode(skipTraversal: true),
                                icon: Icon(Icons.clear, size: 20 * s, color: Colors.white70),
                                onPressed: () => controller.clear(),
                              )
                            : const SizedBox.shrink();
                      },
                    ),
            ),
          ),
        ),
      ],
    );

    if (shakeAnimation != null) {
      return AnimatedBuilder(
        animation: shakeAnimation!,
        builder: (context, child) {
          final dx = sin(shakeAnimation!.value * 4 * pi) * 8;
          return Transform.translate(
            offset: Offset(dx, 0),
            child: child,
          );
        },
        child: child,
      );
    }

    return child;
  }
}
