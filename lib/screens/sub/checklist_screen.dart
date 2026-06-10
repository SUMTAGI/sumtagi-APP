import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});
  @override State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  List<Map<String, dynamic>> _items = [];
  final _textCtrl = TextEditingController();

  static const _defaultItems = [
    {'category': '여행 서류', 'label': '신분증', 'checked': false},
    {'category': '여행 서류', 'label': '예약 확인서', 'checked': false},
    {'category': '짐', 'label': '여벌 옷', 'checked': false},
    {'category': '짐', 'label': '세면도구', 'checked': false},
    {'category': '짐', 'label': '자외선차단제', 'checked': false},
    {'category': '편의', 'label': '비상약', 'checked': false},
    {'category': '편의', 'label': '현금', 'checked': false},
    {'category': '편의', 'label': '충전기', 'checked': false},
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('checklistItems');
    if (stored != null) {
      setState(() => _items = (jsonDecode(stored) as List).cast<Map<String, dynamic>>());
    } else {
      setState(() => _items = _defaultItems.map((i) => Map<String, dynamic>.from(i)).toList());
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('checklistItems', jsonEncode(_items));
  }

  void _toggle(int i) {
    setState(() => _items[i]['checked'] = !(_items[i]['checked'] as bool));
    _save();
  }

  void _addItem() {
    if (_textCtrl.text.isEmpty) return;
    setState(() => _items.add({'category': '기타', 'label': _textCtrl.text, 'checked': false}));
    _textCtrl.clear();
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final completed = _items.where((i) => i['checked'] == true).length;
    final progress = _items.isEmpty ? 0.0 : completed / _items.length;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('체크리스트', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
      ),
      body: Column(
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
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: item['checked'] == true ? AppColors.blue200 : AppColors.gray200),
                  ),
                  child: CheckboxListTile(
                    value: item['checked'] as bool,
                    onChanged: (_) => _toggle(i),
                    title: Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: item['checked'] == true ? AppColors.gray400 : AppColors.gray900,
                        decoration: item['checked'] == true ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text(item['category'] as String, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
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
