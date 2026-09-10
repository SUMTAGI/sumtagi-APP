import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../services/trip_service.dart';
import '../../services/weather_service.dart';
import '../../services/ferry_service.dart';
import '../../services/island_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/ocean_scene.dart';
import '../../widgets/ai_island_search_bar.dart';
import '../../widgets/illust_icons.dart';
import '../../widgets/tap_feedback.dart';
import '../sub/ai_chat_screen.dart';
import '../sub/weather_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _defaultWeatherPlace = '인천 앞바다';

  Map<String, dynamic>? _upcomingTrip;
  WeatherResult? _weather; // 인천 앞바다 기본 날씨
  WeatherResult? _placeWeather; // 드롭다운으로 고른 섬의 날씨
  String _weatherPlace = _defaultWeatherPlace;
  List<IslandModel> _islandCatalog = [];
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(notification['message'] as String? ?? '새 알림이 있어요'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      TripService.getUpcomingTrip().catchError((_) => null),
      WeatherService.getWeather().catchError((_) => null),
    ]);
    if (mounted) {
      setState(() {
        _upcomingTrip = results[0] as Map<String, dynamic>?;
        _weather = results[1] as WeatherResult?;
      });
      FerryService.getHomeFerryStatus()
          .then((status) {
            if (mounted) setState(() => _ferryStatus = status);
          })
          .catchError((e, st) {
            print('[Home Ferry Error] $e\n$st');
          });
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
            SliverToBoxAdapter(child: _buildTomorrowFerryRiskBanner()),
            SliverToBoxAdapter(child: _buildQuickLinks()),
            SliverToBoxAdapter(child: _buildStatus()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      // 고객센터 안에 묻혀 있어 진입성이 낮다는 피드백으로 홈에도 노출
      // 하단 플로팅 네비게이션 바(MainNavigation)에 가리지 않도록 여백을 띄움
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton(
          heroTag: 'ai_chat_fab',
          backgroundColor: AppColors.blue600,
          shape: const CircleBorder(),
          // 루트 네비게이터로 띄워야 탭 셸(하단 네비바) 위를 덮는 전체 화면이 됨
          onPressed: () => Navigator.of(
            context,
            rootNavigator: true,
          ).push(MaterialPageRoute(builder: (_) => const AiChatScreen())),
          child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
        ),
      ),
    );
  }

  void _showAllFerryStatus(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                  const Text(
                    '전체 운항 현황',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray900,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: AppColors.gray400,
                  ),
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
                  final bgColor = isCancelled
                      ? AppColors.red50
                      : isNone
                      ? AppColors.gray100
                      : const Color(0xFFF0FDF4);
                  final textColor = isCancelled
                      ? AppColors.red700
                      : isNone
                      ? AppColors.gray400
                      : const Color(0xFF15803D);
                  final label = s.status == '정상' ? '정상 운항' : s.status;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          s.islandName,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.gray700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
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
    final bgColor = isDanger
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFFFFBEB);
    final iconColor = isDanger
        ? const Color(0xFFDC2626)
        : const Color(0xFFD97706);
    final textColor = isDanger
        ? const Color(0xFF991B1B)
        : const Color(0xFF92400E);
    final icon = isDanger ? Icons.warning_rounded : Icons.info_outline_rounded;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  risk.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${risk.description} (풍속 ${_weather!.current.windSpeed.toStringAsFixed(1)} km/h · 파고 ${_weather!.current.waveHeight.toStringAsFixed(1)} m)',
                  style: TextStyle(fontSize: 14, color: textColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 오늘 기준 배너(_buildFerryRiskBanner)와 별개로, 내일 예보 기반 예측 배너.
  // WEB(FerryRiskBanner.tsx)과 문구를 동일하게 유지할 것 — "예측, 확정 아님" 명시.
  Widget _buildTomorrowFerryRiskBanner() {
    if (_weather == null || _weather!.forecast.isEmpty)
      return const SizedBox.shrink();
    final tomorrow = _weather!.forecast[0];
    if (tomorrow.windSpeed == null || tomorrow.waveHeight == null)
      return const SizedBox.shrink();

    final risk = WeatherService.assessFerryRisk(
      tomorrow.windSpeed!,
      tomorrow.waveHeight!,
    );
    if (risk == FerryRisk.safe) return const SizedBox.shrink();

    final isDanger = risk == FerryRisk.danger;
    final bgColor = isDanger
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFFFFBEB);
    final iconColor = isDanger
        ? const Color(0xFFDC2626)
        : const Color(0xFFD97706);
    final textColor = isDanger
        ? const Color(0xFF991B1B)
        : const Color(0xFF92400E);

    final message = isDanger
        ? '내일 결항 가능성 있음 (예측, 확정 아님)'
        : '내일 기상 악화 가능 (예측, 확정 아님)';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroContent() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: _buildHeroContainer(),
    );
  }

  Widget _buildHeroContainer() {
    return Container(
      decoration: BoxDecoration(gradient: AppGradients.blueFade),
      child: Stack(
        children: [
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
    final days = (itin['days'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final activities = days.isNotEmpty
        ? ((days[0]['activities'] as List?)?.cast<Map<String, dynamic>>() ?? [])
        : <Map<String, dynamic>>[];
    final departurePort =
        (itin['departure_port'] ?? itin['departurePort']) as String? ?? '인천항';
    final islands = (itin['islands'] as List?)?.cast<String>() ?? [];
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.directions_boat_rounded,
                    color: AppColors.gray900,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '오늘의 여행',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray900,
                      fontSize: 18,
                    ),
                  ),
                  if (dday >= 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blue100,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        dday == 0 ? 'D-Day' : 'D-$dday',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gray900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  TapFeedback(
                    onTap: () => context.push('/itinerary/${itin['id']}'),
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      child: Text(
                        '전체보기',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.gray900,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            itin['title'] as String? ?? '',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getDDayMessage(dday),
            style: const TextStyle(fontSize: 14, color: AppColors.gray700),
          ),
          if (activities.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...activities
                .take(3)
                .map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a['time'] as String? ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.gray600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            a['title'] as String? ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.gray900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          if (islands.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.directions_boat_rounded,
                    color: AppColors.gray700,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    departurePort,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.gray900,
                    ),
                  ),
                  const Text(' → ', style: TextStyle(color: AppColors.gray700)),
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.gray700,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      islands.join(', '),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.gray900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.gray900,
                  size: 48,
                ),
                const SizedBox(height: 8),
                const Text(
                  '아직 계획이 없으신가요?',
                  style: TextStyle(
                    color: AppColors.gray900,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '여객선 정보 기반으로 자동 일정을 생성해드려요',
                  style: TextStyle(color: AppColors.gray700, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TapFeedback(
          onTap: () => context.push('/create-trip'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.gray900,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  '여행 계획 시작하기',
                  style: TextStyle(
                    color: AppColors.gray900,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLinks() {
    final links = [
      {
        'illust': const ChecklistIllust(size: 48),
        'title': '체크리스트',
        'route': '/checklist',
      },
      {
        'illust': const BudgetIllust(size: 48),
        'title': '경비관리',
        'route': '/budget',
      },
      {
        'illust': const FavoriteIllust(size: 48),
        'title': '즐겨찾기',
        'route': '/favorites',
      },
      {
        'illust': const ReviewIllust(size: 48),
        'title': '리뷰',
        'route': '/community',
      },
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: links.map((link) {
          return TapFeedback(
            onTap: () => context.push(link['route'] as String),
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                link['illust'] as Widget,
                const SizedBox(height: 6),
                Text(
                  link['title'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // 선택한 장소의 날씨. 기본은 인천 앞바다, 여행 일정의 섬을 고르면 그 섬 좌표 기준으로 조회
  WeatherResult? get _effectiveWeather => _placeWeather ?? _weather;

  // 장소 선택지: 인천 앞바다 + 다가오는 여행 일정에 포함된 섬들
  List<String> get _weatherPlaces {
    final places = <String>[
      _defaultWeatherPlace,
      ...((_upcomingTrip?['islands'] as List?)?.cast<String>() ?? const []),
    ];
    // TODO(테스트용): 예정된 여행이 없어도 탭 UI를 미리 볼 수 있도록 임시로 섬을 채워 넣음.
    // 실제 여행 일정 연동만 쓰려면 이 블록을 지우면 됨.
    if (places.length < 3) {
      for (final demo in ['백령도', '대청도']) {
        if (places.length >= 3) break;
        if (!places.contains(demo)) places.add(demo);
      }
    }
    return places;
  }

  Future<void> _selectWeatherPlace(String name) async {
    if (name == _weatherPlace) return;
    setState(() {
      _weatherPlace = name;
      _placeWeather = null;
    });
    if (name == _defaultWeatherPlace) return;
    if (_islandCatalog.isEmpty) {
      _islandCatalog = await IslandService.getIslands().catchError(
        (_) => <IslandModel>[],
      );
    }
    final island = _islandCatalog.where((i) => i.name == name).firstOrNull;
    if (island == null) return;
    final result = await WeatherService.getWeatherForIsland(
      island.id,
      lat: island.lat,
      lng: island.lng,
    ).catchError((_) => null);
    // 조회 도중 다른 장소로 바꿨으면 결과를 버림
    if (mounted && _weatherPlace == name)
      setState(() => _placeWeather = result);
  }

  // 카드 바깥 헤더: 장소 드롭다운(왼쪽) + 주간 날씨 이동 아이콘(오른쪽)
  Widget _buildWeatherHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        PopupMenuButton<String>(
          onSelected: _selectWeatherPlace,
          position: PopupMenuPosition.under,
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (_) => [
            for (final place in _weatherPlaces)
              PopupMenuItem(
                value: place,
                child: Text(
                  place,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: place == _weatherPlace
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: place == _weatherPlace
                        ? AppColors.blue600
                        : AppColors.gray900,
                  ),
                ),
              ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _weatherPlace,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 22,
                  color: AppColors.gray700,
                ),
              ],
            ),
          ),
        ),
        TapFeedback(
          onTap: () => Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) => WeatherDetailScreen(
                places: _weatherPlaces,
                initialIndex: _weatherPlaces
                    .indexOf(_weatherPlace)
                    .clamp(0, _weatherPlaces.length - 1),
                initial: _effectiveWeather,
              ),
            ),
          ),
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 24,
              color: AppColors.gray500,
            ),
          ),
        ),
      ],
    );
  }

  // 오늘/내일 날씨를 한 카드 안에 2칼럼으로. 배경 장식 없이 아이콘 + 숫자만.
  Widget _buildWeatherCard() {
    final weather = _effectiveWeather;
    final today = weather?.current;
    final tomorrow = (weather?.forecast.isNotEmpty ?? false)
        ? weather!.forecast.first
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _WeatherColumn(
                    title: '오늘의 날씨',
                    condition: today?.condition ?? '맑음',
                    temperature: '${(today?.temperature ?? 22).round()}°',
                    detail:
                        '체감 ${(today?.apparentTemperature ?? 20).round()}° · 파고 ${(today?.waveHeight ?? 0.5).toStringAsFixed(1)}m',
                  ),
                ),
                const VerticalDivider(
                  width: 32,
                  thickness: 1,
                  color: AppColors.gray100,
                ),
                Expanded(
                  child: _WeatherColumn(
                    title: '내일의 날씨',
                    condition: tomorrow?.condition ?? '맑음',
                    temperature:
                        '${tomorrow?.high ?? 23}° / ${tomorrow?.low ?? 18}°',
                    detail: tomorrow == null
                        ? '예보 준비 중'
                        : '강수 ${tomorrow.rainChance}%${tomorrow.waveHeight != null ? ' · 파고 ${tomorrow.waveHeight!.toStringAsFixed(1)}m' : ''}',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatus() {
    return Container(
      color: AppColors.gray50,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Weather — 장소 드롭다운/주간 이동 아이콘은 카드 밖, 카드 안은 오늘·내일 2칼럼
          _buildWeatherHeader(),
          const SizedBox(height: 8),
          _buildWeatherCard(),
          const SizedBox(height: 16),

          // Ferry status
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '운항 현황',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                        fontSize: 18,
                      ),
                    ),
                    TapFeedback(
                      onTap: () => _showAllFerryStatus(context),
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppColors.gray400,
                        ),
                      ),
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
                    rows.add(
                      _StatusRow(
                        island: display[i].islandName,
                        status: display[i].status,
                      ),
                    );
                    if (i != display.length - 1) {
                      rows.add(const SizedBox(height: 10));
                      rows.add(
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Container(
                            height: 1.5,
                            decoration: BoxDecoration(
                              color: AppColors.gray200,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      );
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
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _WeatherColumn extends StatelessWidget {
  final String title;
  final String condition;
  final String temperature;
  final String detail;
  const _WeatherColumn({
    required this.title,
    required this.condition,
    required this.temperature,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.gray600,
          ),
        ),
        const SizedBox(height: 12),
        WeatherIllust(condition: condition, size: 56),
        const SizedBox(height: 10),
        Text(
          temperature,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.gray900,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          detail,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.gray600,
            height: 1.0,
          ),
        ),
      ],
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
          Text(
            island,
            style: const TextStyle(fontSize: 14, color: AppColors.gray700),
          ),
          Text(
            status == '정상'
                ? '정상 운항'
                : status == '결항'
                ? '결항'
                : status == '운항없음'
                ? '운항없음'
                : '확인중...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: status == '결항'
                  ? AppColors.red700
                  : status == '운항없음' || status == '확인중'
                  ? AppColors.gray400
                  : AppColors.green600,
            ),
          ),
        ],
      ),
    );
  }
}
