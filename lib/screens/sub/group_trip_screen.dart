import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class GroupTripScreen extends StatefulWidget {
  const GroupTripScreen({super.key});
  @override State<GroupTripScreen> createState() => _GroupTripScreenState();
}

class _GroupTripScreenState extends State<GroupTripScreen> {
  final List<Map<String, dynamic>> _groups = [
    {'id': 'g1', 'name': '2026 여름 백령도 탐험대', 'island': '백령도', 'date': '2026-08-01', 'members': ['김철수', '이영희', '박민준'], 'maxMembers': 6, 'status': '모집중'},
    {'id': 'g2', 'name': '덕적도 힐링 여행 모집', 'island': '덕적도', 'date': '2026-07-15', 'members': ['홍길동', '김순희'], 'maxMembers': 4, 'status': '모집중'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('그룹 여행', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text('함께 떠나는 섬 여행', style: TextStyle(fontSize: 11, color: AppColors.gray500)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
        titleSpacing: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('그룹 생성 기능은 곧 추가될 예정이에요'))),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.blue600, borderRadius: BorderRadius.circular(8)),
                child: const Row(children: [
                  Icon(Icons.add, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text('그룹 만들기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                ]),
              ),
            ),
          ),
        ],
      ),
      body: _groups.isEmpty
          ? const Center(child: Text('참여 중인 그룹이 없어요', style: TextStyle(color: AppColors.gray500)))
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _groups.length,
              itemBuilder: (context, i) {
                final group = _groups[i];
                final members = (group['members'] as List).cast<String>();
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(group['name'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.gray900))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.blue100, borderRadius: BorderRadius.circular(20)),
                            child: Text(group['status'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.blue700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: AppColors.gray500),
                        const SizedBox(width: 4),
                        Text(group['island'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray700)),
                        const SizedBox(width: 12),
                        const Icon(Icons.calendar_month_rounded, size: 14, color: AppColors.gray500),
                        const SizedBox(width: 4),
                        Text(group['date'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray700)),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        const Icon(Icons.people_rounded, size: 14, color: AppColors.gray500),
                        const SizedBox(width: 4),
                        Text('${members.length}/${group['maxMembers']}명', style: const TextStyle(fontSize: 13, color: AppColors.gray700)),
                        const SizedBox(width: 8),
                        Text(members.take(3).join(', '), style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                      ]),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('상세보기 기능은 곧 추가될 예정이에요'))),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(8)),
                                alignment: Alignment.center,
                                child: const Text('상세보기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('참여 신청이 완료됐어요!'))),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(color: AppColors.blue600, borderRadius: BorderRadius.circular(8)),
                                alignment: Alignment.center,
                                child: const Text('참여 신청', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
