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
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
      context.push('/create-trip?name=$nameParam&style=$styleParam');
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_loading,
              onSubmitted: (_) => _handleSubmit(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: widget.placeholder ?? '어떤 여행을 원하세요? 예: 낚시하고 조용한 섬',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          GestureDetector(
            onTap: _handleSubmit,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue600),
                    )
                  : const Icon(Icons.search, size: 16, color: AppColors.blue600),
            ),
          ),
        ],
      ),
    );
  }
}
