// 여객선/숙박/식당 예약 준비 체크리스트.
// 앱이 실제로 예약(결제/좌석확보)을 대신 해주지 않는다 — 여객선 예매 시스템(가보고싶은섬)과
// 섬 펜션·식당 대부분이 전화 예약만 가능한 폐쇄형 구조라 외부 연동이 불가능하기 때문.
// 대신 연락처/딥링크를 안내하고, 사용자가 직접 예약한 뒤 "완료"로 표시하는 개인 기록용 체크리스트.
import 'package:supabase_flutter/supabase_flutter.dart';
import 'itinerary_generator.dart' show islandIdToKor;

// 한국해운조합이 운영하는 실제 여객선 예매 시스템. 노선별 딥링크 파라미터는 확인 불가해 메인 예매 페이지로 연결.
const _ferryBookingUrl = 'https://island.theksa.co.kr/page/booking';

final Map<String, String> _korToIslandId = {
  for (final e in islandIdToKor.entries) e.value: e.key,
};

class TripBookingService {
  static final _client = Supabase.instance.client;
  static String? get _userId => _client.auth.currentUser?.id;

  static Future<List<Map<String, dynamic>>> getChecklist({
    required String tripId,
    required List<String> islands,
    required String departurePort,
  }) async {
    if (_userId == null) return [];
    final data = await _client
        .from('trip_bookings')
        .select()
        .eq('trip_id', tripId)
        .order('order_index');
    final items = List<Map<String, dynamic>>.from(data as List);
    if (items.isNotEmpty) return items;

    await _generateChecklist(tripId: tripId, islands: islands, departurePort: departurePort);
    final reloaded = await _client
        .from('trip_bookings')
        .select()
        .eq('trip_id', tripId)
        .order('order_index');
    return List<Map<String, dynamic>>.from(reloaded as List);
  }

  static Future<void> _generateChecklist({
    required String tripId,
    required List<String> islands,
    required String departurePort,
  }) async {
    if (_userId == null) return;
    final rows = <Map<String, dynamic>>[];

    if (departurePort.isNotEmpty && departurePort != '육로 이동') {
      rows.add({
        'trip_id': tripId, 'user_id': _userId, 'category': 'ferry',
        'name': '$departurePort 여객선 예매', 'island_id': null,
        'phone': null, 'external_url': _ferryBookingUrl,
        'is_done': false, 'order_index': 0,
      });
    }

    final islandIds = islands.map((n) => _korToIslandId[n]).whereType<String>().toList();

    for (final islandId in islandIds) {
      final accs = await _client
          .from('accommodations')
          .select('name, phone')
          .eq('island_id', islandId)
          .order('order_index')
          .limit(2);
      final rests = await _client
          .from('restaurants')
          .select('name, phone')
          .eq('island_id', islandId)
          .order('order_index')
          .limit(2);

      for (final (i, a) in List<Map<String, dynamic>>.from(accs as List).indexed) {
        rows.add({
          'trip_id': tripId, 'user_id': _userId, 'category': 'accommodation',
          'name': a['name'], 'island_id': islandId, 'phone': a['phone'],
          'external_url': null, 'is_done': false, 'order_index': 10 + i,
        });
      }
      for (final (i, r) in List<Map<String, dynamic>>.from(rests as List).indexed) {
        rows.add({
          'trip_id': tripId, 'user_id': _userId, 'category': 'restaurant',
          'name': r['name'], 'island_id': islandId, 'phone': r['phone'],
          'external_url': null, 'is_done': false, 'order_index': 20 + i,
        });
      }
    }

    if (rows.isEmpty) return;
    await _client.from('trip_bookings').insert(rows);
  }

  static Future<void> toggle(String id, bool current) async {
    await _client.from('trip_bookings').update({'is_done': !current}).eq('id', id);
  }
}
