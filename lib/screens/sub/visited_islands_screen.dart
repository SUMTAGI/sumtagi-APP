import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class VisitedIslandsScreen extends StatelessWidget {
  const VisitedIslandsScreen({super.key});

  static const _visited = [
    {'name': '백령도', 'visitDate': '2025-08-15', 'days': 2, 'rating': 5, 'memo': '두무진 일몰이 너무 아름다웠어요'},
    {'name': '덕적도', 'visitDate': '2025-05-20', 'days': 1, 'rating': 4, 'memo': '서포리 해변 최고!'},
    {'name': '자월도', 'visitDate': '2024-09-10', 'days': 2, 'rating': 5, 'memo': '별이 정말 많이 보였어요'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('방문한 섬', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text('총 ${_visited.length}개 섬 방문', style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          // Stats
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(child: _StatBox(value: '${_visited.length}', label: '방문 섬')),
                const SizedBox(width: 12),
                Expanded(child: _StatBox(value: '${_visited.fold<int>(0, (s, i) => s + (i['days'] as int))}', label: '여행 일수')),
                const SizedBox(width: 12),
                Expanded(child: _StatBox(value: '4.7', label: '평균 별점')),
              ],
            ),
          ),

          Expanded(
            child: _visited.isEmpty
                ? const Center(child: Text('아직 방문한 섬이 없어요', style: TextStyle(color: AppColors.gray500)))
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _visited.length,
                    itemBuilder: (context, i) {
                      final island = _visited[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
                        child: Row(
                          children: [
                            Container(
                              width: 56, height: 56,
                              decoration: const BoxDecoration(color: AppColors.blue50, shape: BoxShape.circle),
                              child: const Icon(Icons.location_on_rounded, size: 28, color: AppColors.blue600),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(island['name'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                                  const SizedBox(height: 4),
                                  Text('${island['visitDate']}  |  ${island['days']}박', style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                                  const SizedBox(height: 4),
                                  Text(island['memo'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: List.generate(5, (j) => Icon(
                                      j < (island['rating'] as int) ? Icons.star_rounded : Icons.star_border_rounded,
                                      size: 14,
                                      color: const Color(0xFFEAB308),
                                    )),
                                  ),
                                ],
                              ),
                            ),
                          ],
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

class _StatBox extends StatelessWidget {
  final String value, label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: AppColors.blue50, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.blue600)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.gray600)),
        ],
      ),
    );
  }
}
