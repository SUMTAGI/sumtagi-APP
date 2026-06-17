import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final _client = Supabase.instance.client;
  static String? get _userId => _client.auth.currentUser?.id;

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    if (_userId == null) return [];
    final data = await _client
        .from('notifications')
        .select()
        .eq('user_id', _userId!)
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(data as List);
  }

  static Future<void> markRead(String id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  static Future<void> markAllRead() async {
    if (_userId == null) return;
    await _client.from('notifications').update({'is_read': true}).eq('user_id', _userId!);
  }
}
