import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../services/island_service.dart';
import '../../services/favorite_service.dart';

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
      if (mounted) setState(() {
        _island = results[0] as IslandDetailModel?;
        _isFavorited = results[1] as bool;
        _isLoading = false;
      });
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
                        value: '${(island.ferryPrice / 10000).floor()}만원~',
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
