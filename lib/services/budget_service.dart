import 'package:supabase_flutter/supabase_flutter.dart';

class BudgetService {
  static final _client = Supabase.instance.client;
  static String? get _userId => _client.auth.currentUser?.id;

  static Future<List<Map<String, dynamic>>> getExpenses({String? tripId}) async {
    if (_userId == null) return [];
    var query = _client.from('budget_items').select().eq('user_id', _userId!);
    query = tripId != null ? query.eq('trip_id', tripId) : query.isFilter('trip_id', null);
    final data = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data as List);
  }

  static Future<void> addExpense({
    required String title,
    required int amount,
    required String category,
    String? tripId,
  }) async {
    if (_userId == null) return;
    await _client.from('budget_items').insert({
      'user_id': _userId,
      'trip_id': tripId,
      'title': title,
      'amount': amount,
      'category': category,
    });
  }

  static Future<void> deleteExpense(String id) async {
    await _client.from('budget_items').delete().eq('id', id);
  }
}
