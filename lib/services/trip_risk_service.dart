// 여행 기간 중 여객선 결항·기상 악화 위험을 감지한다.
// 정부 실시간 결항 데이터(B554035)는 "오늘" 하루치만 제공하므로, 오늘이 여행 기간에
// 포함될 때만 "결항 확정"으로 판단한다. 그 외 날짜는 Open-Meteo 예보(최대 6일)로
// 강수확률이 높으면 "결항 가능성"으로만 표기한다(확정 아님, 과신 금지).
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ferry_service.dart';
import 'weather_service.dart';
import 'itinerary_generator.dart' show islandIdToKor;

final Map<String, String> _korToIslandId = {
  for (final e in islandIdToKor.entries) e.value: e.key,
};

// 다리로 연결돼 여객선 자체가 없는 섬(create_trip_screen.dart의 "육로 이동" 매핑과 동일)
const _bridgeConnected = {'영흥도', '선재도', '시도', '모도', '소야도'};

enum TripRiskLevel { cancelled, forecast }

class TripRisk {
  final String island;
  final String date; // "YYYY-MM-DD"
  final TripRiskLevel level;
  final String message;
  const TripRisk({required this.island, required this.date, required this.level, required this.message});
}

String _todayKstDateStr() {
  final now = DateTime.now().toUtc().add(const Duration(hours: 9));
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

int _daysFromToday(String dateStr) {
  final today = DateTime.parse(_todayKstDateStr());
  final target = DateTime.parse(dateStr.substring(0, 10));
  return target.difference(today).inDays;
}

class TripRiskService {
  static final _client = Supabase.instance.client;

  static Future<List<TripRisk>> checkTripRisks(
    List<String> islands,
    String startDate,
    String endDate,
  ) async {
    final risks = <TripRisk>[];
    final ferryIslands = islands.where((n) => !_bridgeConnected.contains(n)).toList();
    if (ferryIslands.isEmpty || startDate.isEmpty || endDate.isEmpty) return risks;

    final today = _todayKstDateStr();
    final tripStartOffset = _daysFromToday(startDate);
    final tripEndOffset = _daysFromToday(endDate);

    if (tripEndOffset < 0 || tripStartOffset > 5) return risks;

    // 1) 오늘이 여행 기간에 포함되면 실시간 결항 여부 확인
    if (tripStartOffset <= 0 && tripEndOffset >= 0) {
      final statuses = await FerryService.getHomeFerryStatus();
      for (final island in ferryIslands) {
        final matches = statuses.where((x) => x.islandName == island);
        final s = matches.isEmpty ? null : matches.first;
        if (s?.status == '결항') {
          risks.add(TripRisk(island: island, date: today, level: TripRiskLevel.cancelled, message: '$island 여객선이 오늘 결항됐어요'));
        }
      }
    }

    // 2) 내일~5일 후 중 여행 기간과 겹치는 날짜는 강수 예보로 위험만 추정
    final forecastOffsets = [1, 2, 3, 4, 5].where((o) => o >= tripStartOffset && o <= tripEndOffset).toList();
    if (forecastOffsets.isEmpty) return risks;

    final islandIds = ferryIslands.map((n) => _korToIslandId[n]).whereType<String>().toList();
    if (islandIds.isEmpty) return risks;

    final coords = await _client.from('islands').select('id, lat, lng').inFilter('id', islandIds);
    final coordMap = {for (final c in (coords as List)) c['id'] as String: c};

    for (final islandId in islandIds) {
      final coord = coordMap[islandId];
      final weather = await WeatherService.getWeatherForIsland(
        islandId,
        lat: (coord?['lat'] as num?)?.toDouble(),
        lng: (coord?['lng'] as num?)?.toDouble(),
      );
      if (weather == null) continue;
      for (final offset in forecastOffsets) {
        if (offset - 1 >= weather.forecast.length) continue;
        final forecastDay = weather.forecast[offset - 1];
        if (forecastDay.rainChance >= 70 || forecastDay.condition == '비') {
          final island = islandIdToKor[islandId]!;
          final date = DateTime.parse(today).add(Duration(days: offset));
          risks.add(TripRisk(
            island: island,
            date: date.toIso8601String().substring(0, 10),
            level: TripRiskLevel.forecast,
            message: '$island ${forecastDay.date} 강수확률 ${forecastDay.rainChance}%로 결항 가능성이 있어요',
          ));
        }
      }
    }

    return risks;
  }
}
