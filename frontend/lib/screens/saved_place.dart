import 'package:flutter/material.dart';

import '../models/destination.dart';

class SavedPlacesSection extends StatelessWidget {
  final Animation<double> entranceAnimation;
  final List<Destination> savedDestinations;
  final Set<String> updatingSavedNames;
  final bool isLoading;
  final VoidCallback onBack;
  final Future<void> Function(Destination dest, BuildContext cardContext)
      onOpenDetail;
  final Future<bool> Function(Destination dest) onToggleSaved;
  final bool isGuest;

  const SavedPlacesSection({
    super.key,
    required this.entranceAnimation,
    required this.savedDestinations,
    required this.updatingSavedNames,
    required this.isLoading,
    required this.onBack,
    required this.onOpenDetail,
    required this.onToggleSaved,
    this.isGuest = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        key: const ValueKey<String>('saved_tab'),
        children: [
          _buildTopBar(),
          const SizedBox(height: 8),
          _buildTitle(),
          const SizedBox(height: 12),
          Expanded(
            child: _buildSavedPlacesView(),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return FadeTransition(
      opacity: entranceAnimation,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 6),
        child: Row(
          children: [
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.14),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.14),
                ),
              ),
              child: const Icon(
                Icons.bookmark_rounded,
                color: Color(0xFFD4AF7A),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Danh sách đã lưu',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${savedDestinations.length} địa điểm',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.72),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return FadeTransition(
      opacity: entranceAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(entranceAnimation),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Những nơi bạn muốn đến',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.2,
                shadows: [
                  Shadow(
                    color: Color(0x88000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedPlacesView() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (savedDestinations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bookmark_border_rounded,
                size: 72,
                color: Colors.white.withOpacity(0.75),
              ),
              const SizedBox(height: 18),
              Text(
                isGuest ? 'Đăng nhập để sử dụng tính năng này' : 'Chưa có địa điểm nào được lưu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hãy thêm địa điểm bạn muốn đến vào lần tới',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.75),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
      itemCount: savedDestinations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final dest = savedDestinations[index];
        final isBusy = updatingSavedNames.contains(dest.name);

        return Builder(
          builder: (cardContext) {
            return GestureDetector(
              onTap: () => onOpenDetail(dest, cardContext),
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.28),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Destination.buildImage(
                        dest.imagePath,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.12),
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: GestureDetector(
                          onTap: isBusy ? null : () => onToggleSaved(dest),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                              ),
                            ),
                            child: isBusy
                                ? const Padding(
                                    padding: EdgeInsets.all(11),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.bookmark_remove_rounded,
                                    color: Color(0xFFD4AF7A),
                                  ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.pin_drop_rounded,
                                  color: Color(0xFFB5956A),
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    dest.name,
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              dest.province,
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.92),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
