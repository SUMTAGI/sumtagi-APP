// 한국관광공사_지역별관광수요강도
// AI 일정생성 요청에 수요강도 컨텍스트를 넣기 위한 용도로만 포팅
// (VisitorTrendsChart 등 그래프용 나머지 API는 포팅 불필요 — [[project_sumtagi_apis]] 참고).
// WEB(src/lib/api/demandIntensity.ts)의 getIslandDemandLevel을 미러링.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

const _demandUrl = 'https://apis.data.go.kr/B551011/TatsDmndItnsService/tatsDmndItnsList';

// 섬 ID → [areaCd, signguCd] (WEB demandIntensity.ts ISLAND_DEMAND_MAP과 동일)
const Map<String, List<String>> _islandDemandMap = {
  'baengnyeong': ['28', '28720'],
  'daecheong': ['28', '28720'],
  'socheong': ['28', '28720'],
  'yeonpyeong': ['28', '28720'],
  'deokjeok': ['28', '28720'],
  'jawol': ['28', '28720'],
  'seungbong': ['28', '28720'],
  'daeijak': ['28', '28720'],
  'soijak': ['28', '28720'],
  'yeonghung': ['28', '28720'],
  'pungdo': ['41', '41390'],
  'yukdo': ['41', '41390'],
  'guleop': ['28', '28720'],
  'sindo': ['28', '28720'],
  'sido': ['28', '28720'],
  'modo': ['28', '28720'],
  'jangbongdo': ['28', '28720'],
  'soya': ['28', '28720'],
  'mungap': ['28', '28720'],
  'baegado': ['28', '28720'],
  'uldo': ['28', '28720'],
};

final Map<String, String> _cache = {};

String _levelOf(double v) {
  if (v >= 0.65) return 'high';
  if (v >= 0.35) return 'medium';
  return 'low';
}

String _currentYYYYMM() {
  final now = DateTime.now();
  return '${now.year}${now.month.toString().padLeft(2, '0')}';
}

/// 섬 ID 기준 현재 수요강도 레벨 반환 ('low'|'medium'|'high', 조회 실패/미등록 섬은 null)
Future<String?> getIslandDemandLevel(String islandId) async {
  final config = _islandDemandMap[islandId];
  if (config == null) return null;
  final areaCd = config[0];
  final signguCd = config[1];
  final cacheKey = '$areaCd-$signguCd';
  if (_cache.containsKey(cacheKey)) return _cache[cacheKey];

  final apiKey = dotenv.env['FERRY_API_KEY'] ?? '';
  final ym = _currentYYYYMM();
  final uri = Uri.parse(_demandUrl).replace(queryParameters: {
    'serviceKey': apiKey,
    'MobileOS': 'ETC',
    'MobileApp': 'sumtagi',
    '_type': 'json',
    'numOfRows': '6',
    'pageNo': '1',
    'areaCd': areaCd,
    'signguCd': signguCd,
    'startYm': ym,
    'endYm': ym,
  });

  try {
    final res = await http.get(uri);
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final raw = json['response']?['body']?['items']?['item'];
    final list = raw == null ? const [] : (raw is List ? raw : [raw]);
    if (list.isEmpty) return null;
    final item = list.last as Map<String, dynamic>;
    final rawV = double.tryParse((item['dmndIntns'] ?? item['dmnd_intns'] ?? '0').toString()) ?? 0;
    final v = rawV > 1 ? rawV / 100 : rawV;
    final level = _levelOf(v.clamp(0, 1));
    _cache[cacheKey] = level;
    return level;
  } catch (_) {
    return null;
  }
}

/// 여러 섬의 현재 수요강도를 병렬 조회. 반환값: { 섬 id: 'low'|'medium'|'high' } (실패한 섬은 결과에서 생략)
Future<Map<String, String>> getIslandsDemandLevels(List<String> islandIds) async {
  final result = <String, String>{};
  await Future.wait(islandIds.map((id) async {
    final level = await getIslandDemandLevel(id);
    if (level != null) result[id] = level;
  }));
  return result;
}
