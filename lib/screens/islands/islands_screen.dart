import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';

class IslandData {
  final String id, name, description, ferryTime, bestSeason;
  final List<String> features, ports;
  final int ferryPrice;
  final String popularityTrend, congestion, image;

  const IslandData({
    required this.id, required this.name, required this.description,
    required this.features, required this.ferryTime, required this.ferryPrice,
    required this.popularityTrend, required this.congestion, required this.bestSeason,
    required this.image, required this.ports,
  });
}

const islandsData = [
  IslandData(id: 'baengnyeong', name: '백령도', description: '천혜의 자연경관과 독특한 지질을 자랑하는 서해 최북단 섬', features: ['두무진 해안 절벽', '사곶해변', '콩돌해변'], ferryTime: '4시간', ferryPrice: 45000, popularityTrend: 'up', congestion: 'medium', bestSeason: '5~10월', image: 'https://images.unsplash.com/photo-1635355942488-a8bdb5a0803e?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=600', ports: ['인천항']),
  IslandData(id: 'daecheong', name: '대청도', description: '모래사막과 기암절벽이 공존하는 신비로운 섬', features: ['옥죽동 사막', '농여해변', '미아동 해안'], ferryTime: '4시간', ferryPrice: 45000, popularityTrend: 'stable', congestion: 'low', bestSeason: '5~9월', image: 'https://images.unsplash.com/photo-1700621496615-6ee6240503ef?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=600', ports: ['인천항']),
  IslandData(id: 'socheong', name: '소청도', description: '작지만 아름다운 서해의 보석', features: ['분바위', '등대', '해안절벽'], ferryTime: '4시간', ferryPrice: 45000, popularityTrend: 'stable', congestion: 'low', bestSeason: '5~9월', image: 'https://images.unsplash.com/photo-1661488601431-e8257e864068?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=600', ports: ['인천항']),
  IslandData(id: 'yeonpyeong', name: '연평도', description: '조기로 유명한 서해 5도 중 하나', features: ['조기잡이', '낚시', '해안산책'], ferryTime: '3.5시간', ferryPrice: 40000, popularityTrend: 'stable', congestion: 'medium', bestSeason: '4~10월', image: 'https://images.unsplash.com/photo-1628412071389-6e8f7a7a4e6e?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=600', ports: ['인천항']),
  IslandData(id: 'deokjeok', name: '덕적도', description: '맑은 바다와 아름다운 해변이 어우러진 가족 여행지', features: ['서포리해수욕장', '비조봉', '소야도'], ferryTime: '2.5시간', ferryPrice: 28000, popularityTrend: 'stable', congestion: 'medium', bestSeason: '6~9월', image: 'https://images.unsplash.com/photo-1662898069390-badabf2d65df?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=600', ports: ['인천항', '대부도']),
  IslandData(id: 'jawol', name: '자월도', description: '한적한 어촌 풍경과 에메랄드빛 바다', features: ['큰말해변', '선착장마을', '일몰 명소'], ferryTime: '2.5시간', ferryPrice: 25000, popularityTrend: 'up', congestion: 'low', bestSeason: '5~10월', image: 'https://images.unsplash.com/photo-1758327740342-4e705edea29b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=600', ports: ['인천항', '대부도']),
  IslandData(id: 'seungbong', name: '승봉도', description: '작고 아담한 섬의 매력', features: ['해안산책로', '선착장', '조용한 마을'], ferryTime: '2시간', ferryPrice: 23000, popularityTrend: 'stable', congestion: 'low', bestSeason: '5~10월', image: 'https://images.unsplash.com/photo-1635355942488-a8bdb5a0803e?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=600', ports: ['인천항', '대부도']),
  IslandData(id: 'daeijak', name: '대이작도', description: '청정 해역과 고운 모래가 특징인 섬', features: ['목기미해변', '부아산', '해안 트레킹'], ferryTime: '2시간', ferryPrice: 25000, popularityTrend: 'up', congestion: 'low', bestSeason: '6~9월', image: 'https://images.unsplash.com/photo-1661488601431-e8257e864068?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=600', ports: ['인천항', '대부도']),
  IslandData(id: 'soijak', name: '소이작도', description: '작은 이작도의 조용한 해변', features: ['해수욕장', '낚시', '조개잡이'], ferryTime: '2시간', ferryPrice: 25000, popularityTrend: 'stable', congestion: 'low', bestSeason: '6~9월', image: 'https://images.unsplash.com/photo-1662898069390-badabf2d65df?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=600', ports: ['대부도']),
  IslandData(id: 'pungdo', name: '풍도', description: '동백꽃으로 유명한 아름다운 섬', features: ['동백나무숲', '해안트레킹', '일몰명소'], ferryTime: '2.5시간', ferryPrice: 27000, popularityTrend: 'up', congestion: 'medium', bestSeason: '3~5월', image: 'https://images.unsplash.com/photo-1700621496615-6ee6240503ef?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=600', ports: ['대부도']),
  IslandData(id: 'yukdo', name: '육도', description: '작은 섬의 평화로운 풍경', features: ['작은해변', '어촌마을', '산책로'], ferryTime: '3시간', ferryPrice: 28000, popularityTrend: 'stable', congestion: 'low', bestSeason: '5~9월', image: 'https://images.unsplash.com/photo-1758327740342-4e705edea29b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=600', ports: ['대부도']),
];

class IslandsScreen extends StatefulWidget {
  const IslandsScreen({super.key});

  @override
  State<IslandsScreen> createState() => _IslandsScreenState();
}

class _IslandsScreenState extends State<IslandsScreen> {
  String _portFilter = 'all';
  String _congestionFilter = 'all';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  List<IslandData> get _filtered => islandsData.where((island) {
    final portMatch = _portFilter == 'all' || island.ports.contains(_portFilter);
    final congestionMatch = _congestionFilter == 'all' || island.congestion == _congestionFilter;
    final searchMatch = _searchQuery.isEmpty ||
        island.name.contains(_searchQuery) ||
        island.description.contains(_searchQuery) ||
        island.features.any((f) => f.contains(_searchQuery));
    return portMatch && congestionMatch && searchMatch;
  }).toList();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilters(),
          Expanded(
            child: _buildIslandList(),
          ),
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
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.gray50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.gray200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.gray200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.blue600, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.gray200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Port filter
          const Text('출발 항구', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.gray500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _FilterBtn(label: '전체 (${islandsData.length})', isActive: _portFilter == 'all', color: 'blue', onTap: () => setState(() => _portFilter = 'all'))),
              const SizedBox(width: 8),
              Expanded(child: _FilterBtn(label: '인천항 (${islandsData.where((i) => i.ports.contains('인천항')).length})', isActive: _portFilter == '인천항', color: 'red', onTap: () => setState(() => _portFilter = '인천항'))),
              const SizedBox(width: 8),
              Expanded(child: _FilterBtn(label: '대부도 (${islandsData.where((i) => i.ports.contains('대부도')).length})', isActive: _portFilter == '대부도', color: 'orange', onTap: () => setState(() => _portFilter = '대부도'))),
            ],
          ),
          const SizedBox(height: 12),
          // Congestion filter
          const Text('혼잡도', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.gray500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _FilterBtn(label: '전체', isActive: _congestionFilter == 'all', color: 'blue', onTap: () => setState(() => _congestionFilter = 'all'))),
              const SizedBox(width: 8),
              Expanded(child: _FilterBtn(label: '여유', isActive: _congestionFilter == 'low', color: 'green', onTap: () => setState(() => _congestionFilter = 'low'))),
              const SizedBox(width: 8),
              Expanded(child: _FilterBtn(label: '보통', isActive: _congestionFilter == 'medium', color: 'yellow', onTap: () => setState(() => _congestionFilter = 'medium'))),
              const SizedBox(width: 8),
              Expanded(child: _FilterBtn(label: '혼잡', isActive: _congestionFilter == 'high', color: 'red', onTap: () => setState(() => _congestionFilter = 'high'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIslandList() {
    final filtered = _filtered;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
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
          child: _IslandCard(island: filtered[i]),
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
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : _inactiveText,
          ),
        ),
      ),
    );
  }
}

class _IslandCard extends StatelessWidget {
  final IslandData island;
  const _IslandCard({required this.island});

  String get _congestionLabel => switch (island.congestion) {
    'low' => '여유',
    'medium' => '보통',
    _ => '혼잡',
  };

  Color get _congestionBg => switch (island.congestion) {
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
            // Image
            Stack(
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: island.image,
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
                      child: const Row(
                        children: [
                          Icon(Icons.trending_up, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text('인기상승', style: TextStyle(fontSize: 11, color: Colors.white)),
                        ],
                      ),
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
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(island.description, style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
                  const SizedBox(height: 10),
                  ...island.features.take(2).map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.blue500, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(f, style: const TextStyle(fontSize: 12, color: AppColors.gray700)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.gray200),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.directions_boat_rounded, size: 14, color: AppColors.gray400),
                      const SizedBox(width: 4),
                      Text(island.ferryTime, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray900)),
                      const SizedBox(width: 16),
                      const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.gray400),
                      const SizedBox(width: 4),
                      Text(island.bestSeason, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray900)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('여객선 요금', style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
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
