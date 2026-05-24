import 'package:flutter/material.dart';

class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;
  final double breakpointTablet;
  final double breakpointDesktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
    this.breakpointTablet = 600.0,
    this.breakpointDesktop = 1000.0,
  });

  /// Kiểm tra xem màn hình hiện tại có phải là Mobile (< 800px) hay không
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 800;
  }

  /// Kiểm tra xem màn hình hiện tại có phải là Desktop/Web (>= 800px) hay không
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 800;
  }

  /// Helper lấy chiều rộng an toàn hoặc giới hạn chiều rộng tối đa cho màn hình lớn
  static double getResponsiveContentWidth(BuildContext context, {double maxW = 500.0}) {
    final w = MediaQuery.of(context).size.width;
    return w >= 800 ? maxW : w;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpointDesktop) {
          return desktop;
        } else if (constraints.maxWidth >= breakpointTablet) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// Widget bọc để biến con trỏ chuột thành hình bàn tay chỉ khi rê chuột qua (cho Web/Desktop)
class WebHoverable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const WebHoverable({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<WebHoverable> createState() => _WebHoverableState();
}

class _WebHoverableState extends State<WebHoverable> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: widget.onTap != null && _isHovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
