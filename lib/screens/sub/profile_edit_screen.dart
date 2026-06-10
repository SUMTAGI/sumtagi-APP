import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});
  @override State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('user');
    if (stored == null) {
      if (mounted) context.go('/login');
      return;
    }
    final user = jsonDecode(stored) as Map<String, dynamic>;
    setState(() {
      _user = user;
      _nameCtrl.text = user['name'] as String? ?? '';
      _emailCtrl.text = user['email'] as String? ?? '';
      _phoneCtrl.text = user['phone'] as String? ?? '';
    });
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이름과 이메일을 입력해주세요')));
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final updated = {
      ..._user!,
      'name': _nameCtrl.text,
      'email': _emailCtrl.text,
      'phone': _phoneCtrl.text,
    };
    await prefs.setString('user', jsonEncode(updated));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('프로필이 수정됐어요')));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: const Text('프로필 수정', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 88, height: 88,
                    decoration: const BoxDecoration(color: AppColors.blue100, shape: BoxShape.circle),
                    child: const Icon(Icons.person_rounded, size: 44, color: AppColors.blue600),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('프로필 사진 변경 기능은 곧 추가될 예정이에요'))),
                    child: const Text('사진 변경', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.blue600)),
                  ),
                  const SizedBox(height: 32),

                  // Form
                  _FormSection(
                    title: '기본 정보',
                    children: [
                      _FormField(label: '이름', controller: _nameCtrl, hint: '이름을 입력하세요', icon: Icons.person_outline_rounded),
                      const Divider(height: 1, color: AppColors.gray100),
                      _FormField(label: '이메일', controller: _emailCtrl, hint: '이메일을 입력하세요', icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress),
                      const Divider(height: 1, color: AppColors.gray100),
                      _FormField(label: '전화번호', controller: _phoneCtrl, hint: '010-0000-0000', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Password change
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
                    child: ListTile(
                      leading: const Icon(Icons.lock_outline_rounded, color: AppColors.gray500),
                      title: const Text('비밀번호 변경', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.gray900)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.gray400),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('비밀번호 변경 기능은 곧 추가될 예정이에요'))),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.gray200))),
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue600, foregroundColor: Colors.white,
                elevation: 0, minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('저장하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _FormSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray500)),
        ),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
          clipBehavior: Clip.hardEdge,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  const _FormField({required this.label, required this.controller, required this.hint, required this.icon, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.gray500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
                const SizedBox(height: 4),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(fontSize: 15, color: AppColors.gray900),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(color: AppColors.gray400),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
