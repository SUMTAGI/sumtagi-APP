import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});
  @override State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _tab = 0;
  String _selectedRoute = 'all';
  String _selectedIsland = '백령도';

  static const _ferrySchedules = [
    {'id': 'f1', 'route': '인천항 → 백령도', 'departure': '인천항', 'arrival': '백령도', 'departureTime': '08:00', 'arrivalTime': '12:00', 'duration': '4시간', 'price': 45000, 'vessel': '하모니플라워호', 'status': '정상'},
    {'id': 'f2', 'route': '백령도 → 인천항', 'departure': '백령도', 'arrival': '인천항', 'departureTime': '14:00', 'arrivalTime': '18:00', 'duration': '4시간', 'price': 45000, 'vessel': '하모니플라워호', 'status': '정상'},
    {'id': 'f3', 'route': '인천항 → 덕적도', 'departure': '인천항', 'arrival': '덕적도', 'departureTime': '09:00', 'arrivalTime': '11:30', 'duration': '2.5시간', 'price': 28000, 'vessel': '섬사랑2호', 'status': '정상'},
    {'id': 'f4', 'route': '덕적도 → 인천항', 'departure': '덕적도', 'arrival': '인천항', 'departureTime': '15:00', 'arrivalTime': '17:30', 'duration': '2.5시간', 'price': 28000, 'vessel': '섬사랑2호', 'status': '정상'},
    {'id': 'f5', 'route': '인천항 → 영흥도', 'departure': '인천항', 'arrival': '영흥도', 'departureTime': '10:00', 'arrivalTime': '11:00', 'duration': '1시간', 'price': 15000, 'vessel': '영흥페리호', 'status': '정상'},
    {'id': 'f6', 'route': '영흥도 → 인천항', 'departure': '영흥도', 'arrival': '인천항', 'departureTime': '16:00', 'arrivalTime': '17:00', 'duration': '1시간', 'price': 15000, 'vessel': '영흥페리호', 'status': '정상'},
    {'id': 'f7', 'route': '대부도 → 자월도', 'departure': '대부도', 'arrival': '자월도', 'departureTime': '09:30', 'arrivalTime': '11:30', 'duration': '2시간', 'price': 25000, 'vessel': '코리아킹호', 'status': '정상'},
    {'id': 'f8', 'route': '자월도 → 대부도', 'departure': '자월도', 'arrival': '대부도', 'departureTime': '14:30', 'arrivalTime': '16:30', 'duration': '2시간', 'price': 25000, 'vessel': '코리아킹호', 'status': '정상'},
  ];

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
    final departures = ['all', ...{..._ferrySchedules.map((s) => s['departure'] as String)}];
    final filtered = _selectedRoute == 'all'
        ? _ferrySchedules
        : _ferrySchedules.where((s) => s['departure'] == _selectedRoute).toList();
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
                  const Text('여객선 및 섬 내부 교통 정보', style: TextStyle(fontSize: 13, color: Color(0xFFBFDBFE))),
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
                ? _buildFerry(departures, filtered)
                : _buildLocal(transport),
          ),
        ],
      ),
    );
  }

  Widget _buildFerry(List<String> departures, List<Map<String, dynamic>> filtered) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          color: AppColors.gray50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('출발지', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray700)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: departures.map((r) {
                    final selected = r == _selectedRoute;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedRoute = r),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.blue600 : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: selected ? AppColors.blue600 : AppColors.gray200),
                        ),
                        child: Text(r == 'all' ? '전체' : r, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.gray700)),
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
              ...filtered.map((s) => _FerryCard(schedule: s)),
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
                          Text('• 기상 상황에 따라 운항이 지연되거나 결항될 수 있어요', style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.5)),
                          Text('• 출항 30분 전까지 승선 수속을 완료해주세요', style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.5)),
                          Text('• 성수기에는 사전 예약을 권장해요', style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.5)),
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
                        child: Text(island, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.gray700)),
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
    if (s == '정상') return AppColors.blue100;
    if (s == '지연') return const Color(0xFFFFEDD5);
    return const Color(0xFFFEE2E2);
  }

  Color _statusTextColor() {
    final s = schedule['status'] as String;
    if (s == '정상') return AppColors.blue700;
    if (s == '지연') return const Color(0xFFEA580C);
    return const Color(0xFFDC2626);
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
                  Text(schedule['vessel'] as String, style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _statusColor(), borderRadius: BorderRadius.circular(20)),
                child: Text(schedule['status'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusTextColor())),
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
                    const Text('출발', style: TextStyle(fontSize: 11, color: AppColors.gray500)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: AppColors.gray400),
                      const SizedBox(width: 4),
                      Text(schedule['departureTime'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                    ]),
                    Text(schedule['departure'] as String, style: const TextStyle(fontSize: 11, color: AppColors.gray600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(8)),
                child: Text(schedule['duration'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.gray600)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('도착', style: TextStyle(fontSize: 11, color: AppColors.gray500)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: AppColors.gray400),
                      const SizedBox(width: 4),
                      Text(schedule['arrivalTime'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                    ]),
                    Text(schedule['arrival'] as String, style: const TextStyle(fontSize: 11, color: AppColors.gray600)),
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
                  const Text('편도 요금', style: TextStyle(fontSize: 11, color: AppColors.gray500)),
                  Text('${(schedule['price'] as int).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.blue600)),
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
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...details.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(d, style: const TextStyle(fontSize: 12, color: AppColors.gray700)),
                  )),
                ],
              ],
            ),
          ),
          if (phone != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: AppColors.blue600, borderRadius: BorderRadius.circular(8)),
              child: const Text('전화하기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
