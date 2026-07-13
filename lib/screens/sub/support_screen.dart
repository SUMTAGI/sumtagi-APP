import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'ai_chat_screen.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String? _expandedFaq;

  static const _faqs = [
    {'id': 'f1', 'question': '예약 취소는 어떻게 하나요?', 'answer': '여행 일정 페이지에서 해당 예약을 선택한 후 취소 버튼을 누르시면 됩니다. 출발 3일 전까지 무료 취소 가능합니다.'},
    {'id': 'f2', 'question': '여객선 시간표는 어디서 확인하나요?', 'answer': '교통 시간표 메뉴에서 실시간 운항 정보를 확인하실 수 있습니다. 기상 상황에 따라 변경될 수 있으니 출발 전 확인하세요.'},
    {'id': 'f3', 'question': '섬에서 인터넷 사용이 가능한가요?', 'answer': '대부분의 섬에서 4G/5G 서비스가 가능하나, 도서 지역 특성상 신호가 약할 수 있습니다. 중요한 정보는 미리 다운로드해 두세요.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('고객센터', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text('도움이 필요하신가요?', style: TextStyle(fontSize: 13, color: AppColors.gray500)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
        titleSpacing: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Quick Contact
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]), borderRadius: BorderRadius.all(Radius.circular(16))),
            child: Column(
              children: [
                const Icon(Icons.headset_mic_rounded, size: 40, color: Colors.white),
                const SizedBox(height: 12),
                const Text('고객 지원팀', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                const Text('평일 9:00 - 18:00', style: TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('전화 연결 중...'))),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.phone_rounded, size: 18, color: Colors.white),
                            SizedBox(width: 6),
                            Text('전화 상담', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiChatScreen())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.chat_rounded, size: 18, color: AppColors.blue600),
                            SizedBox(width: 6),
                            Text('채팅 상담', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.blue600)),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // FAQ
          const Text('자주 묻는 질문', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray900)),
          const SizedBox(height: 12),
          ..._faqs.map((faq) {
            final expanded = _expandedFaq == faq['id'];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
              clipBehavior: Clip.hardEdge,
              child: Column(
                children: [
                  ListTile(
                    title: Text(faq['question']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                    trailing: Icon(expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppColors.gray400),
                    onTap: () => setState(() => _expandedFaq = expanded ? null : faq['id']),
                  ),
                  if (expanded)
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.blue50, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.blue100)),
                        child: Text(faq['answer']!, style: const TextStyle(fontSize: 13, color: AppColors.gray700, height: 1.5)),
                      ),
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),

          // Email
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(color: AppColors.blue50, shape: BoxShape.circle),
                  child: const Icon(Icons.mail_outline_rounded, size: 20, color: AppColors.blue600),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('이메일 문의', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                      Text('kimsungil322@gmail.com', style: TextStyle(fontSize: 13, color: AppColors.blue600)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.gray400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
