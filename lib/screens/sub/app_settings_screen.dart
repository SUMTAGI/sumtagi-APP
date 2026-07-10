import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';

Future<void> _openUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});
  @override State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  String _language = '한국어';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('앱 설정', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _SectionTitle('언어 및 지역'),
          _SettingCard(children: [
            ListTile(
              title: const Text('언어', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              trailing: DropdownButton<String>(
                value: _language,
                underline: const SizedBox(),
                items: ['한국어', 'English', '日本語'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) => setState(() => _language = v!),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _SectionTitle('약관 및 정책'),
          _SettingCard(children: [
            ListTile(
              title: const Text('이용약관', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.gray400),
              onTap: () => _openUrl('https://sumtagi-web.vercel.app/terms'),
            ),
            const Divider(height: 1, indent: 16, color: AppColors.gray100),
            ListTile(
              title: const Text('개인정보 처리방침', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.gray400),
              onTap: () => _openUrl('https://sumtagi-web.vercel.app/privacy'),
            ),
          ]),
          const SizedBox(height: 16),
          _SectionTitle('데이터'),
          _SettingCard(children: [
            ListTile(
              title: const Text('캐시 삭제', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              subtitle: const Text('앱의 임시 데이터를 삭제합니다', style: TextStyle(fontSize: 13, color: AppColors.gray500)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.gray400),
              onTap: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('캐시 삭제'),
                  content: const Text('캐시를 삭제하시겠습니까?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
                    TextButton(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('캐시가 삭제됐어요'))); }, child: const Text('삭제', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, indent: 16, color: AppColors.gray100),
            ListTile(
              title: const Text('앱 정보', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              trailing: const Text('v1.0.0', style: TextStyle(fontSize: 13, color: AppColors.gray500)),
            ),
          ]),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray500)),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
      clipBehavior: Clip.hardEdge,
      child: Column(children: children),
    );
  }
}
