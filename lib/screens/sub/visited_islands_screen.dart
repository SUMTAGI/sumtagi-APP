import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';

class VisitedIslandsScreen extends StatefulWidget {
  const VisitedIslandsScreen({super.key});
  @override State<VisitedIslandsScreen> createState() => _VisitedIslandsScreenState();
}

class _VisitedIslandsScreenState extends State<VisitedIslandsScreen> {
  List<Map<String, dynamic>> _trips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) { setState(() => _isLoading = false); return; }
    final today = DateTime.now().toIso8601String().split('T')[0];
    final data = await Supabase.instance.client
        .from('trips')
        .select()
        .eq('user_id', userId)
        .eq('confirmed', true)
        .lt('end_date', today)
        .order('start_date', ascending: false);
    if (mounted) setState(() { _trips = List<Map<String, dynamic>>.from(data as List); _isLoading = false; });
  }

  int get _totalDays => _trips.fold<int>(0, (s, t) {
    final start = DateTime.tryParse(t['start_date'] as String? ?? '');
    final end = DateTime.tryParse(t['end_date'] as String? ?? '');
    if (start == null || end == null) return s;
    return s + end.difference(start).inDays + 1;
  });

  List<String> get _allIslands => _trips
      .expand((t) => (t['islands'] as List?)?.cast<String>() ?? <String>[])
      .toSet()
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('방문한 섬', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text('총 ${_allIslands.length}개 섬 방문', style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
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
                  padding: const EdgeInsets.all(24),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(child: _StatBox(value: '${_allIslands.length}', label: '방문 섬')),
                      const SizedBox(width: 12),
                      Expanded(child: _StatBox(value: '$_totalDays', label: '여행 일수')),
                      const SizedBox(width: 12),
                      Expanded(child: _StatBox(value: '${_trips.length}', label: '총 여행')),
                    ],
                  ),
                ),
                Expanded(
                  child: _trips.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_off_outlined, size: 64, color: AppColors.gray300),
                              SizedBox(height: 16),
                              Text('아직 완료된 여행이 없어요', style: TextStyle(fontSize: 16, color: AppColors.gray500)),
                              SizedBox(height: 8),
                              Text('여행을 완료하면 여기에 기록돼요', style: TextStyle(fontSize: 13, color: AppColors.gray400)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: _trips.length,
                            itemBuilder: (context, i) {
                              final trip = _trips[i];
                              final islands = (trip['islands'] as List?)?.cast<String>() ?? [];
                              final startDate = trip['start_date'] as String? ?? '';
                              final endDate = trip['end_date'] as String? ?? '';
                              final start = DateTime.tryParse(startDate);
                              final end = DateTime.tryParse(endDate);
                              final days = (start != null && end != null)
                                  ? end.difference(start).inDays + 1
                                  : 1;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 56, height: 56,
                                      decoration: const BoxDecoration(color: AppColors.blue50, shape: BoxShape.circle),
                                      child: const Icon(Icons.location_on_rounded, size: 28, color: AppColors.blue600),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(trip['title'] as String? ?? islands.join(', '), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                                          const SizedBox(height: 4),
                                          Text('$startDate  |  ${days}일', style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                                          if (islands.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(islands.join(', '), style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.check_circle_rounded, color: AppColors.green600, size: 20),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value, label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: AppColors.blue50, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.blue600)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.gray600)),
        ],
      ),
    );
  }
}
