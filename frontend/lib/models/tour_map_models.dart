import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'ai_trip_response.dart';

class RouteSegment {
  final List<LatLng> points;
  final double distanceKm;
  final double durationMin;
  final Color color;

  RouteSegment({
    required this.points,
    required this.distanceKm,
    required this.durationMin,
    required this.color,
  });
}

class WaypointItem {
  final LatLng? location;
  final String title;
  final AiActivity? activity;
  final bool isUserLocation;
  final int? waypointIndex;

  WaypointItem({
    this.location,
    required this.title,
    this.activity,
    this.isUserLocation = false,
    this.waypointIndex,
  });
}
