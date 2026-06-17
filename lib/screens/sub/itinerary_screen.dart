import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/trip_service.dart';
import '../../theme/app_colors.dart';

class ItineraryScreen extends StatefulWidget {
  final String id;
  const ItineraryScreen({super.key, required this.id});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  Map<String, dynamic>? _itinerary;
  int _selectedDay = 0;
  bool _isConfirmed = false;

  @override
  void initState() {
    super.initState();
    _loadItinerary();
  }

  Future<void> _loadItinerary() async {
    final data = await TripService.getTripById(widget.id);
    if (data != null && mounted) {
      setState(() {
        _itinerary = {
          ...data,
          'departurePort': data['departure_port'],
          'startDate': data['start_date'],
          'endDate': data['end_date'],
          'totalCost': data['total_cost'],
          'travelType': data['travel_type'],
          'days': (data['days'] as List?)?.cast<Map<String, dynamic>>() ?? [],
        };
        _isConfirmed = data['confirmed'] == true;
      });
    }
  }

  Future<void> _handleConfirm() async {
    if (_itinerary == null) return;
    await TripService.confirmTrip(widget.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정이 확정됐어요! 홈에서 확인하세요'), backgroundColor: AppColors.gray900, behavior: SnackBarBehavior.floating),
      );
      context.go('/');
    }
  }

  Future<void> _handleBook(Map<String, dynamic> activity) async {
    if (_itinerary == null) return;
    final days = (_itinerary!['days'] as List).cast<Map<String, dynamic>>();
    for (final day in days) {
      final acts = (day['activities'] as List).cast<Map<String, dynamic>>();
      for (final act in acts) {
        if (act['id'] == activity['id']) {
          act['bookingStatus'] = 'booked';
        }
      }
    }
    setState(() => _itinerary = {..._itinerary!, 'days': days});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${activity['title']} 예약 완료'), backgroundColor: AppColors.gray900, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_itinerary == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final days = (_itinerary!['days'] as List).cast<Map<String, dynamic>>();
    final currentDay = days[_selectedDay];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 120,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)])),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.go('/'),
                    child: Row(
                      children: const [
                        Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 14),
                        SizedBox(width: 4),
                        Text('홈으로', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(_itinerary!['title'] as String? ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.directions_boat_rounded, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(_itinerary!['departurePort'] as String? ?? '인천항', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                      const SizedBox(width: 16),
                      const Icon(Icons.people_rounded, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text('${_itinerary!['travelers']}명', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                      const SizedBox(width: 16),
                      const Icon(Icons.attach_money_rounded, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text('${((_itinerary!['totalCost'] as num?)?.toInt() ?? 0).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildDayTabs(days),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildDayHeader(currentDay),
                  _buildActivities(currentDay),
                  _buildBudgetSummary(),
                  _buildConfirmArea(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTabs(List<Map<String, dynamic>> days) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: days.asMap().entries.map((e) {
            final isSelected = e.key == _selectedDay;
            return GestureDetector(
              onTap: () => setState(() => _selectedDay = e.key),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.blue600 : AppColors.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Day ${e.value['dayNumber']}', style: TextStyle(fontWeight: FontWeight.w500, color: isSelected ? Colors.white : AppColors.gray700)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDayHeader(Map<String, dynamic> day) {
    final date = DateTime.tryParse(day['date'] as String? ?? '');
    const weekdays = ['', '월', '화', '수', '목', '금', '토', '일'];
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.gray200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Day ${day['dayNumber']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
          if (date != null) Text('${date.month}월 ${date.day}일 (${weekdays[date.weekday]})', style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
        ],
      ),
    );
  }

  Widget _buildActivities(Map<String, dynamic> day) {
    final activities = (day['activities'] as List).cast<Map<String, dynamic>>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: activities.asMap().entries.map((e) {
          final isLast = e.key == activities.length - 1;
          return _ActivityCard(activity: e.value, isLast: isLast, onBook: _handleBook);
        }).toList(),
      ),
    );
  }

  Widget _buildBudgetSummary() {
    final days = (_itinerary!['days'] as List).cast<Map<String, dynamic>>();
    int ferryTotal = 0, accommodationTotal = 0, mealTotal = 0;
    for (final day in days) {
      for (final act in (day['activities'] as List).cast<Map<String, dynamic>>()) {
        final price = (act['price'] as num?)?.toInt() ?? 0;
        if (act['type'] == 'ferry') ferryTotal += price;
        if (act['type'] == 'accommodation') accommodationTotal += price;
        if (act['type'] == 'meal') mealTotal += price;
      }
    }
    final total = (_itinerary!['totalCost'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.gray50, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('예산 요약', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.gray900, fontSize: 15)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                _BudgetRow(label: '여객선', amount: ferryTotal),
                const SizedBox(height: 8),
                _BudgetRow(label: '숙박', amount: accommodationTotal),
                const SizedBox(height: 8),
                _BudgetRow(label: '식사', amount: mealTotal),
                const Divider(height: 16),
                _BudgetRow(label: '총 예산', amount: total, isTotal: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmArea() {
    if (_isConfirmed) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.green100, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBBF7D0))),
          child: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.green600, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('일정이 확정됐어요', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.green700, fontSize: 15)),
                    Text('홈 화면에서 일정을 확인하세요', style: TextStyle(fontSize: 12, color: AppColors.green700)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleConfirm,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: const Text('일정 확정하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
          const Text('확정하면 홈 화면에서 일정을 바로 확인할 수 있어요', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.gray600)),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  final bool isLast;
  final Function(Map<String, dynamic>) onBook;
  const _ActivityCard({required this.activity, required this.isLast, required this.onBook});

  IconData get _icon => switch (activity['type']) {
    'ferry' => Icons.directions_boat_rounded,
    'accommodation' => Icons.hotel_rounded,
    'meal' => Icons.restaurant_rounded,
    _ => Icons.place_rounded,
  };

  Color get _iconBg => switch (activity['type']) {
    'ferry' => AppColors.blue100,
    'accommodation' => AppColors.purple100,
    'meal' => AppColors.orange50,
    _ => AppColors.green100,
  };

  Color get _iconColor => switch (activity['type']) {
    'ferry' => AppColors.blue600,
    'accommodation' => AppColors.purple600,
    'meal' => AppColors.orange600,
    _ => AppColors.green600,
  };

  @override
  Widget build(BuildContext context) {
    final canBook = activity['type'] == 'ferry' || activity['type'] == 'accommodation';
    final isBooked = activity['bookingStatus'] == 'booked';
    final price = (activity['price'] as num?)?.toInt() ?? 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: _iconBg, shape: BoxShape.circle),
              child: Icon(_icon, size: 20, color: _iconColor),
            ),
            if (!isLast) Container(width: 2, height: 60, color: AppColors.gray200, margin: const EdgeInsets.symmetric(vertical: 4)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray100),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity['time'] as String? ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.blue600)),
                const SizedBox(height: 4),
                Text(activity['title'] as String? ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                const SizedBox(height: 4),
                Text(activity['description'] as String? ?? '', style: const TextStyle(fontSize: 12, color: AppColors.gray600)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      const Icon(Icons.location_on_rounded, size: 12, color: AppColors.gray500),
                      const SizedBox(width: 4),
                      Text(activity['location'] as String? ?? '', style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                    ]),
                    if (price > 0) Text('${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                  ],
                ),
                if (canBook) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isBooked ? null : () => onBook(activity),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBooked ? AppColors.gray100 : AppColors.blue600,
                        foregroundColor: isBooked ? AppColors.gray500 : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: Text(isBooked ? '예약완료' : '예약하기', style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final String label;
  final int amount;
  final bool isTotal;
  const _BudgetRow({required this.label, required this.amount, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isTotal ? 15 : 13, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: AppColors.gray700)),
        Text('${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원', style: TextStyle(fontSize: isTotal ? 15 : 13, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? AppColors.blue600 : AppColors.gray900)),
      ],
    );
  }
}
