import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {'id': '1', 'type': 'ferry', 'title': '여객선 출항 알림', 'body': '내일 08:00 인천항 → 백령도 여객선이 출항합니다.', 'time': '1시간 전', 'isRead': false},
    {'id': '2', 'type': 'schedule', 'title': '일정 리마인더', 'body': '내일 덕적도 여행이 있어요. 준비물을 확인해보세요!', 'time': '3시간 전', 'isRead': false},
    {'id': '3', 'type': 'weather', 'title': '날씨 알림', 'body': '백령도 내일 날씨: 맑음, 최고기온 26°C', 'time': '5시간 전', 'isRead': true},
    {'id': '4', 'type': 'promo', 'title': '특별 할인 쿠폰', 'body': '자월도 펜션 20% 할인 쿠폰이 도착했어요!', 'time': '1일 전', 'isRead': true},
    {'id': '5', 'type': 'booking', 'title': '예약 확인', 'body': '덕적도 서포리 펜션 예약이 확정되었습니다.', 'time': '2일 전', 'isRead': true},
    {'id': '6', 'type': 'community', 'title': '새 답글', 'body': '"백령도 1박2일 충분할까요?" 질문에 새 답글이 달렸어요.', 'time': '3일 전', 'isRead': true},
  ];

  IconData _typeIcon(String type) {
    switch (type) {
      case 'ferry': return Icons.directions_boat_rounded;
      case 'schedule': return Icons.calendar_month_rounded;
      case 'weather': return Icons.wb_sunny_rounded;
      case 'promo': return Icons.local_offer_rounded;
      case 'booking': return Icons.check_circle_rounded;
      case 'community': return Icons.chat_bubble_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'ferry': return AppColors.blue600;
      case 'schedule': return const Color(0xFF7C3AED);
      case 'weather': return const Color(0xFFEA580C);
      case 'promo': return const Color(0xFF16A34A);
      case 'booking': return AppColors.blue600;
      case 'community': return const Color(0xFFDB2777);
      default: return AppColors.gray600;
    }
  }

  Color _typeBg(String type) {
    switch (type) {
      case 'ferry': return AppColors.blue100;
      case 'schedule': return const Color(0xFFEDE9FE);
      case 'weather': return const Color(0xFFFFEDD5);
      case 'promo': return const Color(0xFFDCFCE7);
      case 'booking': return AppColors.blue100;
      case 'community': return const Color(0xFFFCE7F3);
      default: return AppColors.gray100;
    }
  }

  void _markAllRead() {
    setState(() {
      for (var n in _notifications) n['isRead'] = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('모든 알림을 읽음으로 표시했어요')));
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !(n['isRead'] as bool)).length;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('알림', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text(unreadCount > 0 ? '읽지 않은 알림 $unreadCount개' : '새 알림 없음', style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
        titleSpacing: 0,
        actions: [
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton(
                onPressed: _markAllRead,
                child: const Text('모두 읽음', style: TextStyle(fontSize: 12, color: AppColors.blue600, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.gray300),
                  SizedBox(height: 16),
                  Text('새로운 알림이 없어요', style: TextStyle(fontSize: 16, color: AppColors.gray500)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _notifications.length,
              itemBuilder: (context, i) {
                final notif = _notifications[i];
                final isRead = notif['isRead'] as bool;
                final type = notif['type'] as String;

                return GestureDetector(
                  onTap: () {
                    setState(() => notif['isRead'] = true);
                  },
                  child: Container(
                    color: isRead ? Colors.white : AppColors.blue50,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: _typeBg(type), shape: BoxShape.circle),
                          child: Icon(_typeIcon(type), size: 20, color: _typeColor(type)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(notif['title'] as String, style: TextStyle(fontSize: 14, fontWeight: isRead ? FontWeight.w500 : FontWeight.bold, color: AppColors.gray900)),
                                  if (!isRead)
                                    Container(
                                      width: 8, height: 8,
                                      decoration: const BoxDecoration(color: AppColors.blue600, shape: BoxShape.circle),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(notif['body'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray600, height: 1.4)),
                              const SizedBox(height: 4),
                              Text(notif['time'] as String, style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
