import 'package:flutter/material.dart';
import '../../services/community_service.dart';
import '../../theme/app_colors.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _tab = 0;
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _qna = [];
  bool _isLoading = true;
  final Set<String> _likedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final feeds = await CommunityService.getPosts(type: 'feed');
      final qnas = await CommunityService.getPosts(type: 'qna');
      if (mounted) setState(() { _posts = feeds; _qna = qnas; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLike(Map<String, dynamic> post) async {
    final id = post['id'] as String;
    final isLiked = _likedIds.contains(id);
    final current = (post['likes_count'] as int?) ?? 0;
    final newCount = isLiked ? current - 1 : current + 1;
    setState(() {
      if (isLiked) {
        _likedIds.remove(id);
      } else {
        _likedIds.add(id);
      }
      final idx = _posts.indexWhere((p) => p['id'] == id);
      if (idx != -1) _posts[idx] = {..._posts[idx], 'likes_count': newCount};
    });
    await CommunityService.updateLikes(id, newCount);
  }

  Future<void> _showWriteDialog() async {
    final contentCtrl = TextEditingController();
    final islandCtrl = TextEditingController();
    final isQna = _tab == 1;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isQna ? '질문하기' : '게시글 작성', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (!isQna) ...[
              TextField(
                controller: islandCtrl,
                decoration: InputDecoration(
                  labelText: '섬 이름 (선택)',
                  hintText: '예: 백령도',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: contentCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: isQna ? '질문 내용을 입력하세요' : '여행 중 느낀 점을 공유하세요',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (contentCtrl.text.isEmpty) return;
                  await CommunityService.createPost(
                    content: contentCtrl.text,
                    islandName: islandCtrl.text.isNotEmpty ? islandCtrl.text : null,
                    type: isQna ? 'qna' : 'feed',
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue600, foregroundColor: Colors.white,
                  elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('등록하기', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _congestionColor(String c) {
    if (c == '여유') return const Color(0xFFDCFCE7);
    if (c == '보통') return const Color(0xFFFEF9C3);
    return const Color(0xFFFEE2E2);
  }

  Color _congestionTextColor(String c) {
    if (c == '여유') return const Color(0xFF15803D);
    if (c == '보통') return const Color(0xFFCA8A04);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('커뮤니티', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text('여행자들과 소통하세요', style: TextStyle(fontSize: 11, color: AppColors.gray500)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            color: Colors.white,
            child: Row(
              children: [
                _TabBtn(label: '실시간 피드', selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
                const SizedBox(width: 8),
                _TabBtn(label: '질문 & 답변', selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _tab == 0 ? _buildFeed() : _buildQnA(),
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.gray200))),
            child: ElevatedButton.icon(
              onPressed: _showWriteDialog,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: Text(_tab == 0 ? '게시글 작성' : '질문하기', style: const TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue600, foregroundColor: Colors.white,
                elevation: 0, minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeed() {
    if (_posts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 64, color: AppColors.gray300),
            SizedBox(height: 16),
            Text('아직 게시글이 없어요', style: TextStyle(fontSize: 16, color: AppColors.gray500)),
            SizedBox(height: 8),
            Text('첫 번째 게시글을 작성해보세요!', style: TextStyle(fontSize: 13, color: AppColors.gray400)),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: _posts.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.gray200),
      itemBuilder: (context, i) {
        final post = _posts[i];
        final nickname = post['author_name'] as String? ?? '여행자';
        final islandName = post['island_name'] as String?;
        final isLiked = _likedIds.contains(post['id'] as String);
        final timeAgo = _timeAgo(post['created_at'] as String);

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.blue100, shape: BoxShape.circle, border: Border.all(color: AppColors.blue200)),
                    child: const Icon(Icons.person_rounded, size: 22, color: AppColors.blue600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nickname, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                        Row(
                          children: [
                            if (islandName != null) ...[
                              const Icon(Icons.location_on_rounded, size: 12, color: AppColors.gray500),
                              const SizedBox(width: 2),
                              Text(islandName, style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
                              const Text(' • ', style: TextStyle(fontSize: 11, color: AppColors.gray400)),
                            ],
                            Text(timeAgo, style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(post['content'] as String? ?? '', style: const TextStyle(fontSize: 14, color: AppColors.gray900, height: 1.5)),
              const SizedBox(height: 12),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggleLike(post),
                    child: Row(
                      children: [
                        Icon(isLiked ? Icons.favorite : Icons.favorite_border, size: 20, color: isLiked ? Colors.red : AppColors.gray500),
                        const SizedBox(width: 6),
                        Text('${(post['likes_count'] as int?) ?? 0}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isLiked ? Colors.red : AppColors.gray700)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('링크가 복사됐어요'))),
                    child: const Icon(Icons.share_outlined, size: 18, color: AppColors.gray500),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQnA() {
    if (_qna.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help_outline_rounded, size: 64, color: AppColors.gray300),
            SizedBox(height: 16),
            Text('아직 질문이 없어요', style: TextStyle(fontSize: 16, color: AppColors.gray500)),
            SizedBox(height: 8),
            Text('궁금한 점을 질문해보세요!', style: TextStyle(fontSize: 13, color: AppColors.gray400)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _qna.length,
      itemBuilder: (context, i) {
        final item = _qna[i];
        final nickname = item['author_name'] as String? ?? '여행자';
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
          padding: const EdgeInsets.all(16),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['content'] as String? ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                        const SizedBox(height: 2),
                        Text('$nickname • ${_timeAgo(item['created_at'] as String)}', style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Row(children: [
                    const Icon(Icons.favorite_border, size: 14, color: AppColors.gray500),
                    const SizedBox(width: 4),
                    Text('${(item['likes_count'] as int?) ?? 0}', style: const TextStyle(fontSize: 12, color: AppColors.gray600)),
                  ]),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _timeAgo(String isoString) {
    final dt = DateTime.tryParse(isoString)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${dt.month}/${dt.day}';
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue600 : AppColors.gray100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.gray700)),
      ),
    );
  }
}
