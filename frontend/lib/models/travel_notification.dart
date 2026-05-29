import 'package:flutter/material.dart';
import 'destination.dart';

class TravelNotification {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final DateTime timestamp;
  final String type; // 'itinerary', 'weather', 'expense', 'tip', 'system'
  bool isRead;

  TravelNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });
}

class AppTrendRecommendation {
  final String title;
  final String province;
  final String price;
  final String imagePath;
  final double rating;
  final int reviewsCount;
  final String tag;
  final String trendingReason;
  final String period; // 'day', 'week', 'month'
  final Destination destination;

  AppTrendRecommendation({
    required this.title,
    required this.province,
    required this.price,
    required this.imagePath,
    required this.rating,
    required this.reviewsCount,
    required this.tag,
    required this.trendingReason,
    required this.period,
    required this.destination,
  });
}

