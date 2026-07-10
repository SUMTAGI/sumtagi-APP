import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});
  @override State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  String _selectedIsland = '백령도';
  String? _expandedAid;

  static const _contacts = [
    {
      'island': '백령도',
      'hospital': {'name': '백령보건지소', 'phone': '032-899-3100', 'address': '백령면 백령리 328'},
      'pharmacy': {'name': '백령약국', 'phone': '032-836-3275', 'address': '백령면 백령리 505'},
      'police': {'name': '백령파출소', 'phone': '032-836-3112', 'address': '백령면 백령리 458'},
      'coastGuard': {'name': '백령해경', 'phone': '032-836-5117'},
    },
    {
      'island': '덕적도',
      'hospital': {'name': '덕적보건지소', 'phone': '032-899-3200', 'address': '덕적면 진리 468-2'},
      'pharmacy': {'name': '덕적약국', 'phone': '032-831-8275', 'address': '덕적면 진리 489'},
      'police': {'name': '덕적파출소', 'phone': '032-831-3112', 'address': '덕적면 진리 453'},
      'coastGuard': {'name': '덕적파출소', 'phone': '032-832-0857'},
    },
    {
      'island': '자월도',
      'hospital': {'name': '자월보건진료소', 'phone': '032-899-3300', 'address': '자월면 자월리 230'},
      'police': {'name': '자월파출소', 'phone': '032-832-3112', 'address': '자월면 자월리 195'},
      'coastGuard': {'name': '자월파출소', 'phone': '032-832-2857'},
    },
    {
      'island': '대청도',
      'hospital': {'name': '대청보건지소', 'phone': '032-899-3150', 'address': '대청면 대청리 234'},
      'police': {'name': '대청파출소', 'phone': '032-836-3114', 'address': '대청면 대청리 189'},
      'coastGuard': {'name': '대청해경', 'phone': '032-836-5119'},
    },
    {
      'island': '영흥도',
      'hospital': {'name': '영흥보건지소', 'phone': '032-899-3250', 'address': '영흥면 내리 391'},
      'pharmacy': {'name': '영흥약국', 'phone': '032-886-8275', 'address': '영흥면 내리 458'},
      'police': {'name': '영흥파출소', 'phone': '032-886-3112', 'address': '영흥면 내리 423'},
      'coastGuard': {'name': '영흥파출소', 'phone': '032-886-0857'},
    },
    {
      'island': '소청도',
      'hospital': {'name': '대청보건지소(대청면 관할)', 'phone': '032-899-3120', 'address': '대청면 대청리'},
      'police': {'name': '대청파출소', 'phone': '032-836-3114', 'address': '대청면 대청리 189'},
      'coastGuard': {'name': '대청해경', 'phone': '032-836-5119'},
    },
    {
      'island': '연평도',
      'hospital': {'name': '연평보건지소', 'phone': '032-899-3120', 'address': '연평면 연평리'},
      'police': {'name': '연평파출소', 'phone': '112', 'address': '연평면 연평로 152'},
      'coastGuard': {'name': '인천해양경찰서 연평파출소', 'phone': '032-650-2125'},
    },
    {
      'island': '승봉도',
      'hospital': {'name': '승봉보건진료소', 'phone': '032-899-3120', 'address': '자월면 승봉리'},
      'police': {'name': '자월파출소(자월면 관할)', 'phone': '032-832-3112', 'address': '자월면 자월리 195'},
      'coastGuard': {'name': '자월파출소', 'phone': '032-832-2857'},
    },
    {
      'island': '대이작도',
      'hospital': {'name': '대이작보건진료소', 'phone': '032-899-3120', 'address': '자월면 대이작리'},
      'police': {'name': '자월파출소(자월면 관할)', 'phone': '032-832-3112', 'address': '자월면 자월리 195'},
      'coastGuard': {'name': '자월파출소', 'phone': '032-832-2857'},
    },
    {
      'island': '소이작도',
      'hospital': {'name': '소이작보건진료소', 'phone': '032-899-3120', 'address': '자월면 소이작리'},
      'police': {'name': '자월파출소(자월면 관할)', 'phone': '032-832-3112', 'address': '자월면 자월리 195'},
      'coastGuard': {'name': '자월파출소', 'phone': '032-832-2857'},
    },
    {
      'island': '굴업도',
      'hospital': {'name': '굴업보건진료소', 'phone': '032-899-3120', 'address': '덕적면 굴업리'},
      'police': {'name': '덕적파출소(덕적면 관할)', 'phone': '032-831-3112', 'address': '덕적면 진리 453'},
      'coastGuard': {'name': '덕적파출소', 'phone': '032-832-0857'},
    },
    {
      'island': '풍도',
      'hospital': {'name': '풍도보건진료소', 'phone': '031-481-3000', 'address': '경기도 안산시 단원구 풍도동'},
      'police': {'name': '안산단원경찰서 대부파출소 풍도분소', 'phone': '112', 'address': '경기도 안산시 단원구 풍도동'},
      'coastGuard': {'name': '해양경찰(공통)', 'phone': '122'},
    },
    {
      'island': '육도',
      'police': {'name': '안산단원경찰서 대부파출소', 'phone': '112', 'address': '경기도 안산시 단원구 대부동'},
      'coastGuard': {'name': '해양경찰(공통)', 'phone': '122'},
    },
    {
      'island': '신도',
      'hospital': {'name': '북도보건지소(북도면 관할)', 'phone': '032-899-3120', 'address': '북도면 시도리'},
      'police': {'name': '북도파출소', 'phone': '112', 'address': '북도면 시도리'},
      'coastGuard': {'name': '해양경찰(공통)', 'phone': '122'},
    },
    {
      'island': '시도',
      'hospital': {'name': '북도보건지소', 'phone': '032-899-3120', 'address': '북도면 시도리'},
      'police': {'name': '북도파출소', 'phone': '112', 'address': '북도면 시도리'},
      'coastGuard': {'name': '해양경찰(공통)', 'phone': '122'},
    },
    {
      'island': '모도',
      'hospital': {'name': '북도보건지소(북도면 관할)', 'phone': '032-899-3120', 'address': '북도면 시도리'},
      'police': {'name': '북도파출소', 'phone': '112', 'address': '북도면 시도리'},
      'coastGuard': {'name': '해양경찰(공통)', 'phone': '122'},
    },
    {
      'island': '장봉도',
      'hospital': {'name': '북도보건지소(북도면 관할)', 'phone': '032-899-3120', 'address': '북도면 시도리'},
      'police': {'name': '북도파출소', 'phone': '112', 'address': '북도면 시도리'},
      'coastGuard': {'name': '해양경찰(공통)', 'phone': '122'},
    },
    {
      'island': '소야도',
      'hospital': {'name': '소야보건진료소', 'phone': '032-899-3120', 'address': '덕적면 소야리'},
      'police': {'name': '덕적파출소(덕적면 관할)', 'phone': '032-831-3112', 'address': '덕적면 진리 453'},
      'coastGuard': {'name': '덕적파출소', 'phone': '032-832-0857'},
    },
    {
      'island': '문갑도',
      'hospital': {'name': '문갑보건진료소', 'phone': '032-899-3120', 'address': '덕적면 문갑리'},
      'police': {'name': '덕적파출소(덕적면 관할)', 'phone': '032-831-3112', 'address': '덕적면 진리 453'},
      'coastGuard': {'name': '덕적파출소', 'phone': '032-832-0857'},
    },
    {
      'island': '백아도',
      'hospital': {'name': '백아보건진료소', 'phone': '032-899-3120', 'address': '덕적면 백아리'},
      'police': {'name': '덕적파출소(덕적면 관할)', 'phone': '032-831-3112', 'address': '덕적면 진리 453'},
      'coastGuard': {'name': '덕적파출소', 'phone': '032-832-0857'},
    },
    {
      'island': '울도',
      'hospital': {'name': '울도보건진료소', 'phone': '032-899-3120', 'address': '덕적면 울도리'},
      'police': {'name': '덕적파출소(덕적면 관할)', 'phone': '032-831-3112', 'address': '덕적면 진리 453'},
      'coastGuard': {'name': '덕적파출소', 'phone': '032-832-0857'},
    },
  ];
  // 개별 직통번호가 검색으로 확인되지 않은 곳은 옹진군보건소 대표번호(032-899-3120)·112·122(전국 공통, 실제 연결됨)로 대체.
  // 정확한 직통번호가 필요하면 옹진군청(032-899-3120) 또는 인천중부경찰서 민원실(032-760-8324)에 문의 권장.

  static const _firstAid = [
    {'id': '1', 'title': '해파리 쏘임', 'symptoms': '통증, 붉은 반점, 부종', 'treatment': ['즉시 바닷물로 씻어내기 (수돗물 사용 금지)', '촉수나 자포 제거', '식초나 베이킹소다로 중화', '얼음으로 냉찜질', '심한 경우 즉시 병원 방문']},
    {'id': '2', 'title': '열사병', 'symptoms': '고열, 두통, 현기증, 구토', 'treatment': ['그늘진 곳으로 이동', '젖은 수건으로 몸 식히기', '물 또는 이온음료 섭취', '의식이 없으면 즉시 119 신고', '병원으로 신속 이송']},
    {'id': '3', 'title': '멀미', 'symptoms': '메스꺼움, 구토, 어지러움', 'treatment': ['갑판 위 신선한 공기 쐬기', '멀리 수평선 바라보기', '멀미약 복용 (출항 30분 전)', '생강차나 박하사탕 섭취', '누워서 눈 감고 휴식']},
    {'id': '4', 'title': '베임/찰과상', 'symptoms': '출혈, 상처', 'treatment': ['깨끗한 물로 상처 세척', '지혈 (거즈로 압박)', '소독약 바르기', '밴드나 붕대로 감기', '깊은 상처는 병원 방문']},
  ];

  void _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final contact = _contacts.firstWhere((c) => c['island'] == _selectedIsland, orElse: () => _contacts.first);

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
                  const Text('긴급 연락처', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Text('위급한 상황에 대비하세요', style: TextStyle(fontSize: 13, color: Color(0xFFBFDBFE))),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 119/112 Quick Access
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.blue50,
            child: Row(
              children: [
                Expanded(
                  child: _EmergencyBtn(
                    icon: Icons.warning_amber_rounded,
                    small: '화재·응급',
                    number: '119',
                    onTap: () => _call('119'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _EmergencyBtn(
                    icon: Icons.shield_rounded,
                    small: '범죄·사고',
                    number: '112',
                    onTap: () => _call('112'),
                  ),
                ),
              ],
            ),
          ),

          // Island selector
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.gray200))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('섬 선택', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _contacts.map((c) {
                      final island = c['island'] as String;
                      final selected = island == _selectedIsland;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIsland = island),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.blue600 : AppColors.gray100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(island, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.gray700)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$_selectedIsland 연락처', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                        const SizedBox(height: 12),
                        if (contact['hospital'] != null)
                          _ContactCard(icon: Icons.local_hospital_rounded, iconColor: AppColors.blue600, title: (contact['hospital'] as Map)['name'] as String, subtitle: '병원', phone: (contact['hospital'] as Map)['phone'] as String, address: (contact['hospital'] as Map)['address'] as String, onCall: _call),
                        if (contact['pharmacy'] != null)
                          _ContactCard(icon: Icons.medical_services_rounded, iconColor: const Color(0xFF16A34A), title: (contact['pharmacy'] as Map)['name'] as String, subtitle: '약국', phone: (contact['pharmacy'] as Map)['phone'] as String, address: (contact['pharmacy'] as Map)['address'] as String, onCall: _call),
                        _ContactCard(icon: Icons.local_police_rounded, iconColor: AppColors.blue600, title: (contact['police'] as Map)['name'] as String, subtitle: '경찰서', phone: (contact['police'] as Map)['phone'] as String, address: (contact['police'] as Map)['address'] as String?, onCall: _call),
                        _ContactCard(icon: Icons.directions_boat_rounded, iconColor: const Color(0xFF4F46E5), title: (contact['coastGuard'] as Map)['name'] as String, subtitle: '해양경찰', phone: (contact['coastGuard'] as Map)['phone'] as String, onCall: _call),
                      ],
                    ),
                  ),

                  // First Aid
                  Container(
                    padding: const EdgeInsets.all(24),
                    color: AppColors.gray50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('응급처치 가이드', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                        const SizedBox(height: 12),
                        ...(_firstAid.map((aid) {
                          final expanded = _expandedAid == aid['id'];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
                            clipBehavior: Clip.hardEdge,
                            child: Column(
                              children: [
                                ListTile(
                                  title: Text(aid['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                                  subtitle: Text(aid['symptoms'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
                                  trailing: Icon(expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppColors.gray400),
                                  onTap: () => setState(() => _expandedAid = expanded ? null : aid['id'] as String),
                                ),
                                if (expanded)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: AppColors.blue50, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.blue100)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('응급처치 방법', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.blue900)),
                                          const SizedBox(height: 8),
                                          ...(((aid['treatment'] as List)).asMap().entries.map((e) => Padding(
                                            padding: const EdgeInsets.only(bottom: 6),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('${e.key + 1}. ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.blue800)),
                                                Expanded(child: Text(e.value as String, style: const TextStyle(fontSize: 13, color: AppColors.blue800, height: 1.4))),
                                              ],
                                            ),
                                          ))),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        })),
                      ],
                    ),
                  ),

                  // Emergency Return
                  Container(
                    padding: const EdgeInsets.all(24),
                    color: const Color(0xFFFFF7ED),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFED7AA))),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_rounded, size: 24, color: Color(0xFFEA580C)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('긴급 귀항 안내', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                                SizedBox(height: 8),
                                Text('• 기상 악화 시 여객선 결항 가능', style: TextStyle(fontSize: 13, color: AppColors.gray700, height: 1.6)),
                                Text('• 헬기 긴급 수송: 119 또는 해경 연락', style: TextStyle(fontSize: 13, color: AppColors.gray700, height: 1.6)),
                                Text('• 응급 환자는 최우선 이송', style: TextStyle(fontSize: 13, color: AppColors.gray700, height: 1.6)),
                                Text('• 여행자 보험 가입 권장', style: TextStyle(fontSize: 13, color: AppColors.gray700, height: 1.6)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyBtn extends StatelessWidget {
  final IconData icon;
  final String small, number;
  final VoidCallback onTap;
  const _EmergencyBtn({required this.icon, required this.small, required this.number, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.blue500, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: AppColors.blue600),
            const SizedBox(width: 10),
            Column(
              children: [
                Text(small, style: const TextStyle(fontSize: 13, color: AppColors.blue600)),
                Text(number, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.blue600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle, phone;
  final String? address;
  final void Function(String) onCall;

  const _ContactCard({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.phone, this.address, required this.onCall});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.gray50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.gray200)),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
                if (address != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 12, color: AppColors.gray500),
                      const SizedBox(width: 2),
                      Expanded(child: Text(address!, style: const TextStyle(fontSize: 13, color: AppColors.gray600))),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => onCall(phone),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.blue600, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(phone, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
