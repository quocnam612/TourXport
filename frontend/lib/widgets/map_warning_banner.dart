import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/navigation_helper.dart';

class MapWarningBanner extends StatelessWidget {
  final String? manualStartLocationName;
  final VoidCallback onDismiss;
  final VoidCallback onManualInputTap;
  final VoidCallback onEnableGPSTap;

  const MapWarningBanner({
    super.key,
    required this.manualStartLocationName,
    required this.onDismiss,
    required this.onManualInputTap,
    required this.onEnableGPSTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1E1B).withValues(alpha: 0.85), // Kính tối mờ
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = MediaQuery.of(context).size.width < 500;
              if (isNarrow) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_off_rounded,
                          color: Color(0xFFD4AF7A),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                manualStartLocationName != null
                                    ? 'Vị trí bắt đầu thủ công'
                                    : 'Dịch vụ định vị đang tắt',
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                manualStartLocationName != null
                                    ? 'Từ: ${NavigationHelper.splitAddress(manualStartLocationName!)['title']}'
                                    : 'Nhấp để bật GPS hoặc tự nhập vị trí.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.white.withValues(alpha: 0.4),
                            size: 18,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: onDismiss,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: onManualInputTap,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.06),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text(
                            'Nhập vị trí',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: onEnableGPSTap,
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF7A).withValues(alpha: 0.15),
                            foregroundColor: const Color(0xFFD4AF7A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text(
                            'Bật GPS',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    const Icon(
                      Icons.location_off_rounded,
                      color: Color(0xFFD4AF7A),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            manualStartLocationName != null
                                ? 'Vị trí bắt đầu thủ công'
                                : 'Dịch vụ định vị đang tắt',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            manualStartLocationName != null
                                ? 'Từ: ${NavigationHelper.splitAddress(manualStartLocationName!)['title']}'
                                : 'Nhấp để bật GPS hoặc tự nhập vị trí.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: onManualInputTap,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      child: const Text(
                        'Nhập vị trí',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: onEnableGPSTap,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF7A).withValues(alpha: 0.15),
                        foregroundColor: const Color(0xFFD4AF7A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      child: const Text(
                        'Bật GPS',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.4),
                        size: 18,
                      ),
                      onPressed: onDismiss,
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
