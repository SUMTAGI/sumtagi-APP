import 'package:flutter/material.dart';
import '../../services/island_service.dart';
import '../../services/weather_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/illust_icons.dart';

/// 홈 날씨 헤더의 '›'에서 진입하는 날씨 상세 페이지.
/// 페이지명 아래 장소 헤드라인을 가운데 띄우고, 좌우 화살표 또는 스와이프로
/// 인천 앞바다 ↔ 여행 일정의 섬들 사이를 넘겨 본다.
class WeatherDetailScreen extends StatefulWidget {
  final List<String> places;
  final int initialIndex;
  final WeatherResult? initial; // 진입 시 보고 있던 장소의 날씨 (첫 화면 즉시 표시용)
  static const defaultPlace = '인천 앞바다';

  const WeatherDetailScreen({
    super.key,
    this.places = const [defaultPlace],
    this.initialIndex = 0,
    this.initial,
  });

  @override
  State<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

class _WeatherDetailScreenState extends State<WeatherDetailScreen> {
  late final PageController _pageCtrl;
  late int _index;
  final Map<String, WeatherResult?> _cache = {};
  final Set<String> _loading = {};
  List<IslandModel> _islands = [];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.places.length - 1);
    _pageCtrl = PageController(initialPage: _index);
    if (widget.initial != null) _cache[widget.places[_index]] = widget.initial;
    _ensureLoaded(widget.places[_index]);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _ensureLoaded(String place) async {
    if (_cache.containsKey(place) || _loading.contains(place)) return;
    setState(() => _loading.add(place));
    WeatherResult? result;
    if (place == WeatherDetailScreen.defaultPlace) {
      result = await WeatherService.getWeather().catchError((_) => null);
    } else {
      if (_islands.isEmpty) {
        _islands = await IslandService.getIslands().catchError(
          (_) => <IslandModel>[],
        );
      }
      final island = _islands.where((i) => i.name == place).firstOrNull;
      if (island != null) {
        result = await WeatherService.getWeatherForIsland(
          island.id,
          lat: island.lat,
          lng: island.lng,
        ).catchError((_) => null);
      }
    }
    if (!mounted) return;
    setState(() {
      _cache[place] = result;
      _loading.remove(place);
    });
  }

  void _goTo(int i) {
    if (i < 0 || i >= widget.places.length) return;
    _pageCtrl.animateToPage(
      i,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final places = widget.places;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          '날씨',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 장소 탭 — 뒤로가기(좌상단 화살표)와 형태를 완전히 다르게 하기 위해
          // 화살표 대신 알약 모양 탭으로. 탭하거나 좌우로 스와이프해 장소를 바꿈
          if (places.length > 1)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < places.length; i++)
                    _PlaceTab(
                      label: places[i],
                      selected: i == _index,
                      onTap: () => _goTo(i),
                    ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Text(
                places[_index],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray900,
                ),
              ),
            ),
          if (places.length > 1)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 12),
              child: const Text(
                '좌우로 밀어 다른 장소를 볼 수 있어요',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.gray400),
              ),
            ),
          Expanded(
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: places.length,
              onPageChanged: (i) {
                setState(() => _index = i);
                _ensureLoaded(places[i]);
              },
              itemBuilder: (_, i) => _PlaceWeatherPage(
                weather: _cache[places[i]],
                loading:
                    _loading.contains(places[i]) ||
                    !_cache.containsKey(places[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 장소 전환용 알약 탭. 뒤로가기 버튼(좌상단 화살표 아이콘)과는 형태·위치·동작이
// 뚜렷이 달라 '뒤로가기'와 '장소 바꾸기'가 서로 다른 조작이라는 게 한눈에 보이게 함
class _PlaceTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PlaceTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue600 : AppColors.gray100,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.gray700,
          ),
        ),
      ),
    );
  }
}

// 한 장소의 날씨 본문: 오늘 날씨 상세 + 주간 예보
class _PlaceWeatherPage extends StatelessWidget {
  final WeatherResult? weather;
  final bool loading;
  const _PlaceWeatherPage({required this.weather, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading && weather == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final w = weather;
    if (w == null) {
      return const Center(
        child: Text(
          '날씨를 불러오지 못했어요',
          style: TextStyle(fontSize: 14, color: AppColors.gray500),
        ),
      );
    }
    final days = w.forecast;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const _SectionTitle('오늘의 날씨'),
        const SizedBox(height: 10),
        _TodayDetail(today: w.current, hourly: w.hourly),
        const SizedBox(height: 24),
        const _SectionTitle('주간 날씨'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: days.isEmpty
              ? const Text(
                  '예보 준비 중',
                  style: TextStyle(fontSize: 14, color: AppColors.gray500),
                )
              : Column(
                  children: [
                    for (var i = 0; i < days.length; i++) ...[
                      _DayRow(day: days[i]),
                      if (i < days.length - 1) const SizedBox(height: 14),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.gray500,
      ),
    ),
  );
}

// 오늘 날씨 상세: 큰 아이콘 + 온도, 체감/풍속/파고 3칸, 그 아래 시간별 예보(가로 스크롤)
class _TodayDetail extends StatelessWidget {
  final WeatherCurrent today;
  final List<WeatherHour> hourly;
  const _TodayDetail({required this.today, this.hourly = const []});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              WeatherIllust(condition: today.condition, size: 72),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${today.temperature.round()}°',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray900,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    today.condition,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _Metric(
                label: '체감',
                value: '${today.apparentTemperature.round()}°',
              ),
              _Metric(
                label: '풍속',
                value: '${today.windSpeed.toStringAsFixed(0)}km/h',
              ),
              _Metric(
                label: '파고',
                value: '${today.waveHeight.toStringAsFixed(1)}m',
              ),
            ],
          ),
          if (hourly.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Divider(height: 1, color: AppColors.gray100),
            const SizedBox(height: 14),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: hourly.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) =>
                    _HourItem(hour: hourly[i], isNow: i == 0),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HourItem extends StatelessWidget {
  final WeatherHour hour;
  final bool isNow;
  const _HourItem({required this.hour, required this.isNow});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isNow ? AppColors.blue50 : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isNow ? '지금' : hour.time,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isNow ? FontWeight.w700 : FontWeight.w500,
              color: isNow ? AppColors.blue700 : AppColors.gray600,
            ),
          ),
          WeatherIllust(condition: hour.condition, size: 28),
          Text(
            '${hour.temperature.round()}°',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          Text(
            '${hour.rainChance}%',
            style: TextStyle(
              fontSize: 12,
              color: hour.rainChance >= 50
                  ? AppColors.blue600
                  : AppColors.gray400,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: AppColors.gray50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.gray500),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final WeatherForecastDay day;
  const _DayRow({required this.day});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                day.day,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                ),
              ),
              Text(
                day.date,
                style: const TextStyle(fontSize: 13, color: AppColors.gray500),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        WeatherIllust(condition: day.condition, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Text(
                '${day.low}°',
                style: const TextStyle(fontSize: 14, color: AppColors.gray600),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF60A5FA), Color(0xFFFB923C)],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${day.high}°',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 40,
          child: Text(
            '${day.rainChance}%',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: day.rainChance >= 50
                  ? AppColors.blue600
                  : AppColors.gray500,
            ),
          ),
        ),
      ],
    );
  }
}
