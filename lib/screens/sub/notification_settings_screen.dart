import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});
  @override State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _ferryAlert = true;
  bool _scheduleReminder = true;
  bool _weatherAlert = false;
  bool _promotionAlert = true;
  bool _communityAlert = false;
  bool _bookingConfirm = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('알림 설정', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _SectionTitle('여행 알림'),
          _NotifCard(children: [
            _NotifItem(
              icon: Icons.directions_boat_rounded,
              label: '여객선 출항 알림',
              subtitle: '출항 1시간 전 알림',
              value: _ferryAlert,
              onChanged: (v) => setState(() => _ferryAlert = v),
            ),
            const Divider(height: 1, indent: 56, color: AppColors.gray100),
            _NotifItem(
              icon: Icons.calendar_month_rounded,
              label: '일정 리마인더',
              subtitle: '여행 하루 전 알림',
              value: _scheduleReminder,
              onChanged: (v) => setState(() => _scheduleReminder = v),
            ),
            const Divider(height: 1, indent: 56, color: AppColors.gray100),
            _NotifItem(
              icon: Icons.wb_sunny_rounded,
              label: '날씨 알림',
              subtitle: '여행지 날씨 변화 알림',
              value: _weatherAlert,
              onChanged: (v) => setState(() => _weatherAlert = v),
            ),
          ]),
          const SizedBox(height: 16),
          _SectionTitle('예약 알림'),
          _NotifCard(children: [
            _NotifItem(
              icon: Icons.check_circle_outline_rounded,
              label: '예약 확인',
              subtitle: '예약 완료 및 변경 알림',
              value: _bookingConfirm,
              onChanged: (v) => setState(() => _bookingConfirm = v),
            ),
          ]),
          const SizedBox(height: 16),
          _SectionTitle('커뮤니티'),
          _NotifCard(children: [
            _NotifItem(
              icon: Icons.chat_bubble_outline_rounded,
              label: '커뮤니티 알림',
              subtitle: '답글, 좋아요 알림',
              value: _communityAlert,
              onChanged: (v) => setState(() => _communityAlert = v),
            ),
          ]),
          const SizedBox(height: 16),
          _SectionTitle('마케팅'),
          _NotifCard(children: [
            _NotifItem(
              icon: Icons.local_offer_rounded,
              label: '이벤트 및 혜택',
              subtitle: '할인 정보 알림',
              value: _promotionAlert,
              onChanged: (v) => setState(() => _promotionAlert = v),
            ),
          ]),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.blue50, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.blue100)),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: AppColors.blue600),
                SizedBox(width: 8),
                Expanded(child: Text('알림을 받으려면 기기의 알림 설정도 활성화되어 있어야 합니다.', style: TextStyle(fontSize: 12, color: AppColors.blue700, height: 1.4))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray500)),
  );
}

class _NotifCard extends StatelessWidget {
  final List<Widget> children;
  const _NotifCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
    clipBehavior: Clip.hardEdge,
    child: Column(children: children),
  );
}

class _NotifItem extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _NotifItem({required this.icon, required this.label, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon, size: 22, color: AppColors.gray500),
      title: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.gray900)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.blue600,
    );
  }
}
