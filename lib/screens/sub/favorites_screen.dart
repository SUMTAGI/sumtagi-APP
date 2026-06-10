import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final List<Map<String, dynamic>> _favorites = [
    {'id': '1', 'name': '백령도', 'type': '섬', 'description': '서해 최북단의 신비로운 섬', 'emoji': '🏝️', 'ferryTime': '4시간', 'congestion': '여유'},
    {'id': '2', 'name': '덕적도 서포리 해변', 'type': '해변', 'description': '넓고 아름다운 백사장', 'emoji': '🏖️', 'ferryTime': '2.5시간', 'congestion': '보통'},
    {'id': '3', 'name': '자월도', 'type': '섬', 'description': '조용하고 아름다운 별빛 섬', 'emoji': '⭐', 'ferryTime': '2.5시간', 'congestion': '여유'},
    {'id': '4', 'name': '두무진', 'type': '명소', 'description': '백령도의 웅장한 해안 절벽', 'emoji': '🪨', 'ferryTime': '-', 'congestion': '-'},
  ];

  Color _congestionColor(String c) {
    if (c == '여유') return const Color(0xFFDCFCE7);
    if (c == '보통') return const Color(0xFFFEF9C3);
    if (c == '혼잡') return const Color(0xFFFEE2E2);
    return AppColors.gray100;
  }

  Color _congestionTextColor(String c) {
    if (c == '여유') return const Color(0xFF15803D);
    if (c == '보통') return const Color(0xFFCA8A04);
    if (c == '혼잡') return const Color(0xFFDC2626);
    return AppColors.gray600;
  }

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
      body: _favorites.isEmpty
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
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _favorites.length,
              itemBuilder: (context, i) {
                final fav = _favorites[i];
                return Container(
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
                          child: Text(fav['emoji'] as String, style: const TextStyle(fontSize: 28)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(fav['name'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: AppColors.blue100, borderRadius: BorderRadius.circular(4)),
                                    child: Text(fav['type'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.blue700)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(fav['description'] as String, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                              const SizedBox(height: 8),
                              Row(children: [
                                if (fav['ferryTime'] != '-') ...[
                                  const Icon(Icons.directions_boat_rounded, size: 12, color: AppColors.gray400),
                                  const SizedBox(width: 3),
                                  Text(fav['ferryTime'] as String, style: const TextStyle(fontSize: 11, color: AppColors.gray600)),
                                  const SizedBox(width: 8),
                                ],
                                if (fav['congestion'] != '-')
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: _congestionColor(fav['congestion'] as String), borderRadius: BorderRadius.circular(4)),
                                    child: Text(fav['congestion'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _congestionTextColor(fav['congestion'] as String))),
                                  ),
                              ]),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _favorites.removeAt(i)),
                          child: const Icon(Icons.favorite, color: Colors.red, size: 22),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
