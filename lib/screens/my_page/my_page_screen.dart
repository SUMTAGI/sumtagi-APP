import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/trip_service.dart';
import '../../services/review_service.dart';
import '../../theme/app_colors.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  User? _user;
  int _tripCount = 0;
  int _reviewCount = 0;

  @override
  void initState() {
    super.initState();
    _user = AuthService.currentUser;
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final results = await Future.wait([
      TripService.getTripCount(),
      ReviewService.getMyReviewCount(),
    ]);
    if (mounted) {
      setState(() {
        _tripCount = results[0];
        _reviewCount = results[1];
      });
    }
  }

  void _handleLogout() async {
    await AuthService.signOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('로그아웃됐어요. 다음에 또 만나요!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: AppColors.gray900,
        ),
      );
      context.go('/login');
    }
  }

  String get _displayName {
    final meta = _user?.userMetadata;
    if (meta != null && meta['nickname'] != null) return meta['nickname'] as String;
    return _user?.email?.split('@')[0] ?? '사용자';
  }

  String get _email => _user?.email ?? '';

  int get _daysSinceJoin {
    final raw = _user?.createdAt;
    if (raw == null) return 0;
    final joined = DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now().difference(joined).inDays;
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_outline_rounded, size: 64, color: AppColors.gray300),
                const SizedBox(height: 16),
                const Text('로그인이 필요합니다', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                const SizedBox(height: 8),
                const Text('마이페이지를 이용하려면\n로그인해주세요', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.gray600, height: 1.5)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('로그인하기'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: false,
            floating: false,
            expandedHeight: 200,
            toolbarHeight: 0,
            backgroundColor: const Color(0xFF2563EB),
            elevation: 0,
            scrolledUnderElevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.none,
              background: _buildHeader(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(label: '계정 정보'),
                  _MenuCard(children: [
                    _MenuItem(icon: Icons.person_outline_rounded, label: '프로필 수정', onTap: () => context.push('/profile-edit')),
                    _MenuItem(icon: Icons.mail_outline_rounded, label: '이메일', value: _email, onTap: () => context.push('/profile-edit')),
                    _MenuItem(icon: Icons.lock_outline_rounded, label: '비밀번호 변경', onTap: () => context.push('/profile-edit'), showDivider: false),
                  ]),
                  const SizedBox(height: 20),

                  _SectionTitle(label: '여행 관리'),
                  _MenuCard(children: [
                    _MenuItem(icon: Icons.calendar_month_rounded, label: '내 여행 일정', onTap: () => context.go('/travel')),
                    _MenuItem(icon: Icons.people_rounded, label: '그룹 여행', onTap: () => context.push('/group-trip')),
                    _MenuItem(icon: Icons.book_rounded, label: '여행 다이어리', onTap: () => context.push('/diary')),
                    _MenuItem(icon: Icons.local_offer_rounded, label: '패키지 상품', onTap: () => context.push('/packages')),
                    _MenuItem(icon: Icons.credit_card_rounded, label: '경비 관리', onTap: () => context.push('/budget')),
                    _MenuItem(icon: Icons.card_giftcard_rounded, label: '쿠폰함', onTap: () => context.push('/coupons')),
                    _MenuItem(icon: Icons.location_on_rounded, label: '방문한 섬', onTap: () => context.push('/visited-islands')),
                    _MenuItem(icon: Icons.favorite_rounded, label: '찜한 여행지', onTap: () => context.push('/favorites'), showDivider: false),
                  ]),
                  const SizedBox(height: 20),

                  _SectionTitle(label: '편의 기능'),
                  _MenuCard(children: [
                    _MenuItem(icon: Icons.schedule_rounded, label: '교통 시간표', onTap: () => context.push('/schedule')),
                    _MenuItem(icon: Icons.event_rounded, label: '이벤트 & 축제', onTap: () => context.push('/events')),
                    _MenuItem(icon: Icons.warning_amber_rounded, label: '긴급 연락처', onTap: () => context.push('/emergency'), showDivider: false),
                  ]),
                  const SizedBox(height: 20),

                  _SectionTitle(label: '설정'),
                  _MenuCard(children: [
                    _MenuItem(icon: Icons.notifications_outlined, label: '알림 설정', onTap: () => context.push('/notification-settings')),
                    _MenuItem(icon: Icons.settings_outlined, label: '앱 설정', onTap: () => context.push('/app-settings')),
                    _MenuItem(icon: Icons.help_outline_rounded, label: '고객센터', onTap: () => context.push('/support'), showDivider: false),
                  ]),
                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: _handleLogout,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gray200),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, color: AppColors.red700, size: 20),
                          SizedBox(width: 8),
                          Text('로그아웃', style: TextStyle(color: AppColors.red700, fontWeight: FontWeight.w500, fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(child: Text('버전 1.0.0', style: TextStyle(fontSize: 12, color: AppColors.gray500))),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)])),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.person_rounded, size: 32, color: AppColors.blue600),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(_email, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _StatCard(label: '가입일', value: '$_daysSinceJoin일전')),
                  const SizedBox(width: 8),
                  Expanded(child: _StatCard(label: '예약', value: '$_tripCount건')),
                  const SizedBox(width: 8),
                  Expanded(child: _StatCard(label: '리뷰', value: '$_reviewCount개')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 10),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray500)),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<Widget> children;
  const _MenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(children: children),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;
  final bool showDivider;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.value,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.gray500),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.gray900))),
                if (value != null)
                  Text(value!, style: const TextStyle(fontSize: 13, color: AppColors.gray500))
                else
                  const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.gray400),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 48, color: AppColors.gray100),
      ],
    );
  }
}
