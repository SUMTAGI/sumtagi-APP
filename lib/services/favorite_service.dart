import 'package:supabase_flutter/supabase_flutter.dart';
import 'island_service.dart';

class FavoriteService {
  static final _client = Supabase.instance.client;

  static String? get _userId => _client.auth.currentUser?.id;

  static Future<bool> isFavorited(String islandId) async {
    if (_userId == null) return false;
    final data = await _client
        .from('favorites')
        .select()
        .eq('user_id', _userId!)
        .eq('island_id', islandId)
        .maybeSingle();
    return data != null;
  }

  static Future<bool> toggle(String islandId) async {
    if (_userId == null) return false;
    final existing = await _client
        .from('favorites')
        .select()
        .eq('user_id', _userId!)
        .eq('island_id', islandId)
        .maybeSingle();
    if (existing != null) {
      await _client.from('favorites').delete().eq('user_id', _userId!).eq('island_id', islandId);
      return false;
    } else {
      await _client.from('favorites').insert({'user_id': _userId, 'island_id': islandId});
      return true;
    }
  }

  static Future<List<IslandModel>> getFavorites() async {
    if (_userId == null) return [];
    final data = await _client
        .from('favorites')
        .select('island_id, islands(*)')
        .eq('user_id', _userId!)
        .order('created_at', ascending: false);
    return (data as List)
        .where((e) => e['islands'] != null)
        .map((e) => IslandModel.fromMap(e['islands'] as Map<String, dynamic>))
        .toList();
  }
}
