import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await NotificationService.getNotifications();
    if (mounted) setState(() { _notifications = data; _isLoading = false; });
  }

  Future<void> _markRead(Map<String, dynamic> n) async {
    if (n['is_read'] == true) return;
    await NotificationService.markRead(n['id'] as String);
    setState(() {
      final idx = _notifications.indexWhere((x) => x['id'] == n['id']);
      if (idx != -1) _notifications[idx] = {..._notifications[idx], 'is_read': true};
    });
  }

  IconData _typeIcon(String type) => switch (type) {
    'ferry' => Icons.directions_boat_rounded,
    'schedule' => Icons.calendar_month_rounded,
    'weather' => Icons.wb_sunny_rounded,
    'promo' => Icons.local_offer_rounded,
    'booking' => Icons.check_circle_rounded,
    'community' => Icons.chat_bubble_rounded,
    _ => Icons.notifications_rounded,
  };

  Color _typeColor(String type) => switch (type) {
    'ferry' => AppColors.blue600,
    'schedule' => AppColors.purple600,
    'weather' => const Color(0xFFF59E0B),
    'promo' => AppColors.green600,
    'booking' => AppColors.green600,
    'community' => AppColors.orange600,
    _ => AppColors.gray600,
  };

  Color _typeBg(String type) => switch (type) {
    'ferry' => AppColors.blue50,
    'schedule' => AppColors.purple100,
    'weather' => const Color(0xFFFEF9C3),
    'promo' => AppColors.green100,
    'booking' => AppColors.green100,
    'community' => AppColors.orange50,
    _ => AppColors.gray100,
  };

  String _timeAgo(String isoString) {
    final dt = DateTime.tryParse(isoString)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => n['is_read'] != true).length;
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('알림', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text(unread > 0 ? '읽지 않은 알림 $unread개' : '모두 읽었어요', style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
        titleSpacing: 0,
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () async {
                await NotificationService.markAllRead();
                setState(() {
                  _notifications = _notifications.map((n) => {...n, 'is_read': true}).toList();
                });
              },
              child: const Text('모두 읽기', style: TextStyle(color: AppColors.blue600, fontSize: 13)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none_rounded, size: 64, color: AppColors.gray300),
                      SizedBox(height: 16),
                      Text('알림이 없어요', style: TextStyle(fontSize: 16, color: AppColors.gray500)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.gray200),
                    itemBuilder: (context, i) {
                      final n = _notifications[i];
                      final type = n['type'] as String? ?? 'general';
                      final isRead = n['is_read'] == true;
                      return GestureDetector(
                        onTap: () => _markRead(n),
                        child: Container(
                          color: isRead ? Colors.white : AppColors.blue50,
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(color: _typeBg(type), shape: BoxShape.circle),
                                child: Icon(_typeIcon(type), size: 22, color: _typeColor(type)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n['title'] as String? ?? '', style: TextStyle(fontSize: 14, fontWeight: isRead ? FontWeight.normal : FontWeight.w600, color: AppColors.gray900)),
                                    const SizedBox(height: 4),
                                    Text(n['message'] as String? ?? '', style: const TextStyle(fontSize: 13, color: AppColors.gray600, height: 1.4)),
                                    const SizedBox(height: 6),
                                    Text(_timeAgo(n['created_at'] as String? ?? ''), style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
                                  ],
                                ),
                              ),
                              if (!isRead)
                                Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 6), decoration: const BoxDecoration(color: AppColors.blue600, shape: BoxShape.circle)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
