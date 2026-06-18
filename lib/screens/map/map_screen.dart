import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/app_colors.dart';

class _Island {
  final String id, name, ferryTime, description;
  final LatLng position;
  final Color color;
  final bool isPort;

  const _Island({
    required this.id,
    required this.name,
    required this.ferryTime,
    required this.description,
    required this.position,
    required this.color,
    this.isPort = false,
  });
}

const _islands = [
  _Island(id: 'incheon',    name: '인천항',   ferryTime: '-',    description: '인천 연안여객터미널', position: LatLng(37.4744, 126.6169), color: Color(0xFFEF4444), isPort: true),
  _Island(id: 'daebu',      name: '대부도항', ferryTime: '-',    description: '방아머리여객터미널',  position: LatLng(37.2173, 126.5589), color: Color(0xFFF97316), isPort: true),
  _Island(id: 'baengnyeong',name: '백령도',   ferryTime: '4시간', description: '서해 최북단 섬',    position: LatLng(37.9685, 124.6902), color: Color(0xFF3B82F6)),
  _Island(id: 'daecheong',  name: '대청도',   ferryTime: '4시간', description: '모래사막의 섬',     position: LatLng(37.8371, 124.7182), color: Color(0xFF3B82F6)),
  _Island(id: 'socheong',   name: '소청도',   ferryTime: '4시간', description: '작은 섬',           position: LatLng(37.7625, 124.7431), color: Color(0xFF3B82F6)),
  _Island(id: 'yeonpyeong', name: '연평도',   ferryTime: '3.5시간', description: '조기의 섬',      position: LatLng(37.6736, 125.6814), color: Color(0xFF3B82F6)),
  _Island(id: 'deokjeok',   name: '덕적도',   ferryTime: '2.5시간', description: '서포리 해변',    position: LatLng(37.2269, 126.1432), color: Color(0xFF3B82F6)),
  _Island(id: 'jawol',      name: '자월도',   ferryTime: '2.5시간', description: '한적한 어촌',    position: LatLng(37.2589, 126.3083), color: Color(0xFF3B82F6)),
  _Island(id: 'seungbong',  name: '승봉도',   ferryTime: '2시간', description: '작은 섬',          position: LatLng(37.1669, 126.1611), color: Color(0xFF3B82F6)),
  _Island(id: 'daeijak',    name: '대이작도', ferryTime: '2시간', description: '큰 이작도',         position: LatLng(37.1667, 126.2833), color: Color(0xFF3B82F6)),
  _Island(id: 'soijak',     name: '소이작도', ferryTime: '2시간', description: '작은 이작도',       position: LatLng(37.1500, 126.2917), color: Color(0xFF3B82F6)),
  _Island(id: 'pungdo',     name: '풍도',     ferryTime: '2.5시간', description: '동백꽃의 섬',    position: LatLng(37.0647, 126.2636), color: Color(0xFF3B82F6)),
  _Island(id: 'yukdo',      name: '육도',     ferryTime: '3시간', description: '작은 섬',          position: LatLng(37.0036, 126.3547), color: Color(0xFF3B82F6)),
];

const _routes = [
  ['incheon', 'baengnyeong'], ['incheon', 'daecheong'], ['incheon', 'socheong'],
  ['incheon', 'yeonpyeong'],  ['incheon', 'deokjeok'],  ['incheon', 'jawol'],
  ['incheon', 'seungbong'],   ['incheon', 'daeijak'],
  ['daebu', 'jawol'],   ['daebu', 'seungbong'], ['daebu', 'daeijak'],
  ['daebu', 'soijak'],  ['daebu', 'deokjeok'],  ['daebu', 'pungdo'], ['daebu', 'yukdo'],
  ['deokjeok', 'jawol'], ['jawol', 'daeijak'],
];

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  _Island? _selected;
  bool _showRoutes = true;

  _Island? _getIsland(String id) {
    try { return _islands.firstWhere((i) => i.id == id); }
    catch (_) { return null; }
  }

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
            Text('인천 섬들의 위치와 여객선 항로', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85))),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.gray200)),
      ),
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
                  Text('항로 ${_showRoutes ? "숨기기" : "보기"}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                      color: _showRoutes ? AppColors.blue700 : AppColors.gray700)),
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
    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(37.5, 125.8),
        initialZoom: 7.5,
        minZoom: 6,
        maxZoom: 14,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.sumtagi.app',
        ),
        if (_showRoutes) _buildRouteLayer(),
        _buildMarkerLayer(),
        _buildLegend(),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }

  Widget _buildRouteLayer() {
    final lines = <Polyline>[];
    for (final route in _routes) {
      final from = _getIsland(route[0]);
      final to   = _getIsland(route[1]);
      if (from == null || to == null) continue;

      final isHighlighted = _selected?.id == route[0] || _selected?.id == route[1];
      lines.add(Polyline(
        points: [from.position, to.position],
        color: AppColors.blue500.withValues(alpha: isHighlighted ? 1.0 : 0.4),
        strokeWidth: isHighlighted ? 2.5 : 1.2,
        pattern: StrokePattern.dashed(segments: const [8, 6]),
      ));
    }
    return PolylineLayer(polylines: lines);
  }

  Widget _buildMarkerLayer() {
    return MarkerLayer(
      markers: _islands.map((island) {
        final isSelected = _selected?.id == island.id;
        final size = island.isPort ? 14.0 : isSelected ? 13.0 : 10.0;

        return Marker(
          point: island.position,
          width: size + 8,
          height: size + 8,
          child: GestureDetector(
            onTap: () => setState(() => _selected = island),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: island.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                  if (isSelected)
                    BoxShadow(color: island.color.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2),
                ],
              ),
              child: island.isPort
                  ? const Icon(Icons.anchor_rounded, size: 8, color: Colors.white)
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLegend() {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LegendItem(color: Color(0xFFEF4444), label: '인천항'),
              SizedBox(height: 4),
              _LegendItem(color: Color(0xFFF97316), label: '대부도항'),
              SizedBox(height: 4),
              _LegendItem(color: Color(0xFF3B82F6), label: '섬'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPanel() {
    final island = _selected!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.gray200)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: island.isPort
                  ? (island.id == 'incheon' ? AppColors.red50 : AppColors.orange50)
                  : AppColors.blue50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              island.isPort ? Icons.anchor_rounded : Icons.location_on_rounded,
              size: 24,
              color: island.isPort
                  ? (island.id == 'incheon' ? AppColors.red700 : AppColors.orange600)
                  : AppColors.blue600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(island.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                const SizedBox(height: 2),
                Text(island.description, style: const TextStyle(fontSize: 12, color: AppColors.gray600)),
                if (!island.isPort) ...[
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
    final nonPorts = _islands.where((i) => !i.isPort).toList();
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

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray700)),
      ],
    );
  }
}
