import 'package:flutter/material.dart';
import '../../services/checklist_service.dart';
import '../../services/trip_service.dart';
import '../../theme/app_colors.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});
  @override State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  final _textCtrl = TextEditingController();
  String? _tripId;
  String? _tripTitle;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final trip = await TripService.getUpcomingTrip();
    final tripId = trip?['id'] as String?;
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
    await ChecklistService.addItem(title: _textCtrl.text, tripId: _tripId);
    _textCtrl.clear();
    _load();
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
