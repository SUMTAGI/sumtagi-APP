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
  }) async {
    final base = _client
        .from('community_posts')
        .select()
        .eq('post_type', type);
    final data = islandFilter != null
        ? await base
            .eq('island_name', islandFilter)
            .order('created_at', ascending: false)
            .limit(50)
        : await base.order('created_at', ascending: false).limit(50);
    return List<Map<String, dynamic>>.from(data as List);
  }

  static Future<void> createPost({
    required String title,
    required String content,
    String? islandName,
    String type = 'feed',
    String? imageUrl,
  }) async {
    if (_userId == null) return;
    await _client.from('community_posts').insert({
      'user_id': _userId,
      'title': title,
      'content': content,
      'island_name': islandName,
      'post_type': type,
      'author_name': _authorName,
      if (imageUrl != null) 'image_url': imageUrl,
    });
  }

  static Future<String> uploadImage(XFile file) async {
    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last;
    final path = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _client.storage.from('community-images').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: file.mimeType ?? 'image/jpeg'),
    );
    return _client.storage.from('community-images').getPublicUrl(path);
  }

  static Future<void> deletePost(String postId) async {
    await _client.from('community_posts').delete().eq('id', postId);
  }

  static Future<void> updateLikes(String postId, int newCount) async {
    await _client
        .from('community_posts')
        .update({'likes_count': newCount})
        .eq('id', postId);
  }

  static Future<List<Map<String, dynamic>>> getComments(String postId) async {
    final data = await _client
        .from('community_comments')
        .select()
        .eq('post_id', postId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(data as List);
  }

  static Future<void> createComment(String postId, String content) async {
    if (_userId == null) return;
    await _client.from('community_comments').insert({
      'post_id': postId,
      'user_id': _userId,
      'author_name': _authorName,
      'content': content,
    });
    final rows = await _client
        .from('community_posts')
        .select('comments_count')
        .eq('id', postId);
    if ((rows as List).isNotEmpty) {
      final cur = (rows[0]['comments_count'] as int?) ?? 0;
      await _client
          .from('community_posts')
          .update({'comments_count': cur + 1})
          .eq('id', postId);
    }
  }
}
