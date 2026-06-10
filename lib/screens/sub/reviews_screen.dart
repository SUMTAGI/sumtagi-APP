import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});
  @override State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  static const _reviews = [
    {'id': '1', 'author': '바다러버', 'island': '백령도', 'rating': 5, 'content': '두무진 절벽에서 보는 일몰이 정말 장관이에요. 꼭 한번 방문해보세요!', 'date': '2025-08-20', 'likes': 24, 'photos': 3},
    {'id': '2', 'author': '힐링여행자', 'island': '덕적도', 'rating': 4, 'content': '서포리 해변의 넓고 깨끗한 백사장이 인상적이었어요. 시설은 조금 아쉬웠지만 자연 경관은 최고!', 'date': '2025-07-15', 'likes': 18, 'photos': 5},
    {'id': '3', 'author': '별빛캠퍼', 'island': '자월도', 'rating': 5, 'content': '도심에서는 볼 수 없는 별들이 가득한 밤하늘. 캠핑과 함께하니 더욱 특별한 경험이었어요.', 'date': '2025-06-10', 'likes': 31, 'photos': 8},
    {'id': '4', 'author': '사진작가', 'island': '대청도', 'rating': 5, 'content': '옥죽동 모래사막은 정말 신기한 경험이었어요. 해외에 온 것 같은 느낌!', 'date': '2025-05-25', 'likes': 42, 'photos': 12},
    {'id': '5', 'author': '가족여행맨', 'island': '영흥도', 'rating': 4, 'content': '아이들이 갯벌 체험을 너무 좋아했어요. 접근성이 좋아서 가족 여행으로 추천합니다.', 'date': '2025-09-05', 'likes': 15, 'photos': 6},
  ];

  String _filter = '전체';

  @override
  Widget build(BuildContext context) {
    final islands = ['전체', ...{..._reviews.map((r) => r['island'] as String)}];
    final filtered = _filter == '전체' ? _reviews : _reviews.where((r) => r['island'] == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('리뷰', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text('${_reviews.length}개의 여행 후기', style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
        titleSpacing: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('리뷰 작성 기능은 곧 추가될 예정이에요'))),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.blue600, borderRadius: BorderRadius.circular(8)),
                child: const Text('리뷰 쓰기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: islands.map((island) {
                  final selected = island == _filter;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = island),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.blue600 : AppColors.gray100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(island, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.gray700)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: filtered.length,
        itemBuilder: (context, i) {
          final review = filtered[i];
          return GestureDetector(
            onTap: () => context.push('/review/${review['id']}'),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: const BoxDecoration(color: AppColors.blue100, shape: BoxShape.circle),
                        child: const Icon(Icons.person_rounded, size: 20, color: AppColors.blue600),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(review['author'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                            Row(children: [
                              const Icon(Icons.location_on_rounded, size: 11, color: AppColors.gray400),
                              const SizedBox(width: 2),
                              Text(review['island'] as String, style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
                              const Text(' • ', style: TextStyle(fontSize: 11, color: AppColors.gray400)),
                              Text(review['date'] as String, style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(children: List.generate(5, (j) => Icon(j < (review['rating'] as int) ? Icons.star_rounded : Icons.star_border_rounded, size: 14, color: const Color(0xFFEAB308)))),
                  const SizedBox(height: 8),
                  Text(review['content'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray700, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Row(children: [
                        const Icon(Icons.camera_alt_outlined, size: 14, color: AppColors.gray400),
                        const SizedBox(width: 3),
                        Text('사진 ${review['photos']}장', style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
                      ]),
                      const SizedBox(width: 12),
                      Row(children: [
                        const Icon(Icons.favorite_border, size: 14, color: AppColors.gray400),
                        const SizedBox(width: 3),
                        Text('${review['likes']}', style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
                      ]),
                    ],
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
