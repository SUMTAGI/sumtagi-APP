import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CongestionForecast {
  final String date;
  final String dayLabel;
  final double rate;
  final String level;

  const CongestionForecast({
    required this.date,
    required this.dayLabel,
    required this.rate,
    required this.level,
  });
}

class IslandCongestionData {
  final String todayLevel;
  final List<CongestionForecast> forecast;

  const IslandCongestionData({
    required this.todayLevel,
    required this.forecast,
  });
}

class CongestionService {
  static const _baseUrl =
      'https://apis.data.go.kr/B551011/TatsCnctrRateService/tatsCnctrRatedList';

  // 섬 ID → (areaCd, signguCd, 매칭 키워드)
  static const _islandConfig = {
    'baengnyeong': ('28', '28720', '백령'),
    'daecheong':   ('28', '28720', '대청'),
    'socheong':    ('28', '28720', '소청'),
    'yeonpyeong':  ('28', '28720', '연평'),
    'deokjeok':    ('28', '28720', '덕적'),
    'jawol':       ('28', '28720', '자월'),
    'seungbong':   ('28', '28720', '승봉'),
    'daeijak':     ('28', '28720', '대이작'),
    'soijak':      ('28', '28720', '소이작'),
    'yeonghung':   ('28', '28720', '영흥'),
    'seonjae':     ('28', '28720', '선재'),
    'guleop':      ('28', '28720', '굴업'),
    'pungdo':      ('41', '41390', '풍도'),  // 경기도 안산시 단원구
    'yukdo':       ('41', '41390', '육도'),  // 경기도 안산시
    'sindo':       ('28', '28720', '신도'),
    'sido':        ('28', '28720', '시도'),
    'modo':        ('28', '28720', '모도'),
    'jangbongdo':  ('28', '28720', '장봉'),
    'soya':        ('28', '28720', '소야'),
    'mungap':      ('28', '28720', '문갑'),
    'baegado':     ('28', '28720', '백아'),
    'uldo':        ('28', '28720', '울도'),
  };

  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  // 세션 캐시 (areaCd+signguCd → items)
  static final Map<String, List<dynamic>> _cache = {};

  static String _level(double rate) {
    if (rate >= 0.65) return 'high';
    if (rate >= 0.35) return 'medium';
    return 'low';
  }

  static String _dayLabel(String yyyyMMdd) {
    try {
      final y = int.parse(yyyyMMdd.substring(0, 4));
      final m = int.parse(yyyyMMdd.substring(4, 6));
      final d = int.parse(yyyyMMdd.substring(6, 8));
      final date = DateTime(y, m, d);
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final diff = date.difference(todayDate).inDays;
      if (diff == 0) return '오늘';
      if (diff == 1) return '내일';
      return _weekdays[date.weekday - 1];
    } catch (_) {
      return '';
    }
  }

  static Future<List<dynamic>> _fetchRegion(String areaCd, String signguCd) async {
    final cacheKey = '$areaCd-$signguCd';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    final apiKey = dotenv.env['FERRY_API_KEY'] ?? '';

    // totalCount 먼저 확인
    final countUri = Uri.parse(_baseUrl).replace(queryParameters: {
      'serviceKey': apiKey,
      'numOfRows': '1',
      'pageNo': '1',
      'MobileOS': 'AND',
      'MobileApp': 'sumtagi',
      '_type': 'json',
      'areaCd': areaCd,
      'signguCd': signguCd,
    });
    final countRes = await http.get(countUri);
    if (countRes.statusCode != 200) return [];
    final countBody = jsonDecode(countRes.body);
    final totalCount = (countBody['response']?['body']?['totalCount'] as num?)?.toInt() ?? 0;
    if (totalCount == 0) return [];

    final all = <dynamic>[];
    final pages = (totalCount / 500).ceil();
    for (int p = 1; p <= pages; p++) {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'serviceKey': apiKey,
        'numOfRows': '500',
        'pageNo': p.toString(),
        'MobileOS': 'AND',
        'MobileApp': 'sumtagi',
        '_type': 'json',
        'areaCd': areaCd,
        'signguCd': signguCd,
      });
      final res = await http.get(uri);
      if (res.statusCode != 200) continue;
      final body = jsonDecode(res.body);
      final items = body['response']?['body']?['items']?['item'];
      if (items == null) continue;
      all.addAll(items is List ? items as List : [items]);
    }

    _cache[cacheKey] = all;
    return all;
  }

  static Future<Map<String, IslandCongestionData>> getAllIslandsCongestion() async {
    // 지역별로 한 번씩만 fetch
    final regionKeys = <String>{};
    for (final v in _islandConfig.values) {
      regionKeys.add('${v.$1}-${v.$2}');
    }
    await Future.wait(regionKeys.map((key) {
      final parts = key.split('-');
      return _fetchRegion(parts[0], parts[1]);
    }));

    final result = <String, IslandCongestionData>{};
    for (final entry in _islandConfig.entries) {
      final islandId = entry.key;
      final (areaCd, signguCd, keyword) = entry.value;
      final items = _cache['$areaCd-$signguCd'] ?? [];

      final matched = items.where((item) {
        return ((item['tAtsNm'] ?? '') as String).contains(keyword);
      }).toList();

      if (matched.isEmpty) continue;

      final byDate = <String, List<double>>{};
      for (final item in matched) {
        final raw = item['cnctrRate'];
        final rate = (raw is num ? raw.toDouble() : double.tryParse(raw?.toString() ?? '') ?? 0.0) / 100.0;
        final date = (item['baseYmd'] ?? '') as String;
        if (date.isNotEmpty) (byDate[date] ??= []).add(rate.clamp(0.0, 1.0));
      }

      final forecasts = byDate.entries.map((e) {
        final avg = e.value.reduce((a, b) => a + b) / e.value.length;
        return CongestionForecast(
          date: e.key,
          dayLabel: _dayLabel(e.key),
          rate: avg,
          level: _level(avg),
        );
      }).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      result[islandId] = IslandCongestionData(
        todayLevel: forecasts.isNotEmpty ? forecasts.first.level : 'low',
        forecast: forecasts.take(7).toList(),
      );
    }
    return result;
  }

  static Future<IslandCongestionData?> getIslandCongestion(String islandId) async {
    final config = _islandConfig[islandId];
    if (config == null) return null;

    final (areaCd, signguCd, keyword) = config;
    final items = await _fetchRegion(areaCd, signguCd);

    final matched = items.where((item) {
      return ((item['tAtsNm'] ?? '') as String).contains(keyword);
    }).toList();

    if (matched.isEmpty) return null;

    // 날짜별 평균 집중률 계산 (같은 날짜 여러 관광지 → 평균)
    final byDate = <String, List<double>>{};
    for (final item in matched) {
      final raw = item['cnctrRate'];
      final rate = (raw is num ? raw.toDouble() : double.tryParse(raw?.toString() ?? '') ?? 0.0) / 100.0;
      final date = (item['baseYmd'] ?? '') as String;
      if (date.isNotEmpty) (byDate[date] ??= []).add(rate.clamp(0.0, 1.0));
    }

    final forecasts = byDate.entries.map((e) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return CongestionForecast(
        date: e.key,
        dayLabel: _dayLabel(e.key),
        rate: avg,
        level: _level(avg),
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return IslandCongestionData(
      todayLevel: forecasts.isNotEmpty ? forecasts.first.level : 'low',
      forecast: forecasts.take(7).toList(),
    );
  }
}
