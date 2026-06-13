import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';

import '../models/ai_trip_response.dart';
import '../models/destination.dart';
import '../widgets/weather_widget.dart';
import 'place_detail.dart';
import 'map_screen.dart';
import 'tour_route_map_screen.dart';
import '../api/api.dart';

class SavedTourDetailScreen extends StatefulWidget {
  final String tourTitle;
  final Map<String, dynamic> tourJson;
  final String userName;
  final String? avatarUrl;
  final String? authToken;
  final bool canEditTitle;

  const SavedTourDetailScreen({
    super.key,
    required this.tourTitle,
    required this.tourJson,
    this.userName = 'Username',
    this.avatarUrl,
    this.authToken,
    this.canEditTitle = false,
  });

  @override
  State<SavedTourDetailScreen> createState() => _SavedTourDetailScreenState();
}

class _SavedTourDetailScreenState extends State<SavedTourDetailScreen> {
  late Map<String, dynamic> _tourJson;
  bool _isUpdatingVisibility = false;
  bool _isUpdatingTitle = false;

  String get _displayTourTitle {
    final title = (_tourJson['title'] ?? widget.tourTitle).toString().trim();
    return title.isEmpty ? widget.tourTitle : title;
  }

  bool get _canEditTitle =>
      widget.canEditTitle &&
      widget.authToken != null &&
      widget.authToken!.trim().isNotEmpty;

  bool get _canUpdateVisibility => _canEditTitle;

  @override
  void initState() {
    super.initState();
    _tourJson = Map<String, dynamic>.from(widget.tourJson);
  }

  @override
  Widget build(BuildContext context) {
    AiTripResponse? response;
    try {
      response = AiTripResponse.fromJson(_tourJson);
    } catch (_) {
      response = null;
    }

    final itinerary = response?.data.itinerary ?? [];
    final meta = _TourMeta.fromJson(_tourJson);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;
    final isCompact = width < 600;
    final detailContent = response == null || itinerary.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildSummary(context),
          )
        : _buildDetailContent(context, itinerary, meta, isCompact);

    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        // Background similar to AI result screen
        Image.asset('assets/images/login_bg.jpg', fit: BoxFit.cover),
        BackdropFilter(filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: Container(color: Colors.black.withOpacity(0.6))),
        SafeArea(
          child: response == null || itinerary.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildSummary(context),
                )
              : detailContent,
        ),
      ]),
    );
  }

  void _shareTour(BuildContext context) {
    final String? tourId = _tourId;
    if (tourId == null || tourId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          AppLocalizations.of(context)!.localeName == 'vi'
              ? 'Không tìm thấy mã tour để chia sẻ'
              : 'Tour ID not found for sharing',
        ),
      ));
      return;
    }

    final String shareUrl = _tourShareUrl(tourId);
    final isVi = AppLocalizations.of(context)!.localeName == 'vi';
    final String shareText = isVi
        ? 'Xem lịch trình $_displayTourTitle trên TourXport\n$shareUrl'
        : 'View the $_displayTourTitle itinerary on TourXport\n$shareUrl';
    _showShareDialog(
      context,
      shareUrl,
      shareText,
      isVi ? 'lịch trình' : 'tour',
    );
  }

  String? get _tourId => _tourJson['_id']?.toString() ?? _tourJson['id']?.toString();

  String _tourShareUrl(String tourId) {
    final origin = kIsWeb ? Uri.base.origin : 'https://tourxport.netlify.app';
    return Uri.parse(origin)
        .replace(path: '/tour', queryParameters: {'id': tourId})
        .toString();
  }

  bool _isPrivateVisibility(String visibility) {
    final normalized = visibility.toLowerCase();
    return normalized == 'private' || normalized == 'hidden';
  }

  Future<void> _openGoogleTourDirections(BuildContext context) async {
    final isVi = AppLocalizations.of(context)!.localeName == 'vi';
    AiTripResponse? response;
    try {
      response = AiTripResponse.fromJson(_tourJson);
    } catch (_) {
      response = null;
    }

    final stops = <String>[];
    if (response != null) {
      for (final day in response.data.itinerary) {
        for (final activity in day.activities) {
          final lat = activity.latitude;
          final lng = activity.longitude;
          final stop = lat != null && lng != null
              ? '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}'
              : activity.placeName?.trim();
          if (stop != null && stop.isNotEmpty && !stops.contains(stop)) {
            stops.add(stop);
          }
        }
      }
    }

    if (stops.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isVi
            ? 'Lịch trình cần ít nhất 2 điểm để mở đường đi trên Google Maps'
            : 'The itinerary needs at least 2 stops to open Google Maps directions'),
      ));
      return;
    }

    final params = <String, String>{
      'api': '1',
      'origin': stops.first,
      'destination': stops.last,
      'travelmode': 'driving',
    };
    final waypoints = stops.skip(1).take(stops.length - 2).take(8).join('|');
    if (waypoints.isNotEmpty) {
      params['waypoints'] = waypoints;
    }

    final uri = Uri.https('www.google.com', '/maps/dir/', params);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isVi
            ? 'Không mở được Google Maps'
            : 'Could not open Google Maps'),
      ));
    }
  }

  Future<void> _renameTour(String nextTitle) async {
    final isVi = AppLocalizations.of(context)!.localeName == 'vi';
    final tourId = _tourId;
    final title = nextTitle.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isVi ? 'Tên lịch trình không được để trống' : 'Itinerary title cannot be empty'),
      ));
      return;
    }

    if (tourId == null || tourId.isEmpty || widget.authToken == null || widget.authToken!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isVi
            ? 'Bạn cần đăng nhập để đổi tên lịch trình'
            : 'You need to sign in to rename this itinerary'),
      ));
      return;
    }

    setState(() => _isUpdatingTitle = true);
    try {
      final response = await apiPutJson(
        '/tours/my-tours/$tourId',
        {'title': title},
        token: widget.authToken,
      );
      final body = tryDecodeJsonObject(response.body);
      if (!mounted) return;
      if (response.statusCode == 200 && body?['success'] == true) {
        final data = body?['data'];
        setState(() {
          if (data is Map) {
            _tourJson = Map<String, dynamic>.from(data);
          } else {
            _tourJson = Map<String, dynamic>.from(_tourJson)..['title'] = title;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isVi ? 'Đã đổi tên lịch trình' : 'Itinerary renamed'),
        ));
      } else {
        throw Exception(body?['message'] ?? response.reasonPhrase);
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isVi
            ? 'Không thể đổi tên lịch trình này'
            : 'Could not rename this itinerary'),
      ));
    } finally {
      if (mounted) {
        setState(() => _isUpdatingTitle = false);
      }
    }
  }

  Future<void> _showRenameTourDialog(BuildContext context) async {
    final isVi = AppLocalizations.of(context)!.localeName == 'vi';
    final controller = TextEditingController(text: _displayTourTitle);
    final focusNode = FocusNode();

    final nextTitle = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        Future<void> closeDialog([String? value]) async {
          controller.selection = TextSelection.collapsed(
            offset: controller.text.length,
          );
          focusNode.unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
          await Future<void>.delayed(Duration.zero);
          if (dialogContext.mounted) {
            Navigator.pop(dialogContext, value);
          }
        }

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AlertDialog(
            backgroundColor: const Color(0xFF0F1E1B).withOpacity(0.94),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.white.withOpacity(0.12), width: 1.2),
            ),
            title: Text(
              isVi ? 'Đổi tên lịch trình' : 'Rename itinerary',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            content: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              maxLength: 160,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                counterStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
                hintText: isVi ? 'Nhập tên lịch trình' : 'Enter itinerary title',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.07),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFD4AF7A)),
                ),
              ),
              onSubmitted: (value) => closeDialog(value),
            ),
            actions: [
              TextButton(
                onPressed: () => closeDialog(),
                child: Text(
                  isVi ? 'Hủy' : 'Cancel',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.white.withOpacity(0.62),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => closeDialog(controller.text),
                child: Text(
                  isVi ? 'Lưu' : 'Save',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    color: Color(0xFFD4AF7A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    await Future<void>.delayed(Duration.zero);
    focusNode.dispose();
    controller.dispose();
    if (nextTitle == null) return;
    await _renameTour(nextTitle);
  }

  Future<void> _toggleTourVisibility(BuildContext context, _TourMeta meta) async {
    if (_isUpdatingVisibility) return;

    final isVi = AppLocalizations.of(context)!.localeName == 'vi';
    if (!_canUpdateVisibility) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isVi
            ? 'Chỉ chủ sở hữu mới có thể đổi trạng thái hiển thị'
            : 'Only the owner can change itinerary visibility'),
      ));
      return;
    }

    final tourId = _tourId;
    if (tourId == null || tourId.isEmpty || widget.authToken == null || widget.authToken!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isVi
            ? 'Không thể cập nhật hiển thị lịch trình'
            : 'Cannot update itinerary visibility'),
      ));
      return;
    }

    final nextVisibility = _isPrivateVisibility(meta.visibility) ? 'public' : 'private';
    setState(() => _isUpdatingVisibility = true);
    try {
      final response = await apiPutJson(
        '/tours/my-tours/$tourId',
        {'visibility': nextVisibility},
        token: widget.authToken,
      );
      final body = tryDecodeJsonObject(response.body);
      if (!mounted) return;
      if (response.statusCode == 200 && body?['success'] == true) {
        final data = body?['data'];
        setState(() {
          if (data is Map) {
            _tourJson = Map<String, dynamic>.from(data);
          } else {
            _tourJson = Map<String, dynamic>.from(_tourJson)..['visibility'] = nextVisibility;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(nextVisibility == 'public'
              ? (isVi ? 'Lịch trình đã được đặt thành công khai' : 'Itinerary is now public')
              : (isVi ? 'Lịch trình đã được đặt thành riêng tư' : 'Itinerary is now private')),
        ));
      } else {
        throw Exception(body?['message'] ?? response.reasonPhrase);
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isVi
            ? 'Cập nhật hiển thị thất bại'
            : 'Failed to update visibility'),
      ));
    } finally {
      if (mounted) {
        setState(() => _isUpdatingVisibility = false);
      }
    }
  }

  void _showShareDialog(
    BuildContext context,
    String shareUrl,
    String shareText,
    String title,
  ) {
    final isVi = AppLocalizations.of(context)!.localeName == 'vi';
    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AlertDialog(
            backgroundColor: const Color(0xFF0F1E1B).withOpacity(0.92),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.white.withOpacity(0.12), width: 1.2),
            ),
            title: Text(
              isVi ? 'Chia sẻ $title' : 'Share $title',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVi
                      ? 'Chia sẻ qua ứng dụng khác hoặc sao chép liên kết bên dưới:'
                      : 'Share through another app or copy the link below:',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.10)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          shareUrl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: Color(0xFFD4AF7A), size: 20),
                        tooltip: isVi ? 'Sao chép' : 'Copy',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: shareUrl));
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                              isVi
                                  ? 'Đã sao chép liên kết chia sẻ vào khay nhớ tạm'
                                  : 'Copied share link to clipboard',
                            ),
                          ));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () async {
                  final box = context.findRenderObject() as RenderBox?;
                  await Share.share(
                    shareText,
                    subject: isVi ? 'Chia sẻ lịch trình TourXport' : 'Share TourXport itinerary',
                    sharePositionOrigin:
                        box == null ? null : box.localToGlobal(Offset.zero) & box.size,
                  );
                },
                icon: const Icon(Icons.ios_share_rounded, color: Color(0xFFD4AF7A), size: 18),
                label: Text(
                  isVi ? 'Chia sẻ' : 'Share',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    color: Color(0xFFD4AF7A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  isVi ? 'Đóng' : 'Close',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    color: Color(0xFFD4AF7A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailContent(
    BuildContext context,
    List<AiDailyItinerary> itinerary,
    _TourMeta meta,
    bool isCompact,
  ) {
    return Column(
      children: [
        // Header
        Padding(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 20 : 24,
            isCompact ? 10 : 16,
            isCompact ? 20 : 24,
            isCompact ? 4 : 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _VisibilityBadge(
                    icon: meta.visibilityIcon,
                    isLoading: _isUpdatingVisibility,
                    onTap: _canUpdateVisibility
                        ? () => _toggleTourVisibility(context, meta)
                        : null,
                  ),
                  SizedBox(width: isCompact ? 8 : 10),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _displayTourTitle,
                            maxLines: isCompact ? 2 : null,
                            overflow: isCompact
                                ? TextOverflow.ellipsis
                                : TextOverflow.visible,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: isCompact ? 20 : 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: isCompact ? 1.25 : 1.2,
                            ),
                          ),
                        ),
                        if (_canEditTitle) ...[
                          const SizedBox(width: 6),
                          SizedBox(
                            width: isCompact ? 30 : 36,
                            height: isCompact ? 30 : 36,
                            child: IconButton(
                              tooltip: AppLocalizations.of(context)!.localeName == 'vi'
                                  ? 'Đổi tên lịch trình'
                                  : 'Rename itinerary',
                              icon: _isUpdatingTitle
                                  ? SizedBox(
                                      width: isCompact ? 15 : 17,
                                      height: isCompact ? 15 : 17,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFFD4AF7A),
                                      ),
                                    )
                                  : const Icon(Icons.edit_rounded),
                              iconSize: isCompact ? 16 : 18,
                              color: const Color(0xFFD4AF7A),
                              padding: EdgeInsets.zero,
                              onPressed: _isUpdatingTitle
                                  ? null
                                  : () => _showRenameTourDialog(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(
                    width: isCompact ? 36 : 48,
                    height: isCompact ? 36 : 48,
                    child: IconButton(
                      icon: const Icon(Icons.share_rounded),
                      iconSize: isCompact ? 20 : 24,
                      color: Colors.white,
                      padding: EdgeInsets.zero,
                      onPressed: () => _shareTour(context),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isCompact ? 4 : 8),
              Text(
                '${AppLocalizations.of(context)!.tour_itinerary} đã lưu',
                style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: isCompact ? 12 : 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.3),
              ),
              SizedBox(height: isCompact ? 10 : 16),
              _TripMetaGrid(meta: meta, compact: isCompact),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 16 : 20,
              isCompact ? 8 : 12,
              isCompact ? 16 : 20,
              12,
            ),
            itemCount: itinerary.length,
            itemBuilder: (context, i) {
              return _ItineraryDayCard(day: itinerary[i]);
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 20 : 24,
            8,
            isCompact ? 20 : 24,
            isCompact ? 14 : 20,
          ),
          child: Row(children: [
            // Trang chủ
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: () => Navigator.pop(context, 'go_to_explore'),
                child: Container(
                  height: isCompact ? 48 : 50,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white.withOpacity(0.2))),
                  child: const Center(
                      child: Icon(Icons.home_rounded, color: Colors.white, size: 22)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Bản đồ
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () {
                  AiTripResponse? response;
                  try {
                    response = AiTripResponse.fromJson(_tourJson);
                  } catch (_) {}
                  if (response != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TourRouteMapScreen(tourData: response!),
                      ),
                    );
                  }
                },
                child: Container(
                  height: isCompact ? 48 : 50,
                  decoration: BoxDecoration(
                      color: const Color(0xFF2D6A4F),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF2D6A4F).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4)),
                      ]),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppLocalizations.of(context)!.map,
                            style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                        const SizedBox(width: 6),
                        const Icon(Icons.map_rounded, color: Colors.white, size: 18),
                      ]),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Google Maps
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () => _openGoogleTourDirections(context),
                child: Container(
                  height: isCompact ? 48 : 50,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white.withOpacity(0.18))),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Google',
                            style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                        const SizedBox(width: 6),
                        const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 18),
                      ]),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Đóng
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: isCompact ? 48 : 50,
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFD4AF7A), Color(0xFFB5956A)]),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFFD4AF7A).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4)),
                      ]),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppLocalizations.of(context)!.close,
                            style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ]),
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    final title = _displayTourTitle;
    final totalDays = _tourJson['totalDays'] ?? _tourJson['days']?.length ?? 0;
    final totalNights = _tourJson['totalNights'] ?? 0;
    final isVi = AppLocalizations.of(context)!.localeName == 'vi';
    final destinations = _tourJson['destinations'] is List
        ? (_tourJson['destinations'] as List).map((d) => _translateProvince(d.toString(), context)).join(', ')
        : '';
    final cost = _formatMoneyRange(_tourJson['estimatedCost'] ?? _tourJson['totalEstimatedCost'], context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_canEditTitle) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: isVi ? 'Đổi tên lịch trình' : 'Rename itinerary',
                  onPressed: _isUpdatingTitle
                      ? null
                      : () => _showRenameTourDialog(context),
                  icon: _isUpdatingTitle
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFD4AF7A),
                          ),
                        )
                      : const Icon(Icons.edit_rounded),
                  color: const Color(0xFFD4AF7A),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isVi
                ? 'Thời gian: $totalDays ngày $totalNights đêm'
                : 'Duration: $totalDays days $totalNights nights',
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
          const SizedBox(height: 8),
          if (destinations.isNotEmpty)
            Text(
              (isVi ? 'Điểm đến: ' : 'Destinations: ') + destinations,
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          const SizedBox(height: 12),
          if (cost != null)
            Text(
              (isVi ? 'Chi phí dự tính: ' : 'Estimated Cost: ') + cost,
              style: const TextStyle(color: Color(0xFFD4AF7A), fontWeight: FontWeight.w700),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF7A), foregroundColor: Colors.black),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }
}

class _SavedTourMainSidebar extends StatelessWidget {
  final String userName;
  final String? avatarUrl;
  final bool isGuest;

  const _SavedTourMainSidebar({
    required this.userName,
    required this.avatarUrl,
    required this.isGuest,
  });

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      (Icons.home_rounded, AppLocalizations.of(context)!.explore, 'go_to_explore'),
      (Icons.search_rounded, AppLocalizations.of(context)!.search, 'go_to_search'),
      (Icons.bookmark_rounded, AppLocalizations.of(context)!.saved, 'go_to_saved'),
      (Icons.explore_rounded, AppLocalizations.of(context)!.survey, 'go_to_survey'),
      (Icons.person_rounded, AppLocalizations.of(context)!.account, 'go_to_account'),
    ];

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF070E0D).withOpacity(0.45),
        border: const Border(
          right: BorderSide(color: Colors.white12, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 36),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF7A).withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/logo-compact.png',
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'TourXport',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFD4AF7A),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  _SidebarAvatar(avatarUrl: avatarUrl),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)!.localeName == 'vi' ? 'Thành viên' : 'Member',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: menuItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isActive = item.$3 == 'go_to_saved';
                return _SidebarNavItem(
                  icon: item.$1,
                  label: item.$2,
                  isActive: isActive,
                  onTap: () => Navigator.pop(context, item.$3),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _SidebarNavItem(
              icon: isGuest ? Icons.login_rounded : Icons.logout_rounded,
              label: isGuest ? AppLocalizations.of(context)!.account : (AppLocalizations.of(context)!.localeName == 'vi' ? 'Đăng xuất' : 'Log out'),
              isDanger: !isGuest,
              isGold: isGuest,
              onTap: () => Navigator.pop(
                context,
                isGuest ? 'go_to_account' : 'logout',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDanger;
  final bool isGold;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.isDanger = false,
    this.isGold = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isDanger
        ? const Color(0xFFE74C3C)
        : isActive || isGold
            ? const Color(0xFFD4AF7A)
            : Colors.white.withOpacity(0.65);
    final textColor = isDanger
        ? const Color(0xFFE74C3C)
        : isActive
            ? Colors.white
            : isGold
                ? const Color(0xFFD4AF7A)
                : Colors.white.withOpacity(0.65);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: (isDanger ? const Color(0xFFE74C3C) : Colors.white)
            .withOpacity(0.06),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF2D6A4F).withOpacity(0.25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? const Color(0xFFD4AF7A).withOpacity(0.65)
                  : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: isActive || isDanger || isGold
                      ? FontWeight.bold
                      : FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarAvatar extends StatelessWidget {
  final String? avatarUrl;

  const _SidebarAvatar({required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final cleanUrl = avatarUrl?.trim() ?? '';

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: cleanUrl.isNotEmpty
            ? Image.network(
                cleanUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _SidebarAvatarPlaceholder(),
              )
            : const _SidebarAvatarPlaceholder(),
      ),
    );
  }
}

class _SidebarAvatarPlaceholder extends StatelessWidget {
  const _SidebarAvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white.withOpacity(0.2),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: Colors.white.withOpacity(0.9),
          size: 20,
        ),
      ),
    );
  }
}

class _TourMeta {
  final String visibility;
  final IconData visibilityIcon;
  final String visibilityLabel;
  final double? totalDistanceMeters;
  final double? estimatedCost;
  final String pace;
  final String transportMode;
  final int adults;
  final int children;
  final int totalDays;
  final int totalNights;

  const _TourMeta({
    required this.visibility,
    required this.visibilityIcon,
    required this.visibilityLabel,
    required this.totalDistanceMeters,
    required this.estimatedCost,
    required this.pace,
    required this.transportMode,
    required this.adults,
    required this.children,
    required this.totalDays,
    required this.totalNights,
  });

  factory _TourMeta.fromJson(Map<String, dynamic> json) {
    final visibility = (json['visibility'] ?? json['privacy'] ?? 'public').toString();
    final travelers = json['travelers'] is Map ? Map<String, dynamic>.from(json['travelers']) : const <String, dynamic>{};
    final estimatedCost = _readDouble(json['estimatedCost']) ?? _readDouble(json['totalEstimatedCost']);
    final distanceMeters = _readDouble(json['totalDistanceMeters']) ?? _readDouble(json['distanceMeters']) ?? _readDouble(json['totalDistance']);
    final totalDays = _readInt(json['totalDays']) ?? _readInt(json['days']) ?? (json['itinerary'] is List ? (json['itinerary'] as List).length : 0);
    final totalNights = _readInt(json['totalNights']) ?? (totalDays > 0 ? (totalDays - 1).clamp(0, 999) : 0);

    return _TourMeta(
      visibility: visibility,
      visibilityIcon: _iconForVisibility(visibility),
      visibilityLabel: _labelForVisibility(visibility),
      totalDistanceMeters: distanceMeters,
      estimatedCost: estimatedCost,
      pace: (json['pace'] ?? json['preferences']?['pace'] ?? 'balanced').toString(),
      transportMode: (json['transportMode'] ?? json['preferences']?['transportMode'] ?? 'auto').toString(),
      adults: _readInt(travelers['adults']) ?? 0,
      children: _readInt(travelers['children']) ?? 0,
      totalDays: totalDays,
      totalNights: totalNights,
    );
  }

  static IconData _iconForVisibility(String value) {
    switch (value.toLowerCase()) {
      case 'private':
      case 'hidden':
        return Icons.lock_rounded;
      case 'protected':
      case 'shared':
        return Icons.groups_rounded;
      default:
        return Icons.public_rounded;
    }
  }

  static String _labelForVisibility(String value) {
    switch (value.toLowerCase()) {
      case 'private':
      case 'hidden':
        return 'Riêng tư';
      case 'protected':
      case 'shared':
        return 'Chia sẻ';
      default:
        return 'Công khai';
    }
  }
}

class _TripMetaGrid extends StatelessWidget {
  final _TourMeta meta;
  final bool compact;

  const _TripMetaGrid({required this.meta, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final isVi = AppLocalizations.of(context)!.localeName == 'vi';
    final pills = [
      _MetaPill(
        icon: meta.visibilityIcon,
        label: _translateVisibility(meta.visibility, context),
        value: isVi ? 'Hiển thị' : 'Visibility',
        compact: compact,
      ),
      _MetaPill(
        icon: Icons.straighten_rounded,
        label: meta.totalDistanceMeters != null
            ? _formatDistance(meta.totalDistanceMeters!)
            : (isVi ? 'Chưa có' : 'N/A'),
        value: isVi ? 'Quãng đường' : 'Distance',
        compact: compact,
      ),
      _MetaPill(
        icon: Icons.payments_rounded,
        label: meta.estimatedCost != null
            ? (_formatMoneyRange(meta.estimatedCost, context) ?? (isVi ? 'Chưa có' : 'N/A'))
            : (isVi ? 'Chưa có' : 'N/A'),
        value: isVi ? 'Số tiền dự tính' : 'Estimated Cost',
        compact: compact,
      ),
      _MetaPill(
        icon: _paceIcon(meta.pace),
        label: _paceLabel(meta.pace, context),
        value: isVi ? 'Nhịp độ' : 'Pace',
        compact: compact,
      ),
      _MetaPill(
        icon: _transportIcon(meta.transportMode),
        label: _transportLabel(meta.transportMode, context),
        value: isVi ? 'Phương tiện' : 'Transport',
        compact: compact,
      ),
      _MetaPill(
        icon: Icons.people_alt_rounded,
        label: isVi
            ? '${meta.adults} lớn, ${meta.children} trẻ'
            : '${meta.adults} adults, ${meta.children} kids',
        value: isVi ? 'Người đi' : 'Travelers',
        compact: compact,
      ),
      _MetaPill(
        icon: Icons.event_available_rounded,
        label: isVi
            ? '${meta.totalDays} ngày ${meta.totalNights} đêm'
            : '${meta.totalDays} days ${meta.totalNights} nights',
        value: isVi ? 'Thời lượng' : 'Duration',
        compact: compact,
      ),
    ];

    if (compact) {
      return SizedBox(
        height: 46,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: pills.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, index) => pills[index],
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: pills,
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool compact;

  const _MetaPill({
    required this.icon,
    required this.value,
    required this.label,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 14,
        vertical: compact ? 6 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFD4AF7A), size: compact ? 14 : 18),
          SizedBox(width: compact ? 7 : 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ).copyWith(fontSize: compact ? 11 : 12),
              ),
              SizedBox(height: compact ? 0 : 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: compact ? 9 : 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VisibilityBadge extends StatelessWidget {
  final IconData icon;
  final bool compact;
  final bool isLoading;
  final VoidCallback? onTap;

  const _VisibilityBadge({
    required this.icon,
    this.compact = false,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 17.0 : 20.0;
    final badge = Container(
      padding: EdgeInsets.all(compact ? 8 : 10),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF7A).withOpacity(onTap == null ? 0.12 : 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD4AF7A).withOpacity(onTap == null ? 0.2 : 0.42)),
      ),
      child: isLoading
          ? SizedBox(
              width: size,
              height: size,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFD4AF7A),
              ),
            )
          : Icon(icon, color: const Color(0xFFD4AF7A), size: size),
    );
    if (onTap == null || isLoading) return badge;
    return Tooltip(
      message: AppLocalizations.of(context)!.localeName == 'vi'
          ? 'Đổi trạng thái hiển thị'
          : 'Toggle itinerary visibility',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: badge,
      ),
    );
  }
}

double? _readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    final total = map['total'] ?? map['amount'] ?? map['value'] ?? map['max'] ?? map['min'];
    return _readDouble(total);
  }
  return null;
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String _formatDistance(double meters) {
  if (meters >= 1000) {
    final km = meters / 1000;
    return '${km.toStringAsFixed(km >= 10 ? 0 : 1)} km';
  }
  return '${meters.toStringAsFixed(0)} m';
}

String _formatMoney(double amount, BuildContext context) {
  final isVi = AppLocalizations.of(context)!.localeName == 'vi';
  final raw = amount.toInt().toString();
  final formatted = raw.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.');
  return isVi ? '$formatted đ' : '$formatted VND';
}

String? _formatMoneyRange(dynamic value, BuildContext context) {
  if (value == null) return null;

  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    final min = _readDouble(map['min'] ?? map['from'] ?? map['low']);
    final max = _readDouble(map['max'] ?? map['to'] ?? map['high']);

    if (min != null && max != null) {
      return '${_formatMoney(min, context)}-${_formatMoney(max, context)}';
    }
    if (min != null) {
      return _formatMoney(min, context);
    }
    if (max != null) {
      return _formatMoney(max, context);
    }
    return null;
  }

  final amount = _readDouble(value);
  if (amount == null) return null;
  return _formatMoney(amount, context);
}

String _paceLabel(String pace, BuildContext context) {
  final isVi = AppLocalizations.of(context)!.localeName == 'vi';
  switch (pace.toLowerCase()) {
    case 'fast':
      return isVi ? 'Nhanh' : 'Fast';
    case 'balanced':
      return isVi ? 'Cân bằng' : 'Balanced';
    case 'relaxed':
      return isVi ? 'Thư giãn' : 'Relaxed';
    default:
      return pace;
  }
}

IconData _paceIcon(String pace) {
  switch (pace.toLowerCase()) {
    case 'fast':
      return Icons.flash_on_rounded;
    case 'balanced':
      return Icons.balance_rounded;
    case 'relaxed':
      return Icons.spa_rounded;
    default:
      return Icons.speed_rounded;
  }
}

String _transportLabel(String transportMode, BuildContext context) {
  final isVi = AppLocalizations.of(context)!.localeName == 'vi';
  switch (transportMode.toLowerCase()) {
    case 'car':
      return isVi ? 'Ô tô' : 'Car';
    case 'motorbike':
      return isVi ? 'Xe máy' : 'Motorbike';
    case 'public':
      return isVi ? 'Công cộng' : 'Public';
    case 'auto':
      return isVi ? 'Tự động' : 'Auto';
    default:
      return transportMode;
  }
}

IconData _transportIcon(String transportMode) {
  switch (transportMode.toLowerCase()) {
    case 'car':
      return Icons.directions_car_rounded;
    case 'motorbike':
      return Icons.two_wheeler_rounded;
    case 'public':
      return Icons.directions_bus_rounded;
    case 'auto':
      return Icons.auto_mode_rounded;
    default:
      return Icons.route_rounded;
  }
}

class _ItineraryDayCard extends StatelessWidget {
  final AiDailyItinerary day;
  const _ItineraryDayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final isVi = AppLocalizations.of(context)!.localeName == 'vi';
    // Find coordinates for the day's weather forecast
    double? lat;
    double? lon;
    String? placeName;
    for (var act in day.activities) {
      if (act.latitude != null && act.longitude != null) {
        lat = act.latitude;
        lon = act.longitude;
        placeName = act.placeName;
        break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFD4AF7A), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  isVi ? 'Ngày ${day.day}' : 'Day ${day.day}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              if (lat != null && lon != null) ...[
                const SizedBox(width: 8),
                WeatherWidget(
                  lat: lat,
                  lon: lon,
                  label: placeName,
                  compact: true,
                ),
              ],
              const SizedBox(width: 12),
              Expanded(child: Divider(color: Colors.white.withOpacity(0.06))),
            ],
          ),
          const SizedBox(height: 12),
          ...day.activities.map((act) => _buildActivityItem(act)).toList(),
        ],
      ),
    );
  }

  Widget _buildActivityItem(AiActivity act) {
    return _ActivityCardTile(act: act);
  }

}

class _ActivityCardTile extends StatefulWidget {
  final AiActivity act;
  const _ActivityCardTile({required this.act});

  @override
  State<_ActivityCardTile> createState() => _ActivityCardTileState();
}

class _ActivityCardTileState extends State<_ActivityCardTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final act = widget.act;
    final canOpenLocation = _hasValidLocation(act);

    return MouseRegion(
      cursor: canOpenLocation
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) {
        if (canOpenLocation) {
          setState(() => _hover = true);
        }
      },
      onExit: (_) {
        if (canOpenLocation) {
          setState(() => _hover = false);
        }
      },
      child: GestureDetector(
        onTap: canOpenLocation ? () => _openActivity(act) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: canOpenLocation && _hover ? const Color(0xFFD4AF7A) : Colors.white.withOpacity(0.04), width: canOpenLocation && _hover ? 1.6 : 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFD4AF7A).withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(_getTimeSlotIcon(act.timeSlot), color: const Color(0xFFD4AF7A), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _translateTimeSlot(act.timeSlot, context),
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.bold),
                        ),
                        if (act.estimatedCost > 0)
                          Text(
                            _formatMoney(act.estimatedCost, context),
                            style: TextStyle(color: Colors.white.withOpacity(0.6)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      act.placeName ?? (AppLocalizations.of(context)!.localeName == 'vi' ? 'Địa điểm' : 'Location'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(act.rationale, style: TextStyle(color: Colors.white.withOpacity(0.7))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTimeSlotIcon(String slot) {
    if (slot.contains('Sáng')) return Icons.wb_sunny_rounded;
    if (slot.contains('Chiều')) return Icons.wb_cloudy_rounded;
    return Icons.nightlight_round;
  }

  String _translateTimeSlot(String slot, BuildContext context) {
    final isVi = AppLocalizations.of(context)!.localeName == 'vi';
    if (isVi) return slot;
    if (slot.contains('Sáng')) return 'Morning';
    if (slot.contains('Chiều')) return 'Afternoon';
    if (slot.contains('Tối')) return 'Evening';
    return slot;
  }

  Future<void> _openActivity(AiActivity act) async {
    if (act.placeId != null && act.placeId!.isNotEmpty) {
      // Try resolving to a real location document via sourceLocationId
      final doc = await fetchLocationBySourceId(
        act.placeId!,
        sourceCollection: act.sourceCollection,
      );
      final dest = doc != null
          ? Destination.fromJson(doc)
          : Destination(
              id: act.placeId,
              name: act.placeName ?? 'Địa điểm',
              province: '',
              price: '0',
              imagePath: '',
              bgBlurPath: '',
              latitude: act.latitude ?? 0.0,
              longitude: act.longitude ?? 0.0,
            );

      if (!mounted) return;
      Navigator.of(context).push(PageRouteBuilder(
        pageBuilder: (_, __, ___) => PlaceDetailScreen(
          destination: dest,
          useSimpleTransition: true,
        ),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ));
      return;
    }

    final dest = Destination(
      id: null,
      name: act.placeName ?? 'Địa điểm',
      province: '',
      price: '0',
      imagePath: '',
      bgBlurPath: '',
      latitude: act.latitude ?? 0.0,
      longitude: act.longitude ?? 0.0,
    );

    if (!mounted) return;
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, __, ___) => MapScreen(destination: dest),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
    ));
  }

  bool _hasValidLocation(AiActivity act) {
    final lat = act.latitude;
    final lng = act.longitude;

    return lat != null &&
        lng != null &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180 &&
        !(lat == 0.0 && lng == 0.0);
  }
}

String _translateVisibility(String val, BuildContext context) {
  final isVi = AppLocalizations.of(context)!.localeName == 'vi';
  if (isVi) {
    switch (val.toLowerCase()) {
      case 'private':
      case 'hidden':
        return 'Riêng tư';
      case 'protected':
      case 'shared':
        return 'Chia sẻ';
      default:
        return 'Công khai';
    }
  } else {
    switch (val.toLowerCase()) {
      case 'private':
      case 'hidden':
        return 'Private';
      case 'protected':
      case 'shared':
        return 'Shared';
      default:
        return 'Public';
    }
  }
}

String _translateProvince(String prov, BuildContext context) {
  final isVi = AppLocalizations.of(context)!.localeName == 'vi';
  if (isVi) return prov;
  final maps = {
    'Đà Nẵng': 'Da Nang',
    'Hà Nội': 'Hanoi',
    'TP. Hồ Chí Minh': 'Ho Chi Minh City',
    'Quảng Nam': 'Quang Nam',
    'Quảng Ninh': 'Quang Ninh',
    'Thừa Thiên Huế': 'Thua Thien Hue',
    'Khánh Hòa': 'Khanh Hoa',
    'Lào Cai': 'Lao Cai',
    'Ninh Bình': 'Ninh Binh',
    'Bình Thuận': 'Binh Thuan',
    'Kiên Giang': 'Kien Giang',
    'Bà Rịa - Vũng Tàu': 'Ba Ria - Vung Tau',
    'Quảng Bình': 'Quang Binh',
    'An Giang': 'An Giang',
    'Bạc Liêu': 'Bac Lieu',
    'Bắc Giang': 'Bac Giang',
    'Bắc Kạn': 'Bac Kan',
    'Bắc Ninh': 'Bac Ninh',
    'Bến Tre': 'Ben Tre',
    'Bình Dương': 'Binh Duong',
    'Bình Định': 'Binh Dinh',
    'Bình Phước': 'Binh Phước',
    'Cà Mau': 'Ca Mau',
    'Cao Bằng': 'Cao Bang',
    'Cần Thơ': 'Can Tho',
    'Đắk Lắk': 'Dak Lak',
    'Đắk Nông': 'Dak Nong',
    'Điện Biên': 'Dien Bien',
    'Đồng Nai': 'Dong Nai',
    'Đồng Tháp': 'Dong Thap',
    'Gia Lai': 'Gia Lai',
    'Hà Giang': 'Ha Giang',
    'Hà Nam': 'Ha Nam',
    'Hà Tĩnh': 'Ha Tinh',
    'Hải Dương': 'Hai Duong',
    'Hải Phòng': 'Hai Phong',
    'Hậu Giang': 'Hau Giang',
    'Hòa Bình': 'Hoa Binh',
    'Hưng Yên': 'Hung Yen',
    'Kon Tum': 'Kon Tum',
    'Lai Châu': 'Lai Chau',
    'Lạng Sơn': 'Lang Son',
    'Lâm Đồng': 'Lam Dong',
    'Long An': 'Long An',
    'Nam Định': 'Nam Dinh',
    'Nghệ An': 'Nghe An',
    'Ninh Thuận': 'Ninh Thuan',
    'Phú Thọ': 'Phu Tho',
    'Phú Yên': 'Phu Yen',
    'Quảng Ngãi': 'Quang Ngai',
    'Quảng Trị': 'Quang Tri',
    'Sóc Trăng': 'Soc Trang',
    'Sơn La': 'Son La',
    'Tây Ninh': 'Tay Ninh',
    'Thái Bình': 'Thai Binh',
    'Thái Nguyên': 'Thai Nguyen',
    'Thanh Hóa': 'Thanh Hoa',
    'Tiền Giang': 'Tien Giang',
    'Trà Vinh': 'Tra Vinh',
    'Tuyên Quang': 'Tuyen Quang',
    'Vĩnh Long': 'Vinh Long',
    'Vĩnh Phúc': 'Vinh Phuc',
    'Yên Bái': 'Yen Bai',
  };
  return maps[prov] ?? prov;
}
