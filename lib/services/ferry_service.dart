import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class FerrySchedule {
  final String ferryName;
  final String routeName;
  final String departureTime;
  final String status;

  const FerrySchedule({
    required this.ferryName,
    required this.routeName,
    required this.departureTime,
    required this.status,
  });

  bool get isCancelled => status.contains('결항');
  bool get isDone => status == '완료';
  bool get isActive =>
      status.contains('출항') || status.contains('운항') || status.contains('항중') || status.contains('도착');
}

// 섬 ID → 항로명에 포함된 키워드
const _routeKeywords = {
  'baengnyeong': '백령',
  'daecheong': '대청',
  'socheong': '소청',
  'yeonpyeong': '연평',
  'deokjeok': '덕적',
  'jawol': '자월',
  'seungbong': '승봉',
  'daeijak': '이작',
  'soijak': '이작',
  'pungdo': '풍',
  'yukdo': '육',
  'yeonghung': '영흥',
  'seonjae': '선재',
  'guleop': '굴업',
};

class FerryRouteStatus {
  final String islandName;
  final String status; // '정상' | '결항' | '운항없음'
  const FerryRouteStatus({required this.islandName, required this.status});
}

const _allIslands = [
  {'id': 'baengnyeong', 'name': '백령도'},
  {'id': 'daecheong',   'name': '대청도'},
  {'id': 'socheong',    'name': '소청도'},
  {'id': 'yeonpyeong',  'name': '연평도'},
  {'id': 'deokjeok',    'name': '덕적도'},
  {'id': 'jawol',       'name': '자월도'},
  {'id': 'seungbong',   'name': '승봉도'},
  {'id': 'daeijak',     'name': '대이작도'},
  {'id': 'soijak',      'name': '소이작도'},
  {'id': 'pungdo',      'name': '풍도'},
  {'id': 'yukdo',       'name': '육도'},
  {'id': 'yeonghung',   'name': '영흥도'},
  {'id': 'seonjae',     'name': '선재도'},
  {'id': 'guleop',      'name': '굴업도'},
];

class FerryService {
  static const _baseUrl =
      'https://apis.data.go.kr/B554035/ferry-route-info-v4/get-ferry-route-info-v4';

  static String _todayKst() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 9));
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  static String _formatTime(dynamic t) {
    final s = t?.toString() ?? '';
    final padded = s.padLeft(4, '0');
    return '${padded.substring(0, 2)}:${padded.substring(2)}';
  }

  static Future<List<dynamic>> _fetchAllToday() async {
    final apiKey = dotenv.env['FERRY_API_KEY'] ?? '';
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'serviceKey': apiKey,
      'pageNo': '1',
      'numOfRows': '500',
      'dataType': 'JSON',
      'rlvtYmd': _todayKst(),
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      print('[Ferry] HTTP ${res.statusCode}');
      return [];
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final items = json['response']?['body']?['items']?['item'];
    if (items == null) {
      print('[Ferry] items null. body: ${res.body.substring(0, res.body.length.clamp(0, 300))}');
      return [];
    }
    print('[Ferry] items count: ${items is List ? (items as List).length : 1}');
    return items is List ? items as List : [items];
  }

  static Future<List<FerryRouteStatus>> getHomeFerryStatus() async {
    final items = await _fetchAllToday();
    print('[Ferry Home] items: ${items.length}');
    return _allIslands.map((island) {
      final keyword = _routeKeywords[island['id']] ?? '';
      final filtered = items.where((item) {
        final route = (item['lcns_seawy_nm'] ?? item['nvg_seawy_nm'] ?? '') as String;
        return route.contains(keyword);
      }).toList();
      if (filtered.isEmpty) return FerryRouteStatus(islandName: island['name']!, status: '운항없음');
      final hasCancelled = filtered.any((item) => ((item['nvg_stts_nm'] ?? '') as String).contains('결항'));
      return FerryRouteStatus(islandName: island['name']!, status: hasCancelled ? '결항' : '정상');
    }).toList();
  }

  static Future<List<FerrySchedule>> getScheduleForIsland(String islandId) async {
    final keyword = _routeKeywords[islandId];
    if (keyword == null) return [];

    final list = await _fetchAllToday();

    final filtered = list.where((item) {
      final route = (item['lcns_seawy_nm'] ?? item['nvg_seawy_nm'] ?? '') as String;
      return route.contains(keyword);
    }).toList();

    // 같은 출발(여객선+시각)에 상태 변경마다 row 추가됨 — 최신 상태만 유지
    final map = <String, dynamic>{};
    for (final item in filtered) {
      final key = '${item['psnshp_nm']}_${item['sail_tm']}';
      final existing = map[key];
      if (existing == null ||
          (item['nvg_stts_chg_dt'] as String).compareTo(existing['nvg_stts_chg_dt'] as String) > 0) {
        map[key] = item;
      }
    }

    return map.values
        .map((item) => FerrySchedule(
              ferryName: item['psnshp_nm']?.toString() ?? '',
              routeName: (item['lcns_seawy_nm'] ?? item['nvg_seawy_nm'] ?? '').toString(),
              departureTime: _formatTime(item['sail_tm']),
              status: item['nvg_stts_nm']?.toString() ?? '운항',
            ))
        .toList()
      ..sort((a, b) => a.departureTime.compareTo(b.departureTime));
  }
}
