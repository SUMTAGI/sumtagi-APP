import 'package:supabase_flutter/supabase_flutter.dart';

class TripService {
  static final _client = Supabase.instance.client;

  static String? get _userId => _client.auth.currentUser?.id;

  static Future<String> createTrip({
    required String title,
    required String departurePort,
    required List<String> islands,
    required String startDate,
    required String endDate,
    required int travelers,
    required String travelType,
    required String budget,
    required int totalCost,
    required List<Map<String, dynamic>> days,
  }) async {
    final data = await _client.from('trips').insert({
      'user_id': _userId,
      'title': title,
      'departure_port': departurePort,
      'islands': islands,
      'start_date': startDate,
      'end_date': endDate,
      'travelers': travelers,
      'travel_type': travelType,
      'budget': budget,
      'total_cost': totalCost,
      'days': days,
      'confirmed': false,
    }).select('id').single();
    return data['id'] as String;
  }

  static Future<Map<String, dynamic>?> getUpcomingTrip() async {
    if (_userId == null) return null;
    final today = DateTime.now().toIso8601String().split('T')[0];
    return await _client
        .from('trips')
        .select()
        .eq('user_id', _userId!)
        .gte('start_date', today)
        .order('start_date')
        .limit(1)
        .maybeSingle();
  }

  static Future<Map<String, dynamic>?> getTripById(String id) async {
    return await _client.from('trips').select().eq('id', id).maybeSingle();
  }

  static Future<void> confirmTrip(String id) async {
    await _client.from('trips').update({'confirmed': true}).eq('id', id);
  }

  static Future<void> deleteTrip(String id) async {
    await _client.from('trips').delete().eq('id', id);
  }

  static Future<Map<String, dynamic>?> getLatestConfirmedTrip() async {
    if (_userId == null) return null;
    return await _client
        .from('trips')
        .select()
        .eq('user_id', _userId!)
        .eq('confirmed', true)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }
}
