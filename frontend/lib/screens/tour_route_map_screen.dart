import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/ai_trip_response.dart';
import '../utils/routing_service.dart';
import '../widgets/location_explanation_dialog.dart';
import '../models/tour_map_models.dart';
import '../utils/tour_map_utils.dart';
import '../services/map_location_service.dart';

import '../widgets/tour_map/tour_day_selector.dart';
import '../widgets/tour_map/tour_route_summary.dart';
import '../widgets/tour_map/states/map_loading_state.dart';
import '../widgets/tour_map/states/map_error_state.dart';
import '../widgets/tour_map/lists/map_timeline_list.dart';
import '../widgets/tour_map/lists/map_location_list.dart';
import '../widgets/tour_map/map_layer_view.dart';

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
  bool _hasError = false;
  double _routeDistanceKm = 0.0;
  double _routeDurationMin = 0.0;

  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStreamSubscription;
  AnimationController? _cameraAnimationController;

  AiActivity? _focusedActivity;

  final Map<int, List<RouteSegment>> _routeSegmentsCache = {};
  final Map<int, double> _routeDistanceCache = {};
  final Map<int, double> _routeDurationCache = {};

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
    bool hasPermission = await MapLocationService.handleLocationPermission(() async {
      if (!mounted) return false;
      return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const LocationExplanationDialog(),
      ) ?? false;
    });

    if (hasPermission) {
      final pos = await MapLocationService.getCurrentPosition();
      if (pos != null) {
        _userLocation = LatLng(pos.latitude, pos.longitude);
        _startTracking();
      }
    }

    _calculateRoute();
  }

  void _startTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = MapLocationService.getPositionStream().listen((Position position) {
      if (!mounted) return;
      setState(() => _userLocation = LatLng(position.latitude, position.longitude));
    }, onError: (error) => debugPrint("Lỗi luồng định vị GPS: $error"));
  }

  Future<void> _calculateRoute() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _focusedSegmentIndex = null;
    });

    _prepareWaypointsForSelectedDay();

    if (_routeSegmentsCache.containsKey(_selectedDayIndex)) {
      final cachedRoute = _routeSegmentsCache[_selectedDayIndex]!;
      if (cachedRoute.isNotEmpty && _currentWaypoints.isNotEmpty) {
        final cachedStartPoint = cachedRoute.first.points.first;
        final currentStartPoint = _currentWaypoints.first;
        
        final distance = Geolocator.distanceBetween(
          cachedStartPoint.latitude, cachedStartPoint.longitude,
          currentStartPoint.latitude, currentStartPoint.longitude,
        );
        
        if (distance < 50.0) { 
          _applyCachedRoute();
          return;
        }
      } else {
        _applyCachedRoute();
        return;
      }
    }

    await _fetchRoutesForWaypoints();
  }

  void _prepareWaypointsForSelectedDay() {
    _currentStops.clear();
    _locationNames.clear();
    _currentWaypoints.clear();
    _waypointItems.clear();
    final itinerary = widget.tourData.data.itinerary;
    
    if (_selectedDayIndex == -1) {
      if (_userLocation != null) {
        _addWaypoint(_userLocation!, "Vị trí của bạn", null, _currentWaypoints.length);
      }
      for (var day in itinerary) {
        for (var act in day.activities) {
          _processActivityWaypoint(act);
        }
      }
    } else if (_selectedDayIndex >= 0 && _selectedDayIndex < itinerary.length) {
      if (_selectedDayIndex == 0) {
        if (_userLocation != null) {
          _addWaypoint(_userLocation!, "Vị trí của bạn", null, _currentWaypoints.length);
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
          _addWaypoint(LatLng(lastActPrevDay.latitude!, lastActPrevDay.longitude!), 
                       lastActPrevDay.placeName ?? 'Điểm kết thúc ngày trước', null, _currentWaypoints.length);
        } else if (_userLocation != null) {
          _addWaypoint(_userLocation!, "Vị trí của bạn", null, _currentWaypoints.length);
        }
      }

      for (var act in itinerary[_selectedDayIndex].activities) {
        _processActivityWaypoint(act);
      }
    }
  }

  void _addWaypoint(LatLng loc, String name, AiActivity? act, int index) {
    _currentWaypoints.add(loc);
    _locationNames.add(name);
    if (act != null) _currentStops.add(act);
    _waypointItems.add(WaypointItem(location: loc, title: name, activity: act, waypointIndex: index));
  }

  void _processActivityWaypoint(AiActivity act) {
    if (act.latitude != null && act.longitude != null) {
      _addWaypoint(LatLng(act.latitude!, act.longitude!), act.placeName ?? 'Địa điểm', act, _currentWaypoints.length);
    } else {
      _waypointItems.add(WaypointItem(location: null, title: act.placeName ?? 'Địa điểm', activity: act, waypointIndex: null));
    }
  }

  void _applyCachedRoute() {
    setState(() {
      _routeSegments = _routeSegmentsCache[_selectedDayIndex]!;
      _routeDistanceKm = _routeDistanceCache[_selectedDayIndex]!;
      _routeDurationMin = _routeDurationCache[_selectedDayIndex]!;
      _isLoading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapBounds());
  }

  Future<void> _fetchRoutesForWaypoints() async {
    final int fetchingDayIndex = _selectedDayIndex;
    if (_currentWaypoints.length >= 2) {
      List<RouteSegment> segments = [];
      double totalDist = 0;
      double totalDur = 0;

      try {
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
          final List<RouteResult> results = [];
          for (int i = 0; i < _currentWaypoints.length - 1; i++) {
            try {
              final res = await RoutingService.getRoute(_currentWaypoints[i], _currentWaypoints[i+1]);
              results.add(res);
            } catch (routeError) {
              debugPrint("Chặng $i bị lỗi, bỏ qua: $routeError");
            }
          }
          
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

        if (mounted && _selectedDayIndex == fetchingDayIndex) {
          _routeSegmentsCache[fetchingDayIndex] = List.from(segments);
          _routeDistanceCache[fetchingDayIndex] = totalDist;
          _routeDurationCache[fetchingDayIndex] = totalDur;

          setState(() {
            _routeSegments = segments;
            _routeDistanceKm = totalDist;
            _routeDurationMin = totalDur;
            _isLoading = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapBounds());
        }
      } catch (e) {
        debugPrint("Error fetching route: $e");
        if (mounted && _selectedDayIndex == fetchingDayIndex) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
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
          WidgetsBinding.instance.addPostFrameCallback((_) => _animatedMapMove(_currentWaypoints.first, 14.0));
        } else if (_userLocation != null) {
           WidgetsBinding.instance.addPostFrameCallback((_) => _animatedMapMove(_userLocation!, 14.0));
        }
      }
    }
  }

  void _fitMapBounds([List<LatLng>? specificPoints]) {
    final pointsToFit = specificPoints ?? _currentWaypoints;
    if (pointsToFit.isEmpty) return;
    
    if (pointsToFit.length == 1 && (specificPoints != null || _routeSegments.isEmpty)) {
      _animatedMapMove(pointsToFit.first, 15.0);
      return;
    }
    
    LatLngBounds bounds = LatLngBounds.fromPoints(pointsToFit);
    
    if (specificPoints == null) {
      for (var seg in _routeSegments) {
        for (var point in seg.points) {
          bounds.extend(point);
        }
      }
    } else {
      if (_focusedSegmentIndex != null && _focusedSegmentIndex! < _routeSegments.length) {
        for (var point in _routeSegments[_focusedSegmentIndex!].points) {
          bounds.extend(point);
        }
      }
    }
    
    final cameraFit = CameraFit.bounds(
      bounds: bounds,
      padding: const EdgeInsets.only(left: 40, right: 40, top: 80, bottom: 350),
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

    _cameraAnimationController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    final animation = CurvedAnimation(parent: _cameraAnimationController!, curve: Curves.fastOutSlowIn);

    _cameraAnimationController!.addListener(() {
      if (!mounted) return;
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    _cameraAnimationController!.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final isAllDaysMode = _selectedDayIndex == -1;
    final hasUserLoc = _userLocation != null && (isAllDaysMode || _selectedDayIndex == 0);

    final mapWidget = Stack(
      children: [
        MapLayerView(
          mapController: _mapController,
          userLocation: _userLocation,
          routeSegments: _routeSegments,
          currentWaypoints: _currentWaypoints,
          focusedSegmentIndex: _focusedSegmentIndex,
          isAllDaysMode: isAllDaysMode,
          hasUserLoc: hasUserLoc,
        ),
        if (_isLoading)
          Container(color: Colors.black.withOpacity(0.2)),
        if (_isLoading)
          const Positioned(
            top: 0, left: 0, right: 0,
            child: LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF7A)),
            ),
          ),
        if (!isDesktop)
          Positioned(
            top: 0, left: 0, right: 0,
            child: TourDaySelector(
              itinerary: widget.tourData.data.itinerary,
              selectedDayIndex: _selectedDayIndex,
              onDaySelected: (index) {
                setState(() => _selectedDayIndex = index);
                _calculateRoute();
              },
            ),
          ),
        Positioned(
          right: 16,
          bottom: MediaQuery.of(context).size.height * 0.38, 
          child: Column(
            children: [
              if (_userLocation != null || _focusedSegmentIndex != null)
                FloatingActionButton.small(
                  heroTag: 'zoom_origin',
                  backgroundColor: const Color(0xFF1E1E1E),
                  tooltip: _focusedSegmentIndex != null ? 'Xem điểm đi' : 'Vị trí của bạn',
                  child: Icon(
                    _focusedSegmentIndex != null ? Icons.trip_origin : Icons.my_location, 
                    color: Colors.blueAccent,
                  ),
                  onPressed: () {
                    if (_focusedSegmentIndex != null && _focusedSegmentIndex! < _currentWaypoints.length) {
                      _animatedMapMove(_currentWaypoints[_focusedSegmentIndex!], 16.0);
                    } else if (_userLocation != null) {
                      _animatedMapMove(_userLocation!, 15.0);
                    }
                  },
                ),
              if (_focusedSegmentIndex != null && _focusedSegmentIndex! + 1 < _currentWaypoints.length)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: FloatingActionButton.small(
                    heroTag: 'zoom_dest',
                    backgroundColor: const Color(0xFF1E1E1E),
                    tooltip: 'Xem điểm đến',
                    child: const Icon(Icons.place, color: Color(0xFFE74C3C)),
                    onPressed: () {
                      final dest = _currentWaypoints[_focusedSegmentIndex! + 1];
                      _animatedMapMove(dest, 16.0);
                    },
                  ),
                ),
            ],
          ),
        ),
        if (!isDesktop && (_isLoading || _hasError || _locationNames.isNotEmpty))
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.18,
            maxChildSize: 0.85,
            snap: false,
            builder: (context, scrollController) {
              return RepaintBoundary(
                child: Container(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E).withOpacity(0.95),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
                  ),
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        controller: scrollController,
                        physics: const ClampingScrollPhysics(),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(bottom: 16, top: 8),
                            child: Center(
                              child: Column(
                                children: [
                                  Container(
                                    width: 40, height: 4, 
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(2))
                                  ),
                                  if (_routeDistanceKm > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12.0),
                                      child: Text(
                                        "🚗 Tổng di chuyển: ${TourMapUtils.formatDistance(_routeDistanceKm)}",
                                        style: const TextStyle(color: Color(0xFFD4AF7A), fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _isLoading 
                          ? const MapLoadingState() 
                          : _hasError 
                            ? MapErrorState(onRetry: _calculateRoute) 
                            : (isAllDaysMode 
                                ? MapTimelineList(
                                    itinerary: widget.tourData.data.itinerary,
                                    focusedActivity: _focusedActivity,
                                    onActivityTapped: (item) {
                                      setState(() {
                                        if (_focusedActivity == item) {
                                          _focusedActivity = null;
                                          _fitMapBounds();
                                        } else {
                                          _focusedActivity = item;
                                          if (item.latitude != null && item.longitude != null) {
                                            _animatedMapMove(LatLng(item.latitude!, item.longitude!), 15.0);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Chưa có dữ liệu tọa độ cho địa điểm này.', style: TextStyle(fontFamily: 'Montserrat'))),
                                            );
                                          }
                                        }
                                      });
                                    },
                                    isDesktop: isDesktop,
                                  ) 
                                : MapLocationList(
                                    waypointItems: _waypointItems,
                                    routeSegments: _routeSegments,
                                    currentWaypoints: _currentWaypoints,
                                    focusedSegmentIndex: _focusedSegmentIndex,
                                    selectedDayIndex: _selectedDayIndex,
                                    currentDayItinerary: (_selectedDayIndex >= 0 && _selectedDayIndex < widget.tourData.data.itinerary.length) ? widget.tourData.data.itinerary[_selectedDayIndex] : null,
                                    hasNextDay: _selectedDayIndex != -1 && _selectedDayIndex < widget.tourData.data.itinerary.length - 1,
                                    isDesktop: isDesktop,
                                    onNextDay: () {
                                      setState(() => _selectedDayIndex++);
                                      _calculateRoute();
                                    },
                                    onSegmentFocused: (index) => setState(() => _focusedSegmentIndex = index),
                                    onFitBounds: (pts) {
                                      WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapBounds(pts));
                                    },
                                  ))
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );

    if (isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Row(
          children: [
            RepaintBoundary(
              child: Container(
                width: 380,
                color: const Color(0xFF0F1E1B),
                padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Bản đồ Lộ trình', style: TextStyle(fontFamily: 'Montserrat', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))),
                      if (!_isLoading && _currentWaypoints.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.zoom_out_map_rounded, color: Color(0xFFD4AF7A)),
                          tooltip: 'Xem toàn bộ đường đi',
                          onPressed: () {
                            setState(() => _focusedSegmentIndex = null);
                            _fitMapBounds();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TourDaySelector(
                    itinerary: widget.tourData.data.itinerary,
                    selectedDayIndex: _selectedDayIndex,
                    onDaySelected: (index) {
                      setState(() => _selectedDayIndex = index);
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
                  if (_isLoading)
                    const Expanded(child: MapLoadingState())
                  else if (_hasError)
                    Expanded(child: MapErrorState(onRetry: _calculateRoute))
                  else if (_locationNames.isNotEmpty)
                    Expanded(child: isAllDaysMode 
                      ? MapTimelineList(
                          itinerary: widget.tourData.data.itinerary,
                          focusedActivity: _focusedActivity,
                          onActivityTapped: (item) {
                            setState(() {
                              if (_focusedActivity == item) {
                                _focusedActivity = null;
                                _fitMapBounds();
                              } else {
                                _focusedActivity = item;
                                if (item.latitude != null && item.longitude != null) {
                                  _animatedMapMove(LatLng(item.latitude!, item.longitude!), 15.0);
                                }
                              }
                            });
                          },
                          isDesktop: isDesktop,
                        ) 
                      : MapLocationList(
                          waypointItems: _waypointItems,
                          routeSegments: _routeSegments,
                          currentWaypoints: _currentWaypoints,
                          focusedSegmentIndex: _focusedSegmentIndex,
                          selectedDayIndex: _selectedDayIndex,
                          currentDayItinerary: (_selectedDayIndex >= 0 && _selectedDayIndex < widget.tourData.data.itinerary.length) ? widget.tourData.data.itinerary[_selectedDayIndex] : null,
                          hasNextDay: _selectedDayIndex != -1 && _selectedDayIndex < widget.tourData.data.itinerary.length - 1,
                          isDesktop: isDesktop,
                          onNextDay: () {
                            setState(() => _selectedDayIndex++);
                            _calculateRoute();
                          },
                          onSegmentFocused: (index) => setState(() => _focusedSegmentIndex = index),
                          onFitBounds: (pts) {
                            WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapBounds(pts));
                          },
                        )),
                  TourRouteSummary(routeDistanceKm: _routeDistanceKm, routeDurationMin: _routeDurationMin, stopsCount: _currentStops.length),
                  const SizedBox(height: 16),
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
                              style: TextStyle(fontFamily: 'Montserrat', fontSize: 12, color: Colors.white.withValues(alpha: 0.8), height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            ),
            Expanded(child: mapWidget),
          ],
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Bản đồ Lộ trình', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white)),
          elevation: 0,
          backgroundColor: const Color(0xFF1E1E1E),
          centerTitle: true,
          actions: [
            if (!_isLoading && _currentWaypoints.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.zoom_out_map_rounded, color: Color(0xFFD4AF7A)),
                tooltip: 'Xem toàn bộ đường đi',
                onPressed: () {
                  setState(() => _focusedSegmentIndex = null);
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
