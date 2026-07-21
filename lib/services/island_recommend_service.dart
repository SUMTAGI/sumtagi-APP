import 'package:supabase_flutter/supabase_flutter.dart';

class IslandRecommendation {
  final String island;
  final String travelStyle;
  final String reason;
  const IslandRecommendation({required this.island, required this.travelStyle, required this.reason});
}

/// 홈 검색창 — 자연어 여행 취향 → AI 섬 추천 (섬간 이동이 번거로워 1개만 추천)
Future<IslandRecommendation> recommendIsland(String query) async {
  final response = await Supabase.instance.client.functions.invoke(
    'recommend-island',
    body: {'query': query},
  );
  final data = response.data;
  if (data is! Map || data['ok'] != true) {
    throw Exception('추천 실패 [${data is Map ? data['error'] : 'UNKNOWN'}]');
  }
  return IslandRecommendation(
    island: data['island'] as String,
    travelStyle: data['travelStyle'] as String,
    reason: data['reason'] as String? ?? '',
  );
}
