import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/trip_service.dart';
import '../../services/weather_service.dart';
import '../../services/review_service.dart';
import '../../theme/app_colors.dart';

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
  List<Map<String, dynamic>> _popularReviews = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = AuthService.currentUser;
    final meta = user?.userMetadata;
    final name = (meta != null && meta['nickname'] != null)
        ? meta['nickname'] as String
        : user?.email?.split('@')[0] ?? '';
    final results = await Future.wait([
      TripService.getUpcomingTrip(),
      WeatherService.getWeather(),
      ReviewService.getPopularReviews(),
    ]);
    if (mounted) {
      setState(() {
        _userName = name;
        _upcomingTrip = results[0] as Map<String, dynamic>?;
        _weather = results[1] as WeatherResult?;
        _popularReviews = ((results[2] as List<Map<String, dynamic>>?) ?? [])
            .map((r) {
              final images = r['images'] as List?;
              final island = r['islands'] as Map?;
              return {
                'id': r['id'],
                'author': (r['profiles'] as Map?)?['nickname'] ?? '여행자',
                'location': island?['name'] ?? '',
                'rating': r['rating'],
                'preview': r['content'] ?? '',
                'image': (images != null && images.isNotEmpty)
                    ? images[0] as String
                    : (island?['image'] as String? ?? ''),
                'likes': r['likes_count'] ?? 0,
              };
            })
            .toList();
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
            SliverToBoxAdapter(child: _buildQuickLinks()),
            SliverToBoxAdapter(child: _buildStatus()),
            SliverToBoxAdapter(child: _buildPopularReviews()),
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
                  style: TextStyle(fontSize: 12, color: textColor),
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
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.notifications_outlined, size: 20, color: Color(0xFF2563EB)),
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
                  const SizedBox(height: 20),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
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
                  Text('오늘의 여행', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
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
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          ),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 48),
                const SizedBox(height: 8),
                const Text('아직 계획이 없으신가요?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  '여객선 정보 기반으로 자동 일정을 생성해드려요',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
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
      {'icon': Icons.auto_awesome_rounded, 'title': '패키지', 'route': '/packages'},
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
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.blue50,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gray100),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
                  ),
                  child: Icon(link['icon'] as IconData, color: AppColors.blue600, size: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  link['title'] as String,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.gray700),
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
          // Ferry status
          Container(
            padding: const EdgeInsets.all(16),
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
                    const Text('실시간 운항 현황', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.gray900, fontSize: 15)),
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(color: AppColors.green500, shape: BoxShape.circle),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _StatusRow(island: '백령도', status: '정상'),
                const SizedBox(height: 8),
                _StatusRow(island: '덕적도', status: '정상'),
                const SizedBox(height: 8),
                _StatusRow(island: '영흥도', status: '정상'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Weather widget
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _weatherIcon(_weather?.current.condition ?? '맑음'),
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('오늘의 날씨', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('인천 앞바다', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(
                          _weather?.current.condition ?? '맑음',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '파고: ${(_weather?.current.waveHeight ?? 0.5).toStringAsFixed(1)}m • 풍속: ${(_weather?.current.windSpeed ?? 3).toStringAsFixed(0)}m/s',
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${(_weather?.current.temperature ?? 22).round()}°C',
                          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '체감 ${(_weather?.current.apparentTemperature ?? 20).round()}°C',
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Weekly forecast
          _buildWeeklyForecast(),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('주간 날씨', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.gray900, fontSize: 15)),
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
                        Text(day['date'] as String, style: const TextStyle(fontSize: 10, color: AppColors.gray500)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(_weatherIcon(day['condition'] as String), size: 24, color: _weatherIconColor(day['condition'] as String)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Text('${day['high']}°', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray900)),
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
                        Text('${day['low']}°', style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    child: Text('${day['rainChance']}%', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: (day['rainChance'] as int) >= 50 ? AppColors.blue600 : AppColors.gray500, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPopularReviews() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('인기 리뷰', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                GestureDetector(
                  onTap: () => context.push('/community'),
                  child: const Row(
                    children: [
                      Text('전체보기', style: TextStyle(fontSize: 13, color: AppColors.blue600, fontWeight: FontWeight.w500)),
                      Icon(Icons.chevron_right, size: 16, color: AppColors.blue600),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_popularReviews.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text('아직 리뷰가 없어요.', style: TextStyle(fontSize: 14, color: AppColors.gray400)),
            )
          else
            SizedBox(
              height: 240,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _popularReviews.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) => _ReviewCard(
                  review: _popularReviews[i],
                  onTap: () => context.push('/community'),
                ),
              ),
            ),
        ],
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(island, style: const TextStyle(fontSize: 14, color: AppColors.gray700)),
        Text('$status 운항', style: const TextStyle(fontSize: 14, color: AppColors.green600, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final VoidCallback onTap;
  const _ReviewCard({required this.review, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 240,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray100),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Stack(
                children: [
                  SizedBox(
                    height: 128,
                    width: double.infinity,
                    child: CachedNetworkImage(
                      imageUrl: review['image'] as String,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(color: AppColors.gray100),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x99000000)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12, left: 12, right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(5, (i) => Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: i < (review['rating'] as int) ? const Color(0xFFFBBF24) : Colors.white38,
                          )),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 12, color: Colors.white70),
                            const SizedBox(width: 2),
                            Text(review['location'] as String, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(review['author'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray900)),
                        Row(
                          children: [
                            const Icon(Icons.favorite_rounded, size: 12, color: AppColors.gray500),
                            const SizedBox(width: 4),
                            Text('${review['likes']}', style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      review['preview'] as String,
                      style: const TextStyle(fontSize: 12, color: AppColors.gray600, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
