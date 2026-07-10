import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';

class SignupScreen extends StatefulWidget {
  final String? method;
  const SignupScreen({super.key, this.method});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  int _step = 0;
  String? _signupMethod;
  bool _isLoading = false;

  final _nicknameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _showPw = false;
  bool _showConfirmPw = false;
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  String _travelStyle = '';

  @override
  void initState() {
    super.initState();
    if (widget.method != null &&
        ['kakao', 'google', 'apple'].contains(widget.method)) {
      _signupMethod = widget.method;
      _step = 2;
    }
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppColors.gray900,
      ),
    );
  }

  void _handleBack() {
    if (_step == 0) {
      context.go('/login');
    } else if (_step == 1) {
      setState(() { _step = 0; _signupMethod = null; });
    } else if (_step == 2 && _signupMethod == 'email') {
      setState(() => _step = 1);
    } else {
      context.go('/login');
    }
  }

  void _handleEmailSignup() {
    if (_nicknameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      _showSnack('모든 필드를 입력해주세요'); return;
    }
    if (_passwordCtrl.text.length < 6) {
      _showSnack('비밀번호는 6자 이상이어야 해요'); return;
    }
    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      _showSnack('비밀번호가 일치하지 않아요'); return;
    }
    if (!_agreeTerms || !_agreePrivacy) {
      _showSnack('약관에 동의해주세요'); return;
    }
    setState(() => _step = 2);
  }

  void _handleComplete() async {
    if (_travelStyle.isEmpty) { _showSnack('여행 스타일을 선택해주세요'); return; }
    if (_signupMethod != 'email' && _nicknameCtrl.text.isEmpty) {
      _showSnack('닉네임을 입력해주세요'); return;
    }
    final nickname = _nicknameCtrl.text.isEmpty ? '섬여행러' : _nicknameCtrl.text;

    setState(() => _isLoading = true);
    try {
      await AuthService.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        nickname: nickname,
        travelStyle: _travelStyle,
      );
      if (mounted) {
        _showSnack('회원가입이 완료됐어요! 환영해요');
        context.go('/');
      }
    } on AuthException catch (e) {
      if (mounted) _showSnack('[Auth] ${e.message}');
    } catch (e) {
      if (mounted) _showSnack('[Error] $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static const _travelStyles = [
    {'id': '힐링', 'label': '힐링', 'icon': Icons.favorite_rounded, 'gradient': [Color(0xFFF472B6), Color(0xFFDB2777)]},
    {'id': '액티비티', 'label': '액티비티', 'icon': Icons.photo_camera_rounded, 'gradient': [Color(0xFFC084FC), Color(0xFF9333EA)]},
    {'id': '맛집탐방', 'label': '맛집 탐방', 'icon': Icons.restaurant_rounded, 'gradient': [Color(0xFFFB923C), Color(0xFFEA580C)]},
    {'id': '자연관광', 'label': '자연 관광', 'icon': Icons.park_rounded, 'gradient': [Color(0xFF4ADE80), Color(0xFF16A34A)]},
    {'id': '반려동물동반', 'label': '반려동물 동반', 'icon': Icons.pets_rounded, 'gradient': [Color(0xFF60A5FA), Color(0xFF2563EB)]},
  ];

  @override
  Widget build(BuildContext context) {
    final isSocial = _signupMethod != null && _signupMethod != 'email';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.gray200)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _handleBack,
                    child: Row(
                      children: const [
                        Icon(Icons.chevron_left, color: AppColors.gray700),
                        SizedBox(width: 4),
                        Text('뒤로', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.gray700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Logo
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.blue600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.directions_boat_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    (_step == 2 && isSocial) ? '여행 스타일 선택' : '회원가입',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.gray900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _step == 0 ? '가입 방법을 선택해주세요'
                        : _step == 1 ? '기본 정보를 입력해주세요'
                        : isSocial ? '선호하는 여행 스타일을 알려주세요'
                        : '여행 스타일을 선택해주세요',
                    style: const TextStyle(fontSize: 13, color: AppColors.gray600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: _buildStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    if (_step == 0) return _buildStep0();
    if (_step == 1 && _signupMethod == 'email') return _buildStep1();
    if (_step == 2) return _buildStep2();
    return const SizedBox();
  }

  Widget _buildStep0() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => setState(() { _signupMethod = 'email'; _step = 1; }),
            icon: const Icon(Icons.mail_outline),
            label: const Text('이메일로 시작하기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('이미 계정이 있으신가요? ', style: TextStyle(fontSize: 14, color: AppColors.gray600)),
            GestureDetector(
              onTap: () => context.go('/login'),
              child: const Text('로그인', style: TextStyle(fontSize: 14, color: AppColors.blue600, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label(icon: Icons.person_outline, label: '닉네임'),
        const SizedBox(height: 8),
        TextFormField(controller: _nicknameCtrl, decoration: const InputDecoration(hintText: '섬여행러')),
        const SizedBox(height: 16),
        const _Label(icon: Icons.mail_outline, label: '이메일'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'your@email.com'),
        ),
        const SizedBox(height: 16),
        const _Label(icon: Icons.lock_outline, label: '비밀번호'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordCtrl,
          obscureText: !_showPw,
          decoration: InputDecoration(
            hintText: '6자 이상 입력',
            suffixIcon: IconButton(
              icon: Icon(_showPw ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.gray400),
              onPressed: () => setState(() => _showPw = !_showPw),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _Label(icon: Icons.lock_outline, label: '비밀번호 확인'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordCtrl,
          obscureText: !_showConfirmPw,
          decoration: InputDecoration(
            hintText: '비밀번호 재입력',
            suffixIcon: IconButton(
              icon: Icon(_showConfirmPw ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.gray400),
              onPressed: () => setState(() => _showConfirmPw = !_showConfirmPw),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _AgreementRow(
          value: _agreeTerms,
          onChanged: (v) => setState(() => _agreeTerms = v!),
          label: '[필수] 이용약관에 동의합니다',
          url: 'https://sumtagi-web.vercel.app/terms',
        ),
        const SizedBox(height: 12),
        _AgreementRow(
          value: _agreePrivacy,
          onChanged: (v) => setState(() => _agreePrivacy = v!),
          label: '[필수] 개인정보 처리방침에 동의합니다',
          url: 'https://sumtagi-web.vercel.app/privacy',
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleEmailSignup,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('다음', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    final isSocial = _signupMethod != null && _signupMethod != 'email';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isSocial) ...[
          const _Label(icon: Icons.person_outline, label: '닉네임'),
          const SizedBox(height: 8),
          TextFormField(controller: _nicknameCtrl, decoration: const InputDecoration(hintText: '섬여행러')),
          const SizedBox(height: 24),
        ],
        const Text('선호 여행 스타일', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: _travelStyles.map((style) {
            final isSelected = _travelStyle == style['id'];
            final gradients = style['gradient'] as List<Color>;
            return GestureDetector(
              onTap: () => setState(() => _travelStyle = style['id'] as String),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.blue600 : AppColors.gray200,
                    width: 2,
                  ),
                  color: isSelected ? AppColors.blue50 : Colors.white,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: gradients),
                      ),
                      child: Icon(style['icon'] as IconData, color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      style['label'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.blue600 : AppColors.gray900,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue600,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.blue200,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('가입 완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Label({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.gray700),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray700)),
      ],
    );
  }
}

class _AgreementRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;
  final String? url;
  const _AgreementRow({required this.value, required this.onChanged, required this.label, this.url});

  Future<void> _openUrl() async {
    if (url == null) return;
    final uri = Uri.parse(url!);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20, height: 20,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.blue600,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.gray700)),
        ),
        if (url != null)
          GestureDetector(
            onTap: _openUrl,
            child: const Text(
              '보기',
              style: TextStyle(fontSize: 13, color: AppColors.blue600, decoration: TextDecoration.underline),
            ),
          ),
      ],
    );
  }
}
