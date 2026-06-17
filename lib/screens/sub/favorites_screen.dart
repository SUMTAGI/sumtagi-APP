import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/favorite_service.dart';
import '../../services/island_service.dart';
import '../../theme/app_colors.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<IslandModel> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await FavoriteService.getFavorites();
      if (mounted) setState(() { _favorites = list; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _remove(String islandId) async {
    await FavoriteService.toggle(islandId);
    setState(() => _favorites.removeWhere((i) => i.id == islandId));
  }

  String _congestionLabel(String c) => switch (c) { 'low' => '여유', 'medium' => '보통', _ => '혼잡' };
  Color _congestionBg(String c) => switch (c) { 'low' => const Color(0xFFDCFCE7), 'medium' => const Color(0xFFFEF9C3), _ => const Color(0xFFFEE2E2) };
  Color _congestionText(String c) => switch (c) { 'low' => const Color(0xFF15803D), 'medium' => const Color(0xFFCA8A04), _ => const Color(0xFFDC2626) };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('찜한 여행지', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text('${_favorites.length}개의 즐겨찾기', style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
        titleSpacing: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: AppColors.gray300),
                      SizedBox(height: 16),
                      Text('찜한 여행지가 없어요', style: TextStyle(fontSize: 16, color: AppColors.gray500)),
                      SizedBox(height: 8),
                      Text('마음에 드는 섬을 찜해보세요!', style: TextStyle(fontSize: 13, color: AppColors.gray400)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _favorites.length,
                    itemBuilder: (context, i) {
                      final island = _favorites[i];
                      return GestureDetector(
                        onTap: () => context.push('/island/${island.id}'),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 56, height: 56,
                                  decoration: BoxDecoration(color: AppColors.blue50, borderRadius: BorderRadius.circular(12)),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.directions_boat_rounded, color: AppColors.blue600, size: 28),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(island.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                                      const SizedBox(height: 4),
                                      Text(island.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                                      const SizedBox(height: 8),
                                      Row(children: [
                                        const Icon(Icons.directions_boat_rounded, size: 12, color: AppColors.gray400),
                                        const SizedBox(width: 3),
                                        Text(island.ferryTime, style: const TextStyle(fontSize: 11, color: AppColors.gray600)),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: _congestionBg(island.congestion), borderRadius: BorderRadius.circular(4)),
                                          child: Text(_congestionLabel(island.congestion), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _congestionText(island.congestion))),
                                        ),
                                      ]),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _remove(island.id),
                                  child: const Icon(Icons.favorite, color: Colors.red, size: 22),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
