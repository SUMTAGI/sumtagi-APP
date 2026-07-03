import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../services/island_service.dart';
import '../../services/favorite_service.dart';
import '../../services/ferry_service.dart';
import '../../services/congestion_service.dart';


class IslandDetailScreen extends StatefulWidget {
  final String id;
  const IslandDetailScreen({super.key, required this.id});

  @override
  State<IslandDetailScreen> createState() => _IslandDetailScreenState();
}

class _IslandDetailScreenState extends State<IslandDetailScreen> {
  IslandDetailModel? _island;
  bool _isLoading = true;
  bool _isFavorited = false;
  bool _favLoading = false;
  String _activeTab = 'attractions';
  List<FerrySchedule> _ferrySchedule = [];
  bool _ferryLoading = true;
  IslandCongestionData? _congestion;
  bool _congestionLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        IslandService.getIslandById(widget.id),
        FavoriteService.isFavorited(widget.id),
      ]);
      if (mounted) {
        final islandData = results[0] as IslandDetailModel?;
        setState(() {
          _island = islandData;
          _isFavorited = results[1] as bool;
          _isLoading = false;
        });
        if (islandData != null) {
          FerryService.getScheduleForIsland(widget.id)
              .then((schedule) {
                if (mounted) setState(() { _ferrySchedule = schedule; _ferryLoading = false; });
              })
              .catchError((_) {
                if (mounted) setState(() => _ferryLoading = false);
              });
          CongestionService.getIslandCongestion(widget.id)
              .then((data) {
                if (mounted) setState(() { _congestion = data; _congestionLoading = false; });
              })
              .catchError((_, __) {
                if (mounted) setState(() => _congestionLoading = false);
              });
        } else {
          setState(() { _ferryLoading = false; _congestionLoading = false; });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_favLoading) return;
    setState(() => _favLoading = true);
    try {
      final result = await FavoriteService.toggle(widget.id);
      if (mounted) setState(() => _isFavorited = result);
    } finally {
      if (mounted) setState(() => _favLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final island = _island;
    if (island == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('섬 정보')),
        body: const Center(child: Text('섬을 찾을 수 없어요')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.blue600,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: _favLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(_isFavorited ? Icons.favorite : Icons.favorite_border, color: Colors.white),
                onPressed: _toggleFavorite,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: island.image,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(color: AppColors.blue200),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x33000000), Color(0xCC000000)],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20, left: 20, right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(island.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 6),
                        Text(island.description, style: const TextStyle(fontSize: 14, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info row
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      _InfoCard(icon: Icons.directions_boat_rounded, label: '소요시간', value: island.ferryTime),
                      const SizedBox(width: 12),
                      _InfoCard(
                        icon: Icons.attach_money_rounded,
                        label: '여객선 요금',
                        value: island.formattedFerryPrice,
                      ),
                      const SizedBox(width: 12),
                      _InfoCard(icon: Icons.wb_sunny_rounded, label: '최적 시기', value: island.bestSeason),
                    ],
                  ),
                ),

                // Ports
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('출발 항구', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: island.ports.map((port) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: port == '인천항' ? AppColors.red50 : AppColors.orange50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: port == '인천항' ? AppColors.red100 : const Color(0xFFFFEDD5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.anchor_rounded, size: 14, color: port == '인천항' ? AppColors.red700 : AppColors.orange600),
                              const SizedBox(width: 4),
                              Text(port, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: port == '인천항' ? AppColors.red700 : AppColors.orange600)),
                            ],
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),

                // Congestion forecast
                _buildCongestionForecast(_congestion),

                // Ferry schedule
                _buildFerrySchedule(),

                // Tabs
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.gray200))),
                  child: Row(
                    children: [
                      _TabBtn(label: '관광지', tabKey: 'attractions', activeTab: _activeTab, onTap: (t) => setState(() => _activeTab = t)),
                      const SizedBox(width: 8),
                      _TabBtn(label: '맛집', tabKey: 'restaurants', activeTab: _activeTab, onTap: (t) => setState(() => _activeTab = t)),
                      const SizedBox(width: 8),
                      _TabBtn(label: '숙박', tabKey: 'accommodations', activeTab: _activeTab, onTap: (t) => setState(() => _activeTab = t)),
                      const SizedBox(width: 8),
                      _TabBtn(label: '포토스팟', tabKey: 'photo_spots', activeTab: _activeTab, onTap: (t) => setState(() => _activeTab = t)),
                    ],
                  ),
                ),

                // Tab content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildTabContent(island),
                ),

                // CTA
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/create-trip?name=${island.name}'),
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: Text('${island.name} 여행 계획하기'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCongestionForecast(IslandCongestionData? data) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
        ),
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.people_rounded, size: 14, color: AppColors.blue600),
            ),
            const SizedBox(width: 10),
            const Text('향후 7일 혼잡도 예측',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.gray900)),
          ]),
          const SizedBox(height: 16),
          if (_congestionLoading)
            const SizedBox(
              height: 96,
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue200))),
            )
          else if (data == null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const Row(children: [
                Icon(Icons.info_outline_rounded, size: 14, color: AppColors.gray400),
                SizedBox(width: 6),
                Text('이 섬은 혼잡도 예측 데이터가 없어요',
                    style: TextStyle(fontSize: 13, color: AppColors.gray400)),
              ]),
            )
          else ...[
            _CongestionLineChart(forecasts: data.forecast),
            const SizedBox(height: 12),
            Row(children: [
              _CongestionPill(color: const Color(0xFF34D399), label: '여유'),
              const SizedBox(width: 8),
              _CongestionPill(color: const Color(0xFFF59E0B), label: '보통'),
              const SizedBox(width: 8),
              _CongestionPill(color: const Color(0xFFF87171), label: '혼잡'),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildFerrySchedule() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 9));
    final dateLabel = '${now.month}월 ${now.day}일';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.gray200))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(children: [
                Icon(Icons.directions_boat_rounded, size: 16, color: AppColors.blue600),
                SizedBox(width: 6),
                Text('오늘 출발 여객선', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.gray900)),
              ]),
              Text(dateLabel, style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
            ],
          ),
          const SizedBox(height: 12),
          if (_ferryLoading)
            Row(children: List.generate(3, (_) => Container(
              width: 96, height: 64, margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(12)),
            )))
          else if (_ferrySchedule.isEmpty)
            const Text('오늘 운항 정보가 없어요', style: TextStyle(fontSize: 13, color: AppColors.gray400))
          else
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _ferrySchedule.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final f = _ferrySchedule[i];
                  final bg = f.isCancelled ? AppColors.red50 : f.isDone ? AppColors.gray100 : f.isActive ? const Color(0xFFF0FDF4) : AppColors.blue50;
                  final borderColor = f.isCancelled ? AppColors.red100 : f.isDone ? AppColors.gray200 : f.isActive ? const Color(0xFFBBF7D0) : AppColors.blue100;
                  final labelColor = f.isCancelled ? AppColors.red700 : f.isDone ? AppColors.gray400 : f.isActive ? const Color(0xFF16A34A) : AppColors.blue600;
                  final timeColor = f.isCancelled ? AppColors.red500 : f.isDone ? AppColors.gray400 : AppColors.gray900;
                  return Container(
                    width: 96,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.status,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: labelColor)),
                        const SizedBox(height: 2),
                        Text(f.departureTime,
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: timeColor,
                                decoration: f.isCancelled ? TextDecoration.lineThrough : null)),
                        const SizedBox(height: 2),
                        Text(f.ferryName, style: const TextStyle(fontSize: 10, color: AppColors.gray500),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabContent(IslandDetailModel island) {
    switch (_activeTab) {
      case 'attractions':
        if (island.attractions.isEmpty) return const _EmptyState(message: '등록된 관광지가 없어요');
        return Column(
          children: island.attractions.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlaceCard(name: a.name, subtitle: a.category, description: a.description, image: a.image, rating: a.rating, extra: a.duration),
          )).toList(),
        );
      case 'restaurants':
        if (island.restaurants.isEmpty) return const _EmptyState(message: '등록된 맛집이 없어요');
        return Column(
          children: island.restaurants.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlaceCard(name: r.name, subtitle: '${r.cuisine} · ${r.priceLevel}', description: r.specialty, image: r.image, rating: r.rating),
          )).toList(),
        );
      case 'accommodations':
        if (island.accommodations.isEmpty) return const _EmptyState(message: '등록된 숙박시설이 없어요');
        return Column(
          children: island.accommodations.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlaceCard(
              name: a.name, subtitle: a.type, image: a.image, rating: a.rating,
              extra: '${(a.pricePerNight / 10000).floor()}만원/박',
            ),
          )).toList(),
        );
      case 'photo_spots':
        if (island.photoSpots.isEmpty) return const _EmptyState(message: '등록된 포토스팟이 없어요');
        return GridView.count(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
          childAspectRatio: 0.85, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          children: island.photoSpots.map((s) => ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(imageUrl: s.image, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: AppColors.gray200)),
                Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xCC000000)]))),
                Positioned(bottom: 10, left: 10, right: 10, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(s.bestTime, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                )),
              ],
            ),
          )).toList(),
        );
      default:
        return const SizedBox();
    }
  }
}

class _TabBtn extends StatelessWidget {
  final String label, tabKey, activeTab;
  final void Function(String) onTap;
  const _TabBtn({required this.label, required this.tabKey, required this.activeTab, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = tabKey == activeTab;
    return GestureDetector(
      onTap: () => onTap(tabKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.blue600 : AppColors.gray100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? Colors.white : AppColors.gray700)),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final String name, subtitle, image;
  final String? description, extra;
  final double rating;
  const _PlaceCard({required this.name, required this.subtitle, required this.image, required this.rating, this.description, this.extra});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.gray50, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 80, height: 80,
              child: CachedNetworkImage(imageUrl: image, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: AppColors.gray200)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.gray900))),
                    Row(children: [
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 2),
                      Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray700)),
                    ]),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.blue600, fontWeight: FontWeight.w500)),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(description!, style: const TextStyle(fontSize: 12, color: AppColors.gray600), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                if (extra != null) ...[
                  const SizedBox(height: 4),
                  Text(extra!, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, style: const TextStyle(color: AppColors.gray500)),
    ));
  }
}

class _CongestionLineChart extends StatelessWidget {
  final List<CongestionForecast> forecasts;
  const _CongestionLineChart({required this.forecasts});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: CustomPaint(
        painter: _ChartPainter(forecasts: forecasts),
        size: Size.infinite,
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<CongestionForecast> forecasts;
  _ChartPainter({required this.forecasts});

  static Color _dotColor(String level) => switch (level) {
    'high'   => const Color(0xFFF87171),
    'medium' => const Color(0xFFF59E0B),
    _        => const Color(0xFF34D399),
  };

  @override
  void paint(Canvas canvas, Size size) {
    if (forecasts.isEmpty) return;

    const pt = 12.0;
    const pb = 28.0;
    const pl = 8.0;
    const pr = 8.0;

    final n = forecasts.length;
    final chartW = size.width - pl - pr;
    final chartH = size.height - pt - pb;

    final pts = List.generate(n, (i) {
      final x = pl + (n == 1 ? chartW / 2 : (i / (n - 1)) * chartW);
      final y = pt + (1.0 - forecasts[i].rate) * chartH;
      return Offset(x, y);
    });

    // Smooth bezier path via midpoint technique
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < n - 1; i++) {
      final mid = Offset((pts[i].dx + pts[i + 1].dx) / 2, (pts[i].dy + pts[i + 1].dy) / 2);
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);

    // Gradient fill
    final fillPath = Path.from(path)
      ..lineTo(pts.last.dx, pt + chartH)
      ..lineTo(pts.first.dx, pt + chartH)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0x3D3B82F6), Color(0x053B82F6)],
        ).createShader(Rect.fromLTWH(0, pt, size.width, chartH)),
    );

    // Line stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF3B82F6)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dots + x-axis labels
    for (int i = 0; i < n; i++) {
      final p = pts[i];
      final color = _dotColor(forecasts[i].level);

      canvas.drawCircle(p, 7, Paint()..color = Colors.white);
      canvas.drawCircle(p, 5.5, Paint()..color = color);
      canvas.drawCircle(p, 5.5, Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);

      final tp = TextPainter(
        text: TextSpan(
          text: forecasts[i].dayLabel,
          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(p.dx - tp.width / 2, pt + chartH + 6));
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.forecasts != forecasts;
}

class _CongestionPill extends StatelessWidget {
  final Color color;
  final String label;
  const _CongestionPill({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray500, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.blue50, borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Icon(icon, color: AppColors.blue600, size: 20),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.gray500)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.gray900), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
