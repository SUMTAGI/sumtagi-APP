import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});
  @override State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _nameCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pwConfirmCtrl = TextEditingController();
  bool _isSaving = false;
  bool _showPwForm = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
      return;
    }
    _nameCtrl.text = user.userMetadata?['nickname'] as String? ?? '';
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('닉네임을 입력해주세요')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'nickname': _nameCtrl.text}),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필이 수정됐어요'), backgroundColor: AppColors.gray900, behavior: SnackBarBehavior.floating),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _changePassword() async {
    if (_pwCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('비밀번호는 6자 이상이어야 해요')));
      return;
    }
    if (_pwCtrl.text != _pwConfirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('비밀번호가 일치하지 않아요')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _pwCtrl.text),
      );
      _pwCtrl.clear();
      _pwConfirmCtrl.clear();
      if (mounted) {
        setState(() => _showPwForm = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('비밀번호가 변경됐어요'), backgroundColor: AppColors.gray900, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('비밀번호 변경에 실패했어요')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final email = user?.email ?? '';

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

                  _FormSection(
                    title: '기본 정보',
                    children: [
                      _FormField(label: '닉네임', controller: _nameCtrl, hint: '닉네임을 입력하세요', icon: Icons.person_outline_rounded),
                      const Divider(height: 1, color: AppColors.gray100),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(children: [
                          const Icon(Icons.mail_outline_rounded, size: 20, color: AppColors.gray500),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('이메일', style: TextStyle(fontSize: 11, color: AppColors.gray500)),
                            const SizedBox(height: 4),
                            Text(email, style: const TextStyle(fontSize: 15, color: AppColors.gray600)),
                          ])),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.lock_outline_rounded, color: AppColors.gray500),
                          title: const Text('비밀번호 변경', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.gray900)),
                          trailing: Icon(_showPwForm ? Icons.expand_less : Icons.chevron_right_rounded, color: AppColors.gray400),
                          onTap: () => setState(() => _showPwForm = !_showPwForm),
                        ),
                        if (_showPwForm) ...[
                          const Divider(height: 1, color: AppColors.gray100),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(children: [
                              _PwField(label: '새 비밀번호', controller: _pwCtrl, hint: '6자 이상 입력'),
                              const SizedBox(height: 12),
                              _PwField(label: '비밀번호 확인', controller: _pwConfirmCtrl, hint: '비밀번호 재입력'),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _changePassword,
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue600, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                  child: const Text('변경하기'),
                                ),
                              ),
                            ]),
                          ),
                        ],
                      ],
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
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue600, foregroundColor: Colors.white,
                elevation: 0, minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('저장하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
  const _FormField({required this.label, required this.controller, required this.hint, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, size: 20, color: AppColors.gray500),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            style: const TextStyle(fontSize: 15, color: AppColors.gray900),
            decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: AppColors.gray400), isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none),
          ),
        ])),
      ]),
    );
  }
}

class _PwField extends StatefulWidget {
  final String label, hint;
  final TextEditingController controller;
  const _PwField({required this.label, required this.hint, required this.controller});
  @override State<_PwField> createState() => _PwFieldState();
}

class _PwFieldState extends State<_PwField> {
  bool _obscure = true;
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 20, color: AppColors.gray400), onPressed: () => setState(() => _obscure = !_obscure)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.blue600, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
