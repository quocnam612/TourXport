import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/province_collection.dart';
import '../models/destination.dart';
import '../services/passport_service.dart';
import 'place_detail.dart';
import 'collection_screen.dart'; // To reuse provinceDefaultImages
import 'travel_memory_screen.dart';

class ProvinceDetailScreen extends StatefulWidget {
  final ProvinceCollection collection;
  final Set<String> savedNames;
  final String? authToken;
  final bool isPassportMode;

  const ProvinceDetailScreen({
    super.key,
    required this.collection,
    required this.savedNames,
    this.authToken,
    this.isPassportMode = false,
  });

  @override
  State<ProvinceDetailScreen> createState() => _ProvinceDetailScreenState();
}

class _ProvinceDetailScreenState extends State<ProvinceDetailScreen> with TickerProviderStateMixin {
  static const int _itemsPerPage = 25;

  late Set<String> _localSavedNames;
  int _currentPage = 0;
  double _gpsLat = 21.0285; // Fallback to Hanoi
  double _gpsLon = 105.8542;
  bool _hasGps = false;

  @override
  void initState() {
    super.initState();
    _localSavedNames = Set<String>.from(widget.savedNames);
    _initGps();
  }

  Future<void> _initGps() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 3),
        );
        if (mounted) {
          setState(() {
            _gpsLat = position.latitude;
            _gpsLon = position.longitude;
            _hasGps = true;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _openPlaceDetail(Destination destination) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaceDetailScreen(
          destination: destination,
          authToken: widget.authToken,
          isSaved: _localSavedNames.contains(destination.name),
        ),
      ),
    );

    if (result != null && result is Map) {
      final newSaved = result['isSaved'] as bool?;
      if (newSaved != null) {
        setState(() {
          if (newSaved) {
            _localSavedNames.add(destination.name);
          } else {
            _localSavedNames.remove(destination.name);
          }
        });
      }
    }
  }

  Future<void> _handlePlaceCardTap(Destination place) async {
    if (widget.isPassportMode) {
      final unlocked = PassportService.instance.isUnlocked(place.name);
      if (unlocked) {
        // Unlocked: Navigate directly to Travel Memory screen
        final res = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TravelMemoryScreen(
              placeName: place.name,
              fallbackImageUrl: place.imagePath,
            ),
          ),
        );
        if (res == true && mounted) {
          setState(() {});
        }
      } else {
        // Locked: Open Check-in and unlock dialog
        _showCheckInDialog(place);
      }
    } else {
      // Explore Mode: Open standard Place Detail screen
      _openPlaceDetail(place);
    }
  }

  void _showCheckInDialog(Destination place) {
    double distanceMeters = -1.0;
    if (_hasGps && place.latitude != 0.0 && place.longitude != 0.0) {
      distanceMeters = Geolocator.distanceBetween(
        _gpsLat,
        _gpsLon,
        place.latitude,
        place.longitude,
      );
    }

    final isWithinRange = distanceMeters >= 0 && distanceMeters <= 500;
    final displayDistanceKm = distanceMeters >= 0 ? (distanceMeters / 1000).toStringAsFixed(2) : '---';

    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF070E0D).withOpacity(0.95),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF7A).withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFFD4AF7A),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    place.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    place.province,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Location Status & GPS distance info
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Khoảng cách GPS:',
                          style: TextStyle(fontFamily: 'Montserrat', fontSize: 13, color: Colors.white70),
                        ),
                        Text(
                          '$displayDistanceKm km',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD4AF7A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (distanceMeters > 500)
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Colors.white38, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Vị trí của bạn đang ở xa (> 500m). Vui lòng thử nút giả lập để test ứng dụng.',
                            style: TextStyle(fontFamily: 'Montserrat', fontSize: 11, color: Colors.white.withOpacity(0.4)),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 28),

                  // Actions
                  Column(
                    children: [
                      // Simulated Check-in button (Demo Mode)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          _unlockPlace(place, isMock: true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D6A4F).withOpacity(0.2),
                          foregroundColor: const Color(0xFF2D6A4F),
                          side: const BorderSide(color: Color(0xFF2D6A4F), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          'Mở khóa thử nghiệm (Demo Check-in)',
                          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // GPS Check-in (Real Mode)
                      ElevatedButton(
                        onPressed: isWithinRange
                            ? () {
                                Navigator.pop(context);
                                _unlockPlace(place, isMock: false);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF7A),
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: Colors.white.withOpacity(0.05),
                          disabledForegroundColor: Colors.white24,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          'Xác nhận Check-in (GPS)',
                          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _unlockPlace(Destination place, {required bool isMock}) async {
    final result = await PassportService.instance.checkIn(
      place,
      allDestinations: widget.collection.districts.expand((d) => d.places).toList(),
    );

    if (result['success'] == true && mounted) {
      final List<String> badges = List<String>.from(result['badgesUnlocked'] ?? []);

      // Trigger standard beautiful unlock congratulation dialog
      _showUnlockSuccessAnimationDialog(place, badges);
    }
  }

  void _showUnlockSuccessAnimationDialog(Destination place, List<String> badges) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _UnlockAnimationView(
          place: place,
          badgesUnlocked: badges,
          onClose: () {
            Navigator.pop(context); // close dialogue
            setState(() {}); // refresh detail screen grid
            
            // Navigate directly to Travel Memory diary creation
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TravelMemoryScreen(
                  placeName: place.name,
                  fallbackImageUrl: place.imagePath,
                ),
              ),
            ).then((_) {
              if (mounted) setState(() {});
            });
          },
        );
      },
    );
  }

  Widget _paginationArrow({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(enabled ? 0.34 : 0.16),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.14)),
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : Colors.white.withOpacity(0.32),
          size: 22,
        ),
      ),
    );
  }

  Widget _buildPaginationControls({
    required int currentPage,
    required int totalPages,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _paginationArrow(
          icon: Icons.chevron_left_rounded,
          enabled: currentPage > 0,
          onTap: () => setState(() => _currentPage = currentPage - 1),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.34),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withOpacity(0.16)),
              ),
              child: Text(
                '${currentPage + 1}/$totalPages',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
        _paginationArrow(
          icon: Icons.chevron_right_rounded,
          enabled: currentPage < totalPages - 1,
          onTap: () => setState(() => _currentPage = currentPage + 1),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pc = widget.collection;
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    // Flatten all destinations from all districts in this province
    final places = pc.districts.expand((d) => d.places).toList();

    // Sort: real image first, then by score descending
    places.sort((a, b) {
      if ((a.hasImage == true) != (b.hasImage == true)) {
        return a.hasImage == true ? -1 : 1;
      }
      return (b.totalScore ?? 0).compareTo(a.totalScore ?? 0);
    });

    // Background Image fallback
    final provinceImgUrl = (provinceDefaultImages[pc.name] != null && provinceDefaultImages[pc.name]!.isNotEmpty)
        ? provinceDefaultImages[pc.name]!
        : (pc.imageUrl ?? '');

    // Calculate percentage if in Passport mode
    int unlockedCount = 0;
    if (widget.isPassportMode) {
      unlockedCount = places.where((d) => PassportService.instance.isUnlocked(d.name)).length;
    }
    final percent = places.isNotEmpty ? (unlockedCount / places.length) : 0.0;
    final totalPages = places.isEmpty ? 1 : ((places.length + _itemsPerPage - 1) ~/ _itemsPerPage);
    final currentPage = _currentPage < 0
        ? 0
        : (_currentPage >= totalPages ? totalPages - 1 : _currentPage);
    final startIndex = places.isEmpty ? 0 : currentPage * _itemsPerPage;
    final endIndex = places.isEmpty
        ? 0
        : (startIndex + _itemsPerPage > places.length ? places.length : startIndex + _itemsPerPage);
    final pagePlaces = places.isEmpty ? <Destination>[] : places.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: const Color(0xFF0C1412),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Parallax Header
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF0C1412),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (provinceImgUrl.isNotEmpty)
                    Destination.buildImage(
                      provinceImgUrl,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(color: const Color(0xFF1E2E2A)),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.5),
                          Colors.transparent,
                          const Color(0xFF0C1412).withOpacity(0.85),
                          const Color(0xFF0C1412),
                        ],
                        stops: const [0.0, 0.4, 0.85, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Title Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          pc.name,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                      if (widget.isPassportMode)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF7A).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFD4AF7A).withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.stars_rounded, color: Color(0xFFD4AF7A), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '$unlockedCount/${places.length} ĐÃ MỞ',
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD4AF7A),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (widget.isPassportMode && places.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: percent,
                              backgroundColor: Colors.white12,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF7A)),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${(percent * 100).toInt()}% hoàn thành',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD4AF7A),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    widget.isPassportMode ? 'BẢN ĐỒ THÀNH TỰU ĐỊA ĐIỂM' : 'ĐỊA ĐIỂM DU LỊCH',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white38,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Direct Places Grid
          if (places.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'Không có địa điểm nào trong tỉnh.',
                  style: TextStyle(fontFamily: 'Montserrat', color: Colors.white38),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final minCardWidth = isDesktop ? 200.0 : 150.0;
                  final maxColumns = isDesktop ? 5 : 2;
                  final columns = (constraints.crossAxisExtent / minCardWidth)
                      .floor()
                      .clamp(1, maxColumns)
                      .toInt();

                  final spacing = isDesktop ? 16.0 : 12.0;
                  final cardHeight = isDesktop ? 150.0 : 120.0;

                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      mainAxisExtent: cardHeight,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final place = pagePlaces[index];
                        final bool isUnlocked = !widget.isPassportMode || 
                            PassportService.instance.isUnlocked(place.name);

                        return _SimpleGridCard(
                          name: place.name,
                          imageUrl: place.imagePath,
                          isUnlocked: isUnlocked,
                          isPassportMode: widget.isPassportMode,
                          onTap: () => _handlePlaceCardTap(place),
                        );
                      },
                      childCount: pagePlaces.length,
                    ),
                  );
                },
              ),
            ),
          if (places.isNotEmpty && totalPages > 1)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                child: _buildPaginationControls(
                  currentPage: currentPage,
                  totalPages: totalPages,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SimpleGridCard extends StatefulWidget {
  final String name;
  final String imageUrl;
  final bool isUnlocked;
  final bool isPassportMode;
  final VoidCallback onTap;

  const _SimpleGridCard({
    required this.name,
    required this.imageUrl,
    required this.isUnlocked,
    required this.isPassportMode,
    required this.onTap,
  });

  @override
  State<_SimpleGridCard> createState() => _SimpleGridCardState();
}

class _SimpleGridCardState extends State<_SimpleGridCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final displayName = widget.name;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image - blurry if locked
                AnimatedScale(
                  scale: _isHovered ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: widget.imageUrl.isNotEmpty
                      ? (widget.isUnlocked
                          ? Destination.buildImage(widget.imageUrl, fit: BoxFit.cover)
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                Destination.buildImage(widget.imageUrl, fit: BoxFit.cover),
                                BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                  child: Container(color: Colors.black.withOpacity(0.2)),
                                ),
                              ],
                            ))
                      : Container(color: const Color(0xFF1E2E2A)),
                ),

                // Smooth hover overlay
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  color: Colors.black.withOpacity(
                    widget.isUnlocked 
                        ? (_isHovered ? 0.22 : 0.48) 
                        : (_isHovered ? 0.6 : 0.72)
                  ),
                ),

                // Success integration tag or lock icon
                if (widget.isPassportMode)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: widget.isUnlocked 
                            ? const Color(0xFF2D6A4F)
                            : Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.isUnlocked 
                              ? const Color(0xFFD4AF7A).withOpacity(0.4) 
                              : Colors.white24,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          widget.isUnlocked ? Icons.check_rounded : Icons.lock_outline_rounded,
                          color: widget.isUnlocked ? Colors.white : Colors.white60,
                          size: 12,
                        ),
                      ),
                    ),
                  ),

                // Lock icon in the center if locked
                if (!widget.isUnlocked)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ),

                // Place Name Centered
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Text(
                    displayName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: widget.isUnlocked ? Colors.white : Colors.white38,
                      letterSpacing: -0.2,
                      shadows: [
                        if (widget.isUnlocked)
                          const Shadow(
                            color: Colors.black,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                      ],
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

class _UnlockAnimationView extends StatefulWidget {
  final Destination place;
  final List<String> badgesUnlocked;
  final VoidCallback onClose;

  const _UnlockAnimationView({
    required this.place,
    required this.badgesUnlocked,
    required this.onClose,
  });

  @override
  State<_UnlockAnimationView> createState() => _UnlockAnimationViewState();
}

class _UnlockAnimationViewState extends State<_UnlockAnimationView> with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F3E2F),
                  Color(0xFF051712),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFFD4AF7A), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2D6A4F).withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Trophy or Badge icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF7A).withOpacity(0.12),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF7A).withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFD4AF7A),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'BẠN ĐÃ KHÁM PHÁ!',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFD4AF7A),
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.place.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white12),
                const SizedBox(height: 16),

                if (widget.badgesUnlocked.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.military_tech_rounded, color: Color(0xFFD4AF7A), size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Đạt được Huy hiệu mới!',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD4AF7A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.badgesUnlocked.join(', '),
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 32),
                
                ElevatedButton(
                  onPressed: widget.onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF7A),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    minimumSize: const Size(180, 48),
                  ),
                  child: const Text(
                    'Viết Nhật ký',
                    style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
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
