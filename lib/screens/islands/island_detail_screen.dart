import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import 'islands_screen.dart';

class IslandDetailScreen extends StatelessWidget {
  final String id;
  const IslandDetailScreen({super.key, required this.id});

  IslandData? get _island => islandsData.cast<IslandData?>().firstWhere((i) => i?.id == id, orElse: () => null);

  @override
  Widget build(BuildContext context) {
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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info cards
                  Row(
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
                  const SizedBox(height: 24),

                  // Features
                  const Text('주요 관광지', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                  const SizedBox(height: 12),
                  ...island.features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: const BoxDecoration(color: AppColors.blue50, shape: BoxShape.circle),
                          child: const Icon(Icons.place_rounded, size: 16, color: AppColors.blue600),
                        ),
                        const SizedBox(width: 12),
                        Text(f, style: const TextStyle(fontSize: 14, color: AppColors.gray700, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 24),

                  // Ports
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
                  const SizedBox(height: 32),

                  // CTA
                  SizedBox(
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
                ],
              ),
            ),
          ),
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
        decoration: BoxDecoration(
          color: AppColors.blue50,
          borderRadius: BorderRadius.circular(10),
        ),
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
