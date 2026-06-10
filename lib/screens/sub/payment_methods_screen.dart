import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});
  @override State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<Map<String, dynamic>> _cards = [
    {'id': 'c1', 'type': 'visa', 'last4': '4582', 'expiry': '12/27', 'holder': '홍길동', 'isDefault': true},
    {'id': 'c2', 'type': 'master', 'last4': '8821', 'expiry': '08/26', 'holder': '홍길동', 'isDefault': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('결제 수단', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ..._cards.map((card) {
            final isDefault = card['isDefault'] as bool;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(card['type'] == 'visa' ? 'VISA' : 'MASTERCARD', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
                      if (isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                          child: const Text('기본 카드', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('•••• •••• •••• ${card['last4']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white, letterSpacing: 4)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('카드 소유자', style: TextStyle(fontSize: 10, color: Colors.white60)),
                          Text(card['holder'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('유효기간', style: TextStyle(fontSize: 10, color: Colors.white60)),
                          Text(card['expiry'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                        ],
                      ),
                      Row(
                        children: [
                          if (!isDefault)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  for (var c in _cards) c['isDefault'] = c['id'] == card['id'];
                                });
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('기본 카드로 설정됐어요')));
                              },
                              child: const Icon(Icons.star_border_rounded, color: Colors.white70, size: 22),
                            ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() => _cards.removeWhere((c) => c['id'] == card['id']));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('카드가 삭제됐어요')));
                            },
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.white70, size: 22),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('카드 추가 기능은 곧 추가될 예정이에요'))),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gray300, style: BorderStyle.solid, width: 1.5),
              ),
              child: const Column(
                children: [
                  Icon(Icons.add_circle_outline_rounded, size: 28, color: AppColors.blue600),
                  SizedBox(height: 6),
                  Text('새 카드 추가', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.blue600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(10)),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_rounded, size: 16, color: AppColors.gray500),
                SizedBox(width: 8),
                Expanded(child: Text('결제 정보는 암호화되어 안전하게 보관됩니다.', style: TextStyle(fontSize: 12, color: AppColors.gray600, height: 1.4))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
