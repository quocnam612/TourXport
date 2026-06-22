import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final String label;
  final double s;
  final String? iconAsset;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.label,
    required this.s,
    this.iconAsset,
    this.icon,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.05),
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
                if (iconAsset != null)
                  Image.asset(iconAsset!, width: 26 * s, height: 26 * s)
                else
                  Icon(icon ?? Icons.login_rounded, size: 26 * s, color: Colors.white),
                SizedBox(height: 4 * s),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w300,
                        fontSize: 13 * s,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
