import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/ferry_service.dart';
import '../../services/island_service.dart';
import '../../theme/app_colors.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});
  @override State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _tab = 0;
  String _selectedIsland = '백령도';

  List<IslandModel> _islands = [];
  String _selectedFerryIslandId = 'baengnyeong';
  List<Map<String, dynamic>> _ferrySchedules = [];
  bool _isFerryLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIslands();
  }

  Future<void> _loadIslands() async {
    try {
      final islands = await IslandService.getIslands();
      if (mounted) setState(() => _islands = islands);
    } catch (_) {
      // 섬 목록 실패해도 여객선 시간표는 아래에서 계속 시도
    }
    _loadFerrySchedule();
  }

  Future<void> _loadFerrySchedule() async {
    setState(() => _isFerryLoading = true);
    try {
      final live = await FerryService.getScheduleForIsland(_selectedFerryIslandId);
      IslandModel? island;
      for (final i in _islands) {
        if (i.id == _selectedFerryIslandId) { island = i; break; }
      }
      final departurePort = (island != null && island.ports.isNotEmpty) ? island.ports.first : '인천항';
      final schedules = live.map((s) => {
        'id': '${s.ferryName}_${s.departureTime}',
        'route': s.routeName,
        'departure': departurePort,
        'arrival': island?.name ?? '',
        'departureTime': s.departureTime,
        'duration': island?.ferryTime ?? '',
        'price': island?.ferryPrice ?? 0,
        'vessel': s.ferryName,
        'status': s.status,
      }).toList();
      if (mounted) setState(() { _ferrySchedules = schedules; _isFerryLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _ferrySchedules = []; _isFerryLoading = false; });
    }
  }

  void _selectFerryIsland(String islandId) {
    setState(() => _selectedFerryIslandId = islandId);
    _loadFerrySchedule();
  }

  static const _localTransport = [
    {
      'island': '백령도',
      'hasBus': true,
      'busRoutes': ['항구 - 두무진', '항구 - 사곶해변'],
      'busInterval': '1-2시간',
      'firstBus': '07:00',
      'lastBus': '18:00',
      'taxiAvailable': true,
      'taxiContact': '032-836-3000',
      'rentalAvailable': true,
      'rentalTypes': ['자전거', '전동스쿠터'],
      'rentalContact': '032-836-5500',
    },
    {
      'island': '덕적도',
      'hasBus': true,
      'busRoutes': ['진리 - 서포리', '진리 - 비조봉'],
      'busInterval': '2시간',
      'firstBus': '08:00',
      'lastBus': '17:00',
      'taxiAvailable': true,
      'taxiContact': '032-831-5000',
      'rentalAvailable': true,
      'rentalTypes': ['자전거', '전동스쿠터', 'ATV'],
      'rentalContact': '032-831-7700',
    },
    {
      'island': '영흥도',
      'hasBus': true,
      'busRoutes': ['항구 - 십리포', '순환버스'],
      'busInterval': '30분-1시간',
      'firstBus': '06:30',
      'lastBus': '19:00',
      'taxiAvailable': true,
      'taxiContact': '032-886-5000',
      'rentalAvailable': true,
      'rentalTypes': ['자전거', '전동스쿠터', '자동차'],
      'rentalContact': '032-886-8800',
    },
    {
      'island': '자월도',
      'hasBus': false,
      'taxiAvailable': true,
      'taxiContact': '032-832-3000',
      'rentalAvailable': true,
      'rentalTypes': ['자전거'],
      'rentalContact': '032-832-5500',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final transport = _localTransport.firstWhere((t) => t['island'] == _selectedIsland, orElse: () => _localTransport.first);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 124,
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
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(children: [
                      Icon(Icons.chevron_left, color: Color(0xFFBFDBFE), size: 20),
                      Text('뒤로', style: TextStyle(fontSize: 13, color: Color(0xFFBFDBFE))),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  const Text('교통 시간표', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Text('오늘의 실시간 여객선 운항 정보 및 섬 내부 교통 안내', style: TextStyle(fontSize: 13, color: Color(0xFFBFDBFE))),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(child: _TabBtn(label: '여객선', selected: _tab == 0, onTap: () => setState(() => _tab = 0))),
                const SizedBox(width: 8),
                Expanded(child: _TabBtn(label: '섬 내부 교통', selected: _tab == 1, onTap: () => setState(() => _tab = 1))),
              ],
            ),
          ),

          Expanded(
            child: _tab == 0
                ? _buildFerry()
                : _buildLocal(transport),
          ),
        ],
      ),
    );
  }

  Widget _buildFerry() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          color: AppColors.gray50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('섬 선택', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray700)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _islands.map((island) {
                    final selected = island.id == _selectedFerryIslandId;
                    return GestureDetector(
                      onTap: () => _selectFerryIsland(island.id),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.blue600 : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: selected ? AppColors.blue600 : AppColors.gray200),
                        ),
                        child: Text(island.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.gray700)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isFerryLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (_ferrySchedules.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: const [
                      Icon(Icons.directions_boat_filled_rounded, size: 64, color: AppColors.gray300),
                      SizedBox(height: 16),
                      Text('오늘 예정된 운항이 없어요', style: TextStyle(fontSize: 14, color: AppColors.gray500)),
                      SizedBox(height: 4),
                      Text('다른 섬을 선택해보세요', style: TextStyle(fontSize: 13, color: AppColors.gray400)),
                    ],
                  ),
                )
              else
                ..._ferrySchedules.map((s) => _FerryCard(schedule: s)),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFFEFCE8), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFEF08A))),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFCA8A04)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('운항 안내', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                          SizedBox(height: 6),
                          Text('• 기상 상황에 따라 운항이 지연되거나 결항될 수 있어요', style: TextStyle(fontSize: 13, color: Color(0xFF92400E), height: 1.5)),
                          Text('• 출항 30분 전까지 승선 수속을 완료해주세요', style: TextStyle(fontSize: 13, color: Color(0xFF92400E), height: 1.5)),
                          Text('• 성수기에는 사전 예약을 권장해요', style: TextStyle(fontSize: 13, color: Color(0xFF92400E), height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocal(Map<String, dynamic> transport) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          color: AppColors.gray50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('섬 선택', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray700)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _localTransport.map((t) {
                    final island = t['island'] as String;
                    final selected = island == _selectedIsland;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIsland = island),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.blue600 : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: selected ? AppColors.blue600 : AppColors.gray200),
                        ),
                        child: Text(island, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.gray700)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (transport['hasBus'] == true)
                _TransportCard(
                  icon: Icons.directions_bus_rounded,
                  iconBg: AppColors.blue100,
                  iconColor: AppColors.blue600,
                  title: '마을버스',
                  subtitle: '배차간격: ${transport['busInterval']}',
                  details: [
                    '노선: ${(transport['busRoutes'] as List).join(', ')}',
                    '운행시간: ${transport['firstBus']} - ${transport['lastBus']}',
                  ],
                ),
              if (transport['taxiAvailable'] == true)
                _TransportCard(
                  icon: Icons.local_taxi_rounded,
                  iconBg: const Color(0xFFFFF7ED),
                  iconColor: const Color(0xFFEA580C),
                  title: '택시',
                  subtitle: '호출 가능',
                  phone: transport['taxiContact'] as String?,
                ),
              if (transport['rentalAvailable'] == true)
                _TransportCard(
                  icon: Icons.pedal_bike_rounded,
                  iconBg: AppColors.blue100,
                  iconColor: AppColors.blue600,
                  title: '렌터카/대여',
                  subtitle: (transport['rentalTypes'] as List).join(', '),
                  phone: transport['rentalContact'] as String?,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue600 : AppColors.gray100,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.gray700)),
      ),
    );
  }
}

class _FerryCard extends StatelessWidget {
  final Map<String, dynamic> schedule;
  const _FerryCard({required this.schedule});

  Color _statusColor() {
    final s = schedule['status'] as String;
    if (s.contains('결항')) return const Color(0xFFFEE2E2);
    if (s.contains('지연')) return const Color(0xFFFFEDD5);
    return AppColors.blue100;
  }

  Color _statusTextColor() {
    final s = schedule['status'] as String;
    if (s.contains('결항')) return const Color(0xFFDC2626);
    if (s.contains('지연')) return const Color(0xFFEA580C);
    return AppColors.blue700;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(schedule['route'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                  Text(schedule['vessel'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _statusColor(), borderRadius: BorderRadius.circular(20)),
                child: Text(schedule['status'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _statusTextColor())),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('출발', style: TextStyle(fontSize: 13, color: AppColors.gray500)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: AppColors.gray400),
                      const SizedBox(width: 4),
                      Text(schedule['departureTime'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                    ]),
                    Text(schedule['departure'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
                  ],
                ),
              ),
              if ((schedule['duration'] as String).isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(8)),
                  child: Text('소요 ${schedule['duration']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray600)),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('도착지', style: TextStyle(fontSize: 13, color: AppColors.gray500)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.place_rounded, size: 14, color: AppColors.gray400),
                      const SizedBox(width: 4),
                      Text(schedule['arrival'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.gray200),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('편도 요금', style: TextStyle(fontSize: 13, color: AppColors.gray500)),
                  Text(
                    (schedule['price'] as int) > 0
                        ? '${(schedule['price'] as int).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원'
                        : '정보 없음',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.blue600),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${schedule['departureTime']} 출항 1시간 전에 알림을 드릴게요'))),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(8)),
                  child: const Row(children: [
                    Icon(Icons.notifications_outlined, size: 15, color: AppColors.gray700),
                    SizedBox(width: 6),
                    Text('알림 설정', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransportCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle;
  final List<String> details;
  final String? phone;

  const _TransportCard({required this.icon, required this.iconBg, required this.iconColor, required this.title, required this.subtitle, this.details = const [], this.phone});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...details.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(d, style: const TextStyle(fontSize: 13, color: AppColors.gray700)),
                  )),
                ],
              ],
            ),
          ),
          if (phone != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: AppColors.blue600, borderRadius: BorderRadius.circular(8)),
              child: const Text('전화하기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
