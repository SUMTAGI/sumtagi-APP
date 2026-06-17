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

  static Future<List<Map<String, dynamic>>> getPosts({String type = 'feed'}) async {
    final data = await _client
        .from('community_posts')
        .select()
        .eq('post_type', type)
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(data as List);
  }

  static Future<void> updateLikes(String postId, int newCount) async {
    await _client.from('community_posts').update({'likes_count': newCount}).eq('id', postId);
  }

  static Future<void> createPost({
    required String content,
    String? islandName,
    String type = 'feed',
  }) async {
    if (_userId == null) return;
    await _client.from('community_posts').insert({
      'user_id': _userId,
      'title': content.length > 30 ? '${content.substring(0, 30)}...' : content,
      'content': content,
      'island_name': islandName,
      'post_type': type,
      'author_name': _authorName,
    });
  }
}
