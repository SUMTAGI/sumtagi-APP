import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final _client = Supabase.instance.client;
  static String? get _userId => _client.auth.currentUser?.id;
  static RealtimeChannel? _channel;

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

  static Future<int> getUnreadCount() async {
    if (_userId == null) return 0;
    final res = await _client
        .from('notifications')
        .select()
        .eq('user_id', _userId!)
        .eq('is_read', false)
        .count(CountOption.exact);
    return res.count;
  }

  static void subscribe(void Function(Map<String, dynamic> notification) onNew) {
    final userId = _userId;
    if (userId == null) return;
    _channel?.unsubscribe();
    _channel = _client
        .channel('notifications_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => onNew(payload.newRecord),
        )
        .subscribe();
  }

  static void unsubscribe() {
    _channel?.unsubscribe();
    _channel = null;
  }

  static Future<void> markRead(String id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  static Future<void> markAllRead() async {
    if (_userId == null) return;
    await _client.from('notifications').update({'is_read': true}).eq('user_id', _userId!);
  }
}
