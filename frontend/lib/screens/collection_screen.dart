import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/province_collection.dart';
import '../models/passport_models.dart';
import '../models/destination.dart';
import '../services/passport_service.dart';
import '../services/province_data_service.dart';
import 'province_detail_screen.dart';

/// Mapping of Vietnamese provinces to beautiful travel imagery from Unsplash.
const Map<String, String> provinceDefaultImages = {
  'Tuyên Quang': 'assets/images/TuyenQuang.jpg',
  'Cao Bằng': 'assets/images/CaoBang.jpg',
  'Lai Châu': 'assets/images/LaiChau.jpg',
  'Lào Cai': 'assets/images/LaoCai.jpg',
  'Thái Nguyên': 'assets/images/ThaiNguyen.jpg',
  'Điện Biên': 'assets/images/DienBien.jpg',
  'Lạng Sơn': 'assets/images/LangSon.jpg',
  'Sơn La': 'assets/images/SonLa.jpg',
  'Phú Thọ': 'assets/images/PhuTho.jpg',
  'TP. Hà Nội': 'assets/images/HaNoi.jpg',
  'TP. Hải Phòng': 'assets/images/HaiPhong.jpg',
  'Bắc Ninh': 'assets/images/BacNinh.jpg',
  'Quảng Ninh': 'assets/images/QuangNinh.jpg',
  'Hưng Yên': 'assets/images/HungYen.jpg',
  'Ninh Bình': 'assets/images/NinhBinh.jpg',
  'Thanh Hóa': 'assets/images/ThanhHoa.jpg',
  'Nghệ An': 'assets/images/NgheAn.jpg',
  'Hà Tĩnh': 'assets/images/HaTinh.jpg',
  'Quảng Trị': 'assets/images/QuangTri.jpg',
  'TP. Huế': 'assets/images/Hue.jpg',
  'TP. Đà Nẵng': 'assets/images/DaNang.jpg',
  'Quảng Ngãi': 'assets/images/QuangNgai.jpg',
  'Gia Lai': 'assets/images/GiaLai.jpg',
  'Đắk Lắk': 'assets/images/DakLak.jpg',
  'Khánh Hòa': 'assets/images/KhanhHoa.jpg',
  'Lâm Đồng': 'assets/images/LamDong.jpg',
  'Đồng Nai': 'assets/images/DongNai.jpg',
  'Tây Ninh': 'assets/images/TayNinh.jpg',
  'TP. Hồ Chí Minh': 'assets/images/TPHoChiMinh.jpg',
  'Đồng Tháp': 'assets/images/DongThap.jpg',
  'An Giang': 'assets/images/AnGiang.jpg',
  'Vĩnh Long': 'assets/images/VinhLong.jpg',
  'TP. Cần Thơ': 'assets/images/CanTho.jpg',
  'Cà Mau': 'assets/images/CaMau.jpg',
};

class CollectionScreen extends StatefulWidget {
  final String userName;
  final String? avatarUrl;
  final String? authToken;
  final List<Destination> allDestinations;

  const CollectionScreen({
    super.key,
    required this.userName,
    this.avatarUrl,
    this.authToken,
    this.allDestinations = const [],
  });

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  List<ProvinceCollection> _collections = [];
  bool _isLoading = false;
  int _totalUnlocked = 0;
  int _totalProvincesVisited = 0;
  int _totalBadgesEarned = 0;
  List<PassportBadge> _badges = [];

  bool get _isVi => Localizations.localeOf(context).languageCode == 'vi';

  @override
  void initState() {
    super.initState();
    _loadCollectionData();
  }

  Future<void> _loadCollectionData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    await PassportService.instance.init();

    final unlockedNames = PassportService.instance.getUnlockedNames();
    _totalUnlocked = unlockedNames.length;

    final cols = await ProvinceDataService.instance.getCollections(
      savedNames: unlockedNames,
      forceRefresh: true,
    );

    _totalProvincesVisited = cols.where((c) => c.visitedPlaces > 0).length;

    _badges = PassportService.instance.getBadges(allDestinations: widget.allDestinations);
    _totalBadgesEarned = _badges.where((b) => b.isEarned).length;

    if (mounted) {
      setState(() {
        _collections = cols;
        _isLoading = false;
      });
    }
  }

  void _showBadgeDetail(PassportBadge badge) {
    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF070E0D).withOpacity(0.95),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: badge.isEarned
                      ? const Color(0xFFD4AF7A)
                      : Colors.white.withOpacity(0.12),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: badge.isEarned
                          ? const Color(0xFFD4AF7A).withOpacity(0.12)
                          : Colors.white.withOpacity(0.04),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: badge.isEarned
                            ? const Color(0xFFD4AF7A)
                            : Colors.white24,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      _getBadgeIcon(badge.iconName),
                      color: badge.isEarned ? const Color(0xFFD4AF7A) : Colors.white24,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    badge.title,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    badge.isEarned ? (_isVi ? 'ĐÃ ĐẠT ĐƯỢC' : 'EARNED') : (_isVi ? 'CHƯA ĐẠT ĐƯỢC' : 'LOCKED'),
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: badge.isEarned ? const Color(0xFF2D6A4F) : Colors.white38,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    badge.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: badge.isEarned
                          ? const Color(0xFFD4AF7A)
                          : Colors.white.withOpacity(0.08),
                      foregroundColor: badge.isEarned ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      _isVi ? 'Đóng' : 'Close',
                      style: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getBadgeIcon(String name) {
    switch (name) {
      case 'military_tech_rounded':
        return Icons.military_tech_rounded;
      case 'stars_rounded':
        return Icons.stars_rounded;
      case 'fort_rounded':
        return Icons.castle_rounded;
      case 'workspace_premium_rounded':
        return Icons.workspace_premium_rounded;
      case 'camera_alt_rounded':
        return Icons.camera_alt_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final horizontalPadding = isDesktop ? 50.0 : 24.0;

    return RefreshIndicator(
      color: const Color(0xFFD4AF7A),
      backgroundColor: const Color(0xFF0D1B18),
      onRefresh: _loadCollectionData,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Collection stats card header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, 20),
              child: _buildCollectionHeaderCard(isDesktop),
            ),
          ),

          // Badges horizontal list
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Text(
                    _isVi ? 'HUY HIỆU & THÀNH TỰU' : 'ACHIEVEMENTS & BADGES',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white38,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 110,
                  child: _isLoading
                      ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF7A))))
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                          itemCount: _badges.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 14),
                          itemBuilder: (context, index) {
                            final badge = _badges[index];
                            return GestureDetector(
                              onTap: () => _showBadgeDetail(badge),
                              child: Tooltip(
                                message: badge.title,
                                child: Container(
                                  width: 86,
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: badge.isEarned
                                        ? const Color(0xFF2D6A4F).withOpacity(0.12)
                                        : Colors.white.withOpacity(0.03),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: badge.isEarned
                                          ? const Color(0xFFD4AF7A).withOpacity(0.4)
                                          : Colors.white.withOpacity(0.08),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _getBadgeIcon(badge.iconName),
                                        color: badge.isEarned
                                            ? const Color(0xFFD4AF7A)
                                            : Colors.white24,
                                        size: 28,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        badge.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: badge.isEarned ? Colors.white : Colors.white38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Text(
                    _isVi ? 'TIẾN ĐỘ KHÁM PHÁ CÁC TỈNH' : 'PROVINCE DISCOVERY PROGRESS',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white38,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Provinces Grid list
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 50),
                  child: CircularProgressIndicator(color: Color(0xFFD4AF7A)),
                ),
              ),
            )
          else if (_collections.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: Text(
                    _isVi ? 'Chưa có dữ liệu tỉnh thành.' : 'No province data available.',
                    style: const TextStyle(fontFamily: 'Montserrat', color: Colors.white38),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 120),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final minCardWidth = isDesktop ? 220.0 : 165.0;
                  final maxColumns = isDesktop ? 5 : 2;
                  final columns = (constraints.crossAxisExtent / minCardWidth)
                      .floor()
                      .clamp(1, maxColumns)
                      .toInt();

                  final spacing = isDesktop ? 16.0 : 12.0;
                  final cardHeight = isDesktop ? 166.0 : 144.0;

                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      mainAxisExtent: cardHeight,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _ProvinceProgressCard(
                          collection: _collections[index],
                          authToken: widget.authToken,
                          onBackFromDetail: _loadCollectionData,
                        );
                      },
                      childCount: _collections.length,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCollectionHeaderCard(bool isDesktop) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F2B23),
            Color(0xFF071511),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFD4AF7A).withOpacity(0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorations
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.map_rounded,
              size: 150,
              color: Colors.white.withOpacity(0.02),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF7A).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD4AF7A).withOpacity(0.3)),
                      ),
                      child: Text(
                        _isVi ? 'BỘ SƯU TẬP DU LỊCH' : 'TRAVEL COLLECTION',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF7A),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildAvatar(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userName,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isVi ? 'Hành trình chinh phục Việt Nam' : 'Your journey through Vietnam',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 20),
                // Stat counters
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCounter(
                      value: '$_totalProvincesVisited/34',
                      label: _isVi ? 'Tỉnh đã đi' : 'Provinces',
                    ),
                    _buildStatCounter(
                      value: '$_totalUnlocked',
                      label: _isVi ? 'Đã mở khóa' : 'Unlocked',
                    ),
                    _buildStatCounter(
                      value: '$_totalBadgesEarned',
                      label: _isVi ? 'Huy hiệu' : 'Badges',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final hasAvatar = widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty;
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD4AF7A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 28,
        backgroundColor: const Color(0xFF1E2E2A),
        backgroundImage: hasAvatar ? NetworkImage(widget.avatarUrl!) : null,
        child: !hasAvatar
            ? const Icon(
                Icons.person_rounded,
                color: Color(0xFFD4AF7A),
                size: 28,
              )
            : null,
      ),
    );
  }

  Widget _buildStatCounter({required String value, required String label}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFFD4AF7A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Colors.white38,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _ProvinceProgressCard extends StatefulWidget {
  final ProvinceCollection collection;
  final String? authToken;
  final VoidCallback onBackFromDetail;

  const _ProvinceProgressCard({
    required this.collection,
    this.authToken,
    required this.onBackFromDetail,
  });

  @override
  State<_ProvinceProgressCard> createState() => _ProvinceProgressCardState();
}

class _ProvinceProgressCardState extends State<_ProvinceProgressCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final pc = widget.collection;
    final imageUrl = (provinceDefaultImages[pc.name] != null && provinceDefaultImages[pc.name]!.isNotEmpty)
        ? provinceDefaultImages[pc.name]!
        : (pc.imageUrl ?? '');
    final percent = pc.totalPlaces > 0 ? (pc.visitedPlaces / pc.totalPlaces) : 0.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => ProvinceDetailScreen(
                collection: pc,
                savedNames: PassportService.instance.getUnlockedNames(),
                authToken: widget.authToken,
                isPassportMode: true,
              ),
              transitionDuration: const Duration(milliseconds: 400),
              reverseTransitionDuration: const Duration(milliseconds: 300),
              transitionsBuilder: (_, anim, __, child) {
                return FadeTransition(
                  opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.06),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                    child: child,
                  ),
                );
              },
            ),
          );
          widget.onBackFromDetail();
        },
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
                // Background Image
                AnimatedScale(
                  scale: _isHovered ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: imageUrl.isNotEmpty
                      ? Destination.buildImage(imageUrl, fit: BoxFit.cover)
                      : Container(color: const Color(0xFF1E2E2A)),
                ),

                // Dark Overlay
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  color: Colors.black.withOpacity(_isHovered ? 0.35 : 0.55),
                ),

                // Text and Progress bars
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Lock/Unlock indicator
                      Align(
                        alignment: Alignment.topRight,
                        child: Icon(
                          pc.visitedPlaces > 0 ? Icons.vpn_key_rounded : Icons.lock_outline_rounded,
                          color: pc.visitedPlaces > 0 ? const Color(0xFFD4AF7A) : Colors.white24,
                          size: 14,
                        ),
                      ),
                      
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pc.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${pc.visitedPlaces}/${pc.totalPlaces} điểm',
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                '${(percent * 100).toInt()}%',
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD4AF7A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Mini Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: percent,
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                pc.visitedPlaces > 0 ? const Color(0xFFD4AF7A) : Colors.white54,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ],
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
