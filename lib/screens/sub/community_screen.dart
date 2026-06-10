import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _tab = 0;

  final List<Map<String, dynamic>> _posts = [
    {'id': '1', 'author': '섬여행러', 'island': '백령도', 'content': '두무진 일몰 진짜 미쳤어요!! 꼭 가보세요 🌅', 'likes': 124, 'comments': 18, 'timestamp': '2시간 전', 'isLiked': false, 'hasWeather': false},
    {'id': '2', 'author': '바다사랑', 'island': '덕적도', 'content': '오늘 서포리 해변 날씨 완전 좋아요! 사람도 많지 않고 물도 맑아요 👍', 'likes': 89, 'comments': 12, 'timestamp': '3시간 전', 'isLiked': false, 'hasWeather': true, 'weatherCondition': '맑음 23°C', 'weatherCongestion': '여유'},
    {'id': '3', 'author': '힐링여행', 'island': '자월도', 'content': '자월도 큰말해변에서 캠핑 중이에요. 별이 정말 많이 보여요 ⭐', 'likes': 156, 'comments': 24, 'timestamp': '5시간 전', 'isLiked': true, 'hasWeather': false},
    {'id': '4', 'author': '먹방러버', 'island': '덕적도', 'content': '덕적도 물회 맛집 찾았어요! 항구 근처 "바다횟집" 강추합니다', 'likes': 67, 'comments': 8, 'timestamp': '1일 전', 'isLiked': false, 'hasWeather': false},
    {'id': '5', 'author': '사진작가', 'island': '백령도', 'content': '사곶해변 일출 타임랩스 찍었어요. 날씨가 도와줘서 대박 샷 건졌습니다 📸', 'likes': 203, 'comments': 31, 'timestamp': '1일 전', 'isLiked': false, 'hasWeather': false},
  ];

  final List<Map<String, dynamic>> _qna = [
    {'id': 'q1', 'author': '여행초보', 'question': '백령도 1박2일 충분할까요?', 'answers': 5, 'likes': 12, 'timestamp': '1시간 전', 'bestAnswer': '두무진, 사곶해변 정도만 보신다면 1박2일도 괜찮아요. 하지만 여유롭게 즐기시려면 2박3일 추천드려요!'},
    {'id': 'q2', 'author': '맛집탐방', 'question': '덕적도 맛집 추천해주세요', 'answers': 8, 'likes': 24, 'timestamp': '3시간 전', 'bestAnswer': '항구 근처 "바다횟집" 물회가 정말 맛있어요. 현지인들도 많이 가는 곳이에요!'},
    {'id': 'q3', 'author': '가족여행', 'question': '아이랑 가기 좋은 섬 어디인가요?', 'answers': 12, 'likes': 31, 'timestamp': '5시간 전', 'bestAnswer': '덕적도나 자월도 추천해요. 해변이 넓고 파도가 잔잔해서 아이들이 놀기 좋아요.'},
  ];

  void _toggleLike(String id) {
    final idx = _posts.indexWhere((p) => p['id'] == id);
    if (idx == -1) return;
    setState(() {
      final isLiked = _posts[idx]['isLiked'] as bool;
      _posts[idx] = {
        ..._posts[idx],
        'isLiked': !isLiked,
        'likes': (_posts[idx]['likes'] as int) + (isLiked ? -1 : 1),
      };
    });
  }

  Color _congestionColor(String c) {
    if (c == '여유') return const Color(0xFFDCFCE7);
    if (c == '보통') return const Color(0xFFFEF9C3);
    return const Color(0xFFFEE2E2);
  }

  Color _congestionTextColor(String c) {
    if (c == '여유') return const Color(0xFF15803D);
    if (c == '보통') return const Color(0xFFCA8A04);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('커뮤니티', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text('여행자들과 소통하세요', style: TextStyle(fontSize: 11, color: AppColors.gray500)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            color: Colors.white,
            child: Row(
              children: [
                _TabBtn(label: '실시간 피드', selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
                const SizedBox(width: 8),
                _TabBtn(label: '질문 & 답변', selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _tab == 0 ? _buildFeed() : _buildQnA(),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.gray200))),
            child: ElevatedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('글쓰기 기능은 곧 추가될 예정이에요'))),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: Text(_tab == 0 ? '게시글 작성' : '질문하기', style: const TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue600, foregroundColor: Colors.white,
                elevation: 0, minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeed() {
    return ListView.separated(
      itemCount: _posts.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.gray200),
      itemBuilder: (context, i) {
        final post = _posts[i];
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.blue100, shape: BoxShape.circle, border: Border.all(color: AppColors.blue200)),
                    child: const Icon(Icons.person_rounded, size: 22, color: AppColors.blue600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post['author'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 12, color: AppColors.gray500),
                            const SizedBox(width: 2),
                            Text(post['island'] as String, style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
                            const Text(' • ', style: TextStyle(fontSize: 11, color: AppColors.gray400)),
                            Text(post['timestamp'] as String, style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (post['hasWeather'] == true) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.blue50, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.blue100)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('실시간 현장 정보', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.blue900)),
                      Row(
                        children: [
                          Text(post['weatherCondition'] as String, style: const TextStyle(fontSize: 12, color: AppColors.blue700)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: _congestionColor(post['weatherCongestion'] as String), borderRadius: BorderRadius.circular(4)),
                            child: Text(post['weatherCongestion'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _congestionTextColor(post['weatherCongestion'] as String))),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(post['content'] as String, style: const TextStyle(fontSize: 14, color: AppColors.gray900, height: 1.5)),
              const SizedBox(height: 12),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggleLike(post['id'] as String),
                    child: Row(
                      children: [
                        Icon(post['isLiked'] == true ? Icons.favorite : Icons.favorite_border, size: 20, color: post['isLiked'] == true ? Colors.red : AppColors.gray500),
                        const SizedBox(width: 6),
                        Text('${post['likes']}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: post['isLiked'] == true ? Colors.red : AppColors.gray700)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.gray500),
                      const SizedBox(width: 6),
                      Text('${post['comments']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('링크가 복사됐어요'))),
                    child: const Icon(Icons.share_outlined, size: 18, color: AppColors.gray500),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQnA() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _qna.length,
      itemBuilder: (context, i) {
        final item = _qna[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(color: AppColors.blue100, shape: BoxShape.circle),
                    child: const Icon(Icons.person_rounded, size: 20, color: AppColors.blue600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['question'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                        const SizedBox(height: 2),
                        Text('${item['author']} • ${item['timestamp']}', style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.blue50, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.blue100)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.thumb_up_rounded, size: 14, color: AppColors.blue600),
                        SizedBox(width: 6),
                        Text('베스트 답변', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.blue900)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(item['bestAnswer'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray700, height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Row(children: [
                    const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.gray500),
                    const SizedBox(width: 4),
                    Text('${item['answers']}개 답변', style: const TextStyle(fontSize: 12, color: AppColors.gray600)),
                  ]),
                  const SizedBox(width: 16),
                  Row(children: [
                    const Icon(Icons.favorite_border, size: 14, color: AppColors.gray500),
                    const SizedBox(width: 4),
                    Text('${item['likes']}', style: const TextStyle(fontSize: 12, color: AppColors.gray600)),
                  ]),
                ],
              ),
            ],
          ),
        );
      },
    );
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue600 : AppColors.gray100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.gray700)),
      ),
    );
  }
}
