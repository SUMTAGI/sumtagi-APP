import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewService {
  static final _client = Supabase.instance.client;
  static String? get _userId => _client.auth.currentUser?.id;

  static Future<List<Map<String, dynamic>>> getReviews({String? islandId}) async {
    var query = _client
        .from('reviews')
        .select('*, profiles(nickname), islands(name)');
    if (islandId != null) {
      query = query.eq('island_id', islandId);
    }
    final data = await query.order('created_at', ascending: false).limit(50);
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
    });
  }

  static Future<void> deleteReview(String id) async {
    await _client.from('reviews').delete().eq('id', id);
  }
}
