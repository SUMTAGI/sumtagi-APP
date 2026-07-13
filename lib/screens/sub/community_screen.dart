import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/community_service.dart';
import '../../theme/app_colors.dart';

const _islands = ['강화도', '영흥도', '자월도', '덕적도', '백령도', '대청도', '연평도'];
const _reportReasons = ['스팸/광고', '욕설/혐오 발언', '음란물', '거짓 정보', '기타'];
const _pageSize = 20;

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _tab = 0;
  List<Map<String, dynamic>> _posts = [];
  Set<String> _likedPostIds = {};
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _loadError = false;
  int _page = 0;
  String? _islandFilter;
  String _sortBy = 'recent';
  final _searchCtrl = TextEditingController();
  String _search = '';
  Timer? _searchDebounce;
  final _scrollController = ScrollController();

  String? get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id;
  String get _type => _tab == 0 ? 'feed' : 'qna';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _isLoading) return;
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = false;
      _page = 0;
      _hasMore = true;
    });
    try {
      final data = await CommunityService.getPosts(
        type: _type,
        islandFilter: _islandFilter,
        search: _search.isEmpty ? null : _search,
        sortBy: _sortBy,
        page: 0,
        pageSize: _pageSize,
      );
      final liked = await CommunityService.getMyLikedPostIds(
          data.map((p) => p['id'] as String).toList());
      if (mounted) {
        setState(() {
          _posts = data;
          _likedPostIds = liked;
          _hasMore = data.length == _pageSize;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = true;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _page + 1;
      final data = await CommunityService.getPosts(
        type: _type,
        islandFilter: _islandFilter,
        search: _search.isEmpty ? null : _search,
        sortBy: _sortBy,
        page: nextPage,
        pageSize: _pageSize,
      );
      final liked = await CommunityService.getMyLikedPostIds(
          data.map((p) => p['id'] as String).toList());
      if (mounted) {
        setState(() {
          _posts = [..._posts, ...data];
          _likedPostIds = {..._likedPostIds, ...liked};
          _page = nextPage;
          _hasMore = data.length == _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _search = value.trim());
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: () => context
                  .push('/community-write?type=$_type')
                  .then((_) => _load()),
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
          preferredSize: const Size.fromHeight(150),
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: '리뷰/질문 검색',
                      hintStyle: const TextStyle(
                          fontSize: 13, color: AppColors.gray400),
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 20, color: AppColors.gray400),
                      suffixIcon: _searchCtrl.text.isEmpty
                          ? null
                          : GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                _onSearchChanged('');
                              },
                              child: const Icon(Icons.close_rounded,
                                  size: 18, color: AppColors.gray400),
                            ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.gray200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.gray200),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        _TabBtn(
                            label: '리뷰',
                            selected: _tab == 0,
                            onTap: () {
                              setState(() => _tab = 0);
                              _load();
                            }),
                        const SizedBox(width: 8),
                        _TabBtn(
                            label: '질문 & 답변',
                            selected: _tab == 1,
                            onTap: () {
                              setState(() => _tab = 1);
                              _load();
                            }),
                      ]),
                      Row(children: [
                        _SortChip(
                          label: '최신순',
                          selected: _sortBy == 'recent',
                          onTap: () {
                            if (_sortBy == 'recent') return;
                            setState(() => _sortBy = 'recent');
                            _load();
                          },
                        ),
                        const SizedBox(width: 6),
                        _SortChip(
                          label: '인기순',
                          selected: _sortBy == 'likes',
                          onTap: () {
                            if (_sortBy == 'likes') return;
                            setState(() => _sortBy = 'likes');
                            _load();
                          },
                        ),
                      ]),
                    ],
                  ),
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
                        onTap: () {
                          setState(() => _islandFilter = null);
                          _load();
                        },
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
          : _loadError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          size: 56, color: AppColors.gray300),
                      const SizedBox(height: 12),
                      const Text('불러오는 데 실패했어요',
                          style: TextStyle(
                              fontSize: 15, color: AppColors.gray500)),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _load,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : _posts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded,
                              size: 64, color: AppColors.gray200),
                          const SizedBox(height: 16),
                          Text(
                            _search.isNotEmpty
                                ? '검색 결과가 없어요'
                                : (_tab == 0 ? '첫 리뷰를 남겨보세요' : '첫 질문을 남겨보세요'),
                            style: const TextStyle(
                                fontSize: 16, color: AppColors.gray500),
                          ),
                          const SizedBox(height: 8),
                          if (_search.isEmpty)
                            TextButton(
                              onPressed: () => context
                                  .push('/community-write?type=$_type')
                                  .then((_) => _load()),
                              child: Text(_tab == 0 ? '첫 번째 리뷰 남기기' : '질문하기'),
                            ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _posts.length + 1,
                        itemBuilder: (context, i) {
                          if (i == _posts.length) {
                            return SizedBox(
                              height: 48,
                              child: _isLoadingMore
                                  ? const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    )
                                  : const SizedBox(),
                            );
                          }
                          final post = _posts[i];
                          return _PostCard(
                            post: post,
                            isQna: _tab == 1,
                            currentUserId: _currentUserId,
                            isLiked: _likedPostIds.contains(post['id']),
                            onChanged: _load,
                          );
                        },
                      ),
                    ),
    );
  }
}

class _PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final bool isQna;
  final String? currentUserId;
  final bool isLiked;
  final VoidCallback onChanged;

  const _PostCard({
    required this.post,
    this.isQna = false,
    required this.currentUserId,
    required this.isLiked,
    required this.onChanged,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _isExpanded = false;
  List<Map<String, dynamic>> _comments = [];
  bool _loadingComments = false;
  bool _commentsError = false;
  final _commentCtrl = TextEditingController();
  late bool _liked;
  late int _likesCount;
  late int _commentsCount;
  String? _replyToId;
  String? _replyToName;

  @override
  void initState() {
    super.initState();
    _liked = widget.isLiked;
    _likesCount = (widget.post['likes_count'] as int?) ?? 0;
    _commentsCount = (widget.post['comments_count'] as int?) ?? 0;
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    await Clipboard.setData(
        const ClipboardData(text: 'https://sumtagi-web.vercel.app/community'));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('링크가 복사됐어요')));
  }

  Future<void> _toggleComments() async {
    if (_isExpanded) {
      setState(() => _isExpanded = false);
      return;
    }
    setState(() {
      _isExpanded = true;
      _loadingComments = true;
      _commentsError = false;
    });
    try {
      final data =
          await CommunityService.getComments(widget.post['id'] as String);
      if (mounted) {
        setState(() {
          _comments = data;
          _loadingComments = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingComments = false;
          _commentsError = true;
        });
      }
    }
  }

  Future<void> _addComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    _commentCtrl.clear();
    final replyTo = _replyToId;
    setState(() {
      _replyToId = null;
      _replyToName = null;
    });
    try {
      await CommunityService.createComment(
          widget.post['id'] as String, text,
          parentId: replyTo);
      final data =
          await CommunityService.getComments(widget.post['id'] as String);
      if (mounted) {
        setState(() {
          _comments = data;
          _commentsCount++;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('댓글 등록에 실패했어요')));
      }
    }
  }

  Future<void> _editComment(Map<String, dynamic> comment) async {
    final ctrl =
        TextEditingController(text: comment['content'] as String? ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('댓글 수정'),
        content: TextField(controller: ctrl, maxLines: 4, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('저장')),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    await CommunityService.updateComment(comment['id'] as String, result);
    final data =
        await CommunityService.getComments(widget.post['id'] as String);
    if (mounted) setState(() => _comments = data);
  }

  Future<void> _deleteComment(Map<String, dynamic> comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('이 댓글을 삭제할까요?'),
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
    await CommunityService.deleteComment(comment['id'] as String);
    final data =
        await CommunityService.getComments(widget.post['id'] as String);
    if (mounted) {
      setState(() {
        _comments = data;
        _commentsCount = _commentsCount > 0 ? _commentsCount - 1 : 0;
      });
    }
  }

  Future<void> _toggleLike() async {
    final prevLiked = _liked;
    final prevCount = _likesCount;
    setState(() {
      _liked = !_liked;
      _likesCount = _liked ? _likesCount + 1 : _likesCount - 1;
    });
    try {
      await CommunityService.toggleLike(widget.post['id'] as String, prevLiked);
    } catch (_) {
      if (mounted) {
        setState(() {
          _liked = prevLiked;
          _likesCount = prevCount;
        });
      }
    }
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
    widget.onChanged();
  }

  Future<void> _editPost() async {
    final type = widget.isQna ? 'qna' : 'feed';
    await context
        .push('/community-write?type=$type&editId=${widget.post['id']}');
    widget.onChanged();
  }

  Future<void> _showReportSheet() async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('신고 사유를 선택해주세요',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            ..._reportReasons.map((r) => ListTile(
                  title: Text(r),
                  onTap: () => Navigator.pop(ctx, r),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (reason == null) return;
    await CommunityService.reportPost(widget.post['id'] as String, reason);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('신고했어요. 검토 후 조치할게요')));
    }
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

  List<String> _images(Map<String, dynamic> post) {
    final raw = post['images'];
    if (raw is List && raw.isNotEmpty) {
      return raw.whereType<String>().toList();
    }
    if (post['image_url'] is String) return [post['image_url'] as String];
    return [];
  }

  Widget _buildAvatar(String name, {double size = 38}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
          color: AppColors.blue100, shape: BoxShape.circle),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0] : '?',
          style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
              color: AppColors.blue600),
        ),
      ),
    );
  }

  Widget _buildCommentTile(Map<String, dynamic> c, {bool isReply = false}) {
    final isMine = widget.currentUserId != null &&
        c['user_id'] == widget.currentUserId;
    final name = c['author_name'] as String? ?? '여행자';
    return Padding(
      padding: EdgeInsets.only(bottom: 10, left: isReply ? 32 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(name, size: isReply ? 24 : 28),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray900)),
                    if (widget.isQna && !isReply) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6)),
                        child: const Text('A',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16A34A))),
                      ),
                    ],
                    const SizedBox(width: 6),
                    Text(_timeAgo(c['created_at'] as String? ?? ''),
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.gray400)),
                  ]),
                  const SizedBox(height: 3),
                  Text(c['content'] as String? ?? '',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.gray700)),
                  const SizedBox(height: 4),
                  Row(children: [
                    if (!isReply)
                      GestureDetector(
                        onTap: () => setState(() {
                          _replyToId = c['id'] as String;
                          _replyToName = name;
                        }),
                        child: const Text('답글',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.gray400,
                                fontWeight: FontWeight.w500)),
                      ),
                    if (isMine) ...[
                      if (!isReply) const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _editComment(c),
                        child: const Text('수정',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.gray400)),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _deleteComment(c),
                        child: const Text('삭제',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.gray400)),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final authorName = post['author_name'] as String? ?? '여행자';
    final islandName = post['island_name'] as String?;
    final content = post['content'] as String? ?? '';
    final title = post['title'] as String?;
    final images = _images(post);
    final createdAt = post['created_at'] as String? ?? '';
    final isMyPost = widget.currentUserId != null &&
        post['user_id'] == widget.currentUserId;

    final topLevelComments =
        _comments.where((c) => c['parent_id'] == null).toList();
    List<Map<String, dynamic>> repliesOf(String id) =>
        _comments.where((c) => c['parent_id'] == id).toList();

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
                    _buildAvatar(authorName),
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
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_horiz_rounded,
                          size: 20, color: AppColors.gray400),
                      onSelected: (v) {
                        if (v == 'edit') _editPost();
                        if (v == 'delete') _deletePost();
                        if (v == 'report') _showReportSheet();
                      },
                      itemBuilder: (ctx) => isMyPost
                          ? [
                              const PopupMenuItem(
                                  value: 'edit', child: Text('수정')),
                              const PopupMenuItem(
                                  value: 'delete', child: Text('삭제')),
                            ]
                          : [
                              const PopupMenuItem(
                                  value: 'report', child: Text('신고하기')),
                            ],
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
                if (images.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  if (images.length == 1)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        images[0],
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
                    )
                  else
                    SizedBox(
                      height: 200,
                      child: PageView.builder(
                        controller: PageController(viewportFraction: 0.92),
                        itemCount: images.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              images[i],
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(),
                            ),
                          ),
                        ),
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
                    GestureDetector(
                      onTap: _share,
                      child: const Icon(Icons.share_outlined,
                          size: 18, color: AppColors.gray400),
                    ),
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
                  else if (_commentsError)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(children: [
                          const Text('댓글을 불러오지 못했어요',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.gray400)),
                          TextButton(
                            onPressed: _toggleComments,
                            child: const Text('다시 시도'),
                          ),
                        ]),
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
                    ...topLevelComments.expand((c) => [
                          _buildCommentTile(c),
                          ...repliesOf(c['id'] as String)
                              .map((r) => _buildCommentTile(r, isReply: true)),
                        ]),
                  if (_replyToId != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(children: [
                        Text('$_replyToName님에게 답글 남기는 중',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.blue600)),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => setState(() {
                            _replyToId = null;
                            _replyToName = null;
                          }),
                          child: const Icon(Icons.close,
                              size: 14, color: AppColors.gray400),
                        ),
                      ]),
                    ),
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

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SortChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue50 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? AppColors.blue200 : AppColors.gray200),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? AppColors.blue600 : AppColors.gray500)),
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
