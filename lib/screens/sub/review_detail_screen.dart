import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../services/review_service.dart';

class ReviewDetailScreen extends StatefulWidget {
  final String id;
  const ReviewDetailScreen({super.key, required this.id});

  @override
  State<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends State<ReviewDetailScreen> {
  Map<String, dynamic>? _review;
  bool _isLoading = true;
  bool _liked = false;
  int _likesCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ReviewService.getReviewById(widget.id);
    if (mounted) {
      setState(() {
        _review = data;
        _likesCount = (data?['likes_count'] as int?) ?? 0;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    final newLiked = !_liked;
    final newCount = newLiked ? _likesCount + 1 : _likesCount - 1;
    setState(() {
      _liked = newLiked;
      _likesCount = newCount;
    });
    await ReviewService.updateLikesCount(widget.id, newCount);
  }

  String _formatDate(String isoString) {
    final dt = DateTime.tryParse(isoString)?.toLocal();
    if (dt == null) return '';
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white, foregroundColor: AppColors.gray900, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_review == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('리뷰'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.gray900,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.gray300),
              SizedBox(height: 12),
              Text('리뷰를 찾을 수 없어요', style: TextStyle(color: AppColors.gray500)),
            ],
          ),
        ),
      );
    }

    final r = _review!;
    final island = r['islands'] as Map?;
    final islandName = island?['name'] as String? ?? '';
    final author = r['author_name'] as String? ?? '여행자';
    final rating = (r['rating'] as int?) ?? 0;
    final content = r['content'] as String? ?? '';
    final createdAt = r['created_at'] as String? ?? '';
    final images = (r['images'] as List?)?.cast<String>() ?? [];
    final tags = (r['tags'] as List?)?.cast<String>() ?? [];

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: Text(
          islandName.isNotEmpty ? '$islandName 리뷰' : '리뷰',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(color: AppColors.blue100, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        author.isNotEmpty ? author[0] : '?',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.blue600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(author, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                        Row(
                          children: [
                            if (islandName.isNotEmpty) ...[
                              const Icon(Icons.location_on_rounded, size: 12, color: AppColors.gray400),
                              const SizedBox(width: 2),
                              Text(islandName, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                              const Text(' • ', style: TextStyle(color: AppColors.gray400, fontSize: 12)),
                            ],
                            Text(_formatDate(createdAt), style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (j) => Icon(
                        j < rating ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 16,
                        color: const Color(0xFFEAB308),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Images
            if (images.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: images.length == 1
                    ? CachedNetworkImage(
                        imageUrl: images[0],
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          height: 220,
                          color: AppColors.gray100,
                          child: const Icon(Icons.image_not_supported_outlined, color: AppColors.gray400, size: 40),
                        ),
                      )
                    : SizedBox(
                        height: 220,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: images[i],
                              width: 280,
                              height: 220,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                width: 280,
                                color: AppColors.gray100,
                                child: const Icon(Icons.image_not_supported_outlined, color: AppColors.gray400),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
            ],

            // Content
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('여행 후기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                  const SizedBox(height: 10),
                  Text(content, style: const TextStyle(fontSize: 14, color: AppColors.gray700, height: 1.6)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tags (only if DB has tags field)
            if (tags.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('태그', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
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
            ],

            // Like button
            GestureDetector(
              onTap: _toggleLike,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _liked ? Colors.red.shade200 : AppColors.gray200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_liked ? Icons.favorite : Icons.favorite_border, size: 22, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      '도움이 됐어요 ($_likesCount)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _liked ? Colors.red : AppColors.gray700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
