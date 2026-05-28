import 'dart:ui';
import 'package:flutter/material.dart';

class ManualLocationDialog extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function(String query) fetchSuggestions;

  const ManualLocationDialog({
    super.key,
    required this.fetchSuggestions,
  });

  @override
  State<ManualLocationDialog> createState() => _ManualLocationDialogState();
}

class _ManualLocationDialogState extends State<ManualLocationDialog> {
  final TextEditingController _addressController = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: AlertDialog(
        backgroundColor: const Color(0xFF0F1E1B).withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.edit_location_alt_rounded, color: Color(0xFFD4AF7A), size: 26),
            SizedBox(width: 12),
            Text(
              'Nhập vị trí của bạn',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 320, // Giới hạn chiều rộng cố định để dialog ổn định
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _addressController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) async {
                  final query = value.trim();
                  if (query.isEmpty) return;
                  setState(() {
                    _isSearching = true;
                    _hasSearched = true;
                    _suggestions = [];
                  });
                  final list = await widget.fetchSuggestions(query);
                  setState(() {
                    _suggestions = list;
                    _isSearching = false;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Trường Đại Học Khoa Học Tự Nhiên...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontFamily: 'Montserrat'),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search_rounded, color: Color(0xFFD4AF7A)),
                    onPressed: () async {
                      final query = _addressController.text.trim();
                      if (query.isEmpty) return;
                      setState(() {
                        _isSearching = true;
                        _hasSearched = true;
                        _suggestions = [];
                      });
                      final list = await widget.fetchSuggestions(query);
                      setState(() {
                        _suggestions = list;
                        _isSearching = false;
                      });
                    },
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD4AF7A)),
                  ),
                ),
              ),
              if (_isSearching) ...[
                const SizedBox(height: 16),
                const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF7A)),
                  ),
                ),
              ] else if (_hasSearched && _suggestions.isEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Không tìm thấy địa điểm nào phù hợp. Vui lòng nhập chi tiết hơn.',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else if (_suggestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Chọn địa điểm chính xác từ gợi ý:',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _suggestions.length,
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.white.withValues(alpha: 0.08),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final item = _suggestions[index];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        title: Text(
                          item['display_name'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        leading: const Icon(Icons.location_on_rounded, color: Color(0xFFD4AF7A), size: 16),
                        onTap: () {
                          Navigator.pop(context, item); // Đóng Dialog và trả về kết quả
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isSearching
                ? null
                : () async {
                    final query = _addressController.text.trim();
                    if (query.isEmpty) return;

                    setState(() {
                      _isSearching = true;
                      _hasSearched = true;
                      _suggestions = [];
                    });
                    final list = await widget.fetchSuggestions(query);
                    setState(() {
                      _suggestions = list;
                      _isSearching = false;
                    });
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF7A),
              foregroundColor: const Color(0xFF0F1E1B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Tìm kiếm',
              style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
