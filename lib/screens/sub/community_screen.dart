import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/community_service.dart';
import '../../theme/app_colors.dart';

const _islands = ['강화도', '영흥도', '자월도', '덕적도', '백령도', '대청도', '연평도'];

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _tab = 0;
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _qna = [];
  bool _isLoading = true;
  String? _islandFilter;

  String? get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final feeds = await CommunityService.getPosts(
          type: 'feed', islandFilter: _islandFilter);
      final qnas = await CommunityService.getPosts(
          type: 'qna', islandFilter: _islandFilter);
      if (mounted) {
        setState(() {
          _posts = feeds;
          _qna = qnas;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPosts = _tab == 0 ? _posts : _qna;
    final type = _tab == 0 ? 'feed' : 'qna';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('리뷰 & Q&A',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text('섬 여행 리뷰와 질문을 공유하세요',
                style: TextStyle(fontSize: 13, color: AppColors.gray500)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
        titleSpacing: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: () =>
                  context.push('/community-write?type=$type').then((_) => _load()),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.blue600,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('글쓰기',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(88),
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(children: [
                    _TabBtn(
                        label: '리뷰',
                        selected: _tab == 0,
                        onTap: () => setState(() => _tab = 0)),
                    const SizedBox(width: 8),
                    _TabBtn(
                        label: '질문 & 답변',
                        selected: _tab == 1,
                        onTap: () => setState(() => _tab = 1)),
                  ]),
                ),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(
                        left: 16, right: 16, bottom: 8),
                    children: [
                      _IslandChip(
                        label: '전체',
                        selected: _islandFilter == null,
                        onTap: () => setState(() {
                          _islandFilter = null;
                          _load();
                        }),
                      ),
                      ..._islands.map((island) => Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _IslandChip(
                              label: island,
                              selected: _islandFilter == island,
                              onTap: () {
                                setState(() => _islandFilter =
                                    _islandFilter == island ? null : island);
                                _load();
                              },
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : currentPosts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded,
                          size: 64, color: AppColors.gray200),
                      const SizedBox(height: 16),
                      Text(
                        _tab == 0 ? '첫 리뷰를 남겨보세요' : '첫 질문을 남겨보세요',
                        style: const TextStyle(fontSize: 16, color: AppColors.gray500),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context
                            .push('/community-write?type=$type')
                            .then((_) => _load()),
                        child: Text(_tab == 0 ? '첫 번째 리뷰 남기기' : '질문하기'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: currentPosts.length,
                    itemBuilder: (context, i) => _PostCard(
                      post: currentPosts[i],
                      isQna: _tab == 1,
                      currentUserId: _currentUserId,
                      onDeleted: _load,
                    ),
                  ),
                ),
    );
  }
}

class _PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final bool isQna;
  final String? currentUserId;
  final VoidCallback onDeleted;

  const _PostCard({
    required this.post,
    this.isQna = false,
    required this.currentUserId,
    required this.onDeleted,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _isExpanded = false;
  List<Map<String, dynamic>> _comments = [];
  bool _loadingComments = false;
  final _commentCtrl = TextEditingController();
  bool _liked = false;
  late int _likesCount;
  late int _commentsCount;

  @override
  void initState() {
    super.initState();
    _likesCount = (widget.post['likes_count'] as int?) ?? 0;
    _commentsCount = (widget.post['comments_count'] as int?) ?? 0;
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleComments() async {
    if (_isExpanded) {
      setState(() => _isExpanded = false);
      return;
    }
    setState(() {
      _isExpanded = true;
      _loadingComments = true;
    });
    final data =
        await CommunityService.getComments(widget.post['id'] as String);
    if (mounted) {
      setState(() {
        _comments = data;
        _loadingComments = false;
      });
    }
  }

  Future<void> _addComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    _commentCtrl.clear();
    await CommunityService.createComment(
        widget.post['id'] as String, text);
    final data =
        await CommunityService.getComments(widget.post['id'] as String);
    if (mounted) {
      setState(() {
        _comments = data;
        _commentsCount++;
      });
    }
  }

  Future<void> _toggleLike() async {
    final newCount = _liked ? _likesCount - 1 : _likesCount + 1;
    setState(() {
      _liked = !_liked;
      _likesCount = newCount;
    });
    await CommunityService.updateLikes(
        widget.post['id'] as String, newCount);
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('이 게시글을 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await CommunityService.deletePost(widget.post['id'] as String);
    widget.onDeleted();
  }

  String _timeAgo(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${dt.month}/${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final authorName = post['author_name'] as String? ?? '여행자';
    final islandName = post['island_name'] as String?;
    final content = post['content'] as String? ?? '';
    final title = post['title'] as String?;
    final imageUrl = post['image_url'] as String?;
    final createdAt = post['created_at'] as String? ?? '';
    final isMyPost = widget.currentUserId != null &&
        post['user_id'] == widget.currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                          color: AppColors.blue100,
                          shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          authorName.isNotEmpty ? authorName[0] : '?',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.blue600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(authorName,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.gray900)),
                            const SizedBox(width: 6),
                            if (islandName != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                    color: AppColors.blue50,
                                    borderRadius:
                                        BorderRadius.circular(12)),
                                child: Row(children: [
                                  const Icon(
                                      Icons.location_on_rounded,
                                      size: 11,
                                      color: AppColors.blue600),
                                  const SizedBox(width: 2),
                                  Text(islandName,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.blue600,
                                          fontWeight: FontWeight.w500)),
                                ]),
                              ),
                            if (widget.isQna) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius:
                                        BorderRadius.circular(8)),
                                child: const Text('Q',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFD97706))),
                              ),
                            ],
                          ]),
                          Text(_timeAgo(createdAt),
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.gray400)),
                        ],
                      ),
                    ),
                    if (isMyPost)
                      GestureDetector(
                        onTap: _deletePost,
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.delete_outline_rounded,
                              size: 20, color: AppColors.gray300),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (title != null &&
                    title.isNotEmpty &&
                    title != content) ...[
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray900)),
                  const SizedBox(height: 4),
                ],
                Text(content,
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.gray700,
                        height: 1.5)),
                if (imageUrl != null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _toggleLike,
                      child: Row(children: [
                        Icon(
                          _liked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 20,
                          color: _liked ? Colors.red : AppColors.gray500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_likesCount',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _liked ? Colors.red : AppColors.gray600,
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: _toggleComments,
                      child: Row(children: [
                        const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 18,
                            color: AppColors.gray500),
                        const SizedBox(width: 4),
                        Text(
                          widget.isQna
                              ? '답변 $_commentsCount개'
                              : '댓글 $_commentsCount',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.gray600),
                        ),
                      ]),
                    ),
                    const Spacer(),
                    const Icon(Icons.share_outlined,
                        size: 18, color: AppColors.gray400),
                  ],
                ),
              ],
            ),
          ),
          if (_isExpanded)
            Container(
              color: const Color(0xFFF9FAFB),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_loadingComments)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (_comments.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          widget.isQna
                              ? '첫 답변을 남겨보세요'
                              : '첫 댓글을 남겨보세요',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.gray400),
                        ),
                      ),
                    )
                  else
                    ..._comments.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                    color: AppColors.blue100,
                                    shape: BoxShape.circle),
                                child: Center(
                                  child: Text(
                                    (c['author_name'] as String? ?? '?')
                                            .isNotEmpty
                                        ? (c['author_name'] as String)[0]
                                        : '?',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.blue600),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Text(
                                          c['author_name'] as String? ??
                                              '여행자',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.gray900),
                                        ),
                                        if (widget.isQna) ...[
                                          const SizedBox(width: 4),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 1),
                                            decoration: BoxDecoration(
                                                color: const Color(
                                                    0xFFDCFCE7),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        6)),
                                            child: const Text('A',
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: Color(
                                                        0xFF16A34A))),
                                          ),
                                        ],
                                        const SizedBox(width: 6),
                                        Text(
                                          _timeAgo(c['created_at']
                                                  as String? ??
                                              ''),
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.gray400),
                                        ),
                                      ]),
                                      const SizedBox(height: 3),
                                      Text(
                                        c['content'] as String? ?? '',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.gray700),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentCtrl,
                          decoration: InputDecoration(
                            hintText: widget.isQna
                                ? '답변을 입력하세요'
                                : '댓글을 입력하세요',
                            hintStyle: const TextStyle(
                                fontSize: 13, color: AppColors.gray400),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                  color: AppColors.gray200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                  color: AppColors.gray200),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 13),
                          onSubmitted: (_) => _addComment(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _addComment,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                              color: AppColors.blue600,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.send_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabBtn(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue600 : AppColors.gray100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppColors.gray700)),
      ),
    );
  }
}

class _IslandChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _IslandChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue600 : AppColors.gray100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppColors.gray600)),
      ),
    );
  }
}
