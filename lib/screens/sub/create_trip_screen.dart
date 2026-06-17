import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/trip_service.dart';
import '../../theme/app_colors.dart';

class CreateTripScreen extends StatefulWidget {
  final String? preSelectedIsland;
  const CreateTripScreen({super.key, this.preSelectedIsland});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  int _step = 0;
  String _departurePort = '';
  List<String> _selectedIslands = [];
  DateTime? _startDate;
  DateTime? _endDate;
  int _travelers = 2;
  String _travelType = '';
  String _budget = '보통';

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedIsland != null) {
      _selectedIslands = [widget.preSelectedIsland!];
    }
  }

  List<String> get _availableIslands => switch (_departurePort) {
    '인천항' => ['백령도', '대청도', '소청도', '연평도', '덕적도', '자월도', '승봉도', '대이작도'],
    '대부도' => ['자월도', '승봉도', '대이작도', '소이작도', '덕적도', '풍도', '육도'],
    _ => [],
  };

  bool get _hasPreSelected => widget.preSelectedIsland != null;

  bool _isSubmitting = false;

  void _handleSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final days = [
        {
          'dayNumber': 1,
          'date': _startDate!.toIso8601String().split('T')[0],
          'activities': [
            {'id': '1', 'type': 'ferry', 'time': '07:00', 'title': '$_departurePort 출발', 'description': '여객선 탑승', 'location': _departurePort, 'price': 45000},
            {'id': '2', 'type': 'attraction', 'time': '11:00', 'title': '${_selectedIslands.first} 도착', 'description': '섬 탐방 시작', 'location': _selectedIslands.first, 'price': 0},
            {'id': '3', 'type': 'meal', 'time': '13:00', 'title': '해산물 점심', 'description': '신선한 해산물 정식', 'location': _selectedIslands.first, 'price': 15000},
            {'id': '4', 'type': 'accommodation', 'time': '18:00', 'title': '민박 체크인', 'description': '섬 민박 숙박', 'location': _selectedIslands.first, 'price': 60000},
          ],
        },
      ];

      final id = await TripService.createTrip(
        title: '${_selectedIslands.join(', ')} 여행',
        departurePort: _departurePort,
        islands: _selectedIslands,
        startDate: _startDate!.toIso8601String().split('T')[0],
        endDate: _endDate!.toIso8601String().split('T')[0],
        travelers: _travelers,
        travelType: _travelType,
        budget: _budget,
        totalCost: 80000 * _travelers,
        days: days,
      );

      if (mounted) context.pushReplacement('/itinerary/$id');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('일정 생성 중 오류가 발생했어요'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: AppColors.gray900,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: _buildStep())),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final totalSteps = _hasPreSelected ? 3 : 4;
    final currentStep = _hasPreSelected ? (_step == 0 ? 1 : _step == 2 ? 2 : 3) : _step + 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.gray200))),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.gray700, size: 20),
            onPressed: () {
              if (_step == 0) {
                context.pop();
              } else {
                setState(() => _step--);
              }
            },
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_hasPreSelected ? '${widget.preSelectedIsland} 일정 만들기' : '일정 만들기',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.gray900)),
              Text('Step $currentStep / $totalSteps', style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final steps = _hasPreSelected ? 3 : 4;
    final current = _step == 0 ? 0 : _step == 2 ? 1 : 2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.gray200))),
      child: Row(
        children: List.generate(steps, (i) {
          final filled = i <= (current + (_step == 3 ? 1 : 0));
          return Expanded(
            child: Container(
              height: 8,
              margin: EdgeInsets.only(right: i < steps - 1 ? 6 : 0),
              decoration: BoxDecoration(
                color: filled ? AppColors.blue600 : AppColors.gray200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      0 => _buildStep0(),
      1 => _buildStep1(),
      2 => _buildStep2(),
      3 => _buildStep3(),
      _ => const SizedBox(),
    };
  }

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasPreSelected) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.blue50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.blue200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('선택된 섬', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.blue700)),
                const SizedBox(height: 4),
                Text(widget.preSelectedIsland!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.blue700)),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        const Text('출발 항구 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
        const SizedBox(height: 4),
        const Text('여행을 시작할 항구를 선택하세요', style: TextStyle(fontSize: 13, color: AppColors.gray600)),
        const SizedBox(height: 20),
        _PortCard(
          title: '인천항 연안여객터미널',
          subtitle: '인천 도서 지역 주요 여객선 출발지',
          islands: const ['백령도', '대청도', '소청도', '연평도', '덕적도', '자월도', '승봉도', '대이작도'],
          isSelected: _departurePort == '인천항',
          onTap: () => setState(() => _departurePort = '인천항'),
        ),
        const SizedBox(height: 16),
        _PortCard(
          title: '대부도 방아머리여객터미널',
          subtitle: '수도권 남부에서 접근하기 좋은 섬 여행 출발지',
          islands: const ['자월도', '승봉도', '대이작도', '소이작도', '덕적도', '풍도', '육도'],
          isSelected: _departurePort == '대부도',
          onTap: () => setState(() => _departurePort = '대부도'),
        ),
        if (_departurePort.isNotEmpty) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _step = _hasPreSelected ? 2 : 1),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: Text(_hasPreSelected ? '다음: 날짜 선택' : '다음: 방문할 섬 선택'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('방문할 섬 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
        const SizedBox(height: 4),
        Text('$_departurePort에서 갈 수 있는 섬이에요', style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
          childAspectRatio: 2.5, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          children: _availableIslands.map((island) {
            final selected = _selectedIslands.contains(island);
            return GestureDetector(
              onTap: () => setState(() {
                if (selected) _selectedIslands.remove(island); else _selectedIslands.add(island);
              }),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? AppColors.blue600 : AppColors.gray200, width: 2),
                  color: selected ? AppColors.blue50 : Colors.white,
                ),
                child: Center(child: Text(island, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? AppColors.blue600 : AppColors.gray900))),
              ),
            );
          }).toList(),
        ),
        if (_selectedIslands.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.blue50, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.blue100)),
            child: Text('${_selectedIslands.length}개 섬 선택됨: ${_selectedIslands.join(', ')}', style: const TextStyle(fontSize: 13, color: AppColors.blue700)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _step = 2),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: const Text('다음: 날짜 선택'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('여행 날짜', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
        const SizedBox(height: 4),
        const Text('언제 떠나시나요?', style: TextStyle(fontSize: 13, color: AppColors.gray600)),
        const SizedBox(height: 24),
        const Text('출발일', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
        const SizedBox(height: 8),
        _DatePicker(
          value: _startDate,
          hint: '출발일 선택',
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) setState(() => _startDate = picked);
          },
        ),
        if (_startDate != null) ...[
          const SizedBox(height: 8),
          _DateConfirm(date: _startDate!),
        ],
        const SizedBox(height: 20),
        const Text('귀가일', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
        const SizedBox(height: 8),
        _DatePicker(
          value: _endDate,
          hint: '귀가일 선택',
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _startDate ?? DateTime.now(),
              firstDate: _startDate ?? DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) setState(() => _endDate = picked);
          },
        ),
        if (_endDate != null) ...[
          const SizedBox(height: 8),
          _DateConfirm(date: _endDate!),
        ],
        if (_startDate != null && _endDate != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.blue50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.blue100)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('총 여행 기간', style: TextStyle(fontSize: 11, color: AppColors.blue600, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      '${_endDate!.difference(_startDate!).inDays}박 ${_endDate!.difference(_startDate!).inDays + 1}일',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900),
                    ),
                  ],
                ),
                const Icon(Icons.check_circle_rounded, color: AppColors.blue600, size: 32),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _step = 3),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: const Text('다음: 인원 & 스타일 선택'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('여행 인원 & 스타일', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
        const SizedBox(height: 4),
        const Text('함께 떠나는 인원과 여행 스타일을 선택하세요', style: TextStyle(fontSize: 13, color: AppColors.gray600)),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CounterBtn(icon: Icons.remove, onTap: () { if (_travelers > 1) setState(() => _travelers--); }),
            const SizedBox(width: 24),
            Column(
              children: [
                Text('$_travelers', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                const Text('명', style: TextStyle(fontSize: 13, color: AppColors.gray600)),
              ],
            ),
            const SizedBox(width: 24),
            _CounterBtn(icon: Icons.add, onTap: () => setState(() => _travelers++), isPrimary: true),
          ],
        ),
        const SizedBox(height: 32),
        const Text('여행 스타일', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
          childAspectRatio: 1.4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          children: [
            {'id': '관광', 'emoji': '🏖️'}, {'id': '휴양', 'emoji': '😌'},
            {'id': '체험', 'emoji': '🎣'}, {'id': '사진', 'emoji': '📸'},
          ].map((t) {
            final isSelected = _travelType == t['id'];
            return GestureDetector(
              onTap: () => setState(() => _travelType = t['id']!),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? AppColors.blue600 : AppColors.gray200, width: 2),
                  color: isSelected ? AppColors.blue50 : Colors.white,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(t['emoji']!, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 6),
                    Text(t['id']!, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? AppColors.blue600 : AppColors.gray900)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text('예산', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
        const SizedBox(height: 12),
        Row(
          children: ['알뜰', '보통', '여유'].map((b) {
            final isSelected = _budget == b;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _budget = b),
                child: Container(
                  margin: EdgeInsets.only(right: b != '여유' ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? AppColors.blue600 : AppColors.gray200, width: 2),
                    color: isSelected ? AppColors.blue50 : Colors.white,
                  ),
                  child: Text(b, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? AppColors.blue600 : AppColors.gray900)),
                ),
              ),
            );
          }).toList(),
        ),
        if (_travelType.isNotEmpty) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue600, foregroundColor: Colors.white, disabledBackgroundColor: AppColors.blue200, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('일정 생성하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ],
    );
  }
}

class _PortCard extends StatelessWidget {
  final String title, subtitle;
  final List<String> islands;
  final bool isSelected;
  final VoidCallback onTap;
  const _PortCard({required this.title, required this.subtitle, required this.islands, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.blue600 : AppColors.gray200, width: 2),
          color: isSelected ? AppColors.blue50 : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? AppColors.blue700 : AppColors.gray900)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: TextStyle(fontSize: 12, color: isSelected ? AppColors.blue700 : AppColors.gray600)),
                    ],
                  ),
                ),
                if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.blue600),
              ],
            ),
            const SizedBox(height: 12),
            const Text('이 항구에서 갈 수 있는 섬', style: TextStyle(fontSize: 11, color: AppColors.gray500)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4, runSpacing: 4,
              children: islands.map((i) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.blue100 : AppColors.gray100,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(i, style: TextStyle(fontSize: 11, color: isSelected ? AppColors.blue700 : AppColors.gray700)),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePicker extends StatelessWidget {
  final DateTime? value;
  final String hint;
  final VoidCallback onTap;
  const _DatePicker({required this.value, required this.hint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gray300, width: 2),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: AppColors.gray500, size: 18),
            const SizedBox(width: 10),
            Text(
              value != null ? '${value!.year}년 ${value!.month}월 ${value!.day}일' : hint,
              style: TextStyle(fontSize: 15, color: value != null ? AppColors.gray900 : AppColors.gray400),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateConfirm extends StatelessWidget {
  final DateTime date;
  const _DateConfirm({required this.date});

  static const _weekdays = ['', '월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.blue50, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.blue600, size: 16),
          const SizedBox(width: 8),
          Text('${date.year}년 ${date.month}월 ${date.day}일 (${_weekdays[date.weekday]})', style: const TextStyle(fontSize: 13, color: AppColors.blue700, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  const _CounterBtn({required this.icon, required this.onTap, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.blue600 : AppColors.gray100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isPrimary ? Colors.white : AppColors.gray700, size: 20),
      ),
    );
  }
}
