import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../api/api.dart';
import '../models/destination.dart';

class ManualTourCreatorScreen extends StatefulWidget {
  final String? authToken;

  const ManualTourCreatorScreen({
    super.key,
    required this.authToken,
  });

  @override
  State<ManualTourCreatorScreen> createState() =>
      _ManualTourCreatorScreenState();
}

class _ManualTourCreatorScreenState extends State<ManualTourCreatorScreen> {
  final _titleController = TextEditingController();
  final _adultsController = TextEditingController(text: '1');
  final _childrenController = TextEditingController(text: '0');
  final _browseQueryController = TextEditingController();
  final _scheduleHorizontalController = ScrollController();
  final _scheduleVerticalController = ScrollController();
  final List<_ManualTourDayDraft> _days = [_ManualTourDayDraft(dayNumber: 1)];
  final List<_BrowseLocationDraft> _browseResults = [];

  static const List<String> _browseCities = [
    'Toàn quốc',
    'Đà Nẵng',
    'Hà Nội',
    'TP. Hồ Chí Minh',
    'Quảng Nam',
    'Quảng Ninh',
    'Thừa Thiên Huế',
    'Khánh Hòa',
    'Lào Cai',
    'Ninh Bình',
    'Bình Thuận',
    'Kiên Giang',
    'Bà Rịa - Vũng Tàu',
    'Quảng Bình',
    'An Giang',
    'Bạc Liêu',
    'Bắc Giang',
    'Bắc Kạn',
    'Bắc Ninh',
    'Bến Tre',
    'Bình Dương',
    'Bình Định',
    'Bình Phước',
    'Cần Thơ',
    'Cà Mau',
    'Cao Bằng',
    'Đắk Lắk',
    'Đắk Nông',
    'Điện Biên',
    'Đồng Nai',
    'Đồng Tháp',
    'Gia Lai',
    'Hà Giang',
    'Hà Nam',
    'Hà Tĩnh',
    'Hải Dương',
    'Hải Phòng',
    'Hậu Giang',
    'Hòa Bình',
    'Hưng Yên',
    'Kon Tum',
    'Lai Châu',
    'Lạng Sơn',
    'Lâm Đồng',
    'Long An',
    'Nam Định',
    'Nghệ An',
    'Ninh Thuận',
    'Phú Thọ',
    'Phú Yên',
    'Quảng Ngãi',
    'Quảng Trị',
    'Sóc Trăng',
    'Sơn La',
    'Tây Ninh',
    'Thái Bình',
    'Thái Nguyên',
    'Thanh Hóa',
    'Tiền Giang',
    'Trà Vinh',
    'Tuyên Quang',
    'Vĩnh Long',
    'Vĩnh Phúc',
    'Yên Bái',
  ];

  static const List<String> _placeCategories = [
    'Điểm du lịch',
    'Danh lam & Thắng cảnh',
    'Thiên nhiên & Công viên',
    'Nơi mua sắm',
    'Hoạt động ngoài trời',
    'Bảo tàng',
    'Vui chơi & Giải trí',
    'Chuyến tham quan',
    'Đồ ăn & Đồ uống',
    'Lớp học & hội thảo',
    'Spa & Sức khỏe',
    'Giải trí về đêm',
  ];

  static const List<String> _restaurantCategories = [
    'Nhà hàng',
    'Ngồi xuống',
    'Quán cafe',
    'Đồ ăn nhanh',
  ];

  static const List<String> _hotelCategories = [
    'Khách sạn',
    'Khách sạn / Nhà nghỉ',
    'Khu nghỉ dưỡng',
    'Khách sạn nhỏ',
    'Nhà nghỉ',
    'Nhà trọ',
    'B&B',
    'Nhà khách',
  ];

  Timer? _browseDebounce;
  bool _isPublic = false;
  bool _isSubmitting = false;
  bool _isLoadingBrowse = false;
  String _transportMode = 'auto';
  String _browseType = 'place';
  String? _browseError;
  int _browsePage = 1;
  int _browseTotalPages = 1;
  String? _browseCity;
  String? _browseCategory;
  double _browseMinScore = 0;
  String _browseSortBy = 'totalScore';
  String _browseSortOrder = 'desc';
  int _browseLimit = 10;
  String? _browseTime;
  String? _browseDate;

  bool get _isVi => Localizations.localeOf(context).languageCode == 'vi';
  int get _totalDays => _days.length;
  int get _totalNights => max(_totalDays - 1, 0);
  double get _estimatedBudget {
    double total = 0;
    for (final day in _days) {
      for (final item in day.items) {
        total += _parseMoney(item.costController.text) ?? 0;
      }
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    _fetchBrowseLocations();
  }

  @override
  void dispose() {
    _browseDebounce?.cancel();
    _titleController.dispose();
    _adultsController.dispose();
    _childrenController.dispose();
    _browseQueryController.dispose();
    _scheduleHorizontalController.dispose();
    _scheduleVerticalController.dispose();
    for (final day in _days) {
      day.dispose();
    }
    super.dispose();
  }

  void _addDay() {
    if (_days.length >= 7) {
      _showMessage(_isVi
          ? 'Tour thủ công tối đa 7 ngày'
          : 'Manual itineraries support up to 7 days');
      return;
    }

    setState(() {
      _days.add(_ManualTourDayDraft(dayNumber: _days.length + 1));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scheduleHorizontalController.hasClients) return;
      _scheduleHorizontalController.animateTo(
        _scheduleHorizontalController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _removeDay(int index) {
    if (_days.length == 1) return;
    setState(() {
      final removed = _days.removeAt(index);
      removed.dispose();
      _renumberDays();
    });
  }

  void _renumberDays() {
    for (var i = 0; i < _days.length; i += 1) {
      _days[i].dayNumber = i + 1;
      if (_days[i].titleController.text.trim().isEmpty ||
          RegExp(r'^(Ngày|Day)\s+\d+$', caseSensitive: false)
              .hasMatch(_days[i].titleController.text.trim())) {
        _days[i].titleController.text =
            _isVi ? 'Ngày ${i + 1}' : 'Day ${i + 1}';
      }
    }
  }

  bool get _hasBrowseFilters =>
      (_browseCity?.trim().isNotEmpty ?? false) ||
      (_browseCategory?.trim().isNotEmpty ?? false) ||
      _browseMinScore > 0 ||
      _browseSortBy != 'totalScore' ||
      _browseSortOrder != 'desc' ||
      _browseLimit != 10 ||
      _browseTime != null ||
      _browseDate != null;

  void _addLocationToDay(
    _ManualTourDayDraft day,
    _BrowseLocationDraft location, {
    int? startMinutes,
  }) {
    setState(() {
      final item = _ManualTourItemDraft.fromLocation(location);
      if (startMinutes != null) {
        _setItemStartTime(item, startMinutes);
      } else {
        _applyDefaultTimes(day, item);
      }
      day.items.add(item);
      _sortDayItemsByTime(day);
    });
  }

  void _acceptTimelineDrop(
    _ManualTourDayDraft targetDay,
    Object payload, {
    int? startMinutes,
  }) {
    if (payload is _BrowseLocationDraft) {
      _addLocationToDay(targetDay, payload, startMinutes: startMinutes);
      return;
    }

    if (payload is _DraggedScheduleItem) {
      setState(() {
        final sourceItems = payload.sourceDay.items;
        final sourceIndex = sourceItems.indexOf(payload.item);
        if (sourceIndex < 0) return;

        sourceItems.removeAt(sourceIndex);
        if (startMinutes != null) {
          _setItemStartTime(payload.item, startMinutes);
        } else {
          _applyDefaultTimes(targetDay, payload.item);
        }
        targetDay.items.add(payload.item);
        _sortDayItemsByTime(payload.sourceDay);
        _sortDayItemsByTime(targetDay);
      });
    }
  }

  void _removeItem(_ManualTourDayDraft day, int index) {
    setState(() {
      final removed = day.items.removeAt(index);
      removed.dispose();
    });
  }

  void _reorderItems(_ManualTourDayDraft day, int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = day.items.removeAt(oldIndex);
      day.items.insert(newIndex, item);
    });
  }

  void _onBrowseQueryChanged(String value) {
    _browseDebounce?.cancel();
    _browseDebounce = Timer(const Duration(milliseconds: 350), () {
      _browsePage = 1;
      _fetchBrowseLocations();
    });
  }

  Future<void> _fetchBrowseLocations() async {
    if (!mounted) return;
    setState(() {
      _isLoadingBrowse = true;
      _browseError = null;
    });

    final query = _browseQueryController.text.trim();
    final endpoint = _browseEndpointForType(_browseType);
    final params = <String, String>{
      'limit': _browseLimit.toString(),
      'page': _browsePage.toString(),
      'sortBy': _browseSortBy,
      'order': _browseSortOrder,
      if (query.isNotEmpty) 'query': query,
      if (_browseCity?.trim().isNotEmpty == true) 'city': _browseCity!.trim(),
      if (_browseCategory?.trim().isNotEmpty == true)
        'category': _browseCategory!.trim(),
      if (_browseMinScore > 0) 'minScore': _browseMinScore.toStringAsFixed(1),
      if (_browseTime != null) 'time': _browseTime!,
      if (_browseDate != null) 'date': _browseDate!,
    };
    final path = '$endpoint?${Uri(queryParameters: params).query}';

    try {
      final response = await apiGet(path, token: widget.authToken);
      final data = tryDecodeJsonObject(response.body);
      if (!mounted) return;
      if (response.statusCode == 200 && data?['success'] == true) {
        final rawList = data!['data'];
        final loaded = <_BrowseLocationDraft>[];
        if (rawList is List) {
          for (final raw in rawList) {
            if (raw is! Map) continue;
            final map = Map<String, dynamic>.from(raw);
            map['type'] = _browseDisplayType(_browseType);
            final rawCostText = _BrowseLocationDraft.estimateCostTextFromRaw(
              (map['priceRange'] ?? map['price'] ?? '').toString(),
            );
            final destination = Destination.fromJson(map);
            loaded.add(_BrowseLocationDraft.fromDestination(
              destination,
              sourceCollection: _browseCollectionForType(_browseType),
              itemType: _browseType,
              estimatedCostText: rawCostText,
            ));
          }
        }
        setState(() {
          _browseResults
            ..clear()
            ..addAll(loaded);
          _isLoadingBrowse = false;
          _browsePage = data['page'] is num
              ? max(1, (data['page'] as num).toInt())
              : _browsePage;
          _browseTotalPages = data['totalPages'] is num
              ? max(1, (data['totalPages'] as num).toInt())
              : 1;
        });
      } else {
        setState(() {
          _browseResults.clear();
          _isLoadingBrowse = false;
          _browseTotalPages = 1;
          _browseError = (data?['message'] ?? response.reasonPhrase)
              ?.toString();
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _browseResults.clear();
        _isLoadingBrowse = false;
        _browseTotalPages = 1;
        _browseError = _isVi
            ? 'Không tải được danh sách địa điểm'
            : 'Could not load locations';
      });
    }
  }

  String _browseEndpointForType(String type) {
    if (type == 'restaurant') return '/restaurants';
    if (type == 'hotel') return '/hotels';
    return '/locations';
  }

  String _browseCollectionForType(String type) {
    if (type == 'restaurant') return 'restaurants';
    if (type == 'hotel') return 'hotels';
    return 'places';
  }

  String _browseDisplayType(String type) {
    if (type == 'restaurant') return _isVi ? 'Nhà hàng' : 'Restaurant';
    if (type == 'hotel') return _isVi ? 'Khách sạn' : 'Hotel';
    return _isVi ? 'Địa điểm' : 'Place';
  }

  int _parseInt(String value, int fallback) {
    return int.tryParse(value.trim()) ?? fallback;
  }

  double? _parseMoney(String value) {
    final lower = value.trim().toLowerCase();
    if (lower.isEmpty) return null;
    if (lower == '0' || lower.contains('miễn phí') || lower.contains('free')) {
      return 0;
    }

    final millionMatch =
        RegExp(r'(\d+(?:[,.]\d+)?)\s*(triệu|tr|million|m)\b')
            .firstMatch(lower);
    if (millionMatch != null) {
      final number = double.tryParse(
        millionMatch.group(1)!.replaceAll(',', '.'),
      );
      if (number != null) return number * 1000000;
    }

    final matches = RegExp(r'\d[\d.,]*').allMatches(lower);
    final values = matches
        .map((match) => match.group(0)!.replaceAll(RegExp(r'[^0-9]'), ''))
        .map(double.tryParse)
        .whereType<double>()
        .toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a > b ? a : b);
  }

  double? _parseCoordinate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed.replaceAll(',', '.'));
  }

  String _formatMoney(num value) {
    final rounded = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < rounded.length; i += 1) {
      final fromEnd = rounded.length - i;
      buffer.write(rounded[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) {
        buffer.write('.');
      }
    }
    return '${buffer.toString()} đ';
  }

  List<String> _derivedDestinations() {
    final seen = <String>{};
    final destinations = <String>[];
    for (final day in _days) {
      for (final item in day.items) {
        final value = item.province?.trim().isNotEmpty == true
            ? item.province!.trim()
            : item.titleController.text.trim();
        if (value.isNotEmpty && seen.add(value.toLowerCase())) {
          destinations.add(value);
        }
      }
    }
    return destinations;
  }

  int? _parseTimeMinutes(String value) {
    final match = RegExp(r'(\d{1,2})[:hH](\d{2})?').firstMatch(value.trim());
    if (match == null) return null;
    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
    if (hour == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }
    return hour * 60 + minute;
  }

  String _formatTimeOfDay(int minutes) {
    final clamped = minutes.clamp(0, 23 * 60 + 59).toInt();
    final hour = clamped ~/ 60;
    final minute = clamped % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _formatHourLabel(int hour) {
    if (hour == 0) return '12AM';
    if (hour < 12) return '${hour}AM';
    if (hour == 12) return '12PM';
    return '${hour - 12}PM';
  }

  String _timeRangeText(_ManualTourItemDraft item) {
    final start = item.startTimeController.text.trim();
    final end = item.endTimeController.text.trim();
    if (start.isEmpty && end.isEmpty) return _isVi ? 'Chưa đặt giờ' : 'No time';
    if (end.isEmpty) return start;
    return '$start - $end';
  }

  int _nextAvailableStartMinutes(_ManualTourDayDraft day) {
    if (day.items.isEmpty) return 9 * 60;
    final latestEnd = day.items
        .map((item) => _parseTimeMinutes(item.endTimeController.text) ??
            _parseTimeMinutes(item.startTimeController.text))
        .whereType<int>()
        .fold<int>(8 * 60, (maxValue, value) => value > maxValue ? value : maxValue);
    return min(max(latestEnd + 30, 8 * 60), 20 * 60);
  }

  void _applyDefaultTimes(_ManualTourDayDraft day, _ManualTourItemDraft item) {
    if (item.startTimeController.text.trim().isNotEmpty) return;
    final start = _nextAvailableStartMinutes(day);
    final end = min(start + 90, 23 * 60);
    item.startTimeController.text = _formatTimeOfDay(start);
    item.endTimeController.text = _formatTimeOfDay(end);
  }

  int _itemDurationMinutes(_ManualTourItemDraft item) {
    final oldStart = _parseTimeMinutes(item.startTimeController.text);
    final oldEnd = _parseTimeMinutes(item.endTimeController.text);
    if (oldStart != null && oldEnd != null && oldEnd > oldStart) {
      return oldEnd - oldStart;
    }
    return 90;
  }

  void _setItemStartTime(_ManualTourItemDraft item, int startMinutes) {
    final duration = _itemDurationMinutes(item);
    final start = startMinutes.clamp(6 * 60, 23 * 60).toInt();
    final end = min(start + duration, 24 * 60 - 1);
    item.startTimeController.text = _formatTimeOfDay(start);
    item.endTimeController.text = _formatTimeOfDay(end);
  }

  void _sortDayItemsByTime(_ManualTourDayDraft day) {
    day.items.sort((a, b) {
      final aStart = _parseTimeMinutes(a.startTimeController.text) ?? 24 * 60;
      final bStart = _parseTimeMinutes(b.startTimeController.text) ?? 24 * 60;
      return aStart.compareTo(bStart);
    });
  }

  int _dropStartMinutesForDay({
    required _ManualTourDayDraft day,
    required Offset globalOffset,
    required double hourHeight,
    required int startHour,
    required int endHour,
  }) {
    final renderObject = day.timelineBodyKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) {
      return _nextAvailableStartMinutes(day);
    }

    final local = renderObject.globalToLocal(globalOffset);
    final rawMinutes = startHour * 60 + ((local.dy / hourHeight) * 60).round();
    final snapped = (rawMinutes / 15).round() * 15;
    return snapped.clamp(startHour * 60, (endHour + 1) * 60 - 30).toInt();
  }

  Map<String, dynamic> _buildPayload() {
    final totalCost = _estimatedBudget;
    final days = <Map<String, dynamic>>[];

    for (final day in _days) {
      final items = <Map<String, dynamic>>[];
      for (var index = 0; index < day.items.length; index += 1) {
        final item = day.items[index];
        final cost = _parseMoney(item.costController.text);
        final lat = _parseCoordinate(item.latController.text);
        final lng = _parseCoordinate(item.lngController.text);
        final location = lat != null && lng != null
            ? {
                'type': 'Point',
                'coordinates': [lng, lat],
              }
            : null;

        items.add({
          'order': index + 1,
          'type': item.type,
          'title': item.titleController.text.trim(),
          'category': item.category,
          'startTime': item.startTimeController.text.trim(),
          'endTime': item.endTimeController.text.trim(),
          'notes': item.notesController.text.trim(),
          if (cost != null)
            'estimatedCost': {
              'min': cost,
              'max': cost,
              'currency': 'VND',
            },
          if (location != null) 'location': location,
          'source': {
            'provider': item.sourceProvider,
            if (item.sourceCollection != null)
              'sourceCollection': item.sourceCollection,
            if (item.sourceId != null) 'id': item.sourceId,
          },
        });
      }

      days.add({
        'dayNumber': day.dayNumber,
        'title': day.titleController.text.trim().isEmpty
            ? (_isVi ? 'Ngày ${day.dayNumber}' : 'Day ${day.dayNumber}')
            : day.titleController.text.trim(),
        'summary': day.summaryController.text.trim(),
        'items': items,
      });
    }

    return {
      'title': _titleController.text.trim(),
      'destinations': _derivedDestinations(),
      'visibility': _isPublic ? 'public' : 'private',
      'totalNights': _totalNights,
      'travelers': {
        'adults': _parseInt(_adultsController.text, 1).clamp(1, 99),
        'children': _parseInt(_childrenController.text, 0).clamp(0, 99),
      },
      'preferences': {
        'budgetLevel': totalCost.round(),
        'interests': _derivedDestinations(),
        'transportMode': _transportMode,
        'pace': 'balanced',
      },
      'estimatedCost': {
        'min': totalCost,
        'max': totalCost,
        'currency': 'VND',
      },
      'days': days,
    };
  }

  String? _validateDraft() {
    if (_titleController.text.trim().isEmpty) {
      return _isVi
          ? 'Vui lòng nhập tên lịch trình'
          : 'Please enter an itinerary title';
    }

    for (final day in _days) {
      if (day.items.isEmpty) {
        return _isVi
            ? 'Mỗi ngày cần có ít nhất một hoạt động'
            : 'Each day needs at least one activity';
      }

      for (final item in day.items) {
        if (item.titleController.text.trim().isEmpty) {
          return _isVi
              ? 'Mỗi hoạt động cần có tên'
              : 'Each activity needs a title';
        }

        if (item.isCustom && _parseMoney(item.costController.text) == null) {
          return _isVi
              ? 'Hoạt động tự nhập cần có chi phí dự kiến'
              : 'Custom activities need an estimated cost';
        }

        final hasLat = item.latController.text.trim().isNotEmpty;
        final hasLng = item.lngController.text.trim().isNotEmpty;
        if (hasLat != hasLng) {
          return _isVi
              ? 'Nếu nhập tọa độ, vui lòng nhập đủ vĩ độ và kinh độ'
              : 'If you add coordinates, enter both latitude and longitude';
        }
      }
    }

    return null;
  }

  Future<void> _submit() async {
    final token = widget.authToken?.trim();
    if (token == null || token.isEmpty) {
      _showMessage(_isVi
          ? 'Bạn cần đăng nhập để tạo tour'
          : 'You need to sign in to create an itinerary');
      return;
    }

    final validationMessage = _validateDraft();
    if (validationMessage != null) {
      _showMessage(validationMessage);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await apiPostJson(
        '/tours/manual',
        _buildPayload(),
        token: token,
      );
      final decoded = tryDecodeJsonObject(response.body);
      if (!mounted) return;
      if (response.statusCode == 201 && decoded?['success'] == true) {
        final data = decoded?['data'];
        Navigator.of(context).pop(
          data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{},
        );
      } else {
        _showMessage((decoded?['message'] ?? response.reasonPhrase).toString());
      }
    } catch (_) {
      if (!mounted) return;
      _showMessage(_isVi
          ? 'Không thể tạo lịch trình thủ công'
          : 'Could not create the manual itinerary');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showCustomActivityDialog(_ManualTourDayDraft day) async {
    final titleController = TextEditingController();
    final costController = TextEditingController();
    final startController = TextEditingController();
    final endController = TextEditingController();
    final latController = TextEditingController();
    final lngController = TextEditingController();
    final notesController = TextEditingController();

    final item = await showDialog<_ManualTourItemDraft>(
      context: context,
      builder: (context) {
        return _CustomActivityDialog(
          isVi: _isVi,
          titleController: titleController,
          costController: costController,
          startController: startController,
          endController: endController,
          latController: latController,
          lngController: lngController,
          notesController: notesController,
          parseMoney: _parseMoney,
        );
      },
    );

    titleController.dispose();
    costController.dispose();
    startController.dispose();
    endController.dispose();
    latController.dispose();
    lngController.dispose();
    notesController.dispose();

    if (!mounted || item == null) return;
    setState(() {
      _applyDefaultTimes(day, item);
      day.items.add(item);
      _sortDayItemsByTime(day);
    });
  }

  Future<void> _showCoordinateDialog(_ManualTourItemDraft item) async {
    final latController = TextEditingController(text: item.latController.text);
    final lngController = TextEditingController(text: item.lngController.text);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AlertDialog(
            backgroundColor: const Color(0xFF0F1E1B).withOpacity(0.96),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.white.withOpacity(0.12)),
            ),
            title: Text(
              _isVi ? 'Tọa độ GPS' : 'GPS coordinates',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _compactInput(
                    controller: latController,
                    icon: Icons.my_location_rounded,
                    hint: _isVi ? 'Vĩ độ' : 'Latitude',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _compactInput(
                    controller: lngController,
                    icon: Icons.explore_rounded,
                    hint: _isVi ? 'Kinh độ' : 'Longitude',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  _isVi ? 'Hủy' : 'Cancel',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.white.withOpacity(0.62),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF7A),
                  foregroundColor: const Color(0xFF101512),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  _isVi ? 'Lưu' : 'Save',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (saved == true && mounted) {
      setState(() {
        item.latController.text = latController.text.trim();
        item.lngController.text = lngController.text.trim();
      });
    }

    latController.dispose();
    lngController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1040;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/login_bg.jpg', fit: BoxFit.cover),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(color: Colors.black.withOpacity(0.66)),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 1180 : 760),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildTourInfoCard(isDesktop),
                          const SizedBox(height: 14),
                          if (isDesktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(width: 340, child: _buildBrowsePanel()),
                                const SizedBox(width: 14),
                                Expanded(child: _buildScheduleBoard()),
                              ],
                            )
                          else ...[
                            _buildBrowsePanel(),
                            const SizedBox(height: 14),
                            _buildScheduleBoard(),
                          ],
                          const SizedBox(height: 18),
                          _buildSubmitButton(),
                          const SizedBox(height: 28),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 18, 18),
      child: Row(
        children: [
          IconButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isVi ? 'Bảng lịch trình thủ công' : 'Manual itinerary board',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isVi
                      ? 'Kéo địa điểm từ Browse Location vào từng ngày, hoặc thêm hoạt động tự nhập có chi phí.'
                      : 'Drag locations into each day, or add custom activities with cost.',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.62),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTourInfoCard(bool isDesktop) {
    return _frostedPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _input(
            controller: _titleController,
            label: _isVi ? 'Tên lịch trình' : 'Itinerary title',
            icon: Icons.route_rounded,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final fullWidth = constraints.maxWidth;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _metricChip(Icons.calendar_month_rounded,
                      _isVi ? 'Số ngày' : 'Days', '$_totalDays'),
                  _metricChip(Icons.nights_stay_rounded,
                      _isVi ? 'Số đêm' : 'Nights', '$_totalNights'),
                  _metricChip(Icons.payments_rounded,
                      _isVi ? 'Budget tự tính' : 'Auto budget',
                      _formatMoney(_estimatedBudget)),
                  SizedBox(
                    width: isDesktop ? 170 : fullWidth,
                    child: _input(
                      controller: _adultsController,
                      label: _isVi ? 'Người lớn' : 'Adults',
                      icon: Icons.person_rounded,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  SizedBox(
                    width: isDesktop ? 170 : fullWidth,
                    child: _input(
                      controller: _childrenController,
                      label: _isVi ? 'Trẻ em' : 'Children',
                      icon: Icons.child_care_rounded,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  SizedBox(
                    width: isDesktop ? 220 : fullWidth,
                    child: _transportDropdown(),
                  ),
                ],
              );
            },
          ),
          SwitchListTile.adaptive(
            value: _isPublic,
            onChanged: (value) => setState(() => _isPublic = value),
            activeColor: const Color(0xFFD4AF7A),
            contentPadding: EdgeInsets.zero,
            title: Text(
              _isVi ? 'Công khai tour này' : 'Make this itinerary public',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              _isVi
                  ? 'Điểm đến và ngân sách sẽ được tự tính từ bảng lịch trình.'
                  : 'Destinations and budget are calculated from the board.',
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white.withOpacity(0.52),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricChip(IconData icon, String label, String value) {
    return Container(
      height: 56,
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFD4AF7A), size: 20),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.white.withOpacity(0.52),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBrowsePanel() {
    return _frostedPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.travel_explore_rounded,
                  color: Color(0xFFD4AF7A)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Browse Location',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: _isVi ? 'Bộ lọc' : 'Filters',
                onPressed: _showBrowseFilterDialog,
                icon: Icon(
                  _hasBrowseFilters
                      ? Icons.filter_alt_rounded
                      : Icons.filter_alt_outlined,
                ),
                color: _hasBrowseFilters
                    ? const Color(0xFFD4AF7A)
                    : Colors.white.withOpacity(0.72),
              ),
              IconButton(
                tooltip: _isVi ? 'Tải lại' : 'Refresh',
                onPressed: _isLoadingBrowse ? null : _fetchBrowseLocations,
                icon: const Icon(Icons.refresh_rounded),
                color: Colors.white.withOpacity(0.72),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _input(
            controller: _browseQueryController,
            label: _isVi ? 'Tìm địa điểm trong database' : 'Search database',
            icon: Icons.search_rounded,
            onChanged: _onBrowseQueryChanged,
          ),
          const SizedBox(height: 10),
          _browseTypeSelector(),
          const SizedBox(height: 12),
          if (_isLoadingBrowse)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFD4AF7A),
                ),
              ),
            )
          else if (_browseError != null)
            _emptyBrowseState(_browseError!)
          else if (_browseResults.isEmpty)
            _emptyBrowseState(_isVi
                ? 'Không có địa điểm phù hợp'
                : 'No matching locations')
          else
            Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _browseResults.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _buildDraggableLocation(_browseResults[index]);
                  },
                ),
                const SizedBox(height: 12),
                _buildBrowsePagination(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _browseTypeSelector() {
    final options = [
      ('place', _isVi ? 'Địa điểm' : 'Places', Icons.place_rounded),
      ('restaurant', _isVi ? 'Nhà hàng' : 'Restaurants', Icons.restaurant_rounded),
      ('hotel', _isVi ? 'Khách sạn' : 'Hotels', Icons.hotel_rounded),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          ChoiceChip(
            selected: _browseType == option.$1,
            label: Text(option.$2),
            avatar: Icon(option.$3, size: 16),
            selectedColor: const Color(0xFFD4AF7A),
            backgroundColor: Colors.white.withOpacity(0.06),
            labelStyle: TextStyle(
              fontFamily: 'Montserrat',
              color: _browseType == option.$1
                  ? const Color(0xFF101512)
                  : Colors.white,
              fontWeight: FontWeight.w800,
            ),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
            onSelected: (_) {
              setState(() {
                _browseType = option.$1;
                _browsePage = 1;
              });
              _fetchBrowseLocations();
            },
          ),
      ],
    );
  }

  Widget _buildBrowsePagination() {
    return Row(
      children: [
        IconButton(
          tooltip: _isVi ? 'Trang trước' : 'Previous page',
          onPressed: _isLoadingBrowse || _browsePage <= 1
              ? null
              : () {
                  setState(() => _browsePage -= 1);
                  _fetchBrowseLocations();
                },
          icon: const Icon(Icons.chevron_left_rounded),
          color: Colors.white.withOpacity(0.72),
          disabledColor: Colors.white.withOpacity(0.22),
        ),
        Expanded(
          child: Container(
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Text(
              _isVi
                  ? 'Trang $_browsePage / $_browseTotalPages'
                  : 'Page $_browsePage / $_browseTotalPages',
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white.withOpacity(0.72),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: _isVi ? 'Trang sau' : 'Next page',
          onPressed: _isLoadingBrowse || _browsePage >= _browseTotalPages
              ? null
              : () {
                  setState(() => _browsePage += 1);
                  _fetchBrowseLocations();
                },
          icon: const Icon(Icons.chevron_right_rounded),
          color: Colors.white.withOpacity(0.72),
          disabledColor: Colors.white.withOpacity(0.22),
        ),
      ],
    );
  }

  Future<void> _showBrowseFilterDialog() async {
    var type = _browseType;
    var city = _browseCity;
    var category = _browseCategory;
    var minScore = _browseMinScore;
    var sortBy = _browseSortBy;
    var sortOrder = _browseSortOrder;
    var limit = _browseLimit;
    var filterTime = _browseTime;
    var filterDate = _browseDate;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.62),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final categories = _browseCategoriesForType(type);
            final hasChanges = type != 'place' ||
                (city?.trim().isNotEmpty ?? false) ||
                (category?.trim().isNotEmpty ?? false) ||
                minScore > 0 ||
                sortBy != 'totalScore' ||
                sortOrder != 'desc' ||
                limit != 10 ||
                filterTime != null ||
                filterDate != null;

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: SafeArea(
                top: false,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: 640,
                      maxHeight: MediaQuery.of(context).size.height * 0.9,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1E1B).withOpacity(0.96),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(28)),
                      border: Border.all(color: Colors.white.withOpacity(0.10)),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Container(
                              width: 46,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.28),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _isVi ? 'Bộ lọc' : 'Filters',
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              if (hasChanges)
                                TextButton(
                                  onPressed: () {
                                    setDialogState(() {
                                      type = 'place';
                                      city = null;
                                      category = null;
                                      minScore = 0;
                                      sortBy = 'totalScore';
                                      sortOrder = 'desc';
                                      limit = 10;
                                      filterTime = null;
                                      filterDate = null;
                                    });
                                  },
                                  child: Text(
                                    _isVi ? 'Đặt lại' : 'Reset',
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      color: Color(0xFFD4AF7A),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _filterSectionLabel(
                              _isVi ? 'Loại địa điểm' : 'Location Type'),
                          const SizedBox(height: 10),
                          _filterSelectionField(
                            title: _isVi ? 'Loại địa điểm' : 'Location Type',
                            value: _browseTypeLabel(type),
                            hint: _isVi
                                ? 'Chạm để chọn loại địa điểm'
                                : 'Tap to select location type',
                            onTap: () async {
                              final selected = await _showBrowseSingleSelectSheet(
                                title: _isVi ? 'Loại địa điểm' : 'Location Type',
                                options: [
                                  (_isVi ? 'Du lịch' : 'Explore', 'place'),
                                  (_isVi ? 'Nhà hàng' : 'Restaurants',
                                      'restaurant'),
                                  (_isVi ? 'Khách sạn' : 'Hotels', 'hotel'),
                                ],
                                selectedValue: type,
                              );
                              if (selected == null) return;
                              setDialogState(() {
                                type = selected;
                                category = null;
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          _filterSectionLabel(
                              _isVi ? 'Lọc theo Thành phố' : 'Filter by City'),
                          const SizedBox(height: 10),
                          _filterSelectionField(
                            title: _isVi ? 'Thành phố' : 'City',
                            value: city?.trim().isNotEmpty == true
                                ? city!.trim()
                                : (_isVi ? 'Toàn quốc' : 'All cities'),
                            hint: _isVi
                                ? 'Chạm để chọn thành phố'
                                : 'Tap to select city',
                            onTap: () async {
                              final selected = await _showBrowseSingleSelectSheet(
                                title: _isVi
                                    ? 'Lọc theo Thành phố'
                                    : 'Filter by City',
                                options: [
                                  (_isVi ? 'Toàn quốc' : 'All cities', ''),
                                  ..._browseCities
                                      .skip(1)
                                      .map((item) => (item, item)),
                                ],
                                selectedValue: city ?? '',
                              );
                              if (selected == null) return;
                              setDialogState(() {
                                city = selected.isEmpty ? null : selected;
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          _filterSectionLabel(_isVi ? 'Danh mục' : 'Category'),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _filterChoiceChip(
                                  label: _isVi ? 'Tất cả' : 'All',
                                  isSelected: category == null,
                                  onTap: () {
                                    setDialogState(() => category = null);
                                  },
                                ),
                                const SizedBox(width: 8),
                                for (final option in categories)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _filterChoiceChip(
                                      label: option,
                                      isSelected: category == option,
                                      onTap: () {
                                        setDialogState(() => category = option);
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _filterSectionLabel(_isVi ? 'Sắp xếp theo' : 'Sort by'),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _filterChoiceChip(
                                label: _isVi ? 'Lượt review' : 'Reviews',
                                isSelected: sortBy == 'reviewsCount',
                                onTap: () {
                                  setDialogState(() {
                                    sortBy = 'reviewsCount';
                                    sortOrder = 'desc';
                                  });
                                },
                                centerText: true,
                              ),
                              _filterChoiceChip(
                                label: _isVi ? 'Điểm số' : 'Score',
                                isSelected: sortBy == 'totalScore',
                                onTap: () {
                                  setDialogState(() => sortBy = 'totalScore');
                                },
                                centerText: true,
                              ),
                              _filterChoiceChip(
                                label: _isVi ? 'Tên A-Z' : 'Name A-Z',
                                isSelected: sortBy == 'title',
                                onTap: () {
                                  setDialogState(() {
                                    sortBy = 'title';
                                    sortOrder = 'asc';
                                  });
                                },
                                centerText: true,
                              ),
                              _filterChoiceChip(
                                label: _isVi ? 'Thành phố' : 'City',
                                isSelected: sortBy == 'province',
                                onTap: () {
                                  setDialogState(() => sortBy = 'province');
                                },
                                centerText: true,
                              ),
                              _filterChoiceChip(
                                label: _isVi ? 'Mới nhất' : 'Newest',
                                isSelected: sortBy == 'createdAt',
                                onTap: () {
                                  setDialogState(() {
                                    sortBy = 'createdAt';
                                    sortOrder = 'desc';
                                  });
                                },
                                centerText: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _filterSectionLabel(_isVi ? 'Thứ tự' : 'Order'),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _filterChoiceChip(
                                  label: _isVi ? 'Giảm dần' : 'Descending',
                                  isSelected: sortOrder == 'desc',
                                  onTap: () {
                                    setDialogState(() => sortOrder = 'desc');
                                  },
                                  centerText: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _filterChoiceChip(
                                  label: _isVi ? 'Tăng dần' : 'Ascending',
                                  isSelected: sortOrder == 'asc',
                                  onTap: () {
                                    setDialogState(() => sortOrder = 'asc');
                                  },
                                  centerText: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _filterSectionLabel(_isVi ? 'Số lượng' : 'Limit'),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              for (final value in [10, 20, 50])
                                Expanded(
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 4),
                                    child: _filterChoiceChip(
                                      label: '$value',
                                      isSelected: limit == value,
                                      onTap: () {
                                        setDialogState(() => limit = value);
                                      },
                                      centerText: true,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _filterSectionLabel(
                              _isVi ? 'Điểm đánh giá' : 'Rating Score'),
                          const SizedBox(height: 8),
                          Text(
                            '${minScore.toStringAsFixed(1)} - 5.0 ${_isVi ? 'sao' : 'stars'}',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              color: Colors.white.withOpacity(0.72),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Slider(
                            value: minScore,
                            min: 0,
                            max: 5,
                            divisions: 10,
                            activeColor: const Color(0xFFD4AF7A),
                            inactiveColor: Colors.white.withOpacity(0.12),
                            onChanged: (value) {
                              setDialogState(() => minScore = value);
                            },
                          ),
                          const SizedBox(height: 16),
                          _filterSectionLabel(
                              _isVi ? 'Thời gian mở cửa' : 'Opening Hours'),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _filterValueButton(
                                  icon: Icons.access_time_rounded,
                                  label: filterTime ??
                                      (_isVi ? 'Giờ bất kỳ' : 'Anytime'),
                                  onTap: () async {
                                    final initial = filterTime?.split(':');
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: initial != null &&
                                              initial.length == 2
                                          ? TimeOfDay(
                                              hour:
                                                  int.tryParse(initial[0]) ?? 8,
                                              minute:
                                                  int.tryParse(initial[1]) ?? 0,
                                            )
                                          : const TimeOfDay(hour: 8, minute: 0),
                                    );
                                    if (picked == null) return;
                                    setDialogState(() {
                                      filterTime =
                                          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                    });
                                  },
                                  onClear: filterTime == null
                                      ? null
                                      : () {
                                          setDialogState(() {
                                            filterTime = null;
                                          });
                                        },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _filterValueButton(
                                  icon: Icons.calendar_today_rounded,
                                  label: filterDate ??
                                      (_isVi ? 'Ngày bất kỳ' : 'Anyday'),
                                  onTap: () async {
                                    final now = DateTime.now();
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: now,
                                      firstDate: DateTime(now.year - 1),
                                      lastDate: DateTime(now.year + 1),
                                    );
                                    if (picked == null) return;
                                    setDialogState(() {
                                      filterDate =
                                          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                    });
                                  },
                                  onClear: filterDate == null
                                      ? null
                                      : () {
                                          setDialogState(() {
                                            filterDate = null;
                                          });
                                        },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD4AF7A),
                                foregroundColor: Colors.black,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                textStyle: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(_isVi ? 'Áp dụng' : 'Apply'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (applied == true && mounted) {
      setState(() {
        _browseType = type;
        _browseCity = city?.trim().isEmpty == true ? null : city;
        _browseCategory = category?.trim().isEmpty == true ? null : category;
        _browseMinScore = minScore;
        _browseSortBy = sortBy;
        _browseSortOrder = sortOrder;
        _browseLimit = limit;
        _browseTime = filterTime;
        _browseDate = filterDate;
        _browsePage = 1;
      });
      _fetchBrowseLocations();
    }
  }

  List<String> _browseCategoriesForType(String type) {
    if (type == 'restaurant') return _restaurantCategories;
    if (type == 'hotel') return _hotelCategories;
    return _placeCategories;
  }

  String _browseTypeLabel(String type) {
    if (type == 'restaurant') return _isVi ? 'Nhà hàng' : 'Restaurants';
    if (type == 'hotel') return _isVi ? 'Khách sạn' : 'Hotels';
    return _isVi ? 'Du lịch' : 'Explore';
  }

  Widget _filterSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: Colors.white.withOpacity(0.42),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _filterChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool centerText = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFD4AF7A)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD4AF7A)
                : Colors.white.withOpacity(0.09),
          ),
        ),
        child: isSelected && !centerText
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_rounded, color: Colors.black, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ],
              )
            : Text(
                label,
                textAlign: centerText ? TextAlign.center : null,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
                  color: isSelected ? Colors.black : Colors.white70,
                ),
              ),
      ),
    );
  }

  Widget _filterSelectionField({
    required String title,
    required String value,
    required String hint,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.055),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.09)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF7A).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFFD4AF7A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withOpacity(0.45),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.40),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.expand_more_rounded,
              color: Colors.white.withOpacity(0.70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterValueButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFD4AF7A), size: 17),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white.withOpacity(0.65),
                  size: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<String?> _showBrowseSingleSelectSheet({
    required String title,
    required List<(String, String)> options,
    required String selectedValue,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.48),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 520,
                  maxHeight: MediaQuery.of(context).size.height * 0.62,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1E1B).withOpacity(0.97),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.28),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Colors.white.withOpacity(0.06),
                        ),
                        itemBuilder: (context, index) {
                          final option = options[index];
                          final selected = option.$2 == selectedValue;
                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            title: Text(
                              option.$1,
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                color: selected
                                    ? const Color(0xFFD4AF7A)
                                    : Colors.white,
                                fontWeight:
                                    selected ? FontWeight.w900 : FontWeight.w700,
                              ),
                            ),
                            trailing: selected
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Color(0xFFD4AF7A),
                                  )
                                : null,
                            onTap: () => Navigator.pop(context, option.$2),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyBrowseState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Montserrat',
          color: Colors.white.withOpacity(0.58),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _filterDropdown({
    required String value,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      dropdownColor: const Color(0xFF14231F),
      iconEnabledColor: const Color(0xFFD4AF7A),
      style: const TextStyle(
        fontFamily: 'Montserrat',
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFFD4AF7A), size: 18),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD4AF7A)),
        ),
      ),
    );
  }

  Widget _buildDraggableLocation(_BrowseLocationDraft location) {
    final tile = _locationTile(location);
    return Draggable<_BrowseLocationDraft>(
      data: location,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      ignoringFeedbackPointer: true,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 300, child: tile),
      ),
      childWhenDragging: Opacity(opacity: 0.36, child: tile),
      child: tile,
    );
  }

  Widget _locationTile(_BrowseLocationDraft location) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Destination.buildImage(
              location.imagePath,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    location.province,
                    if (location.totalScore != null)
                      '${location.totalScore!.toStringAsFixed(1)}★',
                  ].where((item) => item.trim().isNotEmpty).join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.white.withOpacity(0.54),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.drag_indicator_rounded,
              color: Color(0xFFD4AF7A), size: 20),
        ],
      ),
    );
  }

  Widget _buildScheduleBoard() {
    const hourHeight = 66.0;
    const headerHeight = 52.0;
    const addDayColumnWidth = 160.0;
    const timeRulerWidth = 58.0;
    const startHour = 6;
    const endHour = 23;
    const timelineHeight = headerHeight + (endHour - startHour + 1) * hourHeight;
    final viewportHeight = MediaQuery.of(context).size.height;
    final boardHeight = min(720.0, max(430.0, viewportHeight * 0.66));

    return _frostedPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.view_week_rounded, color: Color(0xFFD4AF7A)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isVi ? 'Bảng lịch trình' : 'Schedule board',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final availableForDays =
                  constraints.maxWidth - timeRulerWidth - addDayColumnWidth;
              final dayColumnWidth = max(
                230.0,
                availableForDays / max(_days.length, 1),
              );

              return ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: boardHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFF151817).withOpacity(0.86),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Scrollbar(
                    controller: _scheduleHorizontalController,
                    thumbVisibility: true,
                    notificationPredicate: (notification) =>
                        notification.metrics.axis == Axis.horizontal,
                    child: SingleChildScrollView(
                      controller: _scheduleHorizontalController,
                      scrollDirection: Axis.horizontal,
                      child: Scrollbar(
                        controller: _scheduleVerticalController,
                        thumbVisibility: true,
                        notificationPredicate: (notification) =>
                            notification.metrics.axis == Axis.vertical,
                        child: SingleChildScrollView(
                          controller: _scheduleVerticalController,
                          scrollDirection: Axis.vertical,
                          child: SizedBox(
                            height: timelineHeight,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTimeRuler(
                                  width: timeRulerWidth,
                                  headerHeight: headerHeight,
                                  hourHeight: hourHeight,
                                  startHour: startHour,
                                  endHour: endHour,
                                ),
                                for (var index = 0; index < _days.length; index += 1)
                                  _buildTimelineDayColumn(
                                    day: _days[index],
                                    dayIndex: index,
                                    width: dayColumnWidth,
                                    headerHeight: headerHeight,
                                    hourHeight: hourHeight,
                                    startHour: startHour,
                                    endHour: endHour,
                                  ),
                                _buildAddDayTimelineColumn(
                                  width: addDayColumnWidth,
                                  headerHeight: headerHeight,
                                  hourHeight: hourHeight,
                                  startHour: startHour,
                                  endHour: endHour,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddDayTimelineColumn({
    required double width,
    required double headerHeight,
    required double hourHeight,
    required int startHour,
    required int endHour,
  }) {
    final bodyHeight = (endHour - startHour + 1) * hourHeight;
    return SizedBox(
      width: width,
      child: Column(
        children: [
          Container(
            height: headerHeight,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.12),
              border: Border(
                right: BorderSide(color: Colors.white.withOpacity(0.06)),
                bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
            ),
            child: Center(
              child: OutlinedButton.icon(
                onPressed: _addDay,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(_isVi ? 'Thêm ngày' : 'Add day'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD4AF7A),
                  side: BorderSide(color: const Color(0xFFD4AF7A).withOpacity(0.48)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: bodyHeight,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.018),
              border: Border(
                right: BorderSide(color: Colors.white.withOpacity(0.06)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRuler({
    required double width,
    required double headerHeight,
    required double hourHeight,
    required int startHour,
    required int endHour,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          Container(
            height: headerHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.16),
              border: Border(
                right: BorderSide(color: Colors.white.withOpacity(0.06)),
                bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
            ),
            child: Text(
              'GMT+7',
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white.withOpacity(0.44),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          for (var hour = startHour; hour <= endHour; hour += 1)
            Container(
              height: hourHeight,
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(top: 8, right: 8),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.white.withOpacity(0.06)),
                  bottom: BorderSide(color: Colors.white.withOpacity(0.045)),
                ),
              ),
              child: Text(
                _formatHourLabel(hour),
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.white.withOpacity(0.42),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineDayColumn({
    required _ManualTourDayDraft day,
    required int dayIndex,
    required double width,
    required double headerHeight,
    required double hourHeight,
    required int startHour,
    required int endHour,
  }) {
    final bodyHeight = (endHour - startHour + 1) * hourHeight;

    return DragTarget<Object>(
      onWillAccept: (_) => true,
      onMove: (details) {
        final startMinutes = _dropStartMinutesForDay(
          day: day,
          globalOffset: details.offset,
          hourHeight: hourHeight,
          startHour: startHour,
          endHour: endHour,
        );
        if (day.hoverStartMinutes == startMinutes &&
            identical(day.hoverPayload, details.data)) {
          return;
        }
        setState(() {
          day.hoverStartMinutes = startMinutes;
          day.hoverPayload = details.data;
        });
      },
      onLeave: (_) {
        if (day.hoverStartMinutes == null && day.hoverPayload == null) return;
        setState(() {
          day.hoverStartMinutes = null;
          day.hoverPayload = null;
        });
      },
      onAcceptWithDetails: (details) {
        final startMinutes = day.hoverStartMinutes ??
            _dropStartMinutesForDay(
              day: day,
              globalOffset: details.offset,
              hourHeight: hourHeight,
              startHour: startHour,
              endHour: endHour,
            );
        day.hoverStartMinutes = null;
        day.hoverPayload = null;
        _acceptTimelineDrop(
          day,
          details.data,
          startMinutes: startMinutes,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return SizedBox(
          width: width,
          child: Column(
            children: [
              Container(
                height: headerHeight,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isHovering
                      ? const Color(0xFFD4AF7A).withOpacity(0.14)
                      : Colors.black.withOpacity(0.12),
                  border: Border(
                    right: BorderSide(color: Colors.white.withOpacity(0.06)),
                    bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF7A).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${day.dayNumber}',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            color: Color(0xFFD4AF7A),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: day.titleController,
                        maxLines: 1,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: _isVi ? 'Ngày ${day.dayNumber}' : 'Day ${day.dayNumber}',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.36),
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: _isVi ? 'Thêm hoạt động' : 'Add activity',
                      onPressed: () => _showCustomActivityDialog(day),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      color: Colors.white.withOpacity(0.64),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                    ),
                    IconButton(
                      tooltip: _isVi ? 'Xóa ngày' : 'Remove day',
                      onPressed:
                          _days.length == 1 ? null : () => _removeDay(dayIndex),
                      icon: const Icon(Icons.delete_outline_rounded, size: 17),
                      color: const Color(0xFFE74C3C).withOpacity(0.85),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                    ),
                  ],
                ),
              ),
              SizedBox(
                key: day.timelineBodyKey,
                height: bodyHeight,
                child: Stack(
                  children: [
                    for (var hour = startHour; hour <= endHour; hour += 1)
                      Positioned(
                        top: (hour - startHour) * hourHeight,
                        left: 0,
                        right: 0,
                        height: hourHeight,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isHovering
                                ? const Color(0xFFD4AF7A).withOpacity(0.045)
                                : Colors.transparent,
                            border: Border(
                              right: BorderSide(color: Colors.white.withOpacity(0.06)),
                              bottom: BorderSide(color: Colors.white.withOpacity(0.045)),
                            ),
                          ),
                        ),
                      ),
                    if (day.items.isEmpty)
                      Positioned.fill(
                        child: Center(
                          child: Text(
                            _isVi ? 'Thả địa điểm' : 'Drop location',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              color: Colors.white.withOpacity(0.32),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    if (isHovering)
                      _buildTimelineDropSkeleton(
                        day: day,
                        payload: candidateData.first,
                        startMinutes: day.hoverStartMinutes,
                        hourHeight: hourHeight,
                        startHour: startHour,
                        endHour: endHour,
                      ),
                    for (var itemIndex = 0; itemIndex < day.items.length; itemIndex += 1)
                      _buildTimelineItemBlock(
                        day: day,
                        item: day.items[itemIndex],
                        itemIndex: itemIndex,
                        hourHeight: hourHeight,
                        startHour: startHour,
                        endHour: endHour,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineItemBlock({
    required _ManualTourDayDraft day,
    required _ManualTourItemDraft item,
    required int itemIndex,
    required double hourHeight,
    required int startHour,
    required int endHour,
  }) {
    final timelineStart = startHour * 60;
    final timelineEnd = (endHour + 1) * 60;
    final start = _parseTimeMinutes(item.startTimeController.text) ?? timelineStart;
    final end = _parseTimeMinutes(item.endTimeController.text) ?? start + 90;
    final clampedStart = start.clamp(timelineStart, timelineEnd - 30).toInt();
    final clampedEnd = end.clamp(clampedStart + 30, timelineEnd).toInt();
    final top = ((clampedStart - timelineStart) / 60) * hourHeight + 5;
    final height = max(((clampedEnd - clampedStart) / 60) * hourHeight - 10, 42.0);
    final color = _activityColor(item);

    return Positioned(
      top: top,
      left: 8,
      right: 8,
      height: height,
      child: Draggable<_DraggedScheduleItem>(
        data: _DraggedScheduleItem(
          sourceDay: day,
          item: item,
        ),
        dragAnchorStrategy: pointerDragAnchorStrategy,
        ignoringFeedbackPointer: true,
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: 220,
            height: height,
            child: _timelineBlockCard(
              item: item,
              color: color,
              height: height,
              showClose: false,
              elevated: true,
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.24,
          child: _timelineBlockCard(
            item: item,
            color: color,
            height: height,
            showClose: false,
            elevated: false,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _showItemEditorDialog(day, item, itemIndex),
            child: _timelineBlockCard(
              item: item,
              color: color,
              height: height,
              showClose: true,
              elevated: true,
              onClose: () => _removeItem(day, itemIndex),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineDropSkeleton({
    required _ManualTourDayDraft day,
    required Object? payload,
    int? startMinutes,
    required double hourHeight,
    required int startHour,
    required int endHour,
  }) {
    final timelineStart = startHour * 60;
    final timelineEnd = (endHour + 1) * 60;
    final draggedItem = payload is _DraggedScheduleItem ? payload.item : null;
    final start = startMinutes ??
        (draggedItem != null
            ? (_parseTimeMinutes(draggedItem.startTimeController.text) ??
                _nextAvailableStartMinutes(day))
            : _nextAvailableStartMinutes(day));
    final duration =
        draggedItem != null ? _itemDurationMinutes(draggedItem) : 90;
    final end = start + duration;
    final clampedStart = start.clamp(timelineStart, timelineEnd - 30).toInt();
    final clampedEnd = end.clamp(clampedStart + 30, timelineEnd).toInt();
    final top = ((clampedStart - timelineStart) / 60) * hourHeight + 5;
    final height = max(((clampedEnd - clampedStart) / 60) * hourHeight - 10, 46.0);

    return Positioned(
      top: top,
      left: 8,
      right: 8,
      height: height,
      child: IgnorePointer(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF7A).withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFD4AF7A).withOpacity(0.62),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 10,
                width: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 8,
                width: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timelineBlockCard({
    required _ManualTourItemDraft item,
    required Color color,
    required double height,
    required bool showClose,
    required bool elevated,
    VoidCallback? onClose,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 7, 7, 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.95), width: 1),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.titleController.text.trim().isEmpty
                      ? (_isVi ? 'Hoạt động' : 'Activity')
                      : item.titleController.text.trim(),
                  maxLines: height < 62 ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (showClose)
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onClose,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withOpacity(0.74),
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            _timeRangeText(item),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: Colors.white.withOpacity(0.74),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (height >= 76 && item.costController.text.trim().isNotEmpty) ...[
            const Spacer(),
            Text(
              _formatMoney(_parseMoney(item.costController.text) ?? 0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white.withOpacity(0.72),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _activityColor(_ManualTourItemDraft item) {
    if (item.isCustom) return const Color(0xFF6F5598);
    if (item.type == 'restaurant') return const Color(0xFF7E3A2D);
    if (item.type == 'hotel') return const Color(0xFF4D4D4D);
    return const Color(0xFF345569);
  }

  Future<void> _showItemEditorDialog(
    _ManualTourDayDraft day,
    _ManualTourItemDraft item,
    int itemIndex,
  ) async {
    final titleController = TextEditingController(text: item.titleController.text);
    final startController = TextEditingController(text: item.startTimeController.text);
    final endController = TextEditingController(text: item.endTimeController.text);
    final costController = TextEditingController(text: item.costController.text);
    final latController = TextEditingController(text: item.latController.text);
    final lngController = TextEditingController(text: item.lngController.text);
    final notesController = TextEditingController(text: item.notesController.text);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _CustomActivityDialog(
        isVi: _isVi,
        titleController: titleController,
        costController: costController,
        startController: startController,
        endController: endController,
        latController: latController,
        lngController: lngController,
        notesController: notesController,
        parseMoney: _parseMoney,
        saveLabel: _isVi ? 'Lưu' : 'Save',
        returnItem: false,
        requireCost: item.isCustom,
      ),
    );

    if (saved == true && mounted) {
      setState(() {
        item.titleController.text = titleController.text.trim();
        item.startTimeController.text = startController.text.trim();
        item.endTimeController.text = endController.text.trim();
        item.costController.text = costController.text.trim();
        item.latController.text = latController.text.trim();
        item.lngController.text = lngController.text.trim();
        item.notesController.text = notesController.text.trim();
      });
    }

    titleController.dispose();
    startController.dispose();
    endController.dispose();
    costController.dispose();
    latController.dispose();
    lngController.dispose();
    notesController.dispose();
  }

  Widget _buildDayTable(_ManualTourDayDraft day, int dayIndex) {
    return DragTarget<_BrowseLocationDraft>(
      onWillAccept: (_) => true,
      onAccept: (location) => _addLocationToDay(day, location),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isHovering
                ? const Color(0xFFD4AF7A).withOpacity(0.12)
                : Colors.black.withOpacity(0.18),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isHovering
                  ? const Color(0xFFD4AF7A)
                  : Colors.white.withOpacity(0.09),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF7A).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${day.dayNumber}',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          color: Color(0xFFD4AF7A),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _compactInput(
                      controller: day.titleController,
                      icon: Icons.edit_note_rounded,
                      hint: _isVi ? 'Tiêu đề ngày' : 'Day title',
                    ),
                  ),
                  IconButton(
                    tooltip: _isVi ? 'Xóa ngày' : 'Remove day',
                    onPressed:
                        _days.length == 1 ? null : () => _removeDay(dayIndex),
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: const Color(0xFFE74C3C),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _compactInput(
                controller: day.summaryController,
                icon: Icons.notes_rounded,
                hint: _isVi ? 'Ghi chú ngày' : 'Day note',
              ),
              const SizedBox(height: 12),
              _tableHeader(),
              const SizedBox(height: 6),
              if (day.items.isEmpty)
                _emptyDropArea(isHovering)
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: day.items.length,
                  onReorder: (oldIndex, newIndex) =>
                      _reorderItems(day, oldIndex, newIndex),
                  itemBuilder: (context, itemIndex) {
                    return _buildScheduleRow(day, itemIndex);
                  },
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () => _showCustomActivityDialog(day),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(_isVi ? 'Thêm hoạt động tự nhập' : 'Add custom activity'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFD4AF7A),
                      textStyle: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => day.items.add(_ManualTourItemDraft.custom()));
                    },
                    icon: const Icon(Icons.edit_location_alt_rounded),
                    label: Text(_isVi ? 'Thêm dòng trống' : 'Add blank row'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withOpacity(0.72),
                      textStyle: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tableHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              const SizedBox(width: 34),
              _headerCell(_isVi ? 'Thời gian' : 'Time', flex: 2),
              _headerCell(_isVi ? 'Hoạt động' : 'Activity', flex: 4),
              _headerCell(_isVi ? 'Chi phí' : 'Cost', flex: 2),
              _headerCell(_isVi ? 'Tọa độ' : 'Coords', flex: 3),
              const SizedBox(width: 42),
            ],
          ),
        );
      },
    );
  }

  Widget _headerCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Montserrat',
          color: Colors.white.withOpacity(0.45),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _emptyDropArea(bool isHovering) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isHovering ? 0.10 : 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHovering
              ? const Color(0xFFD4AF7A)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Text(
        _isVi
            ? 'Thả địa điểm vào đây để thêm vào ngày này'
            : 'Drop a location here to add it to this day',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Montserrat',
          color: Colors.white.withOpacity(0.56),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildScheduleRow(_ManualTourDayDraft day, int itemIndex) {
    final item = day.items[itemIndex];
    return Container(
      key: ValueKey(item.uid),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isCustom
              ? const Color(0xFFD4AF7A).withOpacity(0.28)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final dragHandle = ReorderableDragStartListener(
            index: itemIndex,
            child: const Icon(
              Icons.drag_indicator_rounded,
              color: Color(0xFFD4AF7A),
              size: 22,
            ),
          );
          final deleteButton = IconButton(
            tooltip: _isVi ? 'Xóa hoạt động' : 'Remove activity',
            onPressed: () => _removeItem(day, itemIndex),
            icon: const Icon(Icons.close_rounded),
            color: Colors.white.withOpacity(0.64),
          );

          if (compact) {
            return Column(
              children: [
                Row(children: [dragHandle, const SizedBox(width: 6), Expanded(child: _typeBadge(item)), deleteButton]),
                const SizedBox(height: 8),
                _compactInput(
                  controller: item.titleController,
                  icon: item.isCustom
                      ? Icons.extension_rounded
                      : Icons.location_on_rounded,
                  hint: _isVi ? 'Hoạt động' : 'Activity',
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _compactInput(
                        controller: item.startTimeController,
                        icon: Icons.schedule_rounded,
                        hint: _isVi ? 'Bắt đầu' : 'Start',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _compactInput(
                        controller: item.endTimeController,
                        icon: Icons.schedule_send_rounded,
                        hint: _isVi ? 'Kết thúc' : 'End',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _costInput(item)),
                    const SizedBox(width: 8),
                    Expanded(child: _coordinateSummary(item)),
                  ],
                ),
                const SizedBox(height: 8),
                _compactInput(
                  controller: item.notesController,
                  icon: Icons.sticky_note_2_rounded,
                  hint: _isVi ? 'Ghi chú' : 'Notes',
                ),
              ],
            );
          }

          return Row(
            children: [
              dragHandle,
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Expanded(
                      child: _compactInput(
                        controller: item.startTimeController,
                        icon: Icons.schedule_rounded,
                        hint: '09:00',
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _compactInput(
                        controller: item.endTimeController,
                        icon: Icons.schedule_send_rounded,
                        hint: '10:30',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _compactInput(
                      controller: item.titleController,
                      icon: item.isCustom
                          ? Icons.extension_rounded
                          : Icons.location_on_rounded,
                      hint: _isVi ? 'Hoạt động' : 'Activity',
                    ),
                    const SizedBox(height: 5),
                    _typeBadge(item),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: _costInput(item)),
              const SizedBox(width: 8),
              Expanded(flex: 3, child: _coordinateSummary(item)),
              deleteButton,
            ],
          );
        },
      ),
    );
  }

  Widget _typeBadge(_ManualTourItemDraft item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: item.isCustom
            ? const Color(0xFFD4AF7A).withOpacity(0.16)
            : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        item.isCustom
            ? (_isVi ? 'Tự nhập' : 'Custom')
            : item.category,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Montserrat',
          color: item.isCustom ? const Color(0xFFD4AF7A) : Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _costInput(_ManualTourItemDraft item) {
    return _compactInput(
      controller: item.costController,
      icon: Icons.payments_rounded,
      hint: _isVi ? 'Chi phí' : 'Cost',
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _coordinateSummary(_ManualTourItemDraft item) {
    final hasCoords = item.latController.text.trim().isNotEmpty &&
        item.lngController.text.trim().isNotEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showCoordinateDialog(item),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(
              hasCoords ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
              color: const Color(0xFFD4AF7A),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasCoords
                    ? '${item.latController.text}, ${item.lngController.text}'
                    : (_isVi ? 'Không tọa độ' : 'No coords'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.white.withOpacity(0.78),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _transportDropdown() {
    return DropdownButtonFormField<String>(
      value: _transportMode,
      dropdownColor: const Color(0xFF14231F),
      decoration: _inputDecoration(
        label: _isVi ? 'Di chuyển' : 'Transport',
        icon: Icons.directions_car_rounded,
      ),
      style: const TextStyle(
        fontFamily: 'Montserrat',
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      items: [
        DropdownMenuItem(value: 'auto', child: Text(_isVi ? 'Tự động' : 'Auto')),
        DropdownMenuItem(value: 'car', child: Text(_isVi ? 'Ô tô' : 'Car')),
        DropdownMenuItem(value: 'walking', child: Text(_isVi ? 'Đi bộ' : 'Walking')),
        DropdownMenuItem(value: 'motorbike', child: Text(_isVi ? 'Xe máy' : 'Motorbike')),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() => _transportMode = value);
      },
    );
  }

  Widget _buildAddDayButton() {
    return OutlinedButton.icon(
      onPressed: _addDay,
      icon: const Icon(Icons.add_rounded),
      label: Text(_isVi ? 'Thêm ngày' : 'Add day'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFD4AF7A),
        side: BorderSide(color: const Color(0xFFD4AF7A).withOpacity(0.55)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submit,
        icon: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF101512),
                ),
              )
            : const Icon(Icons.check_rounded),
        label: Text(_isVi ? 'Tạo lịch trình' : 'Create itinerary'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD4AF7A),
          disabledBackgroundColor: const Color(0xFFD4AF7A).withOpacity(0.62),
          foregroundColor: const Color(0xFF101512),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _frostedPanel({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF101B18).withOpacity(0.72),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: 'Montserrat',
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      decoration: _inputDecoration(label: label, icon: icon),
    );
  }

  Widget _compactInput({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: 'Montserrat',
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFFD4AF7A), size: 18),
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: 'Montserrat',
          color: Colors.white.withOpacity(0.38),
          fontSize: 12,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD4AF7A)),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFFD4AF7A), size: 20),
      labelText: label,
      labelStyle: TextStyle(
        fontFamily: 'Montserrat',
        color: Colors.white.withOpacity(0.58),
        fontSize: 13,
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD4AF7A)),
      ),
    );
  }
}

class _CustomActivityDialog extends StatelessWidget {
  final bool isVi;
  final TextEditingController titleController;
  final TextEditingController costController;
  final TextEditingController startController;
  final TextEditingController endController;
  final TextEditingController latController;
  final TextEditingController lngController;
  final TextEditingController notesController;
  final double? Function(String) parseMoney;
  final String? saveLabel;
  final bool returnItem;
  final bool requireCost;

  const _CustomActivityDialog({
    required this.isVi,
    required this.titleController,
    required this.costController,
    required this.startController,
    required this.endController,
    required this.latController,
    required this.lngController,
    required this.notesController,
    required this.parseMoney,
    this.saveLabel,
    this.returnItem = true,
    this.requireCost = true,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: AlertDialog(
        backgroundColor: const Color(0xFF0F1E1B).withOpacity(0.96),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        title: Text(
          isVi ? 'Thêm hoạt động tự nhập' : 'Add custom activity',
          style: const TextStyle(
            fontFamily: 'Montserrat',
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogInput(titleController, isVi ? 'Tên hoạt động' : 'Activity name', Icons.extension_rounded),
              const SizedBox(height: 10),
              _dialogInput(
                costController,
                requireCost
                    ? (isVi ? 'Chi phí dự kiến bắt buộc' : 'Required estimated cost')
                    : (isVi ? 'Chi phí dự kiến' : 'Estimated cost'),
                Icons.payments_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _dialogInput(startController, isVi ? 'Bắt đầu' : 'Start', Icons.schedule_rounded)),
                  const SizedBox(width: 8),
                  Expanded(child: _dialogInput(endController, isVi ? 'Kết thúc' : 'End', Icons.schedule_send_rounded)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _dialogInput(latController, isVi ? 'Vĩ độ' : 'Latitude', Icons.my_location_rounded, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                  const SizedBox(width: 8),
                  Expanded(child: _dialogInput(lngController, isVi ? 'Kinh độ' : 'Longitude', Icons.explore_rounded, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                ],
              ),
              const SizedBox(height: 10),
              _dialogInput(notesController, isVi ? 'Ghi chú' : 'Notes', Icons.sticky_note_2_rounded),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              isVi ? 'Hủy' : 'Cancel',
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white.withOpacity(0.62),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF7A),
              foregroundColor: const Color(0xFF101512),
            ),
            onPressed: () {
              if (titleController.text.trim().isEmpty ||
                  (requireCost && parseMoney(costController.text) == null)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isVi
                        ? 'Nhập tên hoạt động và chi phí dự kiến'
                        : 'Enter activity name and estimated cost'),
                  ),
                );
                return;
              }
              if (returnItem) {
                Navigator.pop(
                  context,
                  _ManualTourItemDraft.custom(
                    title: titleController.text,
                    cost: costController.text,
                    startTime: startController.text,
                    endTime: endController.text,
                    latitude: latController.text,
                    longitude: lngController.text,
                    notes: notesController.text,
                  ),
                );
              } else {
                Navigator.pop(context, true);
              }
            },
            child: Text(
              saveLabel ?? (isVi ? 'Thêm' : 'Add'),
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogInput(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontFamily: 'Montserrat',
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFFD4AF7A), size: 20),
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: 'Montserrat',
          color: Colors.white.withOpacity(0.4),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD4AF7A)),
        ),
      ),
    );
  }
}

class _DraggedScheduleItem {
  final _ManualTourDayDraft sourceDay;
  final _ManualTourItemDraft item;

  const _DraggedScheduleItem({
    required this.sourceDay,
    required this.item,
  });
}

class _ManualTourDayDraft {
  int dayNumber;
  final GlobalKey timelineBodyKey = GlobalKey();
  final TextEditingController titleController;
  final TextEditingController summaryController = TextEditingController();
  final List<_ManualTourItemDraft> items = [];
  int? hoverStartMinutes;
  Object? hoverPayload;

  _ManualTourDayDraft({required this.dayNumber})
      : titleController = TextEditingController(text: 'Ngày $dayNumber');

  void dispose() {
    titleController.dispose();
    summaryController.dispose();
    for (final item in items) {
      item.dispose();
    }
  }
}

class _ManualTourItemDraft {
  static int _nextUid = 0;

  final int uid = _nextUid++;
  String type;
  String category;
  String sourceProvider;
  String? sourceCollection;
  String? sourceId;
  String? province;
  bool isCustom;
  final TextEditingController titleController;
  final TextEditingController startTimeController;
  final TextEditingController endTimeController;
  final TextEditingController costController;
  final TextEditingController latController;
  final TextEditingController lngController;
  final TextEditingController notesController;

  _ManualTourItemDraft({
    required this.type,
    required this.category,
    required this.sourceProvider,
    this.sourceCollection,
    this.sourceId,
    this.province,
    this.isCustom = false,
    String title = '',
    String startTime = '',
    String endTime = '',
    String cost = '',
    String latitude = '',
    String longitude = '',
    String notes = '',
  })  : titleController = TextEditingController(text: title),
        startTimeController = TextEditingController(text: startTime),
        endTimeController = TextEditingController(text: endTime),
        costController = TextEditingController(text: cost),
        latController = TextEditingController(text: latitude),
        lngController = TextEditingController(text: longitude),
        notesController = TextEditingController(text: notes);

  factory _ManualTourItemDraft.custom({
    String title = '',
    String startTime = '',
    String endTime = '',
    String cost = '',
    String latitude = '',
    String longitude = '',
    String notes = '',
  }) {
    return _ManualTourItemDraft(
      type: 'place',
      category: 'Hoạt động tự chọn',
      sourceProvider: 'websearch',
      isCustom: true,
      title: title,
      startTime: startTime,
      endTime: endTime,
      cost: cost,
      latitude: latitude,
      longitude: longitude,
      notes: notes,
    );
  }

  factory _ManualTourItemDraft.fromLocation(_BrowseLocationDraft location) {
    return _ManualTourItemDraft(
      type: location.itemType,
      category: location.category,
      sourceProvider: 'database',
      sourceCollection: location.sourceCollection,
      sourceId: location.id,
      province: location.province,
      title: location.name,
      cost: location.estimatedCostText,
      latitude: location.latitude == 0 ? '' : location.latitude.toString(),
      longitude: location.longitude == 0 ? '' : location.longitude.toString(),
      notes: location.description ?? '',
    );
  }

  void dispose() {
    titleController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    costController.dispose();
    latController.dispose();
    lngController.dispose();
    notesController.dispose();
  }
}

class _BrowseLocationDraft {
  final String? id;
  final String name;
  final String province;
  final String imagePath;
  final double latitude;
  final double longitude;
  final String sourceCollection;
  final String itemType;
  final String category;
  final String estimatedCostText;
  final String? description;
  final double? totalScore;

  const _BrowseLocationDraft({
    required this.id,
    required this.name,
    required this.province,
    required this.imagePath,
    required this.latitude,
    required this.longitude,
    required this.sourceCollection,
    required this.itemType,
    required this.category,
    required this.estimatedCostText,
    required this.description,
    required this.totalScore,
  });

  factory _BrowseLocationDraft.fromDestination(
    Destination destination, {
    required String sourceCollection,
    required String itemType,
    required String estimatedCostText,
  }) {
    return _BrowseLocationDraft(
      id: destination.id ?? destination.sourceLocationId,
      name: destination.name,
      province: destination.province,
      imagePath: destination.imagePath,
      latitude: destination.latitude,
      longitude: destination.longitude,
      sourceCollection: sourceCollection,
      itemType: itemType,
      category: destination.category?.trim().isNotEmpty == true
          ? destination.category!.trim()
          : destination.type,
      estimatedCostText: estimatedCostText,
      description: destination.description,
      totalScore: destination.totalScore,
    );
  }

  static String estimateCostTextFromRaw(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.isEmpty || lower.contains('miễn phí') || lower.contains('free')) {
      return lower.contains('miễn phí') || lower.contains('free') ? '0' : '';
    }

    final millionMatch =
        RegExp(r'(\d+(?:[,.]\d+)?)\s*(triệu|tr|million|m)\b')
            .firstMatch(lower);
    if (millionMatch != null) {
      final number =
          double.tryParse(millionMatch.group(1)!.replaceAll(',', '.'));
      if (number != null) return (number * 1000000).round().toString();
    }

    final values = RegExp(r'\d[\d.,]*')
        .allMatches(lower)
        .map((match) => match.group(0)!.replaceAll(RegExp(r'[^0-9]'), ''))
        .map(int.tryParse)
        .whereType<int>()
        .toList();
    if (values.isEmpty) return '';
    return values.reduce((a, b) => a > b ? a : b).toString();
  }
}
