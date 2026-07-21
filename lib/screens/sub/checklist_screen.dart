import 'package:flutter/material.dart';
import '../../services/checklist_service.dart';
import '../../services/trip_service.dart';
import '../../theme/app_colors.dart';

class ChecklistScreen extends StatefulWidget {
  final String? tripId;
  const ChecklistScreen({super.key, this.tripId});
  @override State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  static const _categories = ['여행 서류', '짐', '편의', '기타'];

  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  final _textCtrl = TextEditingController();
  String? _tripId;
  String? _tripTitle;
  String _selectedCategory = _categories.first;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final trip = widget.tripId != null
        ? await TripService.getTripById(widget.tripId!)
        : await TripService.getUpcomingTrip();
    final tripId = trip?['id'] as String? ?? widget.tripId;
    final data = await ChecklistService.getItems(tripId: tripId);
    if (mounted) {
      setState(() {
        _tripId = tripId;
        _tripTitle = trip?['title'] as String?;
        _items = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    final newVal = !(item['is_checked'] as bool? ?? false);
    setState(() {
      final idx = _items.indexWhere((i) => i['id'] == item['id']);
      if (idx != -1) _items[idx] = {..._items[idx], 'is_checked': newVal};
    });
    await ChecklistService.toggleItem(item['id'] as String, newVal);
  }

  Future<void> _addItem() async {
    if (_textCtrl.text.isEmpty) return;
    await ChecklistService.addItem(title: _textCtrl.text, category: _selectedCategory, tripId: _tripId);
    _textCtrl.clear();
    _load();
  }

  Future<void> _deleteItem(String id) async {
    await ChecklistService.deleteItem(id);
    setState(() => _items.removeWhere((i) => i['id'] == id));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('항목이 삭제됐어요')));
    }
  }

  Future<void> _reset() async {
    await ChecklistService.reset(tripId: _tripId);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('체크리스트가 초기화됐어요')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = _items.where((i) => i['is_checked'] == true).length;
    final progress = _items.isEmpty ? 0.0 : completed / _items.length;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: Text(
          _tripTitle != null ? '$_tripTitle 체크리스트' : '체크리스트',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _reset,
            child: const Text('초기화', style: TextStyle(color: AppColors.blue600, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$completed / ${_items.length} 완료', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray700)),
                          Text('${(progress * 100).round()}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.blue600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: progress, backgroundColor: AppColors.gray100, color: AppColors.blue600, minHeight: 8),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final item = _items[i];
                      final isChecked = item['is_checked'] == true;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isChecked ? AppColors.blue200 : AppColors.gray200),
                        ),
                        child: CheckboxListTile(
                          value: isChecked,
                          onChanged: (_) => _toggle(item),
                          title: Text(
                            item['title'] as String? ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: isChecked ? AppColors.gray400 : AppColors.gray900,
                              decoration: isChecked ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          subtitle: Text(item['category'] as String? ?? '', style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
                          activeColor: AppColors.blue600,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          secondary: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.gray400),
                            onPressed: () => _deleteItem(item['id'] as String),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.gray200))),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.gray300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            style: const TextStyle(fontSize: 13, color: AppColors.gray900),
                            items: _categories
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedCategory = v);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _textCtrl,
                          decoration: InputDecoration(
                            hintText: '항목 추가...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray300)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.blue600, width: 2)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          onSubmitted: (_) => _addItem(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _addItem,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
