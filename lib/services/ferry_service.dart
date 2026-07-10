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
  'sindo': '장봉',
  'jangbongdo': '장봉',
  'mungap': '덕적',
  'baegado': '덕적',
  'uldo': '울도',
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
  {'id': 'sindo',       'name': '신도'},
  {'id': 'sido',        'name': '시도'},
  {'id': 'modo',        'name': '모도'},
  {'id': 'jangbongdo',  'name': '장봉도'},
  {'id': 'soya',        'name': '소야도'},
  {'id': 'mungap',      'name': '문갑도'},
  {'id': 'baegado',     'name': '백아도'},
  {'id': 'uldo',        'name': '울도'},
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

  static const int _pageSize = 1000;

  static Future<Map<String, dynamic>> _fetchPage(int pageNo) async {
    final apiKey = dotenv.env['FERRY_API_KEY'] ?? '';
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'serviceKey': apiKey,
      'pageNo': '$pageNo',
      'numOfRows': '$_pageSize',
      'dataType': 'JSON',
      'rlvtYmd': _todayKst(),
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      print('[Ferry] HTTP ${res.statusCode}');
      return {'items': <dynamic>[], 'totalCount': 0};
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final body = json['response']?['body'];
    final items = body?['items']?['item'];
    if (items == null) {
      print('[Ferry] items null. body: ${res.body.substring(0, res.body.length.clamp(0, 300))}');
      return {'items': <dynamic>[], 'totalCount': 0};
    }
    return {
      'items': items is List ? items : [items],
      'totalCount': (body?['totalCount'] ?? 0) as int,
    };
  }

  // 하루 전체 항로 데이터가 numOfRows(페이지 크기)보다 많을 수 있어(예: 4000건 이상),
  // 첫 페이지만 받으면 뒤쪽 항로가 누락되어 실제로는 운항했는데도 '운항없음'으로 잘못 표시됨.
  // totalCount를 보고 남은 페이지를 모두 받아온다.
  static Future<List<dynamic>> _fetchAllToday() async {
    final first = await _fetchPage(1);
    final items = List<dynamic>.from(first['items'] as List);
    final totalCount = first['totalCount'] as int;
    final totalPages = (totalCount / _pageSize).ceil();
    for (var pageNo = 2; pageNo <= totalPages; pageNo++) {
      final next = await _fetchPage(pageNo);
      items.addAll(next['items'] as List);
    }
    print('[Ferry] items count: ${items.length} (totalCount: $totalCount)');
    return items;
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

  static List<FerrySchedule> _schedulesFromItems(List<dynamic> items, String keyword) {
    final filtered = items.where((item) {
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

  static Future<List<FerrySchedule>> getScheduleForIsland(String islandId) async {
    final keyword = _routeKeywords[islandId];
    if (keyword == null) return [];

    final items = await _fetchAllToday();
    return _schedulesFromItems(items, keyword);
  }

  // 홈 화면의 '교통시간표'에서 섬 하나씩 getScheduleForIsland를 반복 호출하면
  // 매번 _fetchAllToday()가 다시 실행돼 API를 섬 개수만큼 중복 호출하게 됨.
  // 전체 배편을 보여줄 땐 오늘자 데이터를 한 번만 받아서 섬별로 나눠준다.
  static Future<List<IslandFerrySchedule>> getScheduleForAllIslands() async {
    final items = await _fetchAllToday();
    return _allIslands
        .map((island) {
          final keyword = _routeKeywords[island['id']];
          return IslandFerrySchedule(
            islandId: island['id']!,
            islandName: island['name']!,
            schedules: keyword == null ? [] : _schedulesFromItems(items, keyword),
          );
        })
        .where((entry) => entry.schedules.isNotEmpty)
        .toList();
  }
}

class IslandFerrySchedule {
  final String islandId;
  final String islandName;
  final List<FerrySchedule> schedules;
  const IslandFerrySchedule({required this.islandId, required this.islandName, required this.schedules});
}
