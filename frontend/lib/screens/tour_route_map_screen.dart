import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/ai_trip_response.dart';
import '../utils/routing_service.dart';
import '../widgets/location_explanation_dialog.dart';
import '../widgets/route_metrics_card.dart';
import '../models/tour_map_models.dart';
import '../utils/tour_map_utils.dart';

import '../widgets/tour_map/tour_activity_card.dart';
import '../widgets/tour_map/tour_custom_marker.dart';
import '../widgets/tour_map/tour_day_selector.dart';
import '../widgets/tour_map/tour_route_summary.dart';

class TourRouteMapScreen extends StatefulWidget {
  final AiTripResponse tourData;

  const TourRouteMapScreen({super.key, required this.tourData});

  @override
  State<TourRouteMapScreen> createState() => _TourRouteMapScreenState();
}

class _TourRouteMapScreenState extends State<TourRouteMapScreen> with TickerProviderStateMixin {
  int _selectedDayIndex = -1; // -1: Tất cả các ngày, 0: Ngày 1, 1: Ngày 2...
  int? _focusedSegmentIndex;

  List<RouteSegment> _routeSegments = [];
  List<AiActivity> _currentStops = [];
  List<String> _locationNames = [];
  List<LatLng> _currentWaypoints = [];
  List<WaypointItem> _waypointItems = [];
  LatLng? _userLocation;
  bool _isLoading = true;
  double _routeDistanceKm = 0.0;
  double _routeDurationMin = 0.0;

  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStreamSubscription;
  AnimationController? _cameraAnimationController;

  AiActivity? _focusedActivity;
  bool _isBottomSheetMinimized = false;

  Map<int, List<RouteSegment>> _routeSegmentsCache = {};
  Map<int, double> _routeDistanceCache = {};
  Map<int, double> _routeDurationCache = {};

  @override
  void initState() {
    super.initState();
    _initMapData();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _cameraAnimationController?.dispose();
    super.dispose();
  }

  Future<void> _initMapData() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        final bool userAgreed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => const LocationExplanationDialog(),
        ) ?? false;
        if (userAgreed) {
          await Geolocator.openLocationSettings();
          serviceEnabled = await Geolocator.isLocationServiceEnabled();
        }
      }
    }

    if (serviceEnabled) {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          final bool userAgreed = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => const LocationExplanationDialog(),
          ) ?? false;
          if (userAgreed) {
            permission = await Geolocator.requestPermission();
          }
        }
      }

      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5),
          );
          _userLocation = LatLng(position.latitude, position.longitude);
          _startTracking();
        } catch (e) {
          debugPrint("Không lấy được vị trí GPS: $e");
        }
      }
    }

    _calculateRoute();
  }

  void _startTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      if (!mounted) return;
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    }, onError: (error) {
      debugPrint("Lỗi luồng định vị GPS: $error");
    });
  }

  Future<void> _calculateRoute() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _focusedSegmentIndex = null;
    });

    _currentStops.clear();
    _locationNames.clear();
    _currentWaypoints.clear();
    _waypointItems.clear();
    final itinerary = widget.tourData.data.itinerary;
    
    if (_selectedDayIndex == -1) {
      if (_userLocation != null) {
        _currentWaypoints.add(_userLocation!);
        _locationNames.add("Vị trí của bạn");
      }
      int currentWpIndex = _currentWaypoints.length;
      for (var day in itinerary) {
        for (var act in day.activities) {
          if (act.latitude != null && act.longitude != null) {
            final loc = LatLng(act.latitude!, act.longitude!);
            _currentWaypoints.add(loc);
            _locationNames.add(act.placeName ?? 'Địa điểm');
            _currentStops.add(act);
            _waypointItems.add(WaypointItem(location: loc, title: act.placeName ?? 'Địa điểm', activity: act, waypointIndex: currentWpIndex));
            currentWpIndex++;
          } else {
            _waypointItems.add(WaypointItem(location: null, title: act.placeName ?? 'Địa điểm', activity: act, waypointIndex: null));
          }
        }
      }
    } else if (_selectedDayIndex >= 0 && _selectedDayIndex < itinerary.length) {
      if (_selectedDayIndex == 0) {
        if (_userLocation != null) {
          _currentWaypoints.add(_userLocation!);
          _locationNames.add("Vị trí của bạn");
        }
      } else {
        AiActivity? lastActPrevDay;
        for (int d = _selectedDayIndex - 1; d >= 0; d--) {
          final acts = itinerary[d].activities.where((a) => a.latitude != null && a.longitude != null).toList();
          if (acts.isNotEmpty) {
            lastActPrevDay = acts.last;
            break;
          }
        }
        
        if (lastActPrevDay != null) {
          final loc = LatLng(lastActPrevDay.latitude!, lastActPrevDay.longitude!);
          _currentWaypoints.add(loc);
          _locationNames.add(lastActPrevDay.placeName ?? 'Điểm kết thúc ngày trước');
        } else if (_userLocation != null) {
          _currentWaypoints.add(_userLocation!);
          _locationNames.add("Vị trí của bạn");
        }
      }

      int currentWpIndex = _currentWaypoints.length;
      for (var act in itinerary[_selectedDayIndex].activities) {
        if (act.latitude != null && act.longitude != null) {
          final loc = LatLng(act.latitude!, act.longitude!);
          _currentWaypoints.add(loc);
          _locationNames.add(act.placeName ?? 'Địa điểm');
          _currentStops.add(act);
          _waypointItems.add(WaypointItem(location: loc, title: act.placeName ?? 'Địa điểm', activity: act, waypointIndex: currentWpIndex));
          currentWpIndex++;
        } else {
          _waypointItems.add(WaypointItem(location: null, title: act.placeName ?? 'Địa điểm', activity: act, waypointIndex: null));
        }
      }
    }

    if (_routeSegmentsCache.containsKey(_selectedDayIndex)) {
      setState(() {
        _routeSegments = _routeSegmentsCache[_selectedDayIndex]!;
        _routeDistanceKm = _routeDistanceCache[_selectedDayIndex]!;
        _routeDurationMin = _routeDurationCache[_selectedDayIndex]!;
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapBounds());
      return;
    }

    if (_currentWaypoints.length >= 2) {
      List<RouteSegment> segments = [];
      double totalDist = 0;
      double totalDur = 0;

      if (_selectedDayIndex == -1) {
        final routeResult = await RoutingService.getMultiStopRoute(_currentWaypoints);
        totalDist = routeResult.distanceKm;
        totalDur = routeResult.durationMinutes;
        segments.add(RouteSegment(
          points: routeResult.points,
          distanceKm: routeResult.distanceKm,
          durationMin: routeResult.durationMinutes,
          color: const Color(0xFFB5956A),
        ));
      } else {
        List<Future<RouteResult>> futures = [];
        for (int i = 0; i < _currentWaypoints.length - 1; i++) {
          futures.add(RoutingService.getRoute(_currentWaypoints[i], _currentWaypoints[i+1]));
        }
        
        final results = await Future.wait(futures);
        
        for (int i = 0; i < results.length; i++) {
          totalDist += results[i].distanceKm;
          totalDur += results[i].durationMinutes;
          segments.add(RouteSegment(
            points: results[i].points,
            distanceKm: results[i].distanceKm,
            durationMin: results[i].durationMinutes,
            color: TourMapUtils.getColorForIndex(i + 1),
          ));
        }
      }

      if (mounted) {
        _routeSegmentsCache[_selectedDayIndex] = List.from(segments);
        _routeDistanceCache[_selectedDayIndex] = totalDist;
        _routeDurationCache[_selectedDayIndex] = totalDur;

        setState(() {
          _routeSegments = segments;
          _routeDistanceKm = totalDist;
          _routeDurationMin = totalDur;
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapBounds());
      }
    } else {
      if (mounted) {
        setState(() {
          _routeSegments = [];
          _routeDistanceKm = 0.0;
          _routeDurationMin = 0.0;
          _isLoading = false;
        });
        if (_currentWaypoints.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
             _animatedMapMove(_currentWaypoints.first, 14.0);
          });
        } else if (_userLocation != null) {
           WidgetsBinding.instance.addPostFrameCallback((_) {
             _animatedMapMove(_userLocation!, 14.0);
          });
        }
      }
    }
  }

  void _fitMapBounds([List<LatLng>? specificPoints]) {
    final pointsToFit = specificPoints ?? _currentWaypoints;
    if (pointsToFit.isEmpty) return;
    
    List<LatLng> allPoints = List.from(pointsToFit);
    if (specificPoints == null) {
      for (var seg in _routeSegments) {
        allPoints.addAll(seg.points);
      }
    } else {
      if (_focusedSegmentIndex != null && _focusedSegmentIndex! < _routeSegments.length) {
        allPoints.addAll(_routeSegments[_focusedSegmentIndex!].points);
      }
    }
    
    if (allPoints.isEmpty) return;

    final cameraFit = CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(allPoints),
      padding: const EdgeInsets.all(80.0),
    );
    final fitted = cameraFit.fit(_mapController.camera);
    _animatedMapMove(fitted.center, fitted.zoom);
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    _cameraAnimationController?.stop();
    _cameraAnimationController?.dispose();

    final camera = _mapController.camera;
    final latTween = Tween<double>(begin: camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: camera.zoom, end: destZoom);

    _cameraAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    final animation = CurvedAnimation(
      parent: _cameraAnimationController!,
      curve: Curves.fastOutSlowIn,
    );

    _cameraAnimationController!.addListener(() {
      if (!mounted) return;
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    _cameraAnimationController!.forward();
  }





  Widget _buildDesktopStatCard(String title, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF7A).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFD4AF7A), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineList(bool isDesktop) {
    final itinerary = widget.tourData.data.itinerary;
    final List<Widget> items = [];
    
    for (var day in itinerary) {
      items.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12, top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF7A).withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Ngày ${day.day}',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      );
      
      for (var act in day.activities) {
        items.add(TourActivityCard(
          act: act,
          isSelected: _focusedActivity == act,
          onTap: () {
            setState(() {
              if (_focusedActivity == act) {
                _focusedActivity = null;
                _fitMapBounds();
              } else {
                _focusedActivity = act;
                if (act.latitude != null && act.longitude != null) {
                  _animatedMapMove(LatLng(act.latitude!, act.longitude!), 15.0);
                }
              }
            });
          },
          isDesktop: isDesktop,
        ));
      }
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }



  DateTime? _parseEndTime(String timeSlot) {
    try {
      if (!timeSlot.contains('-')) return null;
      final parts = timeSlot.split('-');
      if (parts.length < 2) return null;
      final endPart = parts[1].trim(); 
      final timeParts = endPart.split(':');
      if (timeParts.length >= 2) {
        final hour = int.tryParse(timeParts[0].trim());
        final min = int.tryParse(timeParts[1].trim());
        if (hour != null && min != null) {
          final now = DateTime.now();
          return DateTime(now.year, now.month, now.day, hour, min);
        }
      }
    } catch (_) {}
    return null;
  }

  Widget _buildLocationList({bool isDesktop = false}) {
    DateTime? segmentStartTime;
    if (_focusedSegmentIndex != null) {
      try {
        final startItem = _waypointItems.firstWhere(
          (w) => w.waypointIndex == _focusedSegmentIndex,
        );
        if (startItem.activity != null && startItem.activity!.timeSlot.isNotEmpty) {
          segmentStartTime = _parseEndTime(startItem.activity!.timeSlot);
        }
      } catch (_) {}
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_focusedSegmentIndex != null && _focusedSegmentIndex! < _routeSegments.length)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: RouteMetricsCard(
              routeDurationMin: _routeSegments[_focusedSegmentIndex!].durationMin,
              routeDistanceKm: _routeSegments[_focusedSegmentIndex!].distanceKm,
              startTime: segmentStartTime,
              onClose: () {
                setState(() {
                  _focusedSegmentIndex = null;
                });
                _fitMapBounds();
              },
            ),
          ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: _waypointItems.length,
            itemBuilder: (context, i) {
              final item = _waypointItems[i];
              final wpIndex = item.waypointIndex;
              
              bool isHighlighted = true;
              bool isSelected = false;
              if (_focusedSegmentIndex != null && wpIndex != null) {
                isSelected = (wpIndex == _focusedSegmentIndex) || (wpIndex == _focusedSegmentIndex! + 1);
                isHighlighted = isSelected;
              } else if (_focusedSegmentIndex != null && wpIndex == null) {
                isHighlighted = false;
              }
              
              final markerColor = wpIndex != null ? TourMapUtils.getColorForIndex(wpIndex) : null;
              
              VoidCallback? onTap;
              if (wpIndex != null) {
                onTap = () {
                  setState(() {
                    int targetSegment = wpIndex == 0 ? 0 : wpIndex - 1;
                    if (_focusedSegmentIndex == targetSegment) {
                      _focusedSegmentIndex = null; 
                      WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapBounds());
                    } else {
                      _focusedSegmentIndex = targetSegment; 
                      if (_focusedSegmentIndex! < _currentWaypoints.length - 1) {
                         WidgetsBinding.instance.addPostFrameCallback((_) {
                           _fitMapBounds([_currentWaypoints[_focusedSegmentIndex!], _currentWaypoints[_focusedSegmentIndex! + 1]]);
                         });
                      }
                    }
                  });
                };
              }
              
              return TourActivityCard(
                act: item.activity!, 
                onTap: onTap, 
                isHighlighted: isHighlighted, 
                isSelected: isSelected, 
                markerColor: markerColor, 
                isDesktop: isDesktop
              );
            }
          ),
        ),
      ],
    );
  }

  Widget _buildMapLayer(bool isAllDaysMode, bool hasUserLoc) {
    return RepaintBoundary(
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _userLocation ?? TourMapUtils.fallbackStart,
          initialZoom: 12.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.tourxport',
          ),
        if (_routeSegments.isNotEmpty)
          PolylineLayer(
            polylines: _routeSegments.asMap().entries.where((entry) {
              if (_focusedSegmentIndex == null) return true;
              return entry.key == _focusedSegmentIndex;
            }).map((entry) {
              final seg = entry.value;
              return Polyline(
                points: seg.points,
                strokeWidth: 6.0,
                color: seg.color.withOpacity(0.9),
                borderColor: Colors.black.withOpacity(0.8),
                borderStrokeWidth: 2.0,
              );
            }).toList(),
          ),
        MarkerLayer(
          markers: [
            for (int i = 0; i < _currentWaypoints.length; i++)
              if (_focusedSegmentIndex == null || _focusedSegmentIndex == i || _focusedSegmentIndex == i - 1)
                Marker(
                  point: _currentWaypoints[i],
                  width: (i == 0 && hasUserLoc) ? 50 : 40,
                  height: (i == 0 && hasUserLoc) ? 50 : 40,
                  alignment: Alignment.center,
                  child: (i == 0 && hasUserLoc)
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isAllDaysMode ? const Color(0xFFB5956A).withOpacity(0.2) : TourMapUtils.getColorForIndex(0).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: isAllDaysMode ? const Color(0xFFB5956A) : TourMapUtils.getColorForIndex(0),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: isAllDaysMode ? const Color(0xFFB5956A).withOpacity(0.6) : TourMapUtils.getColorForIndex(0).withOpacity(0.6),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : TourCustomMarker(
                        text: hasUserLoc ? '$i' : '${i + 1}',
                        color: isAllDaysMode ? const Color(0xFFE74C3C) : TourMapUtils.getColorForIndex(i),
                      ),
                ),
          ],
        ),
      ],
    ));
  }
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final isAllDaysMode = _selectedDayIndex == -1;
    final hasUserLoc = _userLocation != null && (isAllDaysMode || _selectedDayIndex == 0);

    // Xây dựng widget Bản đồ chính
    final mapWidget = Stack(
      children: [
        _buildMapLayer(isAllDaysMode, hasUserLoc),
        
        // Trên mobile, day selector nằm trên map
        if (!isDesktop)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TourDaySelector(
              itinerary: widget.tourData.data.itinerary,
              selectedDayIndex: _selectedDayIndex,
              onDaySelected: (index) {
                setState(() {
                  _selectedDayIndex = index;
                });
                _calculateRoute();
              },
            ),
          ),
          
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(color: Color(0xFFD4AF7A)),
          ),
          
        // Thẻ hiển thị dưới cùng trên Mobile
        if (!isDesktop && !_isLoading && _locationNames.isNotEmpty)
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: RepaintBoundary(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  constraints: BoxConstraints(
                    maxHeight: _isBottomSheetMinimized ? 210 : MediaQuery.of(context).size.height * 0.35,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isBottomSheetMinimized = !_isBottomSheetMinimized;
                          });
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: double.infinity,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      Flexible(
                        child: isAllDaysMode ? _buildTimelineList(isDesktop) : _buildLocationList(isDesktop: isDesktop),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    if (isDesktop) {
      // GIAO DIỆN DESKTOP / WEB
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Row(
          children: [
            // Side Panel (Cột điều khiển bên trái)
            RepaintBoundary(
              child: Container(
                width: 380,
                color: const Color(0xFF0F1E1B),
                padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nút quay lại & Tiêu đề
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Bản đồ Lộ trình',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (!_isLoading && _currentWaypoints.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.zoom_out_map_rounded, color: Color(0xFFD4AF7A)),
                          tooltip: 'Xem toàn bộ đường đi',
                          onPressed: () {
                            setState(() {
                              _focusedSegmentIndex = null;
                            });
                            _fitMapBounds();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Component điều khiển ngày
                  TourDaySelector(
                    itinerary: widget.tourData.data.itinerary,
                    selectedDayIndex: _selectedDayIndex,
                    onDaySelected: (index) {
                      setState(() {
                        _selectedDayIndex = index;
                      });
                      _calculateRoute();
                    },
                  ),
                  
                  if (isAllDaysMode) ...[
                    const SizedBox(height: 16),
                    Divider(color: Colors.white.withOpacity(0.1), thickness: 1),
                    const SizedBox(height: 8),
                  ] else ...[
                    const SizedBox(height: 24),
                  ],

                  // Component thông tin/danh sách
                  if (_isLoading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF7A))),
                    )
                  else if (_locationNames.isNotEmpty)
                    Expanded(
                      child: isAllDaysMode 
                          ? _buildTimelineList(isDesktop)
                          : _buildLocationList(isDesktop: isDesktop),
                    ),
                    
                  TourRouteSummary(
                    routeDistanceKm: _routeDistanceKm,
                    routeDurationMin: _routeDurationMin,
                    stopsCount: _currentStops.length,
                  ),
                  const SizedBox(height: 16),
                    
                  // Thông báo trạng thái tuyến đường từ OSRM
                  if (!_isLoading && _routeSegments.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(top: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2D6A4F).withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF2D6A4F), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tuyến đường tối ưu đã được tính toán từ OSRM.',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            ),
            // Bản đồ bên phải
            Expanded(
              child: mapWidget,
            ),
          ],
        ),
      );
    } else {
      // GIAO DIỆN MOBILE
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Bản đồ Lộ trình',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          elevation: 0,
          backgroundColor: const Color(0xFF1E1E1E),
          centerTitle: true,
          actions: [
            if (!_isLoading && _currentWaypoints.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.zoom_out_map_rounded, color: Color(0xFFD4AF7A)),
                tooltip: 'Xem toàn bộ đường đi',
                onPressed: () {
                  setState(() {
                    _focusedSegmentIndex = null;
                  });
                  _fitMapBounds();
                },
              ),
          ],
        ),
        body: mapWidget,
      );
    }
  }
}


