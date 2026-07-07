import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class TripFormData {
  final String departurePort;
  final String startDate;
  final String endDate;
  final int travelers;
  final String travelType;
  final List<String> islands;
  final String budget;

  const TripFormData({
    required this.departurePort,
    required this.startDate,
    required this.endDate,
    required this.travelers,
    required this.travelType,
    required this.islands,
    required this.budget,
  });
}

class FerrySchedule {
  final String id, from, to, departureTime, arrivalTime;
  final int price;
  const FerrySchedule({required this.id, required this.from, required this.to, required this.departureTime, required this.arrivalTime, required this.price});
}

class Attraction {
  final String id, name, island, category, congestionLevel, description;
  final int duration;
  const Attraction({required this.id, required this.name, required this.island, required this.category, required this.duration, required this.congestionLevel, required this.description});
}

class ItineraryDay {
  final String date;
  final int dayNumber;
  final List<Map<String, dynamic>> activities;
  const ItineraryDay({required this.date, required this.dayNumber, required this.activities});

  Map<String, dynamic> toJson() => {'date': date, 'dayNumber': dayNumber, 'activities': activities};
}

class GeneratedItinerary {
  final String title;
  final String departurePort;
  final String startDate;
  final String endDate;
  final int travelers;
  final List<ItineraryDay> days;
  final int totalCost;
  final List<String> islands;

  const GeneratedItinerary({
    required this.title,
    required this.departurePort,
    required this.startDate,
    required this.endDate,
    required this.travelers,
    required this.days,
    required this.totalCost,
    required this.islands,
  });
}

const List<FerrySchedule> _ferrySchedules = [
  // 인천항 출발
  FerrySchedule(id: 'f1', from: '인천항', to: '백령도', departureTime: '08:00', arrivalTime: '12:00', price: 71700),
  FerrySchedule(id: 'f2', from: '백령도', to: '인천항', departureTime: '14:00', arrivalTime: '18:00', price: 71700),
  FerrySchedule(id: 'f3', from: '인천항', to: '대청도', departureTime: '08:30', arrivalTime: '12:10', price: 65000),
  FerrySchedule(id: 'f4', from: '대청도', to: '인천항', departureTime: '14:00', arrivalTime: '17:40', price: 65000),
  FerrySchedule(id: 'f5', from: '인천항', to: '소청도', departureTime: '08:30', arrivalTime: '12:10', price: 65000),
  FerrySchedule(id: 'f6', from: '소청도', to: '인천항', departureTime: '14:00', arrivalTime: '17:40', price: 65000),
  FerrySchedule(id: 'f7', from: '인천항', to: '연평도', departureTime: '09:00', arrivalTime: '11:30', price: 54550),
  FerrySchedule(id: 'f8', from: '연평도', to: '인천항', departureTime: '14:30', arrivalTime: '17:00', price: 54550),
  FerrySchedule(id: 'f9', from: '인천항', to: '덕적도', departureTime: '09:00', arrivalTime: '10:10', price: 13000),
  FerrySchedule(id: 'f10', from: '덕적도', to: '인천항', departureTime: '15:00', arrivalTime: '16:10', price: 13000),
  FerrySchedule(id: 'f11', from: '인천항', to: '자월도', departureTime: '09:30', arrivalTime: '10:20', price: 20800),
  FerrySchedule(id: 'f12', from: '자월도', to: '인천항', departureTime: '14:30', arrivalTime: '15:20', price: 20800),
  FerrySchedule(id: 'f13', from: '인천항', to: '승봉도', departureTime: '10:00', arrivalTime: '11:15', price: 22600),
  FerrySchedule(id: 'f14', from: '승봉도', to: '인천항', departureTime: '15:00', arrivalTime: '16:15', price: 22600),
  FerrySchedule(id: 'f15', from: '인천항', to: '대이작도', departureTime: '10:30', arrivalTime: '12:00', price: 22600),
  FerrySchedule(id: 'f16', from: '대이작도', to: '인천항', departureTime: '15:30', arrivalTime: '17:00', price: 22600),
  // 대부도항 출발
  FerrySchedule(id: 'd1', from: '대부도', to: '자월도', departureTime: '09:00', arrivalTime: '11:00', price: 20800),
  FerrySchedule(id: 'd2', from: '자월도', to: '대부도', departureTime: '15:00', arrivalTime: '17:00', price: 20800),
  FerrySchedule(id: 'd3', from: '대부도', to: '승봉도', departureTime: '09:30', arrivalTime: '11:00', price: 22600),
  FerrySchedule(id: 'd4', from: '승봉도', to: '대부도', departureTime: '15:30', arrivalTime: '17:00', price: 22600),
  FerrySchedule(id: 'd5', from: '대부도', to: '대이작도', departureTime: '10:00', arrivalTime: '11:30', price: 22600),
  FerrySchedule(id: 'd6', from: '대이작도', to: '대부도', departureTime: '16:00', arrivalTime: '17:30', price: 22600),
  FerrySchedule(id: 'd7', from: '대부도', to: '소이작도', departureTime: '10:30', arrivalTime: '12:00', price: 22600),
  FerrySchedule(id: 'd8', from: '소이작도', to: '대부도', departureTime: '16:30', arrivalTime: '18:00', price: 22600),
  FerrySchedule(id: 'd9', from: '대부도', to: '덕적도', departureTime: '11:00', arrivalTime: '13:00', price: 10700),
  FerrySchedule(id: 'd10', from: '덕적도', to: '대부도', departureTime: '14:00', arrivalTime: '16:00', price: 10700),
  FerrySchedule(id: 'd11', from: '대부도', to: '풍도', departureTime: '11:30', arrivalTime: '14:00', price: 27000),
  FerrySchedule(id: 'd12', from: '풍도', to: '대부도', departureTime: '14:30', arrivalTime: '17:00', price: 27000),
  FerrySchedule(id: 'd13', from: '대부도', to: '육도', departureTime: '12:00', arrivalTime: '15:00', price: 28000),
  FerrySchedule(id: 'd14', from: '육도', to: '대부도', departureTime: '15:00', arrivalTime: '18:00', price: 28000),
  // 섬간 연결
  FerrySchedule(id: 's1', from: '덕적도', to: '자월도', departureTime: '13:00', arrivalTime: '13:40', price: 12000),
  FerrySchedule(id: 's2', from: '자월도', to: '대이작도', departureTime: '14:00', arrivalTime: '14:30', price: 8000),
  FerrySchedule(id: 's3', from: '덕적도', to: '굴업도', departureTime: '11:20', arrivalTime: '12:00', price: 7500),
  FerrySchedule(id: 's4', from: '굴업도', to: '덕적도', departureTime: '14:00', arrivalTime: '14:40', price: 7500),
  // 삼목항 출발
  FerrySchedule(id: 'p1', from: '삼목항', to: '신도', departureTime: '09:00', arrivalTime: '09:10', price: 3400),
  FerrySchedule(id: 'p2', from: '신도', to: '삼목항', departureTime: '15:30', arrivalTime: '15:40', price: 3400),
  FerrySchedule(id: 'p3', from: '삼목항', to: '장봉도', departureTime: '09:00', arrivalTime: '09:40', price: 3400),
  FerrySchedule(id: 'p4', from: '장봉도', to: '삼목항', departureTime: '15:00', arrivalTime: '15:40', price: 3400),
];

const List<Attraction> _hardcodedAttractions = [
  // 백령도
  Attraction(id: 'a1', name: '두무진', island: '백령도', category: '자연경관', duration: 120, congestionLevel: 'medium', description: '서해의 해금강이라 불리는 해안 절벽 명소'),
  Attraction(id: 'a2', name: '사곶해변', island: '백령도', category: '해변', duration: 90, congestionLevel: 'low', description: '천연기념물로 지정된 천연비행장 해변'),
  Attraction(id: 'a3', name: '콩돌해변', island: '백령도', category: '해변', duration: 60, congestionLevel: 'low', description: '알록달록한 천연 콩돌이 가득한 이색 해변'),
  Attraction(id: 'a4', name: '심청각', island: '백령도', category: '문화', duration: 60, congestionLevel: 'low', description: '심청전 배경지, 인당수 전망대'),
  Attraction(id: 'a5', name: '백령도 등대', island: '백령도', category: '문화', duration: 45, congestionLevel: 'low', description: '서해 최북단 등대, 탁 트인 바다 전망'),
  Attraction(id: 'a6', name: '진촌리 해안', island: '백령도', category: '자연경관', duration: 60, congestionLevel: 'low', description: '조용한 어촌 해안과 갯벌 탐방'),
  // 대청도
  Attraction(id: 'b1', name: '옥죽동 사막', island: '대청도', category: '자연경관', duration: 120, congestionLevel: 'low', description: '한국 유일의 모래사막, 신비로운 경관'),
  Attraction(id: 'b2', name: '농여해변', island: '대청도', category: '해변', duration: 90, congestionLevel: 'low', description: '투명한 청정 바다와 고운 모래'),
  Attraction(id: 'b3', name: '미아동 해안', island: '대청도', category: '자연경관', duration: 60, congestionLevel: 'low', description: '기암괴석과 에메랄드빛 바다가 어우러진 절경'),
  Attraction(id: 'b4', name: '대청도 트레킹', island: '대청도', category: '등산', duration: 150, congestionLevel: 'low', description: '섬 전체를 잇는 산책 및 트레킹 코스'),
  Attraction(id: 'b5', name: '지두리 해수욕장', island: '대청도', category: '해변', duration: 90, congestionLevel: 'low', description: '고요하고 청명한 대청도 대표 해수욕장'),
  // 소청도
  Attraction(id: 'c1', name: '분바위', island: '소청도', category: '자연경관', duration: 60, congestionLevel: 'low', description: '흰 분을 뿌린 듯한 독특한 석회암 바위'),
  Attraction(id: 'c2', name: '소청도 등대', island: '소청도', category: '문화', duration: 45, congestionLevel: 'low', description: '1908년 건립된 서해 최북단 유인 등대'),
  Attraction(id: 'c3', name: '해안 절경', island: '소청도', category: '자연경관', duration: 60, congestionLevel: 'low', description: '소청도 해안선을 따라 걷는 비경 탐방'),
  Attraction(id: 'c4', name: '갯벌 체험', island: '소청도', category: '체험', duration: 90, congestionLevel: 'low', description: '깨끗한 갯벌에서 조개·해산물 채취 체험'),
  // 연평도
  Attraction(id: 'd1', name: '조기잡이 체험', island: '연평도', category: '체험', duration: 120, congestionLevel: 'medium', description: '연평도 명물 조기잡이 어업 체험'),
  Attraction(id: 'd2', name: '낚시터', island: '연평도', category: '체험', duration: 90, congestionLevel: 'low', description: '풍요로운 서해 바다낚시'),
  Attraction(id: 'd3', name: '연평도 해수욕장', island: '연평도', category: '해변', duration: 90, congestionLevel: 'low', description: '한적하고 조용한 해수욕장'),
  Attraction(id: 'd4', name: '구리동 해변', island: '연평도', category: '해변', duration: 60, congestionLevel: 'low', description: '때묻지 않은 자연 그대로의 해변'),
  Attraction(id: 'd5', name: '연평 역사관', island: '연평도', category: '문화', duration: 60, congestionLevel: 'low', description: '연평도 역사와 포격전 기념 전시관'),
  // 덕적도
  Attraction(id: 'e1', name: '서포리해수욕장', island: '덕적도', category: '해변', duration: 120, congestionLevel: 'medium', description: '울창한 소나무 숲과 맑은 바다가 어우러진 명소'),
  Attraction(id: 'e2', name: '비조봉', island: '덕적도', category: '등산', duration: 150, congestionLevel: 'low', description: '덕적도 최고봉, 서해 섬들을 한눈에'),
  Attraction(id: 'e3', name: '소야도', island: '덕적도', category: '자연경관', duration: 60, congestionLevel: 'low', description: '도보 연결되는 아기자기한 작은 섬'),
  Attraction(id: 'e4', name: '북리해변', island: '덕적도', category: '해변', duration: 90, congestionLevel: 'low', description: '고요한 어촌 마을 앞 한적한 해변'),
  Attraction(id: 'e5', name: '밧지름해변', island: '덕적도', category: '해변', duration: 90, congestionLevel: 'low', description: '덕적도 서쪽의 숨은 청정 해변'),
  Attraction(id: 'e6', name: '덕적도 자전거길', island: '덕적도', category: '체험', duration: 120, congestionLevel: 'low', description: '섬 일주 자전거 코스, 해안 경치 감상'),
  // 자월도
  Attraction(id: 'f1', name: '선착장마을', island: '자월도', category: '문화', duration: 60, congestionLevel: 'low', description: '정겨운 전통 어촌 마을 골목 탐방'),
  Attraction(id: 'f2', name: '큰말해변', island: '자월도', category: '해변', duration: 90, congestionLevel: 'low', description: '한적한 해변, 서해 일몰 명소'),
  Attraction(id: 'f3', name: '달바위 전망대', island: '자월도', category: '자연경관', duration: 60, congestionLevel: 'low', description: '자월도 전경과 주변 섬들을 조망'),
  Attraction(id: 'f4', name: '갯벌 체험', island: '자월도', category: '체험', duration: 90, congestionLevel: 'low', description: '바지락·낙지 등 갯벌 생물 채취 체험'),
  Attraction(id: 'f5', name: '자월도 트레킹', island: '자월도', category: '등산', duration: 120, congestionLevel: 'low', description: '섬 능선을 따라 걷는 해안 트레킹 코스'),
  // 승봉도
  Attraction(id: 'g1', name: '해안산책로', island: '승봉도', category: '자연경관', duration: 60, congestionLevel: 'low', description: '승봉도를 한 바퀴 도는 조용한 해안 산책'),
  Attraction(id: 'g2', name: '이일레해변', island: '승봉도', category: '해변', duration: 90, congestionLevel: 'low', description: '투명한 바닷물과 흰 모래의 아름다운 해변'),
  Attraction(id: 'g3', name: '부두리 해변', island: '승봉도', category: '해변', duration: 60, congestionLevel: 'low', description: '한적한 자연 그대로의 작은 해변'),
  Attraction(id: 'g4', name: '남대문 바위', island: '승봉도', category: '자연경관', duration: 45, congestionLevel: 'low', description: '서울 남대문을 닮은 독특한 기암'),
  // 대이작도
  Attraction(id: 'h1', name: '목기미해변', island: '대이작도', category: '해변', duration: 120, congestionLevel: 'low', description: '에메랄드빛 바다와 아름다운 모래사장'),
  Attraction(id: 'h2', name: '부아산', island: '대이작도', category: '등산', duration: 90, congestionLevel: 'low', description: '대이작도 최고봉, 주변 섬 조망 절경'),
  Attraction(id: 'h3', name: '해안 트레킹', island: '대이작도', category: '체험', duration: 120, congestionLevel: 'low', description: '섬 외곽 해안을 따라 걷는 둘레길'),
  Attraction(id: 'h4', name: '풀등 모래섬', island: '대이작도', category: '자연경관', duration: 90, congestionLevel: 'low', description: '썰물 때 나타나는 신비로운 모래섬'),
  Attraction(id: 'h5', name: '작은목기미해변', island: '대이작도', category: '해변', duration: 60, congestionLevel: 'low', description: '조용하고 아늑한 숨은 해변'),
  // 소이작도
  Attraction(id: 'i1', name: '큰풀안해변', island: '소이작도', category: '해변', duration: 90, congestionLevel: 'low', description: '작은 섬의 아담하고 청정한 해변'),
  Attraction(id: 'i2', name: '조개잡이', island: '소이작도', category: '체험', duration: 60, congestionLevel: 'low', description: '얕은 바다에서 즐기는 조개 채취 체험'),
  Attraction(id: 'i3', name: '섬 한 바퀴', island: '소이작도', category: '자연경관', duration: 90, congestionLevel: 'low', description: '소이작도 전체를 걸어서 한 바퀴'),
  // 영흥도
  Attraction(id: 'j1', name: '십리포해수욕장', island: '영흥도', category: '해변', duration: 120, congestionLevel: 'medium', description: '솔숲과 황금빛 모래사장이 펼쳐진 명소'),
  Attraction(id: 'j2', name: '장경리해수욕장', island: '영흥도', category: '해변', duration: 90, congestionLevel: 'medium', description: '서해 낙조가 아름다운 인기 해수욕장'),
  Attraction(id: 'j3', name: '영흥도 트레킹', island: '영흥도', category: '등산', duration: 120, congestionLevel: 'low', description: '국사봉을 오르는 섬 트레킹 코스'),
  Attraction(id: 'j4', name: '선재어촌체험', island: '영흥도', category: '체험', duration: 90, congestionLevel: 'low', description: '영흥도 선재마을 갯벌 및 어촌 체험'),
  Attraction(id: 'j5', name: '용담포구', island: '영흥도', category: '문화', duration: 60, congestionLevel: 'low', description: '신선한 해산물을 맛볼 수 있는 포구'),
  // 풍도
  Attraction(id: 'k1', name: '동백나무숲', island: '풍도', category: '자연경관', duration: 90, congestionLevel: 'medium', description: '봄철 붉은 동백꽃이 만발하는 천연 숲'),
  Attraction(id: 'k2', name: '풍도 해안트레킹', island: '풍도', category: '체험', duration: 120, congestionLevel: 'low', description: '섬 외곽 해안 절경을 따라 걷는 둘레길'),
  Attraction(id: 'k3', name: '일몰 명소', island: '풍도', category: '자연경관', duration: 60, congestionLevel: 'low', description: '서해 낙조의 아름다움을 즐기는 전망 포인트'),
  Attraction(id: 'k4', name: '후망산', island: '풍도', category: '등산', duration: 90, congestionLevel: 'low', description: '풍도 최고봉에서 서해 바다 조망'),
  Attraction(id: 'k5', name: '야생화 군락지', island: '풍도', category: '자연경관', duration: 60, congestionLevel: 'low', description: '봄이면 복수초·노루귀 등 야생화 천국'),
  // 육도
  Attraction(id: 'l1', name: '작은해변', island: '육도', category: '해변', duration: 60, congestionLevel: 'low', description: '외딴 섬의 조용하고 깨끗한 모래사장'),
  Attraction(id: 'l2', name: '어촌마을', island: '육도', category: '문화', duration: 45, congestionLevel: 'low', description: '시간이 멈춘 듯한 전통 어촌 마을'),
  Attraction(id: 'l3', name: '육도 트레킹', island: '육도', category: '등산', duration: 90, congestionLevel: 'low', description: '소박한 섬 전체를 걷는 자연 탐방로'),
  // 선재도
  Attraction(id: 'm1', name: '목섬', island: '선재도', category: '자연경관', duration: 60, congestionLevel: 'medium', description: '썰물 때만 걸어 들어갈 수 있는 신비로운 모세의 기적 섬'),
  Attraction(id: 'm2', name: '해안산책로', island: '선재도', category: '자연경관', duration: 60, congestionLevel: 'low', description: '영흥대교·선재대교 조망이 좋은 해안 산책길'),
  Attraction(id: 'm3', name: '갯벌 체험', island: '선재도', category: '체험', duration: 90, congestionLevel: 'low', description: '굴·바지락이 풍부한 갯벌 채취 체험'),
  // 굴업도
  Attraction(id: 'n1', name: '개머리언덕', island: '굴업도', category: '자연경관', duration: 90, congestionLevel: 'low', description: '서해를 조망하는 초원 언덕, 굴업도 대표 트레킹 코스'),
  Attraction(id: 'n2', name: '해안트레킹', island: '굴업도', category: '체험', duration: 120, congestionLevel: 'low', description: '무인도 같은 순수한 해안선을 따라 걷는 트레킹'),
  Attraction(id: 'n3', name: '야생화', island: '굴업도', category: '자연경관', duration: 45, congestionLevel: 'low', description: '사람 손이 닿지 않은 야생화 군락'),
];

const _lunchOptions = ['현지 해산물 정식', '조개구이 점심', '섬 특산물 백반', '싱싱한 회 점심', '해물칼국수'];
const _dinnerOptions = ['현지 맛집 저녁', '바다 뷰 레스토랑', '해산물 바베큐', '어촌 가정식', '해물 전골'];
const Map<String, List<String>> _accomNames = {
  '여유있게': ['프리미엄 리조트', '오션뷰 펜션', '풀빌라 리조트'],
  '여유': ['프리미엄 리조트', '오션뷰 펜션', '풀빌라 리조트'],
  '보통': ['아늑한 펜션', '바다 앞 펜션', '섬 민박 펜션'],
  '알뜰': ['아담한 민박', '어촌 민박', '게스트하우스'],
  '경제적': ['아담한 민박', '어촌 민박', '게스트하우스'],
};
const Map<String, int> _accomPrice = {
  '여유있게': 120000, '여유': 120000,
  '보통': 80000,
  '알뜰': 50000, '경제적': 50000,
};

// Supabase island_id → 한국어 섬 이름 (attractions 테이블 island_id 매핑)
// WEB의 ISLAND_ID_TO_KOR(itineraryGenerator.ts)와 동일한 22개 섬으로 유지할 것.
const Map<String, String> islandIdToKor = {
  'baengnyeong': '백령도', 'daecheong': '대청도', 'socheong': '소청도',
  'yeonpyeong': '연평도', 'deokjeok': '덕적도', 'jawol': '자월도',
  'seungbong': '승봉도', 'daeijak': '대이작도', 'soijak': '소이작도',
  'yeonghung': '영흥도', 'pungdo': '풍도', 'guleop': '굴업도',
  'yukdo': '육도', 'seonjae': '선재도', 'sindo': '신도', 'sido': '시도',
  'modo': '모도', 'jangbongdo': '장봉도', 'soya': '소야도',
  'mungap': '문갑도', 'baegado': '백아도', 'uldo': '울도',
};

final _rand = Random();

List<T> _shuffle<T>(List<T> list) {
  final a = List<T>.from(list);
  for (int i = a.length - 1; i > 0; i--) {
    final j = _rand.nextInt(i + 1);
    final tmp = a[i];
    a[i] = a[j];
    a[j] = tmp;
  }
  return a;
}

T _pick<T>(List<T> list) => list[_rand.nextInt(list.length)];

int _getDaysBetween(String startDate, String endDate) {
  final start = DateTime.parse(startDate);
  final end = DateTime.parse(endDate);
  return end.difference(start).inDays + 1;
}

List<String> _selectIslands(TripFormData formData, int numDays) {
  if (formData.islands.isNotEmpty) {
    return formData.islands.sublist(0, min(formData.islands.length, numDays));
  }
  if (formData.departurePort == '대부도') {
    if (numDays == 1) return ['자월도'];
    if (numDays == 2) return ['대이작도'];
    if (numDays >= 3) return ['풍도', '소이작도'];
    return ['자월도'];
  } else if (formData.departurePort == '삼목항') {
    if (numDays == 1) return ['신도'];
    if (numDays >= 2) return ['신도', '장봉도'];
    return ['신도'];
  } else {
    if (numDays == 1) return ['덕적도'];
    if (numDays == 2) return ['덕적도'];
    if (numDays >= 3) return ['백령도', '덕적도'];
    return ['덕적도'];
  }
}

List<Attraction> _getAttractionsForIsland(String island, String travelType, List<Attraction> all, [int count = 3]) {
  const typeMapping = {
    '관광': ['자연경관', '문화', '해변'],
    '휴양': ['해변', '자연경관'],
    '체험': ['체험', '등산', '문화'],
    '사진': ['자연경관', '해변', '문화'],
    '생태': ['자연경관', '등산', '체험'],
    '무장애': ['해변', '문화', '자연경관'],
    '반려동물': ['해변', '자연경관', '체험'],
  };
  final preferred = typeMapping[travelType] ?? ['자연경관', '해변'];

  final matched = _shuffle(all.where((a) => a.island == island).toList());
  matched.sort((a, b) {
    final ia = preferred.indexOf(a.category);
    final ib = preferred.indexOf(b.category);
    final sa = ia != -1 ? preferred.length - ia : 0;
    final sb = ib != -1 ? preferred.length - ib : 0;
    return sb - sa;
  });
  return matched.take(count).toList();
}

/// Supabase `attractions` 테이블에서 실 데이터 로드, 없으면 하드코딩 목록 사용
Future<List<Attraction>> fetchIslandAttractions() async {
  try {
    final data = await Supabase.instance.client.from('attractions').select('*');
    final rows = List<Map<String, dynamic>>.from(data as List);
    final mapped = rows
        .map((r) {
          final island = islandIdToKor[r['island_id'] as String? ?? ''];
          if (island == null) return null;
          final rawDuration = r['duration'];
          final duration = rawDuration is num ? rawDuration.toInt() : _parseDurationText(rawDuration?.toString() ?? '');
          return Attraction(
            id: r['id'] as String,
            name: r['name'] as String? ?? '',
            island: island,
            category: r['category'] as String? ?? '자연경관',
            duration: duration,
            congestionLevel: 'low',
            description: r['description'] as String? ?? '',
          );
        })
        .whereType<Attraction>()
        .toList();
    if (mapped.isNotEmpty) return mapped;
  } catch (_) {
    // Supabase 실패 시 하드코딩 목록으로
  }
  return _hardcodedAttractions;
}

int _parseDurationText(String text) {
  final m = RegExp(r'(\d+(?:\.\d+)?)-?(\d+(?:\.\d+)?)?').firstMatch(text);
  if (m == null) return 90;
  final low = double.parse(m.group(1)!);
  final high = m.group(2) != null ? double.parse(m.group(2)!) : low;
  return (((low + high) / 2) * 60).round();
}

/// 규칙 기반 일정 생성 (AI 실패 시 fallback, 또는 직접 호출)
GeneratedItinerary generateItinerary(TripFormData formData, List<Attraction> allAttractions) {
  final numDays = _getDaysBetween(formData.startDate, formData.endDate);
  final selectedIslands = _selectIslands(formData, numDays);

  final days = <ItineraryDay>[];
  int totalCost = 0;

  for (int dayIndex = 0; dayIndex < numDays; dayIndex++) {
    final currentDate = DateTime.parse(formData.startDate).add(Duration(days: dayIndex));
    final dateString = currentDate.toIso8601String().split('T')[0];

    final activities = <Map<String, dynamic>>[];
    final isFirstDay = dayIndex == 0;
    final isLastDay = dayIndex == numDays - 1;
    final currentIsland = selectedIslands[min(dayIndex, selectedIslands.length - 1)];

    final accomPrice = _accomPrice[formData.budget] ?? 80000;
    final accomName = _pick(_accomNames[formData.budget] ?? _accomNames['보통']!);
    final departurePort = formData.departurePort.isNotEmpty ? formData.departurePort : '인천항';

    if (isFirstDay) {
      FerrySchedule? ferry;
      try {
        ferry = _ferrySchedules.firstWhere((f) => f.from == departurePort && f.to == currentIsland);
      } catch (_) {
        ferry = null;
      }
      if (ferry != null) {
        activities.add({
          'id': 'act-$dayIndex-1', 'type': 'ferry', 'time': ferry.departureTime,
          'title': '여객선 탑승 (${ferry.from} → ${ferry.to})', 'location': ferry.from, 'duration': 0,
          'description': '${ferry.departureTime} 출발 → ${ferry.arrivalTime} 도착',
          'price': ferry.price * formData.travelers, 'bookingStatus': 'available',
        });
        totalCost += ferry.price * formData.travelers;
      }

      final arrivalHour = ferry != null ? int.parse(ferry.arrivalTime.split(':')[0]) : 12;
      activities.add({
        'id': 'act-$dayIndex-2', 'type': 'meal', 'time': '$arrivalHour:30', 'title': '점심 식사',
        'location': currentIsland, 'duration': 60, 'description': _pick(_lunchOptions),
        'price': 15000 * formData.travelers,
      });
      totalCost += 15000 * formData.travelers;

      final afternoonStart = arrivalHour + 2;
      final attractions = _getAttractionsForIsland(currentIsland, formData.travelType, allAttractions, 2);
      for (int idx = 0; idx < attractions.length; idx++) {
        final a = attractions[idx];
        final h = afternoonStart + idx * 2;
        activities.add({
          'id': 'act-$dayIndex-${3 + idx}', 'type': 'attraction', 'time': '${h.toString().padLeft(2, '0')}:00',
          'title': a.name, 'location': a.island, 'duration': a.duration, 'description': a.description,
          'congestionLevel': a.congestionLevel,
        });
      }

      if (numDays == 1) {
        FerrySchedule? returnFerry;
        try {
          returnFerry = _ferrySchedules.firstWhere((f) => f.from == currentIsland && f.to == departurePort);
        } catch (_) {
          returnFerry = null;
        }
        if (returnFerry != null) {
          activities.add({
            'id': 'act-$dayIndex-return', 'type': 'ferry', 'time': returnFerry.departureTime,
            'title': '여객선 탑승 (${returnFerry.from} → ${returnFerry.to})', 'location': returnFerry.from, 'duration': 0,
            'description': '${returnFerry.departureTime} 출발 → ${returnFerry.arrivalTime} 도착',
            'price': returnFerry.price * formData.travelers, 'bookingStatus': 'available',
          });
          totalCost += returnFerry.price * formData.travelers;
        }
      } else {
        activities.add({
          'id': 'act-$dayIndex-accommodation', 'type': 'accommodation', 'time': '18:00',
          'title': '숙소 체크인 — $accomName', 'location': currentIsland, 'duration': 0,
          'description': accomName, 'price': accomPrice, 'bookingStatus': 'available',
        });
        totalCost += accomPrice;
      }
    } else if (isLastDay) {
      activities.add({
        'id': 'act-$dayIndex-1', 'type': 'meal', 'time': '08:00', 'title': '아침 식사',
        'location': currentIsland, 'duration': 60, 'description': '숙소 조식', 'price': 10000 * formData.travelers,
      });
      totalCost += 10000 * formData.travelers;

      final attractions = _getAttractionsForIsland(currentIsland, formData.travelType, allAttractions, 1);
      if (attractions.isNotEmpty) {
        final a = attractions[0];
        activities.add({
          'id': 'act-$dayIndex-2', 'type': 'attraction', 'time': '09:30', 'title': a.name,
          'location': a.island, 'duration': a.duration, 'description': a.description, 'congestionLevel': a.congestionLevel,
        });
      }

      FerrySchedule? returnFerry;
      try {
        returnFerry = _ferrySchedules.firstWhere((f) => f.from == currentIsland && f.to == departurePort);
      } catch (_) {
        returnFerry = null;
      }
      if (returnFerry != null) {
        activities.add({
          'id': 'act-$dayIndex-3', 'type': 'ferry', 'time': returnFerry.departureTime,
          'title': '여객선 탑승 (${returnFerry.from} → ${returnFerry.to})', 'location': returnFerry.from, 'duration': 0,
          'description': '${returnFerry.departureTime} 출발 → ${returnFerry.arrivalTime} 도착',
          'price': returnFerry.price * formData.travelers, 'bookingStatus': 'available',
        });
        totalCost += returnFerry.price * formData.travelers;
      }
    } else {
      activities.add({
        'id': 'act-$dayIndex-1', 'type': 'meal', 'time': '08:00', 'title': '아침 식사',
        'location': currentIsland, 'duration': 60, 'description': '숙소 조식', 'price': 10000 * formData.travelers,
      });
      totalCost += 10000 * formData.travelers;

      final attractions = _getAttractionsForIsland(currentIsland, formData.travelType, allAttractions);
      for (int idx = 0; idx < attractions.length; idx++) {
        final a = attractions[idx];
        final startHour = 10 + (idx * 2);
        activities.add({
          'id': 'act-$dayIndex-${2 + idx}', 'type': 'attraction', 'time': '${startHour.toString().padLeft(2, '0')}:00',
          'title': a.name, 'location': a.island, 'duration': a.duration, 'description': a.description,
          'congestionLevel': a.congestionLevel,
        });
      }

      activities.add({
        'id': 'act-$dayIndex-meal', 'type': 'meal', 'time': '18:00', 'title': '저녁 식사',
        'location': currentIsland, 'duration': 90, 'description': _pick(_dinnerOptions),
        'price': 20000 * formData.travelers,
      });
      totalCost += 20000 * formData.travelers;

      activities.add({
        'id': 'act-$dayIndex-accommodation', 'type': 'accommodation', 'time': '20:00',
        'title': '숙소 휴식 — $accomName', 'location': currentIsland, 'duration': 0,
        'description': accomName, 'price': accomPrice, 'bookingStatus': 'available',
      });
      totalCost += accomPrice;
    }

    days.add(ItineraryDay(date: dateString, dayNumber: dayIndex + 1, activities: activities));
  }

  return GeneratedItinerary(
    title: '${selectedIslands.join(", ")} $numDays일 여행',
    departurePort: formData.departurePort.isNotEmpty ? formData.departurePort : '인천항',
    startDate: formData.startDate,
    endDate: formData.endDate,
    travelers: formData.travelers,
    days: days,
    totalCost: totalCost,
    islands: selectedIslands,
  );
}
