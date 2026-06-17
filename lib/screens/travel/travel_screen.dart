import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/trip_service.dart';
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
  final List<Map<String, dynamic>> _bookings = [];
  int _checklistProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final trip = await TripService.getLatestConfirmedTrip();
    if (trip != null && mounted) {
      setState(() {
        _currentItinerary = {
          ...trip,
          'startDate': trip['start_date'],
        };
        _currentItineraryId = trip['id'] as String;
      });
    }
  }

  int get _getDDay {
    if (_currentItinerary == null) return -1;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final start = DateTime.parse(_currentItinerary!['startDate'] as String);
    return start.difference(todayDate).inDays;
  }

  List<Map<String, dynamic>> get _confirmedBookings =>
      _bookings.where((b) => b['status'] == 'confirmed').toList();

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
            Text('일정 생성과 예약 관리', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85))),
          ],
        ),
        titleSpacing: 24,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildTabs(),
          Expanded(child: _tabIndex == 0 ? _buildPlanTab() : _buildBookingsTab()),
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
            label: '예약 관리',
            isActive: _tabIndex == 1,
            badge: _confirmedBookings.isNotEmpty ? '${_confirmedBookings.length}' : null,
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
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(50)),
                              child: Text(dday == 0 ? '오늘 출발!' : 'D-$dday', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _deleteItinerary,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
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
                  GestureDetector(
                    onTap: () => context.push('/itinerary/$_currentItineraryId'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: const Text('일정 전체보기', style: TextStyle(color: AppColors.blue600, fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
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
                      _QuickBtn(label: '체크리스트', onTap: () => context.push('/checklist')),
                      const SizedBox(width: 8),
                      _QuickBtn(label: '경비관리', onTap: () => context.push('/budget')),
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

  Widget _buildBookingsTab() {
    if (_bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_boat_rounded, size: 64, color: AppColors.gray300),
            const SizedBox(height: 16),
            const Text('예약 내역이 없어요', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.gray900)),
            const SizedBox(height: 8),
            const Text('일정을 생성하고 예약해보세요', style: TextStyle(fontSize: 13, color: AppColors.gray600)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(label: '확정 예약', value: '${_confirmedBookings.length}'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: '총 금액',
                  value: '${(_confirmedBookings.fold<int>(0, (sum, b) => sum + ((b['activity']?['price'] as num?)?.toInt() ?? 0)) / 10000).floor()}만',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._bookings.map((b) => _BookingCard(
            booking: b,
            onCancel: (id) => _cancelBooking(id),
            onDelete: (id) => _deleteBooking(id),
          )),
        ],
      ),
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

  void _cancelBooking(String id) {
    setState(() {
      for (final b in _bookings) {
        if (b['id'] == id) b['status'] = 'cancelled';
      }
    });
  }

  void _deleteBooking(String id) {
    setState(() => _bookings.removeWhere((b) => b['id'] == id));
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
                  child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 11)),
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
          child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.blue700)),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.blue50, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.blue600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.blue700)),
        ],
      ),
    );
  }
}

class _BookingCard extends StatefulWidget {
  final Map<String, dynamic> booking;
  final Function(String) onCancel;
  final Function(String) onDelete;
  const _BookingCard({required this.booking, required this.onCancel, required this.onDelete});

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  bool _showActions = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final activity = b['activity'] as Map<String, dynamic>?;
    final isConfirmed = b['status'] == 'confirmed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activity?['title'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.gray900, fontSize: 14)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 12, color: AppColors.gray500),
                        const SizedBox(width: 4),
                        Text(activity?['location'] as String? ?? '', style: const TextStyle(fontSize: 12, color: AppColors.gray600)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isConfirmed ? AppColors.green100 : AppColors.red100,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  isConfirmed ? '확정' : '취소',
                  style: TextStyle(fontSize: 11, color: isConfirmed ? AppColors.green700 : AppColors.red700, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(activity?['price'] as num?)?.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},') ?? '0'}원',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.blue600, fontSize: 15),
              ),
              GestureDetector(
                onTap: () => setState(() => _showActions = !_showActions),
                child: Text(_showActions ? '닫기' : '관리', style: const TextStyle(fontSize: 13, color: AppColors.blue600, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          if (_showActions) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.gray100),
            const SizedBox(height: 12),
            Row(
              children: [
                if (isConfirmed)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => widget.onCancel(b['id'] as String),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.red700,
                        side: const BorderSide(color: AppColors.red500),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                if (isConfirmed) const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => widget.onDelete(b['id'] as String),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gray600,
                      side: const BorderSide(color: AppColors.gray300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('삭제'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
