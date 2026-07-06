import 'package:supabase_flutter/supabase_flutter.dart';

class ChecklistService {
  static final _client = Supabase.instance.client;
  static String? get _userId => _client.auth.currentUser?.id;

  static const _defaults = [
    {'title': '신분증', 'category': '여행 서류'},
    {'title': '예약 확인서', 'category': '여행 서류'},
    {'title': '여벌 옷', 'category': '짐'},
    {'title': '세면도구', 'category': '짐'},
    {'title': '자외선차단제', 'category': '짐'},
    {'title': '비상약', 'category': '편의'},
    {'title': '현금', 'category': '편의'},
    {'title': '충전기', 'category': '편의'},
  ];

  static Future<List<Map<String, dynamic>>> getItems({String? tripId}) async {
    if (_userId == null) return [];
    var query = _client.from('checklist_items').select().eq('user_id', _userId!);
    query = tripId != null ? query.eq('trip_id', tripId) : query.isFilter('trip_id', null);
    final data = await query.order('order_index');
    final items = List<Map<String, dynamic>>.from(data as List);
    if (items.isEmpty) {
      await _seedDefaults(tripId: tripId);
      return getItems(tripId: tripId);
    }
    return items;
  }

  static Future<int> getProgress({String? tripId}) async {
    final items = await getItems(tripId: tripId);
    if (items.isEmpty) return 0;
    final done = items.where((i) => i['is_checked'] == true).length;
    return ((done / items.length) * 100).round();
  }

  static Future<void> _seedDefaults({String? tripId}) async {
    if (_userId == null) return;
    final rows = _defaults.asMap().entries.map((e) => {
      'user_id': _userId,
      'trip_id': tripId,
      'title': e.value['title'],
      'category': e.value['category'],
      'is_checked': false,
      'order_index': e.key,
    }).toList();
    await _client.from('checklist_items').insert(rows);
  }

  static Future<void> toggleItem(String id, bool newValue) async {
    await _client.from('checklist_items').update({'is_checked': newValue}).eq('id', id);
  }

  static Future<void> addItem({required String title, String category = '기타', String? tripId}) async {
    if (_userId == null) return;
    var countQuery = _client.from('checklist_items').select('order_index').eq('user_id', _userId!);
    countQuery = tripId != null ? countQuery.eq('trip_id', tripId) : countQuery.isFilter('trip_id', null);
    final data = await countQuery.order('order_index', ascending: false).limit(1);
    final maxIdx = (data as List).isNotEmpty ? ((data.first['order_index'] as int?) ?? 0) + 1 : 0;
    await _client.from('checklist_items').insert({
      'user_id': _userId,
      'trip_id': tripId,
      'title': title,
      'category': category,
      'is_checked': false,
      'order_index': maxIdx,
    });
  }

  static Future<void> deleteItem(String id) async {
    await _client.from('checklist_items').delete().eq('id', id);
  }
}
