import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});
  @override State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  List<Map<String, dynamic>> _entries = [];
  bool _isWriting = false;
  String? _editingId;

  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _islandCtrl = TextEditingController();
  String _date = DateTime.now().toIso8601String().split('T')[0];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('diary');
    if (saved != null) setState(() => _entries = (jsonDecode(saved) as List).cast<Map<String, dynamic>>());
  }

  Future<void> _saveAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('diary', jsonEncode(_entries));
  }

  void _handleSave() {
    if (_titleCtrl.text.isEmpty || _contentCtrl.text.isEmpty || _islandCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('모든 항목을 입력해주세요')));
      return;
    }

    setState(() {
      if (_editingId != null) {
        final idx = _entries.indexWhere((e) => e['id'] == _editingId);
        if (idx != -1) {
          _entries[idx] = {
            ..._entries[idx],
            'date': _date,
            'island': _islandCtrl.text,
            'title': _titleCtrl.text,
            'content': _contentCtrl.text,
          };
        }
      } else {
        _entries.insert(0, {
          'id': 'diary-${DateTime.now().millisecondsSinceEpoch}',
          'date': _date,
          'island': _islandCtrl.text,
          'title': _titleCtrl.text,
          'content': _contentCtrl.text,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
      _isWriting = false;
      _editingId = null;
    });
    _titleCtrl.clear();
    _contentCtrl.clear();
    _islandCtrl.clear();
    _saveAll();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_editingId != null ? '다이어리가 수정됐어요' : '다이어리가 저장됐어요')));
  }

  void _startEdit(Map<String, dynamic> entry) {
    setState(() {
      _editingId = entry['id'] as String;
      _date = entry['date'] as String;
      _islandCtrl.text = entry['island'] as String;
      _titleCtrl.text = entry['title'] as String;
      _contentCtrl.text = entry['content'] as String;
      _isWriting = true;
    });
  }

  void _delete(String id) {
    setState(() => _entries.removeWhere((e) => e['id'] == id));
    _saveAll();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제됐어요')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('여행 다이어리', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text('소중한 여행 기억을 기록하세요', style: TextStyle(fontSize: 11, color: AppColors.gray500)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
        titleSpacing: 0,
        actions: [
          if (!_isWriting)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => setState(() { _isWriting = true; _editingId = null; _titleCtrl.clear(); _contentCtrl.clear(); _islandCtrl.clear(); }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.blue600, borderRadius: BorderRadius.circular(8)),
                  child: const Row(children: [
                    Icon(Icons.add, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text('새 글', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                  ]),
                ),
              ),
            ),
        ],
      ),
      body: _isWriting ? _buildWriteForm() : _buildList(),
    );
  }

  Widget _buildWriteForm() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_editingId != null ? '다이어리 수정' : '새 다이어리 작성', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                const SizedBox(height: 20),
                _formLabel('날짜'),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: DateTime.parse(_date), firstDate: DateTime(2024), lastDate: DateTime.now());
                    if (picked != null) setState(() => _date = picked.toIso8601String().split('T')[0]);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.gray300)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_date, style: const TextStyle(fontSize: 14, color: AppColors.gray900)),
                        const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.gray500),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _formLabel('방문한 섬'),
                _formField(_islandCtrl, '섬 이름을 입력하세요'),
                const SizedBox(height: 14),
                _formLabel('제목'),
                _formField(_titleCtrl, '여행의 제목을 붙여주세요'),
                const SizedBox(height: 14),
                _formLabel('내용'),
                TextField(
                  controller: _contentCtrl,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: '오늘의 여행을 기록해보세요...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.blue600, width: 2)),
                    filled: true, fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.gray200))),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _isWriting = false),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.gray200, foregroundColor: AppColors.gray700, elevation: 0, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('취소', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue600, foregroundColor: Colors.white, elevation: 0, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('저장하기', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.book_rounded, size: 64, color: AppColors.gray300),
            const SizedBox(height: 16),
            const Text('아직 기록이 없어요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray900)),
            const SizedBox(height: 8),
            const Text('여행 중 특별한 순간을\n기록해보세요', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.gray500, height: 1.5)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _entries.length,
      itemBuilder: (context, i) {
        final entry = _entries[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: AppColors.blue600),
                      const SizedBox(width: 4),
                      Text(entry['island'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.blue600)),
                      const SizedBox(width: 8),
                      const Icon(Icons.calendar_month_rounded, size: 12, color: AppColors.gray400),
                      const SizedBox(width: 3),
                      Text(entry['date'] as String, style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
                    ]),
                    Row(children: [
                      GestureDetector(onTap: () => _startEdit(entry), child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.gray400)),
                      const SizedBox(width: 10),
                      GestureDetector(onTap: () => _delete(entry['id'] as String), child: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.gray400)),
                    ]),
                  ],
                ),
                const SizedBox(height: 8),
                Text(entry['title'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                const SizedBox(height: 6),
                Text(entry['content'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray600, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _formLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray700)),
  );

  Widget _formField(TextEditingController ctrl, String hint) => TextField(
    controller: ctrl,
    decoration: InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.blue600, width: 2)),
      filled: true, fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );
}
