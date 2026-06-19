import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';

class ExperiencesScreen extends StatefulWidget {
  const ExperiencesScreen({super.key});
  @override State<ExperiencesScreen> createState() => _ExperiencesScreenState();
}

class _ExperiencesScreenState extends State<ExperiencesScreen> {
  String _categoryFilter = '전체';

  static const _experiences = [
    {'id': 'e1', 'name': '두무진 유람선 투어', 'island': '백령도', 'category': '관광', 'price': 25000, 'duration': '2시간', 'rating': 4.9, 'reviewCount': 142, 'description': '서해의 금강산이라 불리는 두무진 해안 절벽을 배 위에서 감상하는 투어'},
    {'id': 'e2', 'name': '갯벌 체험', 'island': '덕적도', 'category': '체험', 'price': 15000, 'duration': '1.5시간', 'rating': 4.7, 'reviewCount': 89, 'description': '조개, 게, 낙지를 직접 잡아보는 가족 체험 프로그램'},
    {'id': 'e3', 'name': '카약 투어', 'island': '자월도', 'category': '스포츠', 'price': 40000, 'duration': '2시간', 'rating': 4.8, 'reviewCount': 65, 'description': '자월도 해안을 카약으로 누비며 바다를 즐기는 프로그램'},
    {'id': 'e4', 'name': '야간 별자리 관측', 'island': '대청도', 'category': '체험', 'price': 20000, 'duration': '2시간', 'rating': 5.0, 'reviewCount': 34, 'description': '맑은 하늘에서 밤하늘의 별을 관측하고 천체망원경 체험'},
    {'id': 'e5', 'name': '자전거 투어', 'island': '영흥도', 'category': '스포츠', 'price': 30000, 'duration': '3시간', 'rating': 4.5, 'reviewCount': 78, 'description': '영흥도 해안 도로를 따라 자전거로 섬 한 바퀴 여행'},
    {'id': 'e6', 'name': '스노쿨링 체험', 'island': '덕적도', 'category': '스포츠', 'price': 50000, 'duration': '2시간', 'rating': 4.6, 'reviewCount': 45, 'description': '투명한 바닷속 세계를 직접 탐험하는 스노쿨링 프로그램'},
  ];

  @override
  Widget build(BuildContext context) {
    final categories = ['전체', ...{..._experiences.map((e) => e['category'] as String)}];
    final filtered = _categoryFilter == '전체' ? _experiences : _experiences.where((e) => e['category'] == _categoryFilter).toList();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 124,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
        flexibleSpace: Container(
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
                  const Text('섬 체험', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Text('인천 섬에서 즐길 수 있는 특별한 체험들', style: TextStyle(fontSize: 13, color: Color(0xFFBFDBFE))),
                ],
              ),
            ),
          ),
        ),
      ),
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          // Category filter
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  final selected = cat == _categoryFilter;
                  return GestureDetector(
                    onTap: () => setState(() => _categoryFilter = cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.blue600 : AppColors.gray100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(cat, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.gray700)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final exp = filtered[i];
                final price = exp['price'] as int;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 70, height: 70,
                        decoration: BoxDecoration(color: AppColors.blue50, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.beach_access_rounded, size: 32, color: AppColors.blue600),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(exp['name'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.gray900))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: AppColors.blue100, borderRadius: BorderRadius.circular(4)),
                                  child: Text(exp['category'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.blue700)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.location_on_rounded, size: 12, color: AppColors.gray400),
                              const SizedBox(width: 2),
                              Text(exp['island'] as String, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                              const Text(' • ', style: TextStyle(color: AppColors.gray400, fontSize: 12)),
                              const Icon(Icons.access_time_rounded, size: 12, color: AppColors.gray400),
                              const SizedBox(width: 2),
                              Text(exp['duration'] as String, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                            ]),
                            const SizedBox(height: 4),
                            Text(exp['description'] as String, style: const TextStyle(fontSize: 12, color: AppColors.gray600, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      const Icon(Icons.star_rounded, size: 12, color: Color(0xFFEAB308)),
                                      const SizedBox(width: 2),
                                      Text('${exp['rating']} (${exp['reviewCount']})', style: const TextStyle(fontSize: 11, color: AppColors.gray600)),
                                    ]),
                                    const SizedBox(height: 2),
                                    Text('${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.blue600)),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${exp['name']} 예약이 접수됐어요!'))),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(color: AppColors.blue600, borderRadius: BorderRadius.circular(8)),
                                    child: const Text('예약하기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
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
              },
            ),
          ),
        ],
      ),
    );
  }
}
