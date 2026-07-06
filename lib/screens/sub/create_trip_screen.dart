import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/trip_service.dart';
import '../../services/ai_itinerary_service.dart';
import '../../theme/app_colors.dart';

class CreateTripScreen extends StatefulWidget {
  final String? preSelectedIsland;
  const CreateTripScreen({super.key, this.preSelectedIsland});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  int _step = 0;
  List<String> _selectedIslands = [];
  DateTime? _startDate;
  DateTime? _endDate;
  int _travelers = 2;
  String _travelType = '';
  String _budget = '보통';
  bool _isSubmitting = false;

  static const _allIslands = [
    '백령도', '대청도', '소청도', '연평도',
    '덕적도', '자월도', '승봉도', '대이작도',
    '소이작도', '풍도', '육도', '신도', '장봉도',
  ];

  static const _islandPortMap = {
    '백령도': '인천항', '대청도': '인천항', '소청도': '인천항', '연평도': '인천항',
    '덕적도': '인천항', '자월도': '인천항', '승봉도': '인천항', '대이작도': '인천항',
    '소이작도': '대부도', '풍도': '대부도', '육도': '대부도',
    '신도': '삼목항', '장봉도': '삼목항',
  };

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedIsland != null) {
      _selectedIslands = [widget.preSelectedIsland!];
    }
  }

  bool get _hasPreSelected => widget.preSelectedIsland != null;
  int get _totalSteps => _hasPreSelected ? 2 : 3;

  String get _computedPort =>
      _islandPortMap[_selectedIslands.firstOrNull ?? ''] ?? '인천항';

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final result = await generateAIItinerary(
        AIItineraryRequest(
          departurePort: _computedPort,
          islands: _selectedIslands,
          startDate: _startDate!.toIso8601String().split('T')[0],
          endDate: _endDate!.toIso8601String().split('T')[0],
          travelers: _travelers,
          travelStyle: _travelType,
          budget: _budget,
        ),
        onFallback: (reason) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('AI 일정 생성에 실패했어요. 기본 일정으로 대체합니다.'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                backgroundColor: AppColors.gray900,
              ),
            );
          }
        },
      );

      final itinerary = result.itinerary;
      final id = await TripService.createTrip(
        title: itinerary.title,
        departurePort: itinerary.departurePort,
        islands: itinerary.islands,
        startDate: itinerary.startDate,
        endDate: itinerary.endDate,
        travelers: itinerary.travelers,
        travelType: _travelType,
        budget: _budget,
        totalCost: itinerary.totalCost,
        days: itinerary.days.map((d) => d.toJson()).toList(),
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildCurrentStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    if (_hasPreSelected) {
      return _step == 0 ? _buildDateStep() : _buildStyleStep();
    }
    return switch (_step) {
      0 => _buildIslandStep(),
      1 => _buildDateStep(),
      _ => _buildStyleStep(),
    };
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.gray200))),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.gray700, size: 20),
            onPressed: () => _step == 0 ? context.pop() : setState(() => _step--),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _hasPreSelected ? '${widget.preSelectedIsland} 일정 만들기' : '일정 만들기',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.gray900),
              ),
              Text(
                'Step ${_step + 1} / $_totalSteps',
                style: const TextStyle(fontSize: 12, color: AppColors.gray500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.gray200))),
      child: Row(
        children: List.generate(_totalSteps, (i) {
          final filled = i <= _step;
          return Expanded(
            child: Container(
              height: 8,
              margin: EdgeInsets.only(right: i < _totalSteps - 1 ? 6 : 0),
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

  Widget _buildIslandStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('방문할 섬 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
        const SizedBox(height: 4),
        const Text('어느 섬으로 떠나고 싶으세요?', style: TextStyle(fontSize: 13, color: AppColors.gray600)),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
          childAspectRatio: 2.5, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          children: _allIslands.map((island) {
            final selected = _selectedIslands.contains(island);
            return GestureDetector(
              onTap: () => setState(() {
                if (selected) { _selectedIslands.remove(island); } else { _selectedIslands.add(island); }
              }),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? AppColors.blue600 : AppColors.gray200, width: 2),
                  color: selected ? AppColors.blue50 : Colors.white,
                ),
                child: Center(
                  child: Text(
                    island,
                    style: TextStyle(fontWeight: FontWeight.w600, color: selected ? AppColors.blue600 : AppColors.gray900),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_selectedIslands.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.blue50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.blue100),
            ),
            child: Text(
              '${_selectedIslands.length}개 섬 선택됨: ${_selectedIslands.join(', ')}',
              style: const TextStyle(fontSize: 13, color: AppColors.blue700),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _step = 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('다음: 날짜 선택'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasPreSelected) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.blue50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.blue200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('선택된 섬', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.blue700)),
                const SizedBox(height: 4),
                Text(
                  widget.preSelectedIsland!,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.blue700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
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
            decoration: BoxDecoration(
              color: AppColors.blue50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.blue100),
            ),
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
              onPressed: () => setState(() => _step++),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('다음: 인원 & 스타일 선택'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStyleStep() {
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
                  child: Text(
                    b,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? AppColors.blue600 : AppColors.gray900),
                  ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue600,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.blue200,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text('AI가 일정을 만들고 있어요...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    )
                  : const Text('AI 일정 생성하기 ✨', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ],
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
          Text(
            '${date.year}년 ${date.month}월 ${date.day}일 (${_weekdays[date.weekday]})',
            style: const TextStyle(fontSize: 13, color: AppColors.blue700, fontWeight: FontWeight.w500),
          ),
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
