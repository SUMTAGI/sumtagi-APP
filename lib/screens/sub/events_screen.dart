import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});
  @override State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  int _selectedMonth = DateTime.now().month;
  String _islandFilter = 'all';

  static const _events = [
    {'id': 'evt1', 'name': '백령도 조기축제', 'island': '백령도', 'category': '축제', 'startDate': '2026-04-15', 'endDate': '2026-04-17', 'location': '백령항 일대', 'description': '서해 최고의 조기를 맛보고 즐기는 봄 축제. 조기 요리 시연, 시식회, 어선 체험 등 다채로운 프로그램', 'fee': '무료', 'contact': '032-899-3000'},
    {'id': 'evt2', 'name': '덕적도 해변음악회', 'island': '덕적도', 'category': '공연', 'startDate': '2026-07-20', 'endDate': '2026-07-20', 'location': '서포리 해수욕장', 'description': '여름밤 해변에서 즐기는 라이브 공연. 인디밴드와 함께하는 낭만적인 저녁', 'fee': '무료', 'contact': '032-831-2210'},
    {'id': 'evt3', 'name': '자월도 동백꽃 축제', 'island': '자월도', 'category': '축제', 'startDate': '2026-03-10', 'endDate': '2026-03-20', 'location': '자월도 동백숲', 'description': '봄을 알리는 붉은 동백꽃이 만발하는 시기에 열리는 꽃 축제', 'fee': '무료', 'contact': '032-899-2114'},
    {'id': 'evt4', 'name': '덕적도 갯벌체험축제', 'island': '덕적도', 'category': '체험', 'startDate': '2026-05-01', 'endDate': '2026-05-05', 'location': '덕적도 갯벌', 'description': '조개, 게, 낙지를 직접 잡아보는 가족 체험 행사. 갯벌 생태 학습과 체험이 함께하는 축제', 'fee': '1만원 (체험키트 포함)', 'contact': '032-831-2210'},
    {'id': 'evt5', 'name': '백령도 전통문화체험', 'island': '백령도', 'category': '문화행사', 'startDate': '2026-08-15', 'endDate': '2026-08-15', 'location': '백령면사무소 광장', 'description': '전통 놀이, 민속 공연, 지역 특산물 장터가 열리는 여름 문화 행사', 'fee': '무료', 'contact': '032-899-3000'},
    {'id': 'evt6', 'name': '대청도 별빛축제', 'island': '대청도', 'category': '축제', 'startDate': '2026-08-01', 'endDate': '2026-08-03', 'location': '대청도 해변', 'description': '도시에서는 볼 수 없는 맑은 밤하늘의 별을 관측하는 축제. 천체망원경 체험, 별자리 교육', 'fee': '무료', 'contact': '032-899-2114'},
    {'id': 'evt7', 'name': '풍도 동백축제', 'island': '풍도', 'category': '축제', 'startDate': '2026-03-15', 'endDate': '2026-03-25', 'location': '풍도 동백나무숲', 'description': '천연기념물 동백나무 자생지에서 열리는 봄맞이 축제', 'fee': '무료', 'contact': '032-830-2000'},
  ];

  List<Map<String, dynamic>> get _filtered => _events.where((e) {
    final month = int.parse((e['startDate'] as String).split('-')[1]);
    final matchMonth = month == _selectedMonth;
    final matchIsland = _islandFilter == 'all' || e['island'] == _islandFilter;
    return matchMonth && matchIsland;
  }).toList();

  List<String> get _islands => ['all', ...{..._events.map((e) => e['island'] as String)}];

  Color _catBg(String cat) {
    if (cat == '축제') return const Color(0xFFFCE7F3);
    if (cat == '문화행사') return AppColors.blue100;
    if (cat == '체험') return const Color(0xFFDCFCE7);
    return AppColors.blue100;
  }

  Color _catText(String cat) {
    if (cat == '축제') return const Color(0xFFBE185D);
    if (cat == '문화행사') return AppColors.blue700;
    if (cat == '체험') return const Color(0xFF15803D);
    return AppColors.blue700;
  }

  String _formatDate(String start, String end) {
    final s = DateTime.parse(start);
    final e = DateTime.parse(end);
    if (start == end) return '${s.month}월 ${s.day}일';
    return '${s.month}월 ${s.day}일 - ${e.month}월 ${e.day}일';
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
                    const Text('이벤트 & 축제', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    const Text('섬에서 열리는 특별한 행사를 확인하세요', style: TextStyle(fontSize: 13, color: Color(0xFFBFDBFE))),
                  ],
                ),
              ),
            ),
          ),

          // Month selector
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(12, (i) {
                  final m = i + 1;
                  final selected = m == _selectedMonth;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMonth = m),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.blue600 : AppColors.gray100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$m월', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.gray700)),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Island filter
          Container(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            color: AppColors.gray50,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _islands.map((island) {
                  final selected = island == _islandFilter;
                  return GestureDetector(
                    onTap: () => setState(() => _islandFilter = island),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.blue600 : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: selected ? AppColors.blue600 : AppColors.gray200),
                      ),
                      child: Text(island == 'all' ? '전체 섬' : island, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.gray700)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Events
          Expanded(
            child: filtered.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.event_rounded, size: 64, color: AppColors.gray300),
                      SizedBox(height: 16),
                      Text('이번 달 예정된 행사가 없어요', style: TextStyle(fontSize: 14, color: AppColors.gray500)),
                      SizedBox(height: 4),
                      Text('다른 월을 선택해보세요', style: TextStyle(fontSize: 12, color: AppColors.gray400)),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final event = filtered[i];
                      return _EventCard(event: event, catBg: _catBg(event['category'] as String), catText: _catText(event['category'] as String), formatDate: _formatDate);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatefulWidget {
  final Map<String, dynamic> event;
  final Color catBg, catText;
  final String Function(String, String) formatDate;
  const _EventCard({required this.event, required this.catBg, required this.catText, required this.formatDate});
  @override State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Image placeholder with gradient
          Container(
            height: 140,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12, left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: widget.catBg, borderRadius: BorderRadius.circular(20)),
                    child: Text(event['category'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: widget.catText)),
                  ),
                ),
                Positioned(
                  bottom: 12, left: 12, right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event['name'] as String, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: Colors.white70),
                        const SizedBox(width: 2),
                        Text(event['island'] as String, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.calendar_month_rounded, size: 14, color: AppColors.gray400),
                  const SizedBox(width: 6),
                  Text(widget.formatDate(event['startDate'] as String, event['endDate'] as String), style: const TextStyle(fontSize: 13, color: AppColors.gray700)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: AppColors.gray400),
                  const SizedBox(width: 6),
                  Text(event['location'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray700)),
                ]),
                const SizedBox(height: 10),
                Text(event['description'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray600, height: 1.5), maxLines: _expanded ? null : 2, overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis),
                if (_expanded) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.gray50, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('참가비', style: TextStyle(fontSize: 12, color: AppColors.gray600)),
                        Text(event['fee'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(8)),
                          alignment: Alignment.center,
                          child: Text(_expanded ? '접기' : '자세히 보기', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${event['name']}를 즐겨찾기에 추가했어요'))),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(color: AppColors.blue600, borderRadius: BorderRadius.circular(8)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_rounded, size: 16, color: Colors.white),
                              SizedBox(width: 4),
                              Text('즐겨찾기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
                            ],
                          ),
                        ),
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
