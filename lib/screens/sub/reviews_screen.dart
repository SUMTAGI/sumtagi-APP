import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/review_service.dart';
import '../../theme/app_colors.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});
  @override State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  String _filter = '전체';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await ReviewService.getReviews();
    if (mounted) setState(() { _reviews = data; _isLoading = false; });
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == '전체') return _reviews;
    return _reviews.where((r) => _islandName(r) == _filter).toList();
  }

  String _islandName(Map<String, dynamic> r) =>
      (r['islands'] as Map?)?['name'] as String? ?? '';

  String _nickname(Map<String, dynamic> r) =>
      r['author_name'] as String? ?? '여행자';

  String _timeAgo(String isoString) {
    final dt = DateTime.tryParse(isoString)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return '오늘';
    if (diff.inDays < 30) return '${diff.inDays}일 전';
    return '${dt.month}/${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final islandNames = {'전체', ..._reviews.map(_islandName).where((n) => n.isNotEmpty)};
    final islands = islandNames.toList();

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('여행 후기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text('${_reviews.length}개의 후기', style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            height: 52,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              itemCount: islands.length,
              itemBuilder: (_, i) {
                final name = islands[i];
                final isSelected = _filter == name;
                return GestureDetector(
                  onTap: () => setState(() => _filter = name),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.blue600 : AppColors.gray100,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : AppColors.gray700)),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _filtered.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rate_review_outlined, size: 64, color: AppColors.gray300),
                          SizedBox(height: 16),
                          Text('아직 후기가 없어요', style: TextStyle(fontSize: 16, color: AppColors.gray500)),
                          SizedBox(height: 8),
                          Text('섬을 방문하고 후기를 남겨보세요!', style: TextStyle(fontSize: 13, color: AppColors.gray400)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: _filtered.length,
                      itemBuilder: (context, i) {
                        final r = _filtered[i];
                        final rating = (r['rating'] as int?) ?? 0;
                        final islandName = _islandName(r);
                        return GestureDetector(
                          onTap: () => context.push('/review/${r['id']}'),
                          child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.gray200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40, height: 40,
                                    decoration: const BoxDecoration(color: AppColors.blue100, shape: BoxShape.circle),
                                    child: const Icon(Icons.person_rounded, size: 22, color: AppColors.blue600),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_nickname(r), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                                        Row(children: [
                                          if (islandName.isNotEmpty) ...[
                                            const Icon(Icons.location_on_rounded, size: 12, color: AppColors.gray500),
                                            const SizedBox(width: 2),
                                            Text(islandName, style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
                                            const Text(' • ', style: TextStyle(fontSize: 11, color: AppColors.gray400)),
                                          ],
                                          Text(_timeAgo(r['created_at'] as String? ?? ''), style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
                                        ]),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(5, (idx) => Icon(
                                      idx < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                      size: 16,
                                      color: idx < rating ? const Color(0xFFF59E0B) : AppColors.gray300,
                                    )),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(r['content'] as String? ?? '', style: const TextStyle(fontSize: 14, color: AppColors.gray700, height: 1.5)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.favorite_border, size: 16, color: AppColors.gray400),
                                  const SizedBox(width: 4),
                                  Text('${(r['likes_count'] as int?) ?? 0}', style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        );
                      },
                    ),
            ),
    );
  }
}
