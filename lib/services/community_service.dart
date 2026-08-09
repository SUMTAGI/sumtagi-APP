import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityService {
  static final _client = Supabase.instance.client;
  static String? get _userId => _client.auth.currentUser?.id;

  static String get _authorName {
    final meta = _client.auth.currentUser?.userMetadata;
    return meta?['nickname'] as String? ??
        _client.auth.currentUser?.email?.split('@').first ??
        '여행자';
  }

  static Future<List<Map<String, dynamic>>> getPosts({
    String type = 'feed',
    String? islandFilter,
    String? search,
    String sortBy = 'recent',
    int page = 0,
    int pageSize = 20,
  }) async {
    var query = _client.from('community_posts').select().eq('post_type', type);
    if (islandFilter != null) {
      query = query.eq('island_name', islandFilter);
    }
    if (search != null && search.trim().isNotEmpty) {
      final s = search.trim();
      query = query.or('title.ilike.%$s%,content.ilike.%$s%');
    }
    final from = page * pageSize;
    final to = from + pageSize - 1;
    final orderCol = sortBy == 'likes' ? 'likes_count' : 'created_at';
    final data = await query.order(orderCol, ascending: false).range(from, to);
    return List<Map<String, dynamic>>.from(data as List);
  }

  static Future<Map<String, dynamic>?> getPost(String postId) async {
    final data =
        await _client.from('community_posts').select().eq('id', postId);
    final rows = List<Map<String, dynamic>>.from(data as List);
    return rows.isEmpty ? null : rows.first;
  }

  static Future<Set<String>> getMyLikedPostIds(List<String> postIds) async {
    if (_userId == null || postIds.isEmpty) return {};
    final data = await _client
        .from('community_post_likes')
        .select('post_id')
        .eq('user_id', _userId!)
        .inFilter('post_id', postIds);
    return List<Map<String, dynamic>>.from(data as List)
        .map((e) => e['post_id'] as String)
        .toSet();
  }

  static Future<void> createPost({
    required String title,
    required String content,
    String? islandName,
    String type = 'feed',
    List<String> images = const [],
  }) async {
    if (_userId == null) return;
    await _client.from('community_posts').insert({
      'user_id': _userId,
      'title': title,
      'content': content,
      'island_name': islandName,
      'post_type': type,
      'author_name': _authorName,
      'images': images,
    });
  }

  static Future<void> updatePost({
    required String postId,
    required String title,
    required String content,
    String? islandName,
    List<String> images = const [],
  }) async {
    await _client.from('community_posts').update({
      'title': title,
      'content': content,
      'island_name': islandName,
      'images': images,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', postId);
  }

  static Future<String> uploadImage(XFile file) async {
    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last;
    final path =
        '${DateTime.now().millisecondsSinceEpoch}_${file.name.hashCode}.$ext';
    await _client.storage.from('community-images').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: file.mimeType ?? 'image/jpeg'),
    );
    return _client.storage.from('community-images').getPublicUrl(path);
  }

  static Future<List<String>> uploadImages(List<XFile> files) async {
    final urls = <String>[];
    for (final file in files) {
      urls.add(await uploadImage(file));
    }
    return urls;
  }

  static Future<void> deletePost(String postId) async {
    await _client.from('community_posts').delete().eq('id', postId);
  }

  /// 좋아요 상태를 토글하고 새 상태(liked 여부)를 반환한다.
  /// likes_count는 DB 트리거가 자동으로 갱신한다.
  static Future<bool> toggleLike(String postId, bool currentlyLiked) async {
    if (_userId == null) return currentlyLiked;
    if (currentlyLiked) {
      await _client
          .from('community_post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', _userId!);
      return false;
    } else {
      await _client.from('community_post_likes').upsert({
        'post_id': postId,
        'user_id': _userId,
      });
      return true;
    }
  }

  static Future<List<Map<String, dynamic>>> getComments(String postId) async {
    final data = await _client
        .from('community_comments')
        .select()
        .eq('post_id', postId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(data as List);
  }

  static Future<void> createComment(
    String postId,
    String content, {
    String? parentId,
  }) async {
    if (_userId == null) return;
    await _client.from('community_comments').insert({
      'post_id': postId,
      'user_id': _userId,
      'author_name': _authorName,
      'content': content,
      'parent_id': parentId,
    });
  }

  static Future<void> updateComment(String commentId, String content) async {
    await _client.from('community_comments').update({
      'content': content,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', commentId);
  }

  static Future<void> deleteComment(String commentId) async {
    await _client.from('community_comments').delete().eq('id', commentId);
  }

  static Future<void> reportPost(String postId, String reason) async {
    if (_userId == null) return;
    await _client.from('community_reports').insert({
      'post_id': postId,
      'reporter_id': _userId,
      'reason': reason,
    });
  }

  static Future<void> reportComment(String commentId, String reason) async {
    if (_userId == null) return;
    await _client.from('community_reports').insert({
      'comment_id': commentId,
      'reporter_id': _userId,
      'reason': reason,
    });
  }
}
