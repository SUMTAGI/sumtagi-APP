import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/trip_service.dart';
import '../../services/trip_booking_service.dart';
import '../../services/trip_risk_service.dart';
import '../../services/ai_itinerary_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';

// ── Island coordinates ─────────────────────────────────────────
const _coords = {
  '인천항':   LatLng(37.4744, 126.6169),
  '대부도':   LatLng(37.2173, 126.5589),
  '삼목항':   LatLng(37.4986, 126.4532),
  '백령도':   LatLng(37.9685, 124.6902),
  '대청도':   LatLng(37.8371, 124.7182),
  '소청도':   LatLng(37.7625, 124.7431),
  '연평도':   LatLng(37.6736, 125.6814),
  '덕적도':   LatLng(37.2269, 126.1432),
  '자월도':   LatLng(37.2589, 126.3083),
  '승봉도':   LatLng(37.1669, 126.1611),
  '대이작도': LatLng(37.1667, 126.2833),
  '소이작도': LatLng(37.1500, 126.2917),
  '풍도':     LatLng(37.0647, 126.2636),
  '육도':     LatLng(37.0036, 126.3547),
  '신도':     LatLng(37.527931, 126.457237),
  '장봉도':   LatLng(37.53102257, 126.3679055429),
  '영흥도':   LatLng(37.2397, 126.4921),
  '선재도':   LatLng(37.2508, 126.4731),
  '굴업도':   LatLng(37.1917, 126.2186),
  '시도':     LatLng(37.5446026512, 126.431177159),
  '소야도':   LatLng(37.2126756954, 126.175942845),
  '울도':     LatLng(37.0257233193983, 125.997020937643),
  // 모도·문갑도·백아도는 관광공사 API에 데이터가 없어 OSM Nominatim으로 실측 좌표 확보(2026-07-07)
  '모도':     LatLng(37.5331998, 126.4080697),
  '문갑도':   LatLng(37.1769151, 126.0982694),
  '백아도':   LatLng(37.0802720, 125.9468352),
};

const _typeLabels = {
  'ferry': '여객선',
  'attraction': '관광',
  'accommodation': '숙박',
  'meal': '식사',
};
const _typeOrder = ['ferry', 'attraction', 'accommodation', 'meal'];

class ItineraryScreen extends StatefulWidget {
  final String id;
  final bool startInEditMode;
  const ItineraryScreen({super.key, required this.id, this.startInEditMode = false});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  Map<String, dynamic>? _itinerary;
  int _selectedDay = 0;
  bool _isConfirmed = false;
  bool _isEditMode = false;
  List<Map<String, dynamic>> _bookings = [];
  List<TripRisk> _risks = [];
  bool _reconstructing = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.startInEditMode;
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
      _loadBookingChecklist();
      if (_isConfirmed) _checkRisks();
    }
  }

  Future<void> _loadBookingChecklist() async {
    final islands = (_itinerary!['islands'] as List?)?.cast<String>() ?? [];
    final port = _itinerary!['departurePort'] as String? ?? '인천항';
    final bookings = await TripBookingService.getChecklist(
      tripId: widget.id, islands: islands, departurePort: port,
    );
    if (mounted) setState(() => _bookings = bookings);
  }

  Future<void> _checkRisks() async {
    final islands = (_itinerary!['islands'] as List?)?.cast<String>() ?? [];
    final risks = await TripRiskService.checkTripRisks(
      islands, _itinerary!['startDate'] as String? ?? '', _itinerary!['endDate'] as String? ?? '',
    );
    if (mounted) setState(() => _risks = risks);
  }

  Future<void> _handleReconstruct() async {
    if (_itinerary == null || _risks.isEmpty) return;
    setState(() => _reconstructing = true);
    try {
      final riskNote = _risks.map((r) => r.message).join(' / ');
      final req = AIItineraryRequest(
        departurePort: _itinerary!['departurePort'] as String? ?? '인천항',
        islands: (_itinerary!['islands'] as List?)?.cast<String>() ?? [],
        startDate: _itinerary!['startDate'] as String? ?? '',
        endDate: _itinerary!['endDate'] as String? ?? '',
        travelers: (_itinerary!['travelers'] as num?)?.toInt() ?? 1,
        travelStyle: _itinerary!['travel_type'] as String? ?? '관광',
        budget: _itinerary!['budget'] as String? ?? '보통',
        specialRequests: '기상 악화·여객선 결항 위험이 감지됐어요: $riskNote. 이 위험을 피하거나 완화할 수 있도록 일정을 조정해줘(실내 활동으로 대체, 일정 순서 조정 등).',
      );
      final result = await generateAIItinerary(req);
      final days = result.itinerary.days.map((d) => d.toJson()).toList();
      await TripService.updateItinerary(widget.id, days, result.itinerary.totalCost);
      await NotificationService.add('일정이 재구성됐어요', '$riskNote — 위험을 피하도록 일정을 다시 만들었어요.');
      if (mounted) {
        setState(() {
          _itinerary = {..._itinerary!, 'days': days, 'totalCost': result.itinerary.totalCost};
          _risks = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('일정을 재구성했어요'), backgroundColor: AppColors.gray900, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일정 재구성 실패: $e'), backgroundColor: AppColors.gray900, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _reconstructing = false);
    }
  }

  void _toggleBooking(Map<String, dynamic> booking) {
    final current = booking['is_done'] == true;
    setState(() {
      _bookings = _bookings.map((b) => b['id'] == booking['id'] ? {...b, 'is_done': !current} : b).toList();
    });
    TripBookingService.toggle(booking['id'] as String, current);
  }

  void _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ── persist ────────────────────────────────────────────────
  Future<void> _persistItinerary() async {
    if (_itinerary == null) return;
    final days = (_itinerary!['days'] as List).cast<Map<String, dynamic>>();
    int totalCost = 0;
    for (final day in days) {
      for (final act in (day['activities'] as List).cast<Map<String, dynamic>>()) {
        totalCost += (act['price'] as num?)?.toInt() ?? 0;
      }
    }
    setState(() => _itinerary = {..._itinerary!, 'totalCost': totalCost});
    await TripService.updateItinerary(widget.id, days, totalCost);
  }

  void _handleSaveEdit() {
    _persistItinerary();
    setState(() => _isEditMode = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('일정이 저장됐어요'), backgroundColor: AppColors.gray900, behavior: SnackBarBehavior.floating),
    );
  }

  // ── activity mutations ─────────────────────────────────────
  void _updateActivity(int dayIdx, String actId, Map<String, dynamic> updates) {
    setState(() {
      final days = (_itinerary!['days'] as List).cast<Map<String, dynamic>>();
      final acts = (days[dayIdx]['activities'] as List).cast<Map<String, dynamic>>();
      final idx = acts.indexWhere((a) => a['id'] == actId);
      if (idx >= 0) acts[idx] = {...acts[idx], ...updates};
      days[dayIdx] = {...days[dayIdx], 'activities': acts};
      _itinerary = {..._itinerary!, 'days': days};
    });
  }

  void _deleteActivity(int dayIdx, String actId) {
    setState(() {
      final days = (_itinerary!['days'] as List).cast<Map<String, dynamic>>();
      final acts = (days[dayIdx]['activities'] as List)
          .cast<Map<String, dynamic>>()
          .where((a) => a['id'] != actId)
          .toList();
      days[dayIdx] = {...days[dayIdx], 'activities': acts};
      _itinerary = {..._itinerary!, 'days': days};
    });
  }

  void _addActivity(Map<String, dynamic> activity) {
    setState(() {
      final days = (_itinerary!['days'] as List).cast<Map<String, dynamic>>();
      final acts = List<Map<String, dynamic>>.from(
        (days[_selectedDay]['activities'] as List).cast<Map<String, dynamic>>(),
      )..add(activity);
      acts.sort((a, b) => (a['time'] as String).compareTo(b['time'] as String));
      days[_selectedDay] = {...days[_selectedDay], 'activities': acts};
      _itinerary = {..._itinerary!, 'days': days};
    });
  }

  // ── book ───────────────────────────────────────────────────
  Future<void> _handleBook(Map<String, dynamic> activity) async {
    if (_itinerary == null) return;
    final days = (_itinerary!['days'] as List).cast<Map<String, dynamic>>();
    for (final day in days) {
      for (final act in (day['activities'] as List).cast<Map<String, dynamic>>()) {
        if (act['id'] == activity['id']) act['bookingStatus'] = 'booked';
      }
    }
    setState(() => _itinerary = {..._itinerary!, 'days': days});
    await TripService.updateDays(widget.id, days);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${activity['title']} 예약 완료'), backgroundColor: AppColors.gray900, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _handleConfirm() async {
    if (_itinerary == null) return;
    await TripService.confirmTrip(widget.id);
    if (mounted) {
      setState(() => _isConfirmed = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정이 확정됐어요!'), backgroundColor: AppColors.gray900, behavior: SnackBarBehavior.floating),
      );
      context.go('/travel');
    }
  }

  // ── add activity sheet ─────────────────────────────────────
  void _showAddActivitySheet() {
    String type = 'attraction';
    final timeCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.gray300, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('활동 추가', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                      GestureDetector(onTap: () => Navigator.pop(ctx), child: const Icon(Icons.close_rounded, color: AppColors.gray500)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: _typeOrder.map((t) {
                      final selected = type == t;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => set(() => type = t),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.blue600 : AppColors.gray100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_typeLabels[t]!, textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : AppColors.gray700)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _sheetField('시간 *', timeCtrl, '09:00')),
                    const SizedBox(width: 10),
                    Expanded(child: _sheetField('가격 (원)', priceCtrl, '0', type: TextInputType.number)),
                  ]),
                  const SizedBox(height: 10),
                  _sheetField('이름 *', titleCtrl, '예: 두무진 트레킹'),
                  const SizedBox(height: 10),
                  _sheetField('장소', locationCtrl, '예: 백령도 두무진'),
                  const SizedBox(height: 10),
                  _sheetField('설명', descCtrl, '간단한 메모'),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (timeCtrl.text.isEmpty || titleCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('시간과 이름을 입력해주세요')));
                          return;
                        }
                        _addActivity({
                          'id': 'act_${DateTime.now().millisecondsSinceEpoch}',
                          'type': type,
                          'time': timeCtrl.text,
                          'title': titleCtrl.text,
                          'location': locationCtrl.text,
                          'description': descCtrl.text,
                          'price': int.tryParse(priceCtrl.text) ?? 0,
                          'duration': 60,
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('활동이 추가됐어요'), backgroundColor: AppColors.gray900, behavior: SnackBarBehavior.floating),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue600, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
                      ),
                      child: const Text('추가하기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _sheetField(String label, TextEditingController ctrl, String hint, {TextInputType? type}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray600)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: type,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.blue600, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  // ── build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_itinerary == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final days = (_itinerary!['days'] as List).cast<Map<String, dynamic>>();

    if (days.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('새로운 일정을 만들어보세요', style: TextStyle(color: AppColors.gray600)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('돌아가기'),
              ),
            ],
          ),
        ),
      );
    }

    final currentDay = days[_selectedDay];

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildRiskBanner(),
          _buildDayTabs(days),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildDayHeader(currentDay),
                  _buildActivities(currentDay),
                  if (!_isEditMode) ...[
                    _buildMap(),
                    _buildBudgetSummary(),
                    _buildBookingChecklist(),
                    _buildConfirmArea(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_isEditMode) { _handleSaveEdit(); } else { context.go('/'); }
                    },
                    child: Row(children: [
                      const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(_isEditMode ? '저장 후 나가기' : '홈으로',
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ]),
                  ),
                  GestureDetector(
                    onTap: _isEditMode ? _handleSaveEdit : () => setState(() => _isEditMode = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isEditMode ? Colors.green.shade400 : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        Icon(_isEditMode ? Icons.check_rounded : Icons.edit_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(_isEditMode ? '저장' : '편집',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                      ]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(_itinerary!['title'] as String? ?? '',
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 6),
              if (_isEditMode)
                const Text('활동을 탭해서 수정하거나 + 버튼으로 추가하세요',
                  style: TextStyle(fontSize: 13, color: Colors.white70))
              else
                Row(children: [
                  Icon(
                    _itinerary!['departurePort'] == '육로 이동'
                        ? Icons.directions_car_rounded
                        : Icons.directions_boat_rounded,
                    size: 13, color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(_itinerary!['departurePort'] as String? ?? '인천항',
                    style: const TextStyle(fontSize: 13, color: Colors.white70)),
                  const SizedBox(width: 14),
                  const Icon(Icons.people_rounded, size: 13, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text('${_itinerary!['travelers']}명',
                    style: const TextStyle(fontSize: 13, color: Colors.white70)),
                  const SizedBox(width: 14),
                  const Icon(Icons.attach_money_rounded, size: 13, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text('${_fmt((_itinerary!['totalCost'] as num?)?.toInt() ?? 0)}원',
                    style: const TextStyle(fontSize: 13, color: Colors.white70)),
                ]),
            ],
          ),
        ),
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
                child: Text('Day ${e.value['dayNumber']}',
                  style: TextStyle(fontWeight: FontWeight.w500, color: isSelected ? Colors.white : AppColors.gray700)),
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
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.gray200))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Day ${day['dayNumber']}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
          if (date != null)
            Text('${date.month}월 ${date.day}일 (${weekdays[date.weekday]})',
              style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
        ],
      ),
    );
  }

  Widget _buildActivities(Map<String, dynamic> day) {
    final dayIdx = _selectedDay;
    final activities = (day['activities'] as List).cast<Map<String, dynamic>>();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ...activities.asMap().entries.map((e) {
            final isLast = e.key == activities.length - 1;
            if (_isEditMode) {
              return _ActivityEditCard(
                key: ValueKey(e.value['id']),
                activity: e.value,
                isLast: isLast && activities.length <= 1,
                onUpdate: (updates) => _updateActivity(dayIdx, e.value['id'] as String, updates),
                onDelete: () => _deleteActivity(dayIdx, e.value['id'] as String),
              );
            }
            return _ActivityCard(activity: e.value, isLast: isLast, onBook: _handleBook);
          }),
          if (_isEditMode)
            GestureDetector(
              onTap: _showAddActivitySheet,
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.blue200, width: 2, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, color: AppColors.blue600, size: 20),
                    SizedBox(width: 6),
                    Text('활동 추가', style: TextStyle(color: AppColors.blue600, fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── route map ──────────────────────────────────────────────
  Widget _buildMap() {
    final islands = (_itinerary!['islands'] as List?)?.cast<String>() ?? [];
    final port = _itinerary!['departurePort'] as String? ?? '인천항';
    final portCoord = _coords[port];
    final stopCoords = islands.map((n) => _coords[n]).whereType<LatLng>().toList();
    if (stopCoords.isEmpty) return const SizedBox.shrink();

    // 다리로 연결된 섬("육로 이동")은 고정 출발항 좌표가 없어 섬간 경로만 표시
    final route = portCoord != null ? [portCoord, ...stopCoords, portCoord] : stopCoords;
    final routeText = portCoord != null ? [port, ...islands, port].join(' → ') : islands.join(' → ');
    final mapCenter = portCoord ?? stopCoords.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('여행 경로', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.gray900, fontSize: 15)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 200,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: mapCenter,
                  initialZoom: 8,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                  PolylineLayer(polylines: [
                    Polyline(
                      points: route,
                      strokeWidth: 2.5,
                      color: AppColors.blue600,
                    ),
                  ]),
                  MarkerLayer(markers: [
                    if (portCoord != null)
                    Marker(
                      point: portCoord,
                      width: 28, height: 28,
                      child: Container(
                        decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        child: const Center(child: Text('출', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
                      ),
                    ),
                    ...stopCoords.asMap().entries.map((e) => Marker(
                      point: e.value,
                      width: 28, height: 28,
                      child: Container(
                        decoration: BoxDecoration(color: AppColors.blue600, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
                      ),
                    )),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(routeText, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
          const SizedBox(height: 24),
        ],
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
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
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
            child: Column(children: [
              _BudgetRow(label: '여객선', amount: ferryTotal),
              const SizedBox(height: 8),
              _BudgetRow(label: '숙박', amount: accommodationTotal),
              const SizedBox(height: 8),
              _BudgetRow(label: '식사', amount: mealTotal),
              const Divider(height: 16),
              _BudgetRow(label: '총 예산', amount: total, isTotal: true),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskBanner() {
    if (_risks.isEmpty || _isEditMode) return const SizedBox.shrink();
    final hasCancelled = _risks.any((r) => r.level == TripRiskLevel.cancelled);

    return Container(
      width: double.infinity,
      color: const Color(0xFFFFFBEB),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFD97706)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasCancelled ? '여객선 결항이 확인됐어요' : '결항 가능성이 있어요',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF92400E)),
                  ),
                  const SizedBox(height: 4),
                  ..._risks.map((r) => Text(r.message, style: const TextStyle(fontSize: 13, color: Color(0xFF92400E)))),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _reconstructing ? null : _handleReconstruct,
              icon: _reconstructing
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.refresh_rounded, size: 16),
              label: Text(_reconstructing ? '재구성 중...' : '대체 일정 만들기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _bookingCategoryLabel = {
    'ferry': '여객선', 'accommodation': '숙박', 'restaurant': '식당', 'experience': '체험',
  };

  Widget _buildBookingChecklist() {
    if (_bookings.isEmpty) return const SizedBox.shrink();
    final doneCount = _bookings.where((b) => b['is_done'] == true).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.gray50, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Row(children: [
              Icon(Icons.checklist_rounded, size: 18, color: AppColors.gray700),
              SizedBox(width: 6),
              Text('예약 준비 체크리스트', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.gray900, fontSize: 15)),
            ]),
            Text('$doneCount/${_bookings.length}', style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
          ]),
          const SizedBox(height: 4),
          const Text(
            '여객선·숙박·식당 예약은 sumtagi가 대신 해주지 않아요. 연락처로 직접 예약한 뒤 완료로 체크하세요.',
            style: TextStyle(fontSize: 13, color: AppColors.gray500),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: _bookings.map((b) {
                final isDone = b['is_done'] == true;
                final phone = b['phone'] as String?;
                final url = b['external_url'] as String?;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.gray100, width: b == _bookings.first ? 0 : 1))),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => _toggleBooking(b),
                      child: Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone ? AppColors.blue600 : Colors.transparent,
                          border: Border.all(color: isDone ? AppColors.blue600 : AppColors.gray300, width: 2),
                        ),
                        child: isDone ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(4)),
                          child: Text(_bookingCategoryLabel[b['category']] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.gray600, fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            b['name'] as String? ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500,
                              color: isDone ? AppColors.gray400 : AppColors.gray900,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      ]),
                    ),
                    if (phone != null)
                      GestureDetector(
                        onTap: () => _callPhone(phone),
                        child: Container(
                          width: 30, height: 30,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.blue100),
                          child: const Icon(Icons.call_rounded, size: 15, color: AppColors.blue600),
                        ),
                      ),
                    if (url != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: GestureDetector(
                          onTap: () => _openUrl(url),
                          child: Container(
                            width: 30, height: 30,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.blue100),
                            child: const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.blue600),
                          ),
                        ),
                      ),
                  ]),
                );
              }).toList(),
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
          child: const Row(children: [
            Icon(Icons.check_circle_rounded, color: AppColors.green600, size: 24),
            SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('일정이 확정됐어요', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.green700, fontSize: 15)),
                Text('여행 탭에서 일정을 확인하세요', style: TextStyle(fontSize: 13, color: AppColors.green700)),
              ],
            )),
          ]),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleConfirm,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            child: const Text('일정 확정하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 8),
        const Text('확정하면 홈 화면에서 일정을 바로 확인할 수 있어요', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.gray600)),
      ]),
    );
  }

  String _fmt(int n) => n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

// ── View Card ──────────────────────────────────────────────────
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
        Column(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: _iconBg, shape: BoxShape.circle), child: Icon(_icon, size: 20, color: _iconColor)),
          if (!isLast) Container(width: 2, height: 60, color: AppColors.gray200, margin: const EdgeInsets.symmetric(vertical: 4)),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray100), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(activity['time'] as String? ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.blue600)),
              const SizedBox(height: 4),
              Text(activity['title'] as String? ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900)),
              const SizedBox(height: 4),
              Text(activity['description'] as String? ?? '', style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  const Icon(Icons.location_on_rounded, size: 12, color: AppColors.gray500),
                  const SizedBox(width: 4),
                  Text(activity['location'] as String? ?? '', style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
                ]),
                if (price > 0) Text('${_fmtNum(price)}원', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray900)),
              ]),
              if (canBook) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isBooked ? null : () => onBook(activity),
                    style: ElevatedButton.styleFrom(backgroundColor: isBooked ? AppColors.gray100 : AppColors.blue600, foregroundColor: isBooked ? AppColors.gray500 : Colors.white, padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
                    child: Text(isBooked ? '예약완료' : '예약하기', style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

String _fmtNum(int n) => n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

// ── Edit Card ──────────────────────────────────────────────────
class _ActivityEditCard extends StatefulWidget {
  final Map<String, dynamic> activity;
  final bool isLast;
  final void Function(Map<String, dynamic> updates) onUpdate;
  final VoidCallback onDelete;
  const _ActivityEditCard({super.key, required this.activity, required this.isLast, required this.onUpdate, required this.onDelete});

  @override
  State<_ActivityEditCard> createState() => _ActivityEditCardState();
}

class _ActivityEditCardState extends State<_ActivityEditCard> {
  late TextEditingController _time;
  late TextEditingController _title;
  late TextEditingController _location;
  late TextEditingController _desc;
  late TextEditingController _price;

  @override
  void initState() {
    super.initState();
    final a = widget.activity;
    _time = TextEditingController(text: a['time'] as String? ?? '');
    _title = TextEditingController(text: a['title'] as String? ?? '');
    _location = TextEditingController(text: a['location'] as String? ?? '');
    _desc = TextEditingController(text: a['description'] as String? ?? '');
    _price = TextEditingController(text: ((a['price'] as num?)?.toInt() ?? 0) == 0 ? '' : '${(a['price'] as num).toInt()}');
  }

  @override
  void dispose() {
    _time.dispose(); _title.dispose(); _location.dispose(); _desc.dispose(); _price.dispose();
    super.dispose();
  }

  void _flush() {
    widget.onUpdate({
      'time': _time.text,
      'title': _title.text,
      'location': _location.text,
      'description': _desc.text,
      'price': int.tryParse(_price.text) ?? 0,
    });
  }

  Widget _editField(String hint, TextEditingController ctrl, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: (_) => _flush(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.gray200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.gray200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.blue600, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 13, color: AppColors.gray900),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typeLabel = _typeLabels[widget.activity['type'] as String? ?? 'attraction'] ?? '관광';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blue200, width: 2),
        boxShadow: [BoxShadow(color: AppColors.blue600.withValues(alpha: 0.06), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.blue50, borderRadius: BorderRadius.circular(6)),
            child: Text(typeLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.blue600)),
          ),
          GestureDetector(
            onTap: widget.onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _editField('시간  (09:00)', _time)),
          const SizedBox(width: 8),
          Expanded(child: _editField('가격 (원)', _price, keyboardType: TextInputType.number)),
        ]),
        const SizedBox(height: 8),
        _editField('이름', _title),
        const SizedBox(height: 8),
        _editField('장소', _location),
        const SizedBox(height: 8),
        _editField('설명', _desc, maxLines: 2),
      ]),
    );
  }
}

// ── Budget Row ─────────────────────────────────────────────────
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
        Text('${_fmtNum(amount)}원', style: TextStyle(fontSize: isTotal ? 15 : 13, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? AppColors.blue600 : AppColors.gray900)),
      ],
    );
  }
}
