import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/island_recommend_service.dart';
import '../theme/app_colors.dart';

/// 홈 검색창 — 자연어로 여행 취향을 입력하면 AI가 섬을 추천하고 CreateTrip으로 바로 연결
class AiIslandSearchBar extends StatefulWidget {
  final String? placeholder;
  const AiIslandSearchBar({super.key, this.placeholder});

  @override
  State<AiIslandSearchBar> createState() => _AiIslandSearchBarState();
}

class _AiIslandSearchBarState extends State<AiIslandSearchBar> {
  static const _hints = [
    '조용히 쉬고 싶은 섬 어디 없을까요?',
    '아이와 함께 갈 만한 섬은 어디일까요?',
    '낚시하기 좋은 섬은 어디인가요?',
    '당일치기로 다녀올 섬이 있을까요?',
    '노을이 예쁜 섬은 어디일까요?',
  ];
  static const _hintInterval = Duration(seconds: 5);

  final _controller = TextEditingController();
  final _random = Random();
  Timer? _hintTimer;
  int _hintIndex = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _hintIndex = _random.nextInt(_hints.length);
    _controller.addListener(_onTextChanged);
    if (widget.placeholder == null) {
      _hintTimer = Timer.periodic(_hintInterval, (_) => _rotateHint());
    }
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  // 입력 여부에 따라 힌트를 보이거나 숨기기 위해 리빌드
  void _onTextChanged() => setState(() {});

  void _rotateHint() {
    if (!mounted) return;
    // 같은 문장이 연속으로 나오지 않도록 현재 인덱스를 제외하고 랜덤 선택
    var next = _random.nextInt(_hints.length - 1);
    if (next >= _hintIndex) next++;
    setState(() => _hintIndex = next);
  }

  String get _currentHint => widget.placeholder ?? _hints[_hintIndex];

  Future<void> _handleSubmit() async {
    final query = _controller.text.trim();
    if (query.isEmpty || _loading) return;
    setState(() => _loading = true);
    try {
      final result = await recommendIsland(query);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.reason.isNotEmpty ? result.reason : '${result.island} 추천드려요!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: AppColors.gray900,
        ),
      );
      final nameParam = Uri.encodeComponent(result.island);
      final styleParam = Uri.encodeComponent(result.travelStyle);
      final reasonQuery = result.reason.isNotEmpty
          ? '&reason=${Uri.encodeComponent(result.reason)}'
          : '';
      context.push('/create-trip?name=$nameParam&style=$styleParam$reasonQuery');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('추천에 실패했어요. 다시 시도해주세요.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: AppColors.gray900,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // 왼쪽 20 = 아래 여행 카드 안쪽 텍스트들의 시작 위치(카드 패딩)와 정렬
      padding: const EdgeInsets.fromLTRB(20, 6, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // 힌트는 TextField의 hintText 대신 별도 레이어로 그려서 전환 모션을 줌
                if (_controller.text.isEmpty)
                  IgnorePointer(
                    child: ClipRect(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 450),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.centerLeft,
                          children: [...previous, if (current != null) current],
                        ),
                        transitionBuilder: (child, animation) {
                          final slide = Tween<Offset>(
                            begin: const Offset(0, 0.6),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(position: slide, child: child),
                          );
                        },
                        child: Text(
                          _currentHint,
                          key: ValueKey(_currentHint),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.gray500, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                TextField(
                  controller: _controller,
                  enabled: !_loading,
                  onSubmitted: (_) => _handleSubmit(),
                  style: const TextStyle(color: AppColors.gray900, fontSize: 14),
                  decoration: const InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _handleSubmit,
            child: SizedBox(
              width: 32,
              height: 32,
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(7),
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gray900),
                    )
                  : const Icon(Icons.search, size: 22, color: AppColors.gray900),
            ),
          ),
        ],
      ),
    );
  }
}
