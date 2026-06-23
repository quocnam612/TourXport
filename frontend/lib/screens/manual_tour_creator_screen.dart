import 'dart:ui';

import 'package:flutter/material.dart';

import '../api/api.dart';

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
  final _destinationsController = TextEditingController();
  final _totalNightsController = TextEditingController(text: '0');
  final _adultsController = TextEditingController(text: '1');
  final _childrenController = TextEditingController(text: '0');
  final _budgetController = TextEditingController();
  final List<_ManualTourDayDraft> _days = [_ManualTourDayDraft(dayNumber: 1)];
  bool _isPublic = false;
  bool _isSubmitting = false;
  String _transportMode = 'auto';

  bool get _isVi => Localizations.localeOf(context).languageCode == 'vi';

  @override
  void dispose() {
    _titleController.dispose();
    _destinationsController.dispose();
    _totalNightsController.dispose();
    _adultsController.dispose();
    _childrenController.dispose();
    _budgetController.dispose();
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
      _totalNightsController.text = (_days.length - 1).toString();
    });
  }

  void _removeDay(int index) {
    if (_days.length == 1) return;
    setState(() {
      final removed = _days.removeAt(index);
      removed.dispose();
      for (var i = 0; i < _days.length; i += 1) {
        _days[i].dayNumber = i + 1;
      }
      _totalNightsController.text =
          (_parseInt(_totalNightsController.text, _days.length - 1))
              .clamp(0, _days.length)
              .toString();
    });
  }

  void _addItem(_ManualTourDayDraft day) {
    setState(() => day.items.add(_ManualTourItemDraft()));
  }

  void _removeItem(_ManualTourDayDraft day, int index) {
    if (day.items.length == 1) return;
    setState(() {
      final removed = day.items.removeAt(index);
      removed.dispose();
    });
  }

  int _parseInt(String value, int fallback) {
    return int.tryParse(value.trim()) ?? fallback;
  }

  double? _parseMoney(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return double.tryParse(digits);
  }

  double? _parseCoordinate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed.replaceAll(',', '.'));
  }

  List<String> _parseDestinations() {
    return _destinationsController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> _buildPayload() {
    final allItemCosts = <double>[];
    final days = <Map<String, dynamic>>[];

    for (final day in _days) {
      final items = <Map<String, dynamic>>[];
      for (var index = 0; index < day.items.length; index += 1) {
        final item = day.items[index];
        final cost = _parseMoney(item.costController.text);
        if (cost != null) {
          allItemCosts.add(cost);
        }

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
          'category': item.type == 'place'
              ? (_isVi ? 'Địa điểm' : 'Place')
              : item.type == 'restaurant'
                  ? (_isVi ? 'Ăn uống' : 'Dining')
                  : item.type == 'transport'
                      ? (_isVi ? 'Di chuyển' : 'Transport')
                      : item.type == 'hotel'
                          ? (_isVi ? 'Nghỉ ngơi' : 'Accommodation')
                          : (_isVi ? 'Khác' : 'Other'),
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
          'source': {'provider': 'websearch'},
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

    final budget = _parseMoney(_budgetController.text);
    final totalCost = budget ??
        (allItemCosts.isEmpty
            ? null
            : allItemCosts.reduce((sum, value) => sum + value));

    return {
      'title': _titleController.text.trim(),
      'destinations': _parseDestinations(),
      'visibility': _isPublic ? 'public' : 'private',
      'totalNights': _parseInt(_totalNightsController.text, _days.length - 1),
      'travelers': {
        'adults': _parseInt(_adultsController.text, 1).clamp(1, 99),
        'children': _parseInt(_childrenController.text, 0).clamp(0, 99),
      },
      'preferences': {
        'budgetLevel': (totalCost ?? 0).round(),
        'interests': _parseDestinations(),
        'transportMode': _transportMode,
        'pace': 'balanced',
      },
      if (totalCost != null)
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
      for (final item in day.items) {
        if (item.titleController.text.trim().isEmpty) {
          return _isVi
              ? 'Mỗi hoạt động cần có tên địa điểm hoặc hoạt động'
              : 'Each activity needs a place or activity name';
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

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
                constraints: BoxConstraints(maxWidth: isDesktop ? 980 : 720),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildTourInfoCard(isDesktop),
                          const SizedBox(height: 14),
                          for (var index = 0; index < _days.length; index += 1)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _buildDayCard(_days[index], index),
                            ),
                          _buildAddDayButton(),
                          const SizedBox(height: 24),
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
                  _isVi ? 'Tạo tour thủ công' : 'Create manual itinerary',
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
                      ? 'Tự nhập từng ngày, hoạt động, chi phí và tọa độ nếu có.'
                      : 'Add each day, activity, cost, and optional coordinates.',
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
        children: [
          _input(
            controller: _titleController,
            label: _isVi ? 'Tên lịch trình' : 'Itinerary title',
            icon: Icons.route_rounded,
          ),
          const SizedBox(height: 12),
          _input(
            controller: _destinationsController,
            label: _isVi ? 'Điểm đến, cách nhau bằng dấu phẩy' : 'Destinations, comma separated',
            icon: Icons.place_rounded,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final fullWidth = constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: isDesktop ? 180 : fullWidth,
                    child: _input(
                      controller: _totalNightsController,
                      label: _isVi ? 'Số đêm' : 'Nights',
                      icon: Icons.nights_stay_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(
                    width: isDesktop ? 180 : fullWidth,
                    child: _input(
                      controller: _adultsController,
                      label: _isVi ? 'Người lớn' : 'Adults',
                      icon: Icons.person_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(
                    width: isDesktop ? 180 : fullWidth,
                    child: _input(
                      controller: _childrenController,
                      label: _isVi ? 'Trẻ em' : 'Children',
                      icon: Icons.child_care_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(
                    width: isDesktop ? 260 : fullWidth,
                    child: _transportDropdown(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _input(
            controller: _budgetController,
            label: _isVi ? 'Tổng ngân sách dự kiến (tùy chọn)' : 'Estimated total budget (optional)',
            icon: Icons.payments_rounded,
            keyboardType: TextInputType.number,
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
                  ? 'Tour công khai có thể xuất hiện trong cộng đồng.'
                  : 'Public itineraries can appear in the community list.',
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

  Widget _buildDayCard(_ManualTourDayDraft day, int dayIndex) {
    return _frostedPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF7A).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
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
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isVi ? 'Ngày ${day.dayNumber}' : 'Day ${day.dayNumber}',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: _isVi ? 'Xóa ngày' : 'Remove day',
                onPressed: _days.length == 1 ? null : () => _removeDay(dayIndex),
                icon: const Icon(Icons.delete_outline_rounded),
                color: const Color(0xFFE74C3C),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _input(
            controller: day.titleController,
            label: _isVi ? 'Tiêu đề ngày' : 'Day title',
            icon: Icons.edit_note_rounded,
          ),
          const SizedBox(height: 12),
          _input(
            controller: day.summaryController,
            label: _isVi ? 'Ghi chú ngày (tùy chọn)' : 'Day note (optional)',
            icon: Icons.notes_rounded,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          for (var itemIndex = 0; itemIndex < day.items.length; itemIndex += 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildItemEditor(day, itemIndex),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _addItem(day),
              icon: const Icon(Icons.add_rounded),
              label: Text(_isVi ? 'Thêm hoạt động' : 'Add activity'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFD4AF7A),
                textStyle: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemEditor(_ManualTourDayDraft day, int itemIndex) {
    final item = day.items[itemIndex];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.20),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _isVi
                      ? 'Hoạt động ${itemIndex + 1}'
                      : 'Activity ${itemIndex + 1}',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: _isVi ? 'Xóa hoạt động' : 'Remove activity',
                onPressed: day.items.length == 1
                    ? null
                    : () => _removeItem(day, itemIndex),
                icon: const Icon(Icons.close_rounded),
                color: Colors.white.withOpacity(0.68),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _itemTypeDropdown(item),
          const SizedBox(height: 10),
          _input(
            controller: item.titleController,
            label: _isVi ? 'Tên hoạt động / địa điểm' : 'Activity / place name',
            icon: Icons.location_on_rounded,
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 520;
              final startField = _input(
                controller: item.startTimeController,
                label: _isVi ? 'Bắt đầu (Thời gian)' : 'Start time',
                icon: Icons.schedule_rounded,
              );
              final endField = _input(
                controller: item.endTimeController,
                label: _isVi ? 'Kết thúc (Thời gian)' : 'End time',
                icon: Icons.schedule_send_rounded,
              );
              if (!twoColumns) {
                return Column(
                  children: [
                    startField,
                    const SizedBox(height: 10),
                    endField,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: startField),
                  const SizedBox(width: 10),
                  Expanded(child: endField),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          _input(
            controller: item.costController,
            label: _isVi ? 'Chi phí dự kiến' : 'Estimated cost',
            icon: Icons.payments_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          _input(
            controller: item.notesController,
            label: _isVi ? 'Ghi chú' : 'Notes',
            icon: Icons.sticky_note_2_rounded,
            maxLines: 3,
          ),
          const SizedBox(height: 10),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text(
                _isVi ? 'Tọa độ GPS (Tùy chọn cho bản đồ)' : 'GPS Coordinates (Optional for map)',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              iconColor: Colors.white.withOpacity(0.6),
              collapsedIconColor: Colors.white.withOpacity(0.6),
              tilePadding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 6),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final twoColumns = constraints.maxWidth >= 520;
                    final lat = _input(
                      controller: item.latController,
                      label: _isVi ? 'Vĩ độ' : 'Latitude',
                      icon: Icons.my_location_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                    );
                    final lng = _input(
                      controller: item.lngController,
                      label: _isVi ? 'Kinh độ' : 'Longitude',
                      icon: Icons.explore_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                    );
                    if (!twoColumns) {
                      return Column(children: [lat, const SizedBox(height: 10), lng]);
                    }
                    return Row(
                      children: [
                        Expanded(child: lat),
                        const SizedBox(width: 10),
                        Expanded(child: lng),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemTypeDropdown(_ManualTourItemDraft item) {
    // Fallback if item.type is not in the list (e.g. from server data or default config)
    final allowedValues = ['place', 'restaurant', 'transport', 'hotel', 'other'];
    final dropdownValue = allowedValues.contains(item.type) ? item.type : 'place';

    return DropdownButtonFormField<String>(
      value: dropdownValue,
      dropdownColor: const Color(0xFF14231F),
      decoration: _inputDecoration(
        label: _isVi ? 'Danh mục' : 'Category',
        icon: Icons.segment_rounded,
      ),
      style: const TextStyle(
        fontFamily: 'Montserrat',
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      items: [
        DropdownMenuItem(value: 'place', child: Text(_isVi ? 'Địa điểm' : 'Location')),
        DropdownMenuItem(value: 'restaurant', child: Text(_isVi ? 'Ăn uống' : 'Dining')),
        DropdownMenuItem(value: 'transport', child: Text(_isVi ? 'Di chuyển' : 'Transport')),
        DropdownMenuItem(value: 'hotel', child: Text(_isVi ? 'Nghỉ ngơi' : 'Accommodation')),
        DropdownMenuItem(value: 'other', child: Text(_isVi ? 'Khác' : 'Other')),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() => item.type = value);
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
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontFamily: 'Montserrat',
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      decoration: _inputDecoration(label: label, icon: icon),
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

class _ManualTourDayDraft {
  int dayNumber;
  final TextEditingController titleController;
  final TextEditingController summaryController = TextEditingController();
  final List<_ManualTourItemDraft> items = [_ManualTourItemDraft()];

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
  String type = 'place';
  final TextEditingController titleController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  final TextEditingController costController = TextEditingController();
  final TextEditingController latController = TextEditingController();
  final TextEditingController lngController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

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
