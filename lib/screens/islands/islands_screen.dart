import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../services/island_service.dart';
import '../../services/congestion_service.dart';

class IslandsScreen extends StatefulWidget {
  const IslandsScreen({super.key});

  @override
  State<IslandsScreen> createState() => _IslandsScreenState();
}

class _IslandsScreenState extends State<IslandsScreen> {
  List<IslandModel> _islands = [];
  bool _isLoading = true;
  String _portFilter = 'all';
  String _congestionFilter = 'all';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  Map<String, IslandCongestionData> _congestionMap = {};

  @override
  void initState() {
    super.initState();
    _loadIslands();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadIslands() async {
    try {
      final islands = await IslandService.getIslands();
      if (mounted) setState(() { _islands = islands; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
    CongestionService.getAllIslandsCongestion()
        .then((map) { if (mounted) setState(() => _congestionMap = map); })
        .catchError((e, st) { print('[IslandsCongestion ERROR] $e\n$st'); });
  }

  List<IslandModel> get _filtered => _islands.where((island) {
    final portMatch = _portFilter == 'all' || island.ports.contains(_portFilter);
    final effective = _congestionMap[island.id]?.todayLevel ?? island.congestion;
    final congestionMatch = _congestionFilter == 'all' || effective == _congestionFilter;
    final searchMatch = _searchQuery.isEmpty ||
        island.name.contains(_searchQuery) ||
        island.description.contains(_searchQuery) ||
        island.features.any((f) => f.contains(_searchQuery));
    return portMatch && congestionMatch && searchMatch;
  }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF3B82F6)]),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('섬 둘러보기', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('인천의 아름다운 섬들을 탐색해보세요', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85))),
          ],
        ),
        titleSpacing: 24,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchBar(),
                _buildFilters(),
                Expanded(child: _buildIslandList()),
              ],
            ),
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
                  icon: const Icon(Icons.close, color: AppColors.gray400, size: 18),
                  onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                )
              : null,
          filled: true,
          fillColor: AppColors.gray50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.blue600, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final total = _islands.length;
    final incheon = _islands.where((i) => i.ports.contains('인천항')).length;
    final daebudo = _islands.where((i) => i.ports.contains('대부도')).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.gray200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('출발 항구', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.gray500)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _FilterBtn(label: '전체 ($total)', isActive: _portFilter == 'all', color: 'blue', onTap: () => setState(() => _portFilter = 'all'))),
            const SizedBox(width: 8),
            Expanded(child: _FilterBtn(label: '인천항 ($incheon)', isActive: _portFilter == '인천항', color: 'red', onTap: () => setState(() => _portFilter = '인천항'))),
            const SizedBox(width: 8),
            Expanded(child: _FilterBtn(label: '대부도 ($daebudo)', isActive: _portFilter == '대부도', color: 'orange', onTap: () => setState(() => _portFilter = '대부도'))),
          ]),
          const SizedBox(height: 12),
          const Text('혼잡도', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.gray500)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _FilterBtn(label: '전체', isActive: _congestionFilter == 'all', color: 'blue', onTap: () => setState(() => _congestionFilter = 'all'))),
            const SizedBox(width: 8),
            Expanded(child: _FilterBtn(label: '여유', isActive: _congestionFilter == 'low', color: 'green', onTap: () => setState(() => _congestionFilter = 'low'))),
            const SizedBox(width: 8),
            Expanded(child: _FilterBtn(label: '보통', isActive: _congestionFilter == 'medium', color: 'yellow', onTap: () => setState(() => _congestionFilter = 'medium'))),
            const SizedBox(width: 8),
            Expanded(child: _FilterBtn(label: '혼잡', isActive: _congestionFilter == 'high', color: 'red', onTap: () => setState(() => _congestionFilter = 'high'))),
          ]),
        ],
      ),
    );
  }

  Widget _buildIslandList() {
    final filtered = _filtered;
    if (filtered.isEmpty) {
      return const Center(child: Text('검색 결과가 없어요', style: TextStyle(color: AppColors.gray500)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: filtered.length + 1,
      itemBuilder: (context, i) {
        if (i == filtered.length) {
          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.blue100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.blue200),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('💡 여행 가이드', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.blue700, fontSize: 14)),
                SizedBox(height: 8),
                Text('• 주말/공휴일은 1주일 전에 미리 예약하세요', style: TextStyle(fontSize: 13, color: AppColors.blue700, height: 1.5)),
                Text('• 출발 전날 운항 여부를 꼭 확인해주세요', style: TextStyle(fontSize: 13, color: AppColors.blue700, height: 1.5)),
                Text('• 자외선 차단제, 편한 신발 챙기는 거 잊지 마세요', style: TextStyle(fontSize: 13, color: AppColors.blue700, height: 1.5)),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _IslandCard(island: filtered[i], congestion: _congestionMap[filtered[i].id]),
        );
      },
    );
  }
}

class _FilterBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final String color;
  final VoidCallback onTap;
  const _FilterBtn({required this.label, required this.isActive, required this.color, required this.onTap});

  Color get _activeColor => switch (color) {
    'green' => AppColors.green500,
    'yellow' => AppColors.yellow500,
    'red' => AppColors.red500,
    'orange' => AppColors.orange500,
    _ => AppColors.blue500,
  };

  Color get _inactiveBg => switch (color) {
    'green' => AppColors.green100,
    'yellow' => AppColors.yellow100,
    _ => AppColors.gray100,
  };

  Color get _inactiveText => switch (color) {
    'green' => AppColors.green700,
    'yellow' => AppColors.yellow700,
    _ => AppColors.gray700,
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _activeColor : _inactiveBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isActive ? Colors.white : _inactiveText)),
      ),
    );
  }
}

class _IslandCard extends StatelessWidget {
  final IslandModel island;
  final IslandCongestionData? congestion;
  const _IslandCard({required this.island, this.congestion});

  String get _effectiveCongestion => congestion?.todayLevel ?? island.congestion;

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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 160, width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: island.image, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(color: AppColors.gray100),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x66000000), Color(0x99000000)],
                        stops: [0.3, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
                if (island.popularityTrend == 'up')
                  Positioned(
                    top: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.red500, borderRadius: BorderRadius.circular(50)),
                      child: const Row(children: [
                        Icon(Icons.trending_up, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text('인기상승', style: TextStyle(fontSize: 11, color: Colors.white)),
                      ]),
                    ),
                  ),
                Positioned(
                  bottom: 12, left: 12, right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(island.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: _congestionBg, borderRadius: BorderRadius.circular(6)),
                        child: Text(_congestionLabel, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(island.description, style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
                  const SizedBox(height: 10),
                  ...island.features.take(2).map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.blue500, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(f, style: const TextStyle(fontSize: 12, color: AppColors.gray700)),
                    ]),
                  )),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.gray200),
                  const SizedBox(height: 12),
                  Row(children: [
                    const Icon(Icons.directions_boat_rounded, size: 14, color: AppColors.gray400),
                    const SizedBox(width: 4),
                    Text(island.ferryTime, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray900)),
                    const SizedBox(width: 16),
                    const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.gray400),
                    const SizedBox(width: 4),
                    Text(island.bestSeason, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray900)),
                  ]),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('여객선 요금', style: TextStyle(fontSize: 13, color: AppColors.gray600)),
                      Text(
                        '${island.ferryPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.blue500, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: island.ports.map((port) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: port == '인천항' ? AppColors.red100 : AppColors.orange100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(port, style: TextStyle(fontSize: 11, color: port == '인천항' ? AppColors.red700 : AppColors.orange600)),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
