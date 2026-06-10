import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';

class _IslandPoint {
  final String id, name, ferryTime, description;
  final double x, y;
  final Color color;
  const _IslandPoint({required this.id, required this.name, required this.x, required this.y, required this.color, required this.ferryTime, required this.description});
}

const _islands = [
  _IslandPoint(id: 'incheon', name: '인천항', x: 0.20, y: 0.50, color: Color(0xFFEF4444), ferryTime: '-', description: '인천 연안여객터미널'),
  _IslandPoint(id: 'daebu', name: '대부도항', x: 0.30, y: 0.65, color: Color(0xFFF97316), ferryTime: '-', description: '방아머리여객터미널'),
  _IslandPoint(id: 'baengnyeong', name: '백령도', x: 0.25, y: 0.15, color: Color(0xFF3B82F6), ferryTime: '4시간', description: '서해 최북단 섬'),
  _IslandPoint(id: 'daecheong', name: '대청도', x: 0.30, y: 0.25, color: Color(0xFF3B82F6), ferryTime: '4시간', description: '모래사막의 섬'),
  _IslandPoint(id: 'socheong', name: '소청도', x: 0.28, y: 0.20, color: Color(0xFF3B82F6), ferryTime: '4시간', description: '작은 섬'),
  _IslandPoint(id: 'yeonpyeong', name: '연평도', x: 0.35, y: 0.30, color: Color(0xFF3B82F6), ferryTime: '3.5시간', description: '조기의 섬'),
  _IslandPoint(id: 'deokjeok', name: '덕적도', x: 0.50, y: 0.55, color: Color(0xFF3B82F6), ferryTime: '2.5시간', description: '서포리 해변'),
  _IslandPoint(id: 'jawol', name: '자월도', x: 0.55, y: 0.65, color: Color(0xFF3B82F6), ferryTime: '2.5시간', description: '한적한 어촌'),
  _IslandPoint(id: 'seungbong', name: '승봉도', x: 0.60, y: 0.60, color: Color(0xFF3B82F6), ferryTime: '2시간', description: '작은 섬'),
  _IslandPoint(id: 'daeijak', name: '대이작도', x: 0.58, y: 0.68, color: Color(0xFF3B82F6), ferryTime: '2시간', description: '큰 이작도'),
  _IslandPoint(id: 'soijak', name: '소이작도', x: 0.62, y: 0.72, color: Color(0xFF3B82F6), ferryTime: '2시간', description: '작은 이작도'),
  _IslandPoint(id: 'pungdo', name: '풍도', x: 0.65, y: 0.75, color: Color(0xFF3B82F6), ferryTime: '2.5시간', description: '동백꽃의 섬'),
  _IslandPoint(id: 'yukdo', name: '육도', x: 0.68, y: 0.78, color: Color(0xFF3B82F6), ferryTime: '3시간', description: '작은 섬'),
];

const _routes = [
  ['incheon', 'baengnyeong'], ['incheon', 'daecheong'], ['incheon', 'socheong'],
  ['incheon', 'yeonpyeong'], ['incheon', 'deokjeok'], ['incheon', 'jawol'],
  ['incheon', 'seungbong'], ['incheon', 'daeijak'],
  ['daebu', 'jawol'], ['daebu', 'seungbong'], ['daebu', 'daeijak'],
  ['daebu', 'soijak'], ['daebu', 'deokjeok'], ['daebu', 'pungdo'], ['daebu', 'yukdo'],
  ['deokjeok', 'jawol'], ['jawol', 'daeijak'],
];

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  _IslandPoint? _selected;
  bool _showRoutes = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 54,
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
            const Text('섬 지도', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('인천 섬들의 위치와 여객선 항로', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85))),
          ],
        ),
        titleSpacing: 24,
      ),
      body: Column(
        children: [
          _buildControls(),
          Expanded(child: _buildMap()),
          if (_selected != null) _buildInfoPanel(),
          if (_selected == null) _buildIslandList(),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.gray200))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => setState(() => _showRoutes = !_showRoutes),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _showRoutes ? AppColors.blue100 : AppColors.gray100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.directions_boat_rounded, size: 16, color: _showRoutes ? AppColors.blue700 : AppColors.gray700),
                  const SizedBox(width: 6),
                  Text('항로 ${_showRoutes ? "숨기기" : "보기"}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _showRoutes ? AppColors.blue700 : AppColors.gray700)),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _selected = null),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.explore_rounded, size: 16, color: AppColors.gray700),
                  SizedBox(width: 6),
                  Text('전체보기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Container(
      color: const Color(0xFFEFF6FF),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return GestureDetector(
            onTapDown: (details) {
              final dx = details.localPosition.dx / w;
              final dy = details.localPosition.dy / h;
              _IslandPoint? nearest;
              double minDist = double.infinity;
              for (final island in _islands) {
                final dist = ((island.x - dx) * (island.x - dx) + (island.y - dy) * (island.y - dy));
                if (dist < minDist && dist < 0.005) {
                  minDist = dist;
                  nearest = island;
                }
              }
              setState(() => _selected = nearest);
            },
            child: CustomPaint(
              size: Size(w, h),
              painter: _MapPainter(
                islands: _islands,
                routes: _routes,
                selected: _selected,
                showRoutes: _showRoutes,
                width: w,
                height: h,
              ),
              child: Stack(
                children: _islands.map((island) {
                  final left = island.x * w - 40;
                  final top = island.y * h - 36;
                  return Positioned(
                    left: left,
                    top: top,
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = island),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: island.id == 'incheon'
                              ? AppColors.red500
                              : island.id == 'daebu'
                                  ? AppColors.orange500
                                  : _selected?.id == island.id
                                      ? AppColors.blue600
                                      : Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                        ),
                        child: Text(
                          island.name,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: (island.id == 'incheon' || island.id == 'daebu' || _selected?.id == island.id)
                                ? Colors.white
                                : AppColors.gray700,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoPanel() {
    final island = _selected!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.gray200))),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: island.id == 'incheon' ? AppColors.red50 : island.id == 'daebu' ? AppColors.orange50 : AppColors.blue50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_on_rounded, size: 24, color: island.id == 'incheon' ? AppColors.red700 : island.id == 'daebu' ? AppColors.orange600 : AppColors.blue600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(island.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                const SizedBox(height: 2),
                Text(island.description, style: const TextStyle(fontSize: 12, color: AppColors.gray600)),
                if (island.id != 'incheon' && island.id != 'daebu') ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.directions_boat_rounded, size: 14, color: AppColors.gray500),
                      const SizedBox(width: 4),
                      Text(island.ferryTime, style: const TextStyle(fontSize: 13, color: AppColors.gray700)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.gray400),
            onPressed: () => setState(() => _selected = null),
          ),
        ],
      ),
    );
  }

  Widget _buildIslandList() {
    final nonPorts = _islands.where((i) => i.id != 'incheon' && i.id != 'daebu').toList();
    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      decoration: const BoxDecoration(
        color: AppColors.gray50,
        border: Border(top: BorderSide(color: AppColors.gray200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('섬 목록', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray700)),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 3.5,
              ),
              itemCount: nonPorts.length,
              itemBuilder: (context, i) {
                final island = nonPorts[i];
                return GestureDetector(
                  onTap: () => setState(() => _selected = island),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.gray200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(island.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.gray900)),
                        Row(
                          children: [
                            const Icon(Icons.directions_boat_rounded, size: 10, color: AppColors.gray400),
                            const SizedBox(width: 2),
                            Text(island.ferryTime, style: const TextStyle(fontSize: 10, color: AppColors.gray600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final List<_IslandPoint> islands;
  final List<List<String>> routes;
  final _IslandPoint? selected;
  final bool showRoutes;
  final double width, height;

  const _MapPainter({
    required this.islands, required this.routes, required this.selected,
    required this.showRoutes, required this.width, required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background dots
    final dotPaint = Paint()..color = const Color(0xFF93C5FD).withOpacity(0.3);
    for (double x = 0; x < size.width; x += 20) {
      for (double y = 0; y < size.height; y += 20) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }

    // Routes
    if (showRoutes) {
      final routePaint = Paint()
        ..color = AppColors.blue500.withOpacity(0.5)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      for (final route in routes) {
        final from = islands.cast<_IslandPoint?>().firstWhere((i) => i?.id == route[0], orElse: () => null);
        final to = islands.cast<_IslandPoint?>().firstWhere((i) => i?.id == route[1], orElse: () => null);
        if (from == null || to == null) continue;

        final path = Path()
          ..moveTo(from.x * size.width, from.y * size.height)
          ..lineTo(to.x * size.width, to.y * size.height);
        canvas.drawPath(path, routePaint);
      }
    }

    // Islands
    for (final island in islands) {
      final isPort = island.id == 'incheon' || island.id == 'daebu';
      final isSelected = selected?.id == island.id;
      final radius = isPort ? 8.0 : isSelected ? 7.0 : 5.0;
      final alpha = selected != null && !isSelected ? 0.4 : 1.0;

      final circlePaint = Paint()..color = island.color.withOpacity(alpha);
      final whitePaint = Paint()..color = Colors.white;

      canvas.drawCircle(Offset(island.x * size.width, island.y * size.height), radius + 2, whitePaint);
      canvas.drawCircle(Offset(island.x * size.width, island.y * size.height), radius, circlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.selected != selected || old.showRoutes != showRoutes;
}
