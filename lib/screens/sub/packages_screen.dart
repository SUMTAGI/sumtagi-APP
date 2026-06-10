import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});
  @override State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  String _durationFilter = 'all';
  String _priceSort = 'none';

  static const _packages = [
    {'id': 'pkg1', 'name': '1박2일 덕적도 힐링', 'subtitle': '가까운 섬에서 힐링하는 주말여행', 'islands': ['덕적도'], 'duration': '1박 2일', 'nights': 1, 'minPeople': 2, 'maxPeople': 4, 'price': 189000, 'rating': 4.8, 'reviewCount': 142, 'tags': ['힐링', '해변', '가족여행'], 'departurePort': '인천항', 'highlights': ['서포리 해수욕장 자유시간', '비조봉 정상 트레킹', '현지 맛집 투어', '일몰 포토 타임']},
    {'id': 'pkg2', 'name': '2박3일 백령도 완전정복', 'subtitle': '서해 최북단 섬의 모든 것', 'islands': ['백령도'], 'duration': '2박 3일', 'nights': 2, 'minPeople': 2, 'maxPeople': 6, 'price': 459000, 'rating': 4.9, 'reviewCount': 89, 'tags': ['자연경관', '사진', '트레킹'], 'departurePort': '인천항', 'highlights': ['두무진 해안 절벽 투어', '사곶해변 천연비행장', '콩돌해변 석양', '심청각 등 역사 탐방']},
    {'id': 'pkg3', 'name': '1박2일 자월도 로맨틱', 'subtitle': '커플을 위한 낭만 여행', 'islands': ['자월도'], 'duration': '1박 2일', 'nights': 1, 'minPeople': 2, 'maxPeople': 2, 'price': 249000, 'rating': 4.7, 'reviewCount': 156, 'tags': ['커플', '힐링', '일몰'], 'departurePort': '대부도', 'highlights': ['큰말해변 일몰 감상', '2인 카약 투어', '해변 캠핑 파이어', '별빛 사진 촬영']},
    {'id': 'pkg4', 'name': '2박3일 섬 호핑 투어', 'subtitle': '덕적도 + 자월도 + 이작도', 'islands': ['덕적도', '자월도', '이작도'], 'duration': '2박 3일', 'nights': 2, 'minPeople': 4, 'maxPeople': 8, 'price': 389000, 'rating': 4.8, 'reviewCount': 78, 'tags': ['체험', '해변', '모험'], 'departurePort': '인천항', 'highlights': ['3개 섬 탐방', '섬마다 다른 숙소 체험', '해산물 BBQ', '갯벌 체험']},
    {'id': 'pkg5', 'name': '당일 영흥도 체험', 'subtitle': '가장 가까운 섬에서 즐기는 하루', 'islands': ['영흥도'], 'duration': '당일', 'nights': 0, 'minPeople': 2, 'maxPeople': 10, 'price': 89000, 'rating': 4.5, 'reviewCount': 203, 'tags': ['당일', '가족', '체험'], 'departurePort': '인천항', 'highlights': ['십리포 해변', '갯벌 생물 채집', '현지 해산물 점심', '자전거 대여 (옵션)']},
    {'id': 'pkg6', 'name': '3박4일 대청도 & 소청도', 'subtitle': '서해의 숨은 보석을 찾아서', 'islands': ['대청도', '소청도'], 'duration': '3박 4일', 'nights': 3, 'minPeople': 2, 'maxPeople': 6, 'price': 589000, 'rating': 4.9, 'reviewCount': 45, 'tags': ['자연', '사진', '프리미엄'], 'departurePort': '인천항', 'highlights': ['옥죽동 모래사막', '농여해변 절벽', '분바위 일출', '등대 투어']},
  ];

  List<Map<String, dynamic>> get _filtered {
    var list = _packages.where((p) {
      final n = p['nights'] as int;
      if (_durationFilter == '당일') return n == 0;
      if (_durationFilter == '1박') return n == 1;
      if (_durationFilter == '2박이상') return n >= 2;
      return true;
    }).toList();

    if (_priceSort == 'low') list.sort((a, b) => (a['price'] as int).compareTo(b['price'] as int));
    if (_priceSort == 'high') list.sort((a, b) => (b['price'] as int).compareTo(a['price'] as int));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)])),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Row(children: [
                        Icon(Icons.chevron_left, color: Color(0xFFBFDBFE), size: 20),
                        Text('뒤로', style: TextStyle(fontSize: 13, color: Color(0xFFBFDBFE))),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    const Text('패키지 상품', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    const Text('미리 준비된 완벽한 여행 코스', style: TextStyle(fontSize: 13, color: Color(0xFFBFDBFE))),
                  ],
                ),
              ),
            ),
          ),

          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.gray50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('여행 기간', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.gray500)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      {'value': 'all', 'label': '전체'},
                      {'value': '당일', 'label': '당일'},
                      {'value': '1박', 'label': '1박2일'},
                      {'value': '2박이상', 'label': '2박 이상'},
                    ].map((opt) {
                      final selected = _durationFilter == opt['value'];
                      return GestureDetector(
                        onTap: () => setState(() => _durationFilter = opt['value']!),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.blue600 : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: selected ? AppColors.blue600 : AppColors.gray200),
                          ),
                          child: Text(opt['label']!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.gray700)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('가격순', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.gray500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    {'value': 'none', 'label': '기본순'},
                    {'value': 'low', 'label': '낮은 가격'},
                    {'value': 'high', 'label': '높은 가격'},
                  ].map((opt) {
                    final selected = _priceSort == opt['value'];
                    return GestureDetector(
                      onTap: () => setState(() => _priceSort = opt['value']!),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.blue600 : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: selected ? AppColors.blue600 : AppColors.gray200),
                        ),
                        child: Text(opt['label']!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.gray700)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Package list
          Expanded(
            child: filtered.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('검색 결과가 없어요', style: TextStyle(fontSize: 14, color: AppColors.gray500)),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => setState(() { _durationFilter = 'all'; _priceSort = 'none'; }),
                        child: const Text('필터 초기화', style: TextStyle(color: AppColors.blue600, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => _PackageCard(pkg: filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final Map<String, dynamic> pkg;
  const _PackageCard({required this.pkg});

  @override
  Widget build(BuildContext context) {
    final price = pkg['price'] as int;
    final highlights = (pkg['highlights'] as List).cast<String>();
    final tags = (pkg['tags'] as List).cast<String>();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Image area with gradient
          Container(
            height: 160,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade900],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12, left: 12,
                  child: Row(
                    children: tags.take(2).map((tag) => Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(4)),
                      child: Text(tag, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                    )).toList(),
                  ),
                ),
                Positioned(
                  top: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(6)),
                    child: Row(children: [
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFEAB308)),
                      const SizedBox(width: 3),
                      Text('${pkg['rating']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                      Text(' (${pkg['reviewCount']})', style: const TextStyle(fontSize: 11, color: AppColors.gray600)),
                    ]),
                  ),
                ),
                Positioned(
                  bottom: 12, left: 12,
                  child: Text(pkg['name'] as String, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pkg['subtitle'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoChip(icon: Icons.access_time_rounded, label: pkg['duration'] as String),
                    const SizedBox(width: 12),
                    _InfoChip(icon: Icons.people_rounded, label: '${pkg['minPeople']}~${pkg['maxPeople']}명'),
                    const SizedBox(width: 12),
                    _InfoChip(icon: Icons.directions_boat_rounded, label: pkg['departurePort'] as String),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('하이라이트', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.gray500)),
                const SizedBox(height: 6),
                ...highlights.take(3).map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.blue600, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(h, style: const TextStyle(fontSize: 13, color: AppColors.gray700)),
                  ]),
                )),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.gray200),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('1인 기준', style: TextStyle(fontSize: 11, color: AppColors.gray500)),
                        Text('${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.blue600)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${pkg['name']} 일정이 생성됐어요!'))),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(color: AppColors.blue600, borderRadius: BorderRadius.circular(8)),
                        child: const Row(children: [
                          Text('일정 생성', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 16, color: Colors.white),
                        ]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 14, color: AppColors.gray400),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.gray700)),
    ]);
  }
}
