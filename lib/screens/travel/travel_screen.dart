import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/trip_service.dart';
import '../../services/checklist_service.dart';
import '../../theme/app_colors.dart';

class TravelScreen extends StatefulWidget {
  const TravelScreen({super.key});

  @override
  State<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends State<TravelScreen> {
  int _tabIndex = 0;
  Map<String, dynamic>? _currentItinerary;
  String? _currentItineraryId;
  List<Map<String, dynamic>> _visitedTrips = [];
  int _checklistProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      TripService.getUpcomingTrip(),
      TripService.getVisitedTrips(),
    ]);
    final trip = results[0] as Map<String, dynamic>?;
    final visited = results[1] as List<Map<String, dynamic>>;
    if (!mounted) return;
    setState(() {
      if (trip != null) {
        _currentItinerary = {
          ...trip,
          'startDate': trip['start_date'],
        };
        _currentItineraryId = trip['id'] as String;
      }
      _visitedTrips = visited;
    });
    if (trip != null) {
      final progress = await ChecklistService.getProgress(tripId: trip['id'] as String);
      if (mounted) setState(() => _checklistProgress = progress);
    }
  }

  int get _getDDay {
    if (_currentItinerary == null) return -1;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final start = DateTime.parse(_currentItinerary!['startDate'] as String);
    return start.difference(todayDate).inDays;
  }

  Future<void> _deleteVisitedTrip(String id) async {
    await TripService.deleteTrip(id);
    setState(() => _visitedTrips.removeWhere((t) => t['id'] == id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('여행 계획', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('일정 생성과 예약 관리', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85))),
          ],
        ),
        titleSpacing: 24,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildTabs(),
          Expanded(child: _tabIndex == 0 ? _buildPlanTab() : _buildVisitedTab()),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.gray200)),
      ),
      child: Row(
        children: [
          _TabButton(
            icon: Icons.calendar_month_rounded,
            label: '일정 생성',
            isActive: _tabIndex == 0,
            onTap: () => setState(() => _tabIndex = 0),
          ),
          _TabButton(
            icon: Icons.directions_boat_rounded,
            label: '지난 여행',
            isActive: _tabIndex == 1,
            badge: _visitedTrips.isNotEmpty ? '${_visitedTrips.length}' : null,
            onTap: () => setState(() => _tabIndex = 1),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanTab() {
    if (_currentItinerary != null) {
      final dday = _getDDay;
      final islands = (_currentItinerary!['islands'] as List?)?.join(', ') ?? '';
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Upcoming trip
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('다가오는 여행', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                      Row(
                        children: [
                          if (dday >= 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(50)),
                              child: Text(dday == 0 ? '오늘 출발!' : 'D-$dday', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => context.push('/itinerary/$_currentItineraryId?edit=true'),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: _deleteItinerary,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                              child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_currentItinerary!['title'] as String? ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(islands, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/itinerary/$_currentItineraryId'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                          child: const Text('일정 전체보기', style: TextStyle(color: AppColors.blue600, fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                      ),
                      if (_currentItinerary!['confirmed'] != true) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                          ),
                          child: const Text('미확정', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (_currentItinerary!['confirmed'] != true) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => context.push('/itinerary/$_currentItineraryId'),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '일정이 아직 미확정이에요. 열어서 확정하면 홈에도 표시돼요.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF92400E)),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: Color(0xFFD97706), size: 18),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Preparation status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.checklist_rounded, color: AppColors.blue600, size: 20),
                      SizedBox(width: 8),
                      Text('준비 상황', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.gray900, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('체크리스트', style: TextStyle(fontSize: 13, color: AppColors.gray700)),
                      Text('$_checklistProgress%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.blue600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _checklistProgress / 100,
                      backgroundColor: AppColors.gray100,
                      color: AppColors.blue600,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _QuickBtn(label: '체크리스트', onTap: () => context.push('/checklist?tripId=$_currentItineraryId')),
                      const SizedBox(width: 8),
                      _QuickBtn(label: '경비관리', onTap: () => context.push('/budget?tripId=$_currentItineraryId')),
                      const SizedBox(width: 8),
                      _QuickBtn(label: '시간표', onTap: () => context.push('/schedule')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // New trip button
            GestureDetector(
              onTap: () => context.push('/create-trip'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gray300, width: 2, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: AppColors.gray600, size: 20),
                    SizedBox(width: 8),
                    Text('새 여행 계획 만들기', style: TextStyle(color: AppColors.gray600, fontWeight: FontWeight.w600, fontSize: 15)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // No itinerary
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppColors.blue50, shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome_rounded, color: AppColors.blue600, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('AI 맞춤 일정 생성', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.gray900)),
            const SizedBox(height: 8),
            const Text(
              '여행 날짜와 스타일을 선택하면\n최적의 일정을 자동으로 만들어드려요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.gray600, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/create-trip'),
                icon: const Icon(Icons.calendar_month_rounded),
                label: const Text('일정 만들기 시작'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitedTab() {
    if (_visitedTrips.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_boat_rounded, size: 64, color: AppColors.gray300),
            SizedBox(height: 16),
            Text('첫 여행을 계획해보세요', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.gray900)),
            SizedBox(height: 8),
            Text('여행을 다녀오면 여기에 기록돼요', style: TextStyle(fontSize: 13, color: AppColors.gray600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _visitedTrips.length,
      itemBuilder: (context, i) {
        final trip = _visitedTrips[i];
        final islands = (trip['islands'] as List?)?.cast<String>() ?? [];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(trip['title'] as String? ?? '여행', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.gray900, fontSize: 15)),
                  ),
                  GestureDetector(
                    onTap: () => _deleteVisitedTrip(trip['id'] as String),
                    child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.gray400),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 12, color: AppColors.gray500),
                  const SizedBox(width: 4),
                  Expanded(child: Text(islands.isNotEmpty ? islands.join(', ') : '섬 정보 없음', style: const TextStyle(fontSize: 13, color: AppColors.gray600))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${trip['start_date']} ~ ${trip['end_date']}', style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
                  GestureDetector(
                    onTap: () => context.push('/itinerary/${trip['id']}'),
                    child: const Text('일정보기', style: TextStyle(fontSize: 13, color: AppColors.blue600, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteItinerary() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('일정 삭제'),
        content: const Text('이 일정을 삭제할까요?\n삭제하면 되돌릴 수 없어요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: AppColors.red700)),
          ),
        ],
      ),
    );
    if (confirmed != true || _currentItineraryId == null) return;
    await TripService.deleteTrip(_currentItineraryId!);
    setState(() {
      _currentItinerary = null;
      _currentItineraryId = null;
    });
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final String? badge;
  final VoidCallback onTap;
  const _TabButton({required this.icon, required this.label, required this.isActive, this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isActive ? AppColors.blue600 : Colors.transparent, width: 2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isActive ? AppColors.blue600 : AppColors.gray500),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: isActive ? AppColors.blue600 : AppColors.gray500)),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.blue600, borderRadius: BorderRadius.circular(50)),
                  child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 13)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: AppColors.blue50, borderRadius: BorderRadius.circular(8)),
          child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.blue700)),
        ),
      ),
    );
  }
}
