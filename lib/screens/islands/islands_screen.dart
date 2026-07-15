import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../services/island_service.dart';
import '../../services/congestion_service.dart';

enum _ViewMode { list, map }

class _Marker {
  final String id, name, ferryTime, description;
  final LatLng position;
  final Color color;
  final bool isPort;
  final List<String> ports;
  final String congestion;
  final int? ferryPrice;
  final List<String> features;
  final String? image;

  const _Marker({
    required this.id,
    required this.name,
    required this.ferryTime,
    required this.description,
    required this.position,
    required this.color,
    this.isPort = false,
    this.ports = const [],
    this.congestion = 'low',
    this.ferryPrice,
    this.features = const [],
    this.image,
  });

  String get formattedFerryPrice {
    final price = ferryPrice;
    if (price == null) return '요금 확인 필요';
    if (price > 0)
      return '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원';
    return '육로 연결';
  }
}

const _ports = [
  _Marker(
    id: 'incheon',
    name: '인천항',
    ferryTime: '-',
    description: '인천 연안여객터미널',
    position: LatLng(37.4744, 126.6169),
    color: Color(0xFFEF4444),
    isPort: true,
  ),
  _Marker(
    id: 'daebu',
    name: '대부도항',
    ferryTime: '-',
    description: '방아머리여객터미널',
    position: LatLng(37.2173, 126.5589),
    color: Color(0xFFF97316),
    isPort: true,
  ),
];

const _routes = [
  ['incheon', 'baengnyeong'],
  ['incheon', 'daecheong'],
  ['incheon', 'socheong'],
  ['incheon', 'yeonpyeong'],
  ['incheon', 'deokjeok'],
  ['incheon', 'jawol'],
  ['incheon', 'seungbong'],
  ['incheon', 'daeijak'],
  ['daebu', 'jawol'],
  ['daebu', 'seungbong'],
  ['daebu', 'daeijak'],
  ['daebu', 'soijak'],
  ['daebu', 'deokjeok'],
  ['daebu', 'pungdo'],
  ['daebu', 'yukdo'],
  ['deokjeok', 'jawol'],
  ['jawol', 'daeijak'],
  ['incheon', 'yeonghung'],
  ['incheon', 'guleop'],
  ['yeonghung', 'seonjae'],
];

const _congestionLabels = {'low': '여유', 'medium': '보통', 'high': '혼잡'};
const _congestionColors = {
  'low': AppColors.green500,
  'medium': AppColors.yellow500,
  'high': AppColors.red500,
};

class IslandsScreen extends StatefulWidget {
  const IslandsScreen({super.key});

  @override
  State<IslandsScreen> createState() => _IslandsScreenState();
}

class _IslandsScreenState extends State<IslandsScreen> {
  List<IslandModel> _islands = [];
  Map<String, IslandCongestionData> _congestionMap = {};
  bool _loading = true;

  _ViewMode _viewMode = _ViewMode.list;
  _Marker? _selected;
  bool _showRoutes = true;
  String _portFilter = 'all';
  String _congestionFilter = 'all';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  final GlobalKey _headerKey = GlobalKey();
  double _headerHeight = 240;
  bool _headerVisible = true;

  @override
  void initState() {
    super.initState();
    _loadIslands();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeader());
  }

  void _measureHeader() {
    final box = _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null &&
        box.hasSize &&
        (box.size.height - _headerHeight).abs() > 0.5) {
      setState(() => _headerHeight = box.size.height);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadIslands() async {
    try {
      final islands = await IslandService.getIslands();
      if (mounted)
        setState(() {
          _islands = islands;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
    CongestionService.getAllIslandsCongestion()
        .then((map) {
          if (mounted) setState(() => _congestionMap = map);
        })
        .catchError((e, st) {
          debugPrint('[IslandsCongestion ERROR] $e\n$st');
        });
  }

  String _effectiveCongestion(IslandModel island) =>
      _congestionMap[island.id]?.todayLevel ?? island.congestion;

  List<IslandModel> get _filtered => _islands.where((island) {
    final portMatch =
        _portFilter == 'all' || island.ports.contains(_portFilter);
    final congestionMatch =
        _congestionFilter == 'all' ||
        _effectiveCongestion(island) == _congestionFilter;
    final searchMatch =
        _searchQuery.isEmpty ||
        island.name.contains(_searchQuery) ||
        island.description.contains(_searchQuery) ||
        island.features.any((f) => f.contains(_searchQuery));
    return portMatch && congestionMatch && searchMatch;
  }).toList();

  List<IslandModel> get _mappable =>
      _filtered.where((i) => i.lat != null && i.lng != null).toList();

  List<_Marker> get _markers => [
    ..._ports,
    ..._mappable.map(
      (i) => _Marker(
        id: i.id,
        name: i.name,
        ferryTime: i.ferryTime,
        description: i.description,
        position: LatLng(i.lat!, i.lng!),
        color: const Color(0xFF3B82F6),
        ports: i.ports,
        congestion: _effectiveCongestion(i),
        ferryPrice: i.ferryPrice,
        features: i.features,
        image: i.image,
      ),
    ),
  ];

  _Marker? _getMarker(String id) {
    try {
      return _markers.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF3B82F6)],
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '섬 둘러보기',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '인천의 아름다운 섬들을 탐색해보세요',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
        titleSpacing: 24,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _viewMode == _ViewMode.list
          ? Stack(
              children: [
                Positioned.fill(
                  child: NotificationListener<UserScrollNotification>(
                    onNotification: (notification) {
                      if (notification.direction == ScrollDirection.reverse &&
                          _headerVisible) {
                        setState(() => _headerVisible = false);
                      } else if (notification.direction ==
                              ScrollDirection.forward &&
                          !_headerVisible) {
                        setState(() => _headerVisible = true);
                      }
                      return false;
                    },
                    child: _buildIslandList(),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOutCubic,
                  top: _headerVisible ? 0 : -_headerHeight,
                  left: 0,
                  right: 0,
                  child: KeyedSubtree(
                    key: _headerKey,
                    child: _buildHeaderContent(),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                _buildHeaderContent(),
                Expanded(child: _buildMapView()),
              ],
            ),
    );
  }

  Widget _buildHeaderContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [_buildSearchBar(), _buildViewTabBar(), _buildFilters()],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.gray200)),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: '섬 이름, 특징으로 검색...',
          prefixIcon: const Icon(Icons.search, color: AppColors.gray400),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.gray400,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.gray50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.gray200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.gray200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.blue600, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildViewTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.gray200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ViewTab(
              icon: Icons.grid_view_rounded,
              label: '리스트',
              active: _viewMode == _ViewMode.list,
              onTap: () => setState(() => _viewMode = _ViewMode.list),
            ),
          ),
          Expanded(
            child: _ViewTab(
              icon: Icons.map_rounded,
              label: '지도',
              active: _viewMode == _ViewMode.map,
              onTap: () => setState(() => _viewMode = _ViewMode.map),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final total = _islands.length;
    final incheon = _islands.where((i) => i.ports.contains('인천항')).length;
    final daebudo = _islands.where((i) => i.ports.contains('대부도')).length;
    final samok = _islands.where((i) => i.ports.contains('삼목선착장')).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.gray200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '출발 항구',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _FilterDropdown(
                      value: _portFilter,
                      items: [
                        ('all', '전체 ($total)'),
                        ('인천항', '인천항 ($incheon)'),
                        ('대부도', '대부도 ($daebudo)'),
                        ('삼목선착장', '삼목항 ($samok)'),
                      ],
                      onChanged: (v) => setState(() => _portFilter = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '혼잡도',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _FilterDropdown(
                      value: _congestionFilter,
                      items: const [
                        ('all', '전체'),
                        ('low', '여유'),
                        ('medium', '보통'),
                        ('high', '혼잡'),
                      ],
                      onChanged: (v) => setState(() => _congestionFilter = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_viewMode == _ViewMode.map) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _showRoutes = !_showRoutes),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _showRoutes ? AppColors.blue100 : AppColors.gray100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_boat_rounded,
                      size: 15,
                      color: _showRoutes
                          ? AppColors.blue700
                          : AppColors.gray700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '항로 ${_showRoutes ? "숨기기" : "보기"}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _showRoutes
                            ? AppColors.blue700
                            : AppColors.gray700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIslandList() {
    final filtered = _filtered;
    if (filtered.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: _headerHeight),
        child: const Center(
          child: Text(
            '다른 키워드로 검색해보세요',
            style: TextStyle(color: AppColors.gray500),
          ),
        ),
      );
    }
    return ListView.builder(
      // top padding clears the floating header; bottom padding clears the floating nav bar
      padding: EdgeInsets.fromLTRB(24, _headerHeight + 24, 24, 124),
      itemCount: filtered.length + 1,
      itemBuilder: (context, i) {
        if (i == filtered.length) {
          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.blue100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.blue200),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 여행 가이드',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.blue700,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '• 주말/공휴일은 1주일 전에 미리 예약하세요',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.blue700,
                    height: 1.5,
                  ),
                ),
                Text(
                  '• 출발 전날 운항 여부를 꼭 확인해주세요',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.blue700,
                    height: 1.5,
                  ),
                ),
                Text(
                  '• 자외선 차단제, 편한 신발 챙기는 거 잊지 마세요',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.blue700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _IslandCard(
            island: filtered[i],
            congestion: _congestionMap[filtered[i].id],
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(37.5, 125.8),
                  initialZoom: 7.5,
                  minZoom: 6,
                  maxZoom: 14,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.sumtagi.app',
                  ),
                  if (_showRoutes) _buildRouteLayer(),
                  _buildMarkerLayer(),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),
              _buildLegend(),
            ],
          ),
        ),
        if (_selected != null) _buildInfoPanel(),
      ],
    );
  }

  Widget _buildRouteLayer() {
    final lines = <Polyline>[];
    for (final route in _routes) {
      final from = _getMarker(route[0]);
      final to = _getMarker(route[1]);
      if (from == null || to == null) continue;

      final isHighlighted =
          _selected?.id == route[0] || _selected?.id == route[1];
      lines.add(
        Polyline(
          points: [from.position, to.position],
          color: AppColors.blue500.withValues(alpha: isHighlighted ? 1.0 : 0.4),
          strokeWidth: isHighlighted ? 2.5 : 1.2,
          pattern: StrokePattern.dashed(segments: const [8, 6]),
        ),
      );
    }
    return PolylineLayer(polylines: lines);
  }

  Widget _buildMarkerLayer() {
    return MarkerLayer(
      markers: _markers.map((marker) {
        final isSelected = _selected?.id == marker.id;
        final size = marker.isPort
            ? 14.0
            : isSelected
            ? 13.0
            : 10.0;

        return Marker(
          point: marker.position,
          width: size + 8,
          height: size + 8,
          child: GestureDetector(
            onTap: () => setState(() => _selected = marker),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: marker.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                  if (isSelected)
                    BoxShadow(
                      color: marker.color.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: marker.isPort
                  ? const Icon(
                      Icons.anchor_rounded,
                      size: 8,
                      color: Colors.white,
                    )
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
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 6,
              ),
            ],
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
    final marker = _selected!;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.gray200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!marker.isPort &&
              marker.image != null &&
              marker.image!.isNotEmpty)
            SizedBox(
              height: 110,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: marker.image!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    Container(color: AppColors.gray100),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (marker.isPort ||
                        marker.image == null ||
                        marker.image!.isEmpty)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: marker.isPort
                              ? (marker.id == 'incheon'
                                    ? AppColors.red50
                                    : AppColors.orange50)
                              : AppColors.blue50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          marker.isPort
                              ? Icons.anchor_rounded
                              : Icons.location_on_rounded,
                          size: 24,
                          color: marker.isPort
                              ? (marker.id == 'incheon'
                                    ? AppColors.red700
                                    : AppColors.orange600)
                              : AppColors.blue600,
                        ),
                      ),
                    if (marker.isPort ||
                        marker.image == null ||
                        marker.image!.isEmpty)
                      const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            marker.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gray900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            marker.description,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.gray600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.gray400),
                      onPressed: () => setState(() => _selected = null),
                    ),
                  ],
                ),
                if (!marker.isPort) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_boat_rounded,
                        size: 14,
                        color: AppColors.gray500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        marker.ferryTime,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.gray700,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _congestionColors[marker.congestion],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _congestionLabels[marker.congestion] ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        marker.formattedFerryPrice,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blue600,
                        ),
                      ),
                    ],
                  ),
                  if (marker.features.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: marker.features
                          .take(4)
                          .map(
                            (f) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.gray100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                f,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.gray700,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.push('/island/${marker.id}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        '섬 상세 보기',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ViewTab({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.blue600 : AppColors.gray500;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppColors.blue600 : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String value;
  final List<(String, String)> items;
  final ValueChanged<String> onChanged;
  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.gray500,
            size: 20,
          ),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.gray900,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item.$1,
                  child: Text(item.$2, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _IslandCard extends StatelessWidget {
  final IslandModel island;
  final IslandCongestionData? congestion;
  const _IslandCard({required this.island, this.congestion});

  String get _effectiveCongestion =>
      congestion?.todayLevel ?? island.congestion;

  String get _congestionLabel => switch (_effectiveCongestion) {
    'low' => '여유',
    'medium' => '보통',
    _ => '혼잡',
  };

  Color get _congestionBg => switch (_effectiveCongestion) {
    'low' => AppColors.green500,
    'medium' => AppColors.yellow500,
    _ => AppColors.red500,
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/island/${island.id}'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 240,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: island.image,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        Container(color: AppColors.gray100),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0x66000000),
                          Color(0x99000000),
                        ],
                        stops: [0.3, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        island.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _congestionBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _congestionLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Stack(
              children: [
                Positioned.fill(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: CachedNetworkImage(
                      imageUrl: island.image,
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomCenter,
                      errorWidget: (_, __, ___) =>
                          Container(color: AppColors.gray100),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.68),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        island.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.gray600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...island.features
                          .take(2)
                          .map(
                            (f) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: AppColors.blue500,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    f,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.gray700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      const SizedBox(height: 8),
                      const Divider(height: 1, color: AppColors.gray200),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.directions_boat_rounded,
                            size: 14,
                            color: AppColors.gray400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            island.ferryTime,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.gray900,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: AppColors.gray400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            island.bestSeason,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.gray900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '여객선 요금',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.gray600,
                            ),
                          ),
                          Text(
                            island.formattedFerryPrice,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.blue500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 4,
                        children: island.ports
                            .map(
                              (port) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: port == '인천항'
                                      ? AppColors.blue600
                                      : const Color(0xFF93C5FD),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  port,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
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
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.gray700),
        ),
      ],
    );
  }
}
