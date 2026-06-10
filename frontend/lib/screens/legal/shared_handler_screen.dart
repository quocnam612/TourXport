import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../api/api.dart';
import '../../models/destination.dart';
import '../../utils/auth_storage.dart';
import '../place_detail.dart';
import '../saved_tour_detail.dart';

class SharedHandlerScreen extends StatefulWidget {
  final String id;
  final String type; // 'tour', 'place', 'restaurant', or 'hotel'

  const SharedHandlerScreen({
    super.key,
    required this.id,
    required this.type,
  });

  @override
  State<SharedHandlerScreen> createState() => _SharedHandlerScreenState();
}

class _SharedHandlerScreenState extends State<SharedHandlerScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasStartedLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasStartedLoading) return;
    _hasStartedLoading = true;
    _loadSharedResource();
  }

  Future<void> _loadSharedResource() async {
    try {
      final isVi = Localizations.localeOf(context).languageCode == 'vi';
      final token = await AuthStorage.getToken();
      final userName = await AuthStorage.getUserName() ?? (isVi ? 'Thành viên' : 'Member');

      print('SharedHandlerScreen: _loadSharedResource called with id: ${widget.id}, type: ${widget.type}');
      print('SharedHandlerScreen: token present: ${token != null}');

      if (widget.type.toLowerCase() == 'tour') {
        print('SharedHandlerScreen: Fetching public tour detail from /tours/${widget.id}');
        var response = await apiGet('/tours/${widget.id}', token: token).timeout(const Duration(seconds: 10));
        print('SharedHandlerScreen: Public tour response status: ${response.statusCode}');
        var data = tryDecodeJsonObject(response.body);
        var canEditTour = false;

        // 2. Fallback to private tour endpoint if unauthorized/not found and we have a session
        if ((response.statusCode != 200 || data?['success'] != true) && token != null) {
          print('SharedHandlerScreen: Public tour fetch failed or success is false. Falling back to /tours/my-tours/${widget.id}');
          response = await apiGet('/tours/my-tours/${widget.id}', token: token).timeout(const Duration(seconds: 10));
          print('SharedHandlerScreen: Private tour response status: ${response.statusCode}');
          data = tryDecodeJsonObject(response.body);
          canEditTour = response.statusCode == 200 && data?['success'] == true;
        }

        if (response.statusCode == 200 && data?['success'] == true && data?['data'] != null) {
          print('SharedHandlerScreen: Tour data loaded successfully');
          final tourData = data!['data'] as Map<String, dynamic>;
          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SavedTourDetailScreen(
                tourTitle: tourData['title'] ?? (isVi ? 'Lịch trình được chia sẻ' : 'Shared Tour'),
                tourJson: tourData,
                userName: userName,
                authToken: token,
                canEditTitle: canEditTour,
              ),
            ),
          );
        } else {
          print('SharedHandlerScreen: Tour data failed to load. status: ${response.statusCode}, body: ${response.body}');
          throw Exception(data?['message'] ?? (isVi ? 'Không tìm thấy lịch trình du lịch.' : 'Tour not found.'));
        }
      } else {
        // 3. Fetch location details based on type
        String endpoint;
        final normalizedType = widget.type.trim().toLowerCase();
        if (normalizedType == 'hotel' ||
            normalizedType.contains('khách sạn') ||
            normalizedType.contains('khach san')) {
          endpoint = '/hotels/search?id=${widget.id}';
        } else if (normalizedType == 'restaurant' ||
            normalizedType.contains('nhà hàng') ||
            normalizedType.contains('nha hang')) {
          endpoint = '/restaurants/search?id=${widget.id}';
        } else {
          endpoint = '/locations/search?id=${widget.id}';
        }

        print('SharedHandlerScreen: Fetching location detail from $endpoint');
        final response = await apiGet(endpoint, token: token).timeout(const Duration(seconds: 10));
        print('SharedHandlerScreen: Location response status: ${response.statusCode}');
        final data = tryDecodeJsonObject(response.body);

        if (response.statusCode == 200 && data?['success'] == true && data?['data'] != null) {
          print('SharedHandlerScreen: Location data loaded successfully');
          final placeJson = data!['data'];
          
          // The search endpoint might return a list or a single object.
          Map<String, dynamic>? item;
          if (placeJson is List && placeJson.isNotEmpty) {
            item = Map<String, dynamic>.from(placeJson.first);
          } else if (placeJson is Map) {
            item = Map<String, dynamic>.from(placeJson);
          }

          if (item != null) {
            final Destination dest = Destination.fromJson(item);
            if (!mounted) return;

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PlaceDetailScreen(
                  destination: dest,
                  authToken: token,
                  useSimpleTransition: true,
                ),
              ),
            );
          } else {
            print('SharedHandlerScreen: Location data is null or empty in response');
            throw Exception(isVi ? 'Không tìm thấy thông tin địa điểm.' : 'Place data not found.');
          }
        } else {
          print('SharedHandlerScreen: Location data failed to load. status: ${response.statusCode}, body: ${response.body}');
          throw Exception(data?['message'] ?? (isVi ? 'Không tìm thấy địa điểm được chia sẻ.' : 'Shared place not found.'));
        }
      }
    } catch (e, stack) {
      print('SharedHandlerScreen: Error loading resource: $e');
      print('SharedHandlerScreen: Stack trace: $stack');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/login_bg.jpg', fit: BoxFit.cover),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(color: Colors.black.withOpacity(0.65)),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    padding: const EdgeInsets.all(32.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isLoading) ...[
                          const SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              strokeWidth: 3.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF7A)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            isVi ? 'Đang tải dữ liệu...' : 'Loading data...',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isVi ? 'Vui lòng chờ trong giây lát' : 'Please wait a moment',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.55),
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.12),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
                            ),
                            child: const Icon(
                              Icons.error_outline_rounded,
                              color: Colors.redAccent,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            isVi ? 'Lỗi liên kết chia sẻ' : 'Share Link Error',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage ?? (isVi ? 'Có lỗi xảy ra khi tải tài nguyên.' : 'An error occurred while loading the resource.'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              height: 1.45,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                              },
                              icon: const Icon(Icons.home_rounded, size: 20),
                              label: Text(
                                isVi ? 'Về trang chủ' : 'Back to Home',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD4AF7A),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
