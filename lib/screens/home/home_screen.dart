import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/trip_service.dart';
import '../../services/weather_service.dart';
import '../../services/ferry_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/ocean_scene.dart';
import '../../widgets/ai_island_search_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _unreadNotifications = 0;
  Map<String, dynamic>? _upcomingTrip;
  String _userName = '';
  WeatherResult? _weather;
  List<FerryRouteStatus> _ferryStatus = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    NotificationService.subscribe(_handleNewNotification);
  }

  @override
  void dispose() {
    NotificationService.unsubscribe();
    super.dispose();
  }

  void _handleNewNotification(Map<String, dynamic> notification) {
    if (!mounted) return;
    setState(() => _unreadNotifications++);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(notification['message'] as String? ?? '새 알림이 있어요'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loadData() async {
    final user = AuthService.currentUser;
    final meta = user?.userMetadata;
    final name = (meta != null && meta['nickname'] != null)
        ? meta['nickname'] as String
        : user?.email?.split('@')[0] ?? '';
    final results = await Future.wait([
      TripService.getUpcomingTrip().catchError((_) => null),
      WeatherService.getWeather().catchError((_) => null),
      NotificationService.getUnreadCount().catchError((_) => 0),
    ]);
    if (mounted) {
      setState(() {
        _userName = name;
        _upcomingTrip = results[0] as Map<String, dynamic>?;
        _weather = results[1] as WeatherResult?;
        _unreadNotifications = results[2] as int;
      });
      FerryService.getHomeFerryStatus()
          .then((status) { if (mounted) setState(() => _ferryStatus = status); })
          .catchError((e, st) { print('[Home Ferry Error] $e\n$st'); });
    }
  }

  int _getDDay(String startDate) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final start = DateTime.parse(startDate);
    return start.difference(todayDate).inDays;
  }

  String _getDDayMessage(int dday) {
    if (dday == 0) return '오늘 출발이에요! 🎉';
    if (dday == 1) return '내일 떠나요! 설레네요 ✨';
    if (dday <= 3) return '곧 출발이에요! 준비 다 되셨나요? 🌊';
    if (dday <= 7) return '설레는 여행이 다가와요 ⛴️';
    return '여행 준비 잘 하고 계신가요? 🏝️';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeroContent()),
            SliverToBoxAdapter(child: _buildFerryRiskBanner()),
            SliverToBoxAdapter(child: _buildQuickLinks()),
            SliverToBoxAdapter(child: _buildStatus()),
          ],
        ),
      ),
    );
  }

  void _showAllFerryStatus(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('전체 운항 현황', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context), color: AppColors.gray400),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                children: _ferryStatus.map((s) {
                  final isCancelled = s.status == '결항';
                  final isNone = s.status == '운항없음';
                  final bgColor = isCancelled ? AppColors.red50 : isNone ? AppColors.gray100 : const Color(0xFFF0FDF4);
                  final textColor = isCancelled ? AppColors.red700 : isNone ? AppColors.gray400 : const Color(0xFF15803D);
                  final label = s.status == '정상' ? '정상 운항' : s.status;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s.islandName, style: const TextStyle(fontSize: 15, color: AppColors.gray700)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
                          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFerryRiskBanner() {
    if (_weather == null) return const SizedBox.shrink();
    final risk = WeatherService.assessFerryRisk(
      _weather!.current.windSpeed,
      _weather!.current.waveHeight,
    );
    if (risk == FerryRisk.safe) return const SizedBox.shrink();

    final isDanger = risk == FerryRisk.danger;
    final bgColor  = isDanger ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);
    final border   = isDanger ? const Color(0xFFFECACA) : const Color(0xFFFDE68A);
    final iconColor= isDanger ? const Color(0xFFDC2626) : const Color(0xFFD97706);
    final textColor= isDanger ? const Color(0xFF991B1B) : const Color(0xFF92400E);
    final icon     = isDanger ? Icons.warning_rounded : Icons.info_outline_rounded;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(risk.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 2),
                Text(
                  '${risk.description} (풍속 ${_weather!.current.windSpeed.toStringAsFixed(1)} km/h · 파고 ${_weather!.current.waveHeight.toStringAsFixed(1)} m)',
                  style: TextStyle(fontSize: 13, color: textColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroContent() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: _buildHeroContainer(),
    );
  }

  Widget _buildHeroContainer() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: CachedNetworkImage(
                imageUrl: 'https://images.unsplash.com/photo-1700621497504-d241a3803bbd?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080',
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xCC2563EB), Color(0xCC1D4ED8)],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: OceanScene(waveColor: Colors.white, waveHeight: 28),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _userName.isNotEmpty ? '안녕하세요, $_userName님!' : '인천 섬 여행',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/notifications'),
                        child: Stack(
                          children: [
                            ClipOval(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
                                  ),
                                  child: const Icon(Icons.notifications_outlined, size: 20, color: Colors.white),
                                ),
                              ),
                            ),
                            if (_unreadNotifications > 0)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const AiIslandSearchBar(),
                  const SizedBox(height: 16),
                  if (_upcomingTrip != null)
                    _buildConfirmedTrip()
                  else
                    _buildNoTrip(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmedTrip() {
    final itin = _upcomingTrip!;
    final dday = _getDDay((itin['start_date'] ?? itin['startDate']) as String);
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.directions_boat_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text('오늘의 여행', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                ],
              ),
              Row(
                children: [
                  if (dday >= 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        dday == 0 ? 'D-Day' : 'D-$dday',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            itin['title'] as String? ?? '',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            _getDDayMessage(dday),
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoTrip() {
    return Column(
      children: [
        _GlassCard(
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 48),
                const SizedBox(height: 8),
                const Text('아직 계획이 없으신가요?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  '여객선 정보 기반으로 자동 일정을 생성해드려요',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => context.push('/create-trip'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month_rounded, color: AppColors.blue600, size: 20),
                SizedBox(width: 8),
                Text('여행 계획 시작하기', style: TextStyle(color: AppColors.blue600, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLinks() {
    final links = [
      {'icon': Icons.photo_camera_rounded, 'title': '체험', 'route': '/experiences'},
      {'icon': Icons.people_rounded, 'title': '리뷰', 'route': '/community'},
      {'icon': Icons.security_rounded, 'title': '체크리스트', 'route': '/checklist'},
      {'icon': Icons.attach_money_rounded, 'title': '경비관리', 'route': '/budget'},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: links.map((link) {
          return GestureDetector(
            onTap: () => context.push(link['route'] as String),
            child: Column(
              children: [
                _GlassOrb(icon: link['icon'] as IconData),
                const SizedBox(height: 6),
                Text(
                  link['title'] as String,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray700),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatus() {
    return Container(
      color: AppColors.gray50,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Weather widget
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _weatherGradientColors(_weather?.current.condition ?? '맑음'),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text('인천 앞바다', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white.withValues(alpha: 0.35), Colors.white.withValues(alpha: 0.1)],
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.white.withValues(alpha: 0.18), blurRadius: 24, spreadRadius: 2),
                        ],
                      ),
                      child: Icon(
                        _weatherIcon(_weather?.current.condition ?? '맑음'),
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${(_weather?.current.temperature ?? 22).round()}°C',
                  style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold, height: 1.0),
                ),
                const SizedBox(height: 2),
                Text(
                  '체감 ${(_weather?.current.apparentTemperature ?? 20).round()}°C',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '파고 ${(_weather?.current.waveHeight ?? 0.5).toStringAsFixed(1)}m · 풍속 ${(_weather?.current.windSpeed ?? 3).toStringAsFixed(0)}m/s',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Weekly forecast
          _buildWeeklyForecast(),
          const SizedBox(height: 16),

          // Ferry status
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray100),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('실시간 운항 현황', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gray900, fontSize: 18)),
                    GestureDetector(
                      onTap: () => _showAllFerryStatus(context),
                      child: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.gray400),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...(() {
                  final display = _ferryStatus.isNotEmpty
                      ? _ferryStatus.take(3).toList()
                      : [
                          FerryRouteStatus(islandName: '백령도', status: '확인중'),
                          FerryRouteStatus(islandName: '덕적도', status: '확인중'),
                          FerryRouteStatus(islandName: '영흥도', status: '확인중'),
                        ];
                  final rows = <Widget>[];
                  for (var i = 0; i < display.length; i++) {
                    rows.add(_StatusRow(island: display[i].islandName, status: display[i].status));
                    if (i != display.length - 1) {
                      rows.add(const SizedBox(height: 10));
                      rows.add(Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          height: 1.5,
                          decoration: BoxDecoration(
                            color: AppColors.gray200,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ));
                      rows.add(const SizedBox(height: 10));
                    }
                  }
                  return rows;
                })(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _weatherIcon(String condition) {
    switch (condition) {
      case '맑음': return Icons.wb_sunny_rounded;
      case '구름조금': return Icons.wb_cloudy_rounded;
      case '흐림': return Icons.cloud_rounded;
      case '비': return Icons.water_drop_rounded;
      default: return Icons.wb_sunny_rounded;
    }
  }

  Color _weatherIconColor(String condition) {
    switch (condition) {
      case '맑음': return const Color(0xFFF97316);
      case '구름조금': return AppColors.gray400;
      case '흐림': return AppColors.gray500;
      case '비': return AppColors.blue600;
      default: return const Color(0xFFF97316);
    }
  }

  List<Color> _weatherGradientColors(String condition) {
    switch (condition) {
      case '맑음': return const [Color(0xFF60A5FA), Color(0xFF3B82F6)];
      case '구름조금': return const [Color(0xFF93C5FD), Color(0xFF64748B)];
      case '흐림': return const [Color(0xFF9CA3AF), Color(0xFF4B5563)];
      case '비': return const [Color(0xFF64748B), Color(0xFF1E3A8A)];
      default: return const [Color(0xFF60A5FA), Color(0xFF3B82F6)];
    }
  }

  Widget _buildWeeklyForecast() {
    final days = _weather?.forecast.map((f) => {
      'day': f.day,
      'date': f.date,
      'condition': f.condition,
      'high': f.high,
      'low': f.low,
      'rainChance': f.rainChance,
    }).toList() ?? List.generate(5, (i) {
      final date = DateTime.now().add(Duration(days: i + 1));
      return {
        'day': ['월', '화', '수', '목', '금', '토', '일'][date.weekday - 1],
        'date': '${date.month}/${date.day}',
        'condition': '맑음',
        'high': 23,
        'low': 18,
        'rainChance': 0,
      };
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('주간 날씨', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gray900, fontSize: 18)),
          const SizedBox(height: 12),
          ...days.asMap().entries.map((e) {
            final i = e.key;
            final day = e.value;
            final isLast = i == days.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(day['day'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray900)),
                        Text(day['date'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(_weatherIcon(day['condition'] as String), size: 24, color: _weatherIconColor(day['condition'] as String)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Text('${day['low']}°', style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF60A5FA), Color(0xFFFB923C)]),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('${day['high']}°', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    child: Text('${day['rainChance']}%', textAlign: TextAlign.right, style: TextStyle(fontSize: 13, color: (day['rainChance'] as int) >= 50 ? AppColors.blue600 : AppColors.gray500, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassOrb extends StatelessWidget {
  final IconData icon;
  const _GlassOrb({required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: ClipOval(
        child: Stack(
          children: [
            // 거의 투명한 물방울 몸체 - 파란빛은 아주 살짝만
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.3),
                    AppColors.blue50.withOpacity(0.2),
                  ],
                ),
              ),
            ),
            // 물방울 가장자리 얇은 테두리
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.blue100.withOpacity(0.6), width: 1),
                ),
              ),
            ),
            // 아주 옅은 광택
            Positioned(
              top: 5, left: 6,
              child: Container(
                width: 16, height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Colors.white.withOpacity(0.4), Colors.white.withOpacity(0.0)],
                  ),
                ),
              ),
            ),
            Center(child: Icon(icon, color: AppColors.blue700, size: 22)),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String island;
  final String status;
  const _StatusRow({required this.island, required this.status});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(island, style: const TextStyle(fontSize: 14, color: AppColors.gray700)),
          Text(
            status == '정상' ? '정상 운항' : status == '결항' ? '결항' : status == '운항없음' ? '운항없음' : '확인중...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: status == '결항' ? AppColors.red700 : status == '운항없음' || status == '확인중' ? AppColors.gray400 : AppColors.green600,
            ),
          ),
        ],
      ),
    );
  }
}

