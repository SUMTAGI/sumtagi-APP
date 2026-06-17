import 'package:supabase_flutter/supabase_flutter.dart';

class BudgetService {
  static final _client = Supabase.instance.client;
  static String? get _userId => _client.auth.currentUser?.id;

  static Future<List<Map<String, dynamic>>> getExpenses() async {
    if (_userId == null) return [];
    final data = await _client
        .from('budget_items')
        .select()
        .eq('user_id', _userId!)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data as List);
  }

  static Future<void> addExpense({
    required String title,
    required int amount,
    required String category,
  }) async {
    if (_userId == null) return;
    await _client.from('budget_items').insert({
      'user_id': _userId,
      'title': title,
      'amount': amount,
      'category': category,
    });
  }

  static Future<void> deleteExpense(String id) async {
    await _client.from('budget_items').delete().eq('id', id);
  }
}
