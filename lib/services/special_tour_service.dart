// 한국관광공사_무장애여행정보 / 반려동물_동반여행_데이터
// 생태관광: data.go.kr 미제공 → 국문관광정보 키워드 검색으로 대체
// WEB(src/lib/api/specialTour.ts) 미러링.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

const _korServiceBase = 'https://apis.data.go.kr/B551011/KorService2';
const _incheonAreaCode = '2';
const _ongjinSigunguCode = '9';

const _endpoints = {
  'barrier_free': 'https://apis.data.go.kr/B551011/KorWithService1/withList',
  'pet_friendly': 'https://apis.data.go.kr/B551011/PetTourService1/petTourList',
};

class SpecialTourItem {
  final String contentId;
  final String title;
  final String addr1;
  final String type;
  final String? firstimage;
  final double? mapx;
  final double? mapy;
  final String? tel;
  final List<String> tags;

  const SpecialTourItem({
    required this.contentId,
    required this.title,
    required this.addr1,
    required this.type,
    this.firstimage,
    this.mapx,
    this.mapy,
    this.tel,
    required this.tags,
  });
}

final Map<String, List<SpecialTourItem>> _cache = {};

List<String> _extractTags(String type, Map<String, dynamic> item) {
  final tags = <String>[];
  if (type == 'pet_friendly') {
    if (item['acmpyPsblCpam'] == 'Y') tags.add('동반가능');
    if ((item['relaFclty'] as String?)?.isNotEmpty == true) tags.add('반려동물 시설');
    if (item['acmpyTypeCd'] == '01') tags.add('소형견');
    if (item['acmpyTypeCd'] == '02') tags.add('중형견');
    if (item['acmpyTypeCd'] == '03') tags.add('대형견');
  } else if (type == 'barrier_free') {
    if (item['wheelchair'] == 'Y') tags.add('휠체어 가능');
    if (item['parking'] == 'Y') tags.add('장애인 주차');
    if (item['elevator'] == 'Y') tags.add('엘리베이터');
    if (item['toilet'] == 'Y') tags.add('장애인 화장실');
    if (item['audioguide'] == 'Y') tags.add('오디오가이드');
    if (item['brailleblock'] == 'Y') tags.add('점자블록');
  }
  return tags;
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  return double.tryParse(v.toString());
}

List<dynamic> _rawItems(Map<String, dynamic> json) {
  final raw = json['response']?['body']?['items']?['item'];
  if (raw == null) return [];
  return raw is List ? raw : [raw];
}

Future<List<SpecialTourItem>> _fetchSpecial(
  String type, {
  String areaCode = _incheonAreaCode,
  String sigunguCode = _ongjinSigunguCode,
}) async {
  final key = '$type-$areaCode-$sigunguCode';
  if (_cache.containsKey(key)) return _cache[key]!;

  final apiKey = dotenv.env['FERRY_API_KEY'] ?? '';
  final uri = Uri.parse(_endpoints[type]!).replace(queryParameters: {
    'serviceKey': apiKey,
    'MobileOS': 'ETC',
    'MobileApp': 'sumtagi',
    '_type': 'json',
    'numOfRows': '30',
    'pageNo': '1',
    'areaCode': areaCode,
    'sigunguCode': sigunguCode,
    'arrange': 'P',
  });

  try {
    final res = await http.get(uri);
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final list = _rawItems(json);
    final result = list.map<SpecialTourItem>((raw) {
      final item = raw as Map<String, dynamic>;
      return SpecialTourItem(
        contentId: item['contentid'] ?? '',
        title: item['title'] ?? '',
        addr1: item['addr1'] ?? '',
        type: type,
        firstimage: (item['firstimage'] as String?)?.isNotEmpty == true ? item['firstimage'] : null,
        mapx: _toDouble(item['mapx']),
        mapy: _toDouble(item['mapy']),
        tel: (item['tel'] as String?)?.isNotEmpty == true ? item['tel'] : null,
        tags: _extractTags(type, item),
      );
    }).toList();
    _cache[key] = result;
    return result;
  } catch (_) {
    return [];
  }
}

Future<List<SpecialTourItem>> _fetchEcoTour() async {
  const key = 'eco-keyword';
  if (_cache.containsKey(key)) return _cache[key]!;

  try {
    const keywords = ['생태', '자연', '탐방', '트레킹'];
    final apiKey = dotenv.env['FERRY_API_KEY'] ?? '';
    final results = await Future.wait(keywords.map((kw) async {
      final uri = Uri.parse('$_korServiceBase/searchKeyword2').replace(queryParameters: {
        'serviceKey': apiKey,
        'MobileOS': 'ETC',
        'MobileApp': 'sumtagi',
        '_type': 'json',
        'numOfRows': '50',
        'pageNo': '1',
        'keyword': kw,
        'areaCode': _incheonAreaCode,
        'sigunguCode': _ongjinSigunguCode,
      });
      try {
        final res = await http.get(uri);
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return _rawItems(json);
      } catch (_) {
        return <dynamic>[];
      }
    }));

    final seen = <String>{};
    final items = <SpecialTourItem>[];
    for (final list in results) {
      for (final raw in list) {
        final item = raw as Map<String, dynamic>;
        final id = item['contentid'] ?? '';
        if (id.isEmpty || seen.contains(id)) continue;
        seen.add(id);
        items.add(SpecialTourItem(
          contentId: id,
          title: item['title'] ?? '',
          addr1: item['addr1'] ?? '',
          type: 'eco',
          firstimage: (item['firstimage'] as String?)?.isNotEmpty == true ? item['firstimage'] : null,
          mapx: _toDouble(item['mapx']),
          mapy: _toDouble(item['mapy']),
          tel: (item['tel'] as String?)?.isNotEmpty == true ? item['tel'] : null,
          tags: const ['자연생태'],
        ));
      }
    }
    _cache[key] = items;
    return items;
  } catch (_) {
    return [];
  }
}

/// 여행 스타일에 맞는 특수 관광지 조회
Future<List<SpecialTourItem>> getSpecialTourByStyle(String travelStyle) async {
  if (travelStyle == '생태') return _fetchEcoTour();
  if (travelStyle == '무장애') return _fetchSpecial('barrier_free');
  if (travelStyle == '반려동물') return _fetchSpecial('pet_friendly');
  return [];
}

/// 여행 스타일이 특수 여행 카테고리인지 확인
bool isSpecialTravelStyle(String style) => ['생태', '무장애', '반려동물'].contains(style);
