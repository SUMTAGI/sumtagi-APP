import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ReviewDetailScreen extends StatelessWidget {
  final String id;
  const ReviewDetailScreen({super.key, required this.id});

  static const _reviews = {
    '1': {
      'id': '1', 'author': '바다러버', 'island': '백령도', 'rating': 5,
      'content': '두무진 절벽에서 보는 일몰이 정말 장관이에요. 서해의 웅장한 절벽과 붉게 물드는 하늘이 어우러져 정말 잊을 수 없는 풍경이었습니다. 꼭 한번 방문해보세요!\n\n백령도는 교통이 좀 불편하긴 하지만, 그만큼 청정한 자연이 잘 보존되어 있어요. 사곶해변의 천연 비행장도 정말 신기한 경험이었고, 두무진 유람선 투어도 강력 추천합니다.',
      'date': '2025-08-20', 'likes': 24, 'photos': 3,
      'tags': ['자연경관', '일몰', '트레킹'],
      'visitInfo': {'duration': '2박3일', 'season': '여름', 'group': '커플'},
    },
    '2': {
      'id': '2', 'author': '힐링여행자', 'island': '덕적도', 'rating': 4,
      'content': '서포리 해변의 넓고 깨끗한 백사장이 인상적이었어요. 시설은 조금 아쉬웠지만 자연 경관은 최고!',
      'date': '2025-07-15', 'likes': 18, 'photos': 5,
      'tags': ['해변', '힐링', '가족여행'],
      'visitInfo': {'duration': '1박2일', 'season': '여름', 'group': '가족'},
    },
  };

  @override
  Widget build(BuildContext context) {
    final review = _reviews[id] ?? _reviews['1']!;
    final tags = (review['tags'] as List).cast<String>();
    final visitInfo = review['visitInfo'] as Map<String, String>;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: Text('${review['island']} 리뷰', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: const BoxDecoration(color: AppColors.blue100, shape: BoxShape.circle),
                        child: const Icon(Icons.person_rounded, size: 26, color: AppColors.blue600),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(review['author'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                            Row(children: [
                              const Icon(Icons.location_on_rounded, size: 12, color: AppColors.gray400),
                              const SizedBox(width: 2),
                              Text(review['island'] as String, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                              const Text(' • ', style: TextStyle(color: AppColors.gray400, fontSize: 12)),
                              Text(review['date'] as String, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                            ]),
                          ],
                        ),
                      ),
                      Row(children: List.generate(5, (j) => Icon(j < (review['rating'] as int) ? Icons.star_rounded : Icons.star_border_rounded, size: 16, color: const Color(0xFFEAB308)))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Visit info chips
                  Row(
                    children: visitInfo.entries.map((e) => Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.blue50, borderRadius: BorderRadius.circular(6)),
                      child: Text(e.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.blue700)),
                    )).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Photo placeholder
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blue.shade300, Colors.blue.shade600]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_library_rounded, size: 32, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text('사진 ${review['photos']}장', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Content
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('여행 후기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                  const SizedBox(height: 10),
                  Text(review['content'] as String, style: const TextStyle(fontSize: 14, color: AppColors.gray700, height: 1.6)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tags
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('태그', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.blue100, borderRadius: BorderRadius.circular(20)),
                      child: Text('#$tag', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.blue700)),
                    )).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Like
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border, size: 22, color: Colors.red),
                  const SizedBox(width: 8),
                  Text('도움이 됐어요 (${review['likes']})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
