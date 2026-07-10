import 'package:flutter/material.dart';
import '../../services/budget_service.dart';
import '../../services/trip_service.dart';
import '../../theme/app_colors.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  int _totalBudget = 500000;
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;
  bool _showAddForm = false;
  String? _tripId;
  String? _tripTitle;

  String _newCategory = '식사';
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  final _categories = ['교통', '숙박', '식사', '체험', '기타'];
  final _catColors = {
    '교통': const Color(0xFFDBEAFE), '숙박': const Color(0xFFEDE9FE),
    '식사': const Color(0xFFFFEDD5), '체험': const Color(0xFFDCFCE7), '기타': AppColors.gray100,
  };
  final _catTextColors = {
    '교통': const Color(0xFF1D4ED8), '숙박': const Color(0xFF7C3AED),
    '식사': const Color(0xFFEA580C), '체험': const Color(0xFF16A34A), '기타': AppColors.gray700,
  };
  final _catIcons = {
    '교통': Icons.directions_boat_rounded, '숙박': Icons.hotel_rounded,
    '식사': Icons.restaurant_rounded, '체험': Icons.camera_alt_rounded, '기타': Icons.attach_money_rounded,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final trip = await TripService.getUpcomingTrip();
    final data = await BudgetService.getExpenses(tripId: trip?['id'] as String?);
    if (mounted) {
      setState(() {
        _tripId = trip?['id'] as String?;
        _tripTitle = trip?['title'] as String?;
        _expenses = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _addExpense() async {
    if (_amountCtrl.text.isEmpty || _descCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('모든 항목을 입력해주세요')));
      return;
    }
    await BudgetService.addExpense(
      title: _descCtrl.text,
      amount: int.tryParse(_amountCtrl.text) ?? 0,
      category: _newCategory,
      tripId: _tripId,
    );
    _amountCtrl.clear();
    _descCtrl.clear();
    setState(() => _showAddForm = false);
    _load();
  }

  Future<void> _delete(String id) async {
    await BudgetService.deleteExpense(id);
    setState(() => _expenses.removeWhere((e) => e['id'] == id));
  }

  @override
  Widget build(BuildContext context) {
    final totalExpense = _expenses.fold<int>(0, (s, e) => s + ((e['amount'] as int?) ?? 0));
    final remaining = _totalBudget - totalExpense;
    final progress = _totalBudget > 0 ? (totalExpense / _totalBudget).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('여행 경비 관리', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text(
              _tripTitle != null ? '$_tripTitle 지출 관리' : '여행 중이 아닐 때의 지출을 기록하세요',
              style: const TextStyle(fontSize: 13, color: AppColors.gray500),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
        titleSpacing: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)])),
                  child: Column(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('총 예산', style: TextStyle(fontSize: 13, color: Color(0xFFBFDBFE))),
                          const SizedBox(height: 4),
                          Text('${_totalBudget.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('총 지출', style: TextStyle(fontSize: 13, color: Color(0xFFBFDBFE))),
                            Text('${totalExpense.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          ])),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('남은 예산', style: TextStyle(fontSize: 13, color: Color(0xFFBFDBFE))),
                            Row(children: [
                              Icon(remaining >= 0 ? Icons.trending_up : Icons.trending_down, size: 18, color: remaining >= 0 ? Colors.white : const Color(0xFFFCA5A5)),
                              const SizedBox(width: 4),
                              Text('${remaining.abs().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: remaining >= 0 ? Colors.white : const Color(0xFFFCA5A5))),
                            ]),
                          ])),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('사용률', style: TextStyle(fontSize: 13, color: Color(0xFFBFDBFE))),
                        Text('${(progress * 100).round()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      ]),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: progress, backgroundColor: Colors.white.withOpacity(0.2),
                          color: totalExpense > _totalBudget ? const Color(0xFFF87171) : Colors.white, minHeight: 8),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('지출 내역', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                        TextButton.icon(
                          onPressed: () => setState(() => _showAddForm = !_showAddForm),
                          icon: const Icon(Icons.add, size: 16, color: AppColors.blue600),
                          label: const Text('추가', style: TextStyle(color: AppColors.blue600, fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                      ]),
                      if (_showAddForm) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppColors.blue50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.blue100)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('지출 추가', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                              const SizedBox(height: 12),
                              const Text('카테고리', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray700)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _newCategory,
                                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                onChanged: (v) => setState(() => _newCategory = v!),
                                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.gray300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.gray300)), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                              ),
                              const SizedBox(height: 10),
                              const Text('금액', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray700)),
                              const SizedBox(height: 6),
                              TextField(controller: _amountCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: '10000', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
                              const SizedBox(height: 10),
                              const Text('내용', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray700)),
                              const SizedBox(height: 6),
                              TextField(controller: _descCtrl, decoration: InputDecoration(hintText: '점심 식사', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
                              const SizedBox(height: 12),
                              Row(children: [
                                Expanded(child: ElevatedButton(onPressed: _addExpense, style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue600, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('추가'))),
                                const SizedBox(width: 8),
                                Expanded(child: ElevatedButton(onPressed: () => setState(() => _showAddForm = false), style: ElevatedButton.styleFrom(backgroundColor: AppColors.gray200, foregroundColor: AppColors.gray700, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('취소'))),
                              ]),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (_expenses.isEmpty)
                        Column(children: [
                          const SizedBox(height: 48),
                          const Icon(Icons.attach_money_rounded, size: 48, color: AppColors.gray300),
                          const SizedBox(height: 12),
                          const Text('지출 내역을 기록해보세요', style: TextStyle(fontSize: 14, color: AppColors.gray500)),
                          const SizedBox(height: 12),
                          TextButton(onPressed: () => setState(() => _showAddForm = true), child: const Text('첫 지출 추가하기', style: TextStyle(color: AppColors.blue600, fontWeight: FontWeight.w600))),
                        ])
                      else
                        ...(_expenses.map((expense) {
                          final cat = expense['category'] as String? ?? '기타';
                          final amount = (expense['amount'] as int?) ?? 0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: AppColors.gray50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: _catColors[cat] ?? AppColors.gray100, borderRadius: BorderRadius.circular(8)),
                                  child: Icon(_catIcons[cat] ?? Icons.attach_money_rounded, size: 20, color: _catTextColors[cat] ?? AppColors.gray700),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text(expense['title'] as String? ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                                          const SizedBox(height: 2),
                                          Text(
                                            DateTime.tryParse(expense['created_at'] as String? ?? '')?.toLocal().toString().substring(0, 10) ?? '',
                                            style: const TextStyle(fontSize: 13, color: AppColors.gray500),
                                          ),
                                        ]),
                                        GestureDetector(
                                          onTap: () => _delete(expense['id'] as String),
                                          child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.gray400),
                                        ),
                                      ]),
                                      const SizedBox(height: 8),
                                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(color: _catColors[cat] ?? AppColors.gray100, borderRadius: BorderRadius.circular(4)),
                                          child: Text(cat, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _catTextColors[cat] ?? AppColors.gray700)),
                                        ),
                                        Text('${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원',
                                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                                      ]),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        })),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
