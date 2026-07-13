// 한국관광공사_관광지별연관관광지정보
// AI 일정생성 요청에 코스 힌트를 넣기 위한 용도로만 포팅.
// WEB(src/lib/api/relatedAttractions.ts)의 buildRoutingHints를 미러링.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

const _baseUrl = 'https://apis.data.go.kr/B551011/TatsAtsRlatService/tatsAtsRlatList';

// 섬 ID → TourAPI contentId (WEB relatedAttractions.ts와 동일, 실제 검증된 것만 등록)
const Map<String, String> _islandContentIds = {
  'baengnyeong': '126508',
  'daecheong': '126514',
  'socheong': '126518',
  'yeonpyeong': '126520',
  'deokjeok': '126528',
  'jawol': '126534',
  'seungbong': '126538',
  'daeijak': '126542',
  'soijak': '126544',
  'yeonghung': '126550',
  'pungdo': '128899',
  'guleop': '126546',
  'seonjae': '127851',
  'jangbongdo': '128005',
  'soya': '2782222',
  'uldo': '128004',
};

final Map<String, List<String>> _cache = {};

List<dynamic> _rawItems(Map<String, dynamic> json) {
  final raw = json['response']?['body']?['items']?['item'];
  if (raw == null) return [];
  return raw is List ? raw : [raw];
}

Future<List<String>> _getRelatedNames(String contentId) async {
  if (_cache.containsKey(contentId)) return _cache[contentId]!;

  final apiKey = dotenv.env['FERRY_API_KEY'] ?? '';
  final uri = Uri.parse(_baseUrl).replace(queryParameters: {
    'serviceKey': apiKey,
    'MobileOS': 'ETC',
    'MobileApp': 'sumtagi',
    '_type': 'json',
    'numOfRows': '10',
    'pageNo': '1',
    'contentId': contentId,
  });

  try {
    final res = await http.get(uri);
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final names = _rawItems(json)
        .map((raw) {
          final item = raw as Map<String, dynamic>;
          return (item['rlatAtsNm'] ?? item['rlattitle'] ?? '') as String;
        })
        .where((n) => n.isNotEmpty)
        .toList();
    _cache[contentId] = names;
    return names;
  } catch (_) {
    return [];
  }
}

/// 여러 섬의 연관관광지를 병렬 조회해 일정 생성 엔진용 코스 힌트를 반환.
/// 반환값: { 섬 id: [연관관광지명, ...] }. contentId 미등록 섬은 결과에서 생략됨.
Future<Map<String, List<String>>> buildRoutingHints(List<String> islandIds) async {
  final hints = <String, List<String>>{};
  await Future.wait(islandIds.map((id) async {
    final contentId = _islandContentIds[id];
    if (contentId == null) return;
    hints[id] = await _getRelatedNames(contentId);
  }));
  return hints;
}
