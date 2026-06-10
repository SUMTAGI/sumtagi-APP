import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});
  @override State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  int _tab = 0;
  String _categoryFilter = 'all';

  final List<Map<String, dynamic>> _coupons = [
    {'id': 'c1', 'title': '백령리조트 20% 할인', 'category': '숙박', 'discount': '20%', 'description': '1박 이상 예약 시 20% 할인', 'island': '백령도', 'expiryDate': '2026-12-31', 'minAmount': 100000, 'isDownloaded': false, 'code': 'BAEK20'},
    {'id': 'c2', 'title': '덕적펜션 얼리버드', 'category': '숙박', 'discount': '15%', 'description': '30일 전 예약 시 15% 할인', 'island': '덕적도', 'expiryDate': '2026-11-30', 'minAmount': 80000, 'isDownloaded': false, 'code': 'EARLY15'},
    {'id': 'c3', 'title': '백령횟집 10,000원 할인', 'category': '맛집', 'discount': '10,000원', 'description': '5만원 이상 주문 시', 'island': '백령도', 'expiryDate': '2026-10-31', 'minAmount': 50000, 'isDownloaded': false, 'code': 'FISH10K'},
    {'id': 'c4', 'title': '덕적맛집 무료 음료', 'category': '맛집', 'discount': '음료 1잔', 'description': '회 주문 시 음료 1잔 무료', 'island': '덕적도', 'expiryDate': '2026-09-30', 'isDownloaded': false, 'code': 'DRINK1'},
    {'id': 'c5', 'title': '카약 체험 30% 할인', 'category': '체험', 'discount': '30%', 'description': '자월도 카약 투어', 'island': '자월도', 'expiryDate': '2026-08-31', 'minAmount': 40000, 'isDownloaded': false, 'code': 'KAYAK30'},
    {'id': 'c6', 'title': '갯벌체험 20% 할인', 'category': '체험', 'discount': '20%', 'description': '가족 단위 예약 시', 'island': '덕적도', 'expiryDate': '2026-07-31', 'minAmount': 30000, 'isDownloaded': false, 'code': 'MUD20'},
    {'id': 'c7', 'title': '여객선 왕복 5% 할인', 'category': '교통', 'discount': '5%', 'description': '왕복 티켓 구매 시', 'island': '전체', 'expiryDate': '2026-12-31', 'minAmount': 40000, 'isDownloaded': false, 'code': 'ROUND5'},
    {'id': 'c8', 'title': '자전거 대여 무료', 'category': '교통', 'discount': '무료 (4시간)', 'description': '전동스쿠터 대여 시', 'island': '영흥도', 'expiryDate': '2026-10-31', 'isDownloaded': false, 'code': 'BIKE4H'},
  ];

  List<Map<String, dynamic>> get _filtered => _coupons.where((c) {
    final tabMatch = _tab == 0 ? !(c['isDownloaded'] as bool) : (c['isDownloaded'] as bool);
    final catMatch = _categoryFilter == 'all' || c['category'] == _categoryFilter;
    return tabMatch && catMatch;
  }).toList();

  int _daysLeft(String expiry) {
    final now = DateTime.now();
    final exp = DateTime.parse(expiry);
    return exp.difference(now).inDays;
  }

  void _download(String id) {
    final idx = _coupons.indexWhere((c) => c['id'] == id);
    if (idx == -1) return;
    setState(() => _coupons[idx] = {..._coupons[idx], 'isDownloaded': true});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('쿠폰이 다운로드됐어요!')));
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
                    const Text('쿠폰', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    const Text('특별 할인과 혜택을 받으세요', style: TextStyle(fontSize: 13, color: Color(0xFFBFDBFE))),
                  ],
                ),
              ),
            ),
          ),

          // Tabs
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(child: _TabBtn(label: '받을 수 있는 쿠폰', selected: _tab == 0, onTap: () => setState(() => _tab = 0))),
                const SizedBox(width: 8),
                Expanded(child: _TabBtn(label: '내 쿠폰함', selected: _tab == 1, onTap: () => setState(() => _tab = 1))),
              ],
            ),
          ),

          // Category filter
          Container(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            color: AppColors.gray50,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['all', '숙박', '맛집', '체험', '교통'].map((cat) {
                  final selected = cat == _categoryFilter;
                  return GestureDetector(
                    onTap: () => setState(() => _categoryFilter = cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.blue600 : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: selected ? AppColors.blue600 : AppColors.gray200),
                      ),
                      child: Text(cat == 'all' ? '전체' : cat, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.gray700)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Coupons
          Expanded(
            child: filtered.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.card_giftcard_rounded, size: 64, color: AppColors.gray300),
                      const SizedBox(height: 16),
                      Text(_tab == 0 ? '사용 가능한 쿠폰이 없어요' : '다운로드한 쿠폰이 없어요', style: const TextStyle(fontSize: 14, color: AppColors.gray500)),
                      const SizedBox(height: 4),
                      Text(_tab == 0 ? '다른 카테고리를 선택해보세요' : '받을 수 있는 쿠폰을 확인해보세요', style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final coupon = filtered[i];
                      final days = _daysLeft(coupon['expiryDate'] as String);
                      final downloaded = coupon['isDownloaded'] as bool;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.gray300, style: BorderStyle.solid, width: 1.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: const BoxDecoration(color: AppColors.blue600, shape: BoxShape.circle),
                                    child: Icon(_catIcon(coupon['category'] as String), size: 24, color: Colors.white),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(coupon['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                                        Text(coupon['island'] as String, style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
                                        Text(coupon['description'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(coupon['discount'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.blue600)),
                                      const Text('할인', style: TextStyle(fontSize: 11, color: AppColors.gray500)),
                                    ],
                                  ),
                                ],
                              ),
                              if (coupon['minAmount'] != null) ...[
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('${(coupon['minAmount'] as int).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원 이상 구매 시', style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(children: [
                                    const Icon(Icons.access_time_rounded, size: 12, color: AppColors.gray500),
                                    const SizedBox(width: 3),
                                    Text(days > 0 ? '$days일 남음' : '기간 만료', style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
                                  ]),
                                  if (downloaded)
                                    GestureDetector(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: coupon['code'] as String));
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('쿠폰 코드가 복사됐어요')));
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: AppColors.blue50, borderRadius: BorderRadius.circular(4)),
                                        child: Text(coupon['code'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.blue600)),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (!downloaded)
                                GestureDetector(
                                  onTap: days > 0 ? () => _download(coupon['id'] as String) : null,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: days > 0 ? AppColors.blue600 : AppColors.gray300,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.download_rounded, size: 16, color: Colors.white),
                                        SizedBox(width: 6),
                                        Text('쿠폰 받기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(8)),
                                  alignment: Alignment.center,
                                  child: const Text('보유 중인 쿠폰', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray700)),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _catIcon(String cat) {
    if (cat == '숙박') return Icons.hotel_rounded;
    if (cat == '맛집') return Icons.restaurant_rounded;
    if (cat == '체험') return Icons.camera_alt_rounded;
    return Icons.directions_boat_rounded;
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue600 : AppColors.gray100,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.gray700)),
      ),
    );
  }
}
