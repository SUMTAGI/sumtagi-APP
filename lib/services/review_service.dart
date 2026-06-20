import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewService {
  static final _client = Supabase.instance.client;
  static String? get _userId => _client.auth.currentUser?.id;

  static String get _authorName {
    final meta = _client.auth.currentUser?.userMetadata;
    return (meta?['nickname'] as String?) ??
        (_client.auth.currentUser?.email?.split('@').first ?? '여행자');
  }

  static Future<int> getMyReviewCount() async {
    if (_userId == null) return 0;
    final res = await _client
        .from('reviews')
        .select()
        .eq('user_id', _userId!)
        .count(CountOption.exact);
    return res.count;
  }

  static Future<List<Map<String, dynamic>>> getReviews({String? islandId}) async {
    var query = _client
        .from('reviews')
        .select('*, islands(name)');
    if (islandId != null) {
      query = query.eq('island_id', islandId);
    }
    final data = await query.order('created_at', ascending: false).limit(50);
    return List<Map<String, dynamic>>.from(data as List);
  }

  static Future<List<Map<String, dynamic>>> getPopularReviews() async {
    final data = await _client
        .from('reviews')
        .select('id, rating, content, images, likes_count, author_name, islands(name, image)')
        .order('likes_count', ascending: false)
        .limit(3);
    return List<Map<String, dynamic>>.from(data as List);
  }

  static Future<void> createReview({
    required String islandId,
    required int rating,
    required String content,
  }) async {
    if (_userId == null) return;
    await _client.from('reviews').insert({
      'user_id': _userId,
      'island_id': islandId,
      'rating': rating,
      'content': content,
      'author_name': _authorName,
    });
  }

  static Future<void> deleteReview(String id) async {
    await _client.from('reviews').delete().eq('id', id);
  }
}
