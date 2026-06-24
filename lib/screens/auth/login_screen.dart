import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showPassword = false;
  bool _keepLoggedIn = false;
  bool _isLoading = false;
  late final _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.session != null && mounted) {
      context.go('/');
    }
  });

  @override
  void initState() {
    super.initState();
    _authSubscription;
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      _showSnack('이메일과 비밀번호를 입력해주세요');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AuthService.signIn(_emailCtrl.text.trim(), _passwordCtrl.text);
      if (mounted) {
        _showSnack('로그인됐어요! 반가워요');
        context.go('/');
      }
    } on AuthException catch (e) {
      if (mounted) _showSnack(AuthService.localizedError(e.message));
    } catch (_) {
      if (mounted) _showSnack('로그인 중 오류가 발생했어요');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleKakaoLogin() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.signInWithKakao();
    } catch (_) {
      if (mounted) _showSnack('카카오 로그인 중 오류가 발생했어요');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.signInWithGoogle();
    } catch (_) {
      if (mounted) _showSnack('구글 로그인 중 오류가 발생했어요');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.blue600,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.directions_boat_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '인천 도서 여행',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.gray900),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '계정에 로그인하세요',
                    style: TextStyle(fontSize: 14, color: AppColors.gray600),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),

                    // Email
                    _Label(icon: Icons.mail_outline, label: '이메일'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(hintText: 'your@email.com'),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    _Label(icon: Icons.lock_outline, label: '비밀번호'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: !_showPassword,
                      onFieldSubmitted: (_) => _handleSubmit(),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.gray400,
                          ),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Keep logged in + forgot password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: _keepLoggedIn,
                                onChanged: (v) => setState(() => _keepLoggedIn = v!),
                                activeColor: AppColors.blue600,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('로그인 유지', style: TextStyle(fontSize: 14, color: AppColors.gray700)),
                          ],
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('비밀번호 찾기', style: TextStyle(color: AppColors.blue600, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
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
                            : const Text('로그인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.gray200)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: const Text('또는', style: TextStyle(fontSize: 13, color: AppColors.gray500)),
                        ),
                        const Expanded(child: Divider(color: AppColors.gray200)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Social login
                    _SocialButton(
                      color: const Color(0xFFFEE500),
                      textColor: AppColors.gray900,
                      label: '카카오로 시작하기',
                      leading: SvgPicture.asset('assets/images/kakao_logo.svg', width: 20, height: 20),
                      onTap: _isLoading ? () {} : _handleKakaoLogin,
                    ),
                    const SizedBox(height: 12),
                    _SocialButton(
                      color: Colors.white,
                      textColor: AppColors.gray900,
                      label: '구글로 시작하기',
                      border: Border.all(color: AppColors.gray300, width: 2),
                      leading: SvgPicture.asset('assets/images/google_logo.svg', width: 20, height: 20),
                      onTap: _isLoading ? () {} : _handleGoogleLogin,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.gray200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('아직 계정이 없으신가요? ', style: TextStyle(fontSize: 14, color: AppColors.gray600)),
                  GestureDetector(
                    onTap: () => context.go('/signup'),
                    child: const Text('회원가입', style: TextStyle(fontSize: 14, color: AppColors.blue600, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

class _SocialButton extends StatelessWidget {
  final Color color;
  final Color textColor;
  final String label;
  final Color? dotColor;
  final double dotRadius;
  final Widget? leading;
  final Border? border;
  final bool useGoogleDot;
  final VoidCallback onTap;

  const _SocialButton({
    required this.color,
    required this.textColor,
    required this.label,
    this.leading,
    this.dotColor,
    this.dotRadius = 10,
    this.border,
    this.useGoogleDot = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: border,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null)
              SizedBox(width: 20, height: 20, child: Center(child: leading))
            else if (useGoogleDot)
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFFBBF24), Color(0xFF3B82F6)],
                  ),
                ),
              )
            else if (dotColor != null)
              Container(
                width: dotRadius * 2,
                height: dotRadius * 2,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
          ],
        ),
      ),
    );
  }
}
