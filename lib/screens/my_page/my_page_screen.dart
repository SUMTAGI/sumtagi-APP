import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/trip_service.dart';
import '../../services/favorite_service.dart';
import '../../services/group_trip_service.dart';
import '../../services/host_service.dart';
import '../../theme/app_colors.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  User? _user;
  int _tripCount = 0;
  bool _loadingDashboard = true;
  Map<String, dynamic>? _upcomingTrip;
  List<Map<String, dynamic>> _visitedTrips = [];
  int _favoriteCount = 0;
  int _groupCount = 0;
  HostApplication? _hostApplication;
  String _role = 'user';

  @override
  void initState() {
    super.initState();
    _user = AuthService.currentUser;
    _loadCounts();
    _loadDashboard();
  }

  Future<void> _loadCounts() async {
    final tripCount = await TripService.getTripCount();
    if (mounted) {
      setState(() {
        _tripCount = tripCount;
      });
    }
  }

  Future<void> _loadDashboard() async {
    final results = await Future.wait([
      TripService.getUpcomingTrip(),
      TripService.getVisitedTrips(),
      FavoriteService.getFavorites(),
      GroupTripService.getMyGroups(),
      HostService.getMyHostApplication(),
      HostService.getMyRole(),
    ]);
    if (mounted) {
      setState(() {
        _upcomingTrip = results[0] as Map<String, dynamic>?;
        _visitedTrips = results[1] as List<Map<String, dynamic>>;
        _favoriteCount = (results[2] as List).length;
        _groupCount = (results[3] as List).length;
        _hostApplication = results[4] as HostApplication?;
        _role = results[5] as String;
        _loadingDashboard = false;
      });
    }
  }

  bool get _isHost => _role == 'host';
  bool get _isAdmin => _role == 'admin';

  IconData get _hostMenuIcon {
    if (_isHost) return Icons.check_circle_rounded;
    if (_hostApplication?.status == 'pending') return Icons.assignment_turned_in_rounded;
    if (_hostApplication?.status == 'rejected') return Icons.cancel_rounded;
    return Icons.business_rounded;
  }

  Color get _hostMenuIconBg => _hostApplication?.status == 'pending' ? const Color(0xFFFFFBEB) : AppColors.blue50;

  Color get _hostMenuIconColor {
    if (_hostApplication?.status == 'pending') return const Color(0xFFB45309);
    if (_hostApplication?.status == 'rejected') return AppColors.red500;
    return AppColors.blue600;
  }

  String get _hostMenuLabel {
    if (_isHost) return '호스트 대시보드';
    if (_hostApplication?.status == 'pending') return '호스트 신청 검토 중';
    if (_hostApplication?.status == 'rejected') return '호스트 신청 수정 / 재신청';
    return '숙소 운영자 신청';
  }

  String get _hostMenuDesc {
    if (_isHost) return '승인 완료 · 기능 준비 중이에요';
    if (_hostApplication?.status == 'pending') return '제출한 신청서를 검토하고 있어요';
    if (_hostApplication?.status == 'rejected') return '반려됨 · 정보를 수정하고 재신청하세요';
    return '섬타기에 숙소를 등록해보세요';
  }

  int get _visitedIslandCount {
    final islands = <String>{};
    for (final t in _visitedTrips) {
      islands.addAll((t['islands'] as List?)?.cast<String>() ?? []);
    }
    return islands.length;
  }

  String get _travelStyleLabel => _visitedTrips.isEmpty ? '아직 없음' : '다양한 스타일';

  int _dDay(String startDate) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final start = DateTime.parse(startDate);
    return start.difference(todayDate).inDays;
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
                  if (!_loadingDashboard) ...[
                    GestureDetector(
                      onTap: () => _upcomingTrip != null
                          ? context.push('/itinerary/${_upcomingTrip!['id']}')
                          : context.push('/create-trip'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: _upcomingTrip != null ? AppColors.blue50 : AppColors.gray100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _upcomingTrip != null
                                    ? '다음 여행 · ${_upcomingTrip!['title'] ?? '여행'}'
                                    : '예정된 여행이 없어요',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _upcomingTrip != null ? AppColors.blue700 : AppColors.gray500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_upcomingTrip != null)
                              Builder(builder: (context) {
                                final dday = _dDay(_upcomingTrip!['start_date'] as String);
                                if (dday < 0) return const SizedBox();
                                return Text(
                                  dday == 0 ? '오늘' : 'D-$dday',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.blue600),
                                );
                              })
                            else
                              const Text('여행 계획 →', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.blue600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _SectionTitle(label: '여행 통계'),
                    Row(
                      children: [
                        Expanded(child: _StatTile(icon: Icons.calendar_month_rounded, label: '총 여행 횟수', value: '$_tripCount', onTap: () => context.go('/travel'))),
                        const SizedBox(width: 8),
                        Expanded(child: _StatTile(icon: Icons.location_on_rounded, label: '방문한 섬 수', value: '$_visitedIslandCount', onTap: () => context.go('/travel'))),
                        const SizedBox(width: 8),
                        Expanded(child: _StatTile(icon: Icons.favorite_rounded, label: '즐겨찾기', value: '$_favoriteCount', onTap: () => context.push('/favorites'))),
                        const SizedBox(width: 8),
                        Expanded(child: _StatTile(icon: Icons.explore_rounded, label: '여행 스타일', value: _travelStyleLabel, onTap: null)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (_visitedTrips.isNotEmpty) ...[
                      _SectionTitle(label: '최근 여행'),
                      ..._visitedTrips.take(3).map((trip) => GestureDetector(
                            onTap: () => context.push('/itinerary/${trip['id']}'),
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.gray200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(trip['title'] as String? ?? '여행', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                                  const SizedBox(height: 2),
                                  Text(
                                    ((trip['islands'] as List?)?.cast<String>() ?? []).join(', ').isEmpty
                                        ? '섬 정보 없음'
                                        : ((trip['islands'] as List).cast<String>()).join(', '),
                                    style: const TextStyle(fontSize: 13, color: AppColors.gray500),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(trip['start_date'] as String? ?? '', style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
                                ],
                              ),
                            ),
                          )),
                      const SizedBox(height: 12),
                    ],
                  ],

                  _SectionTitle(label: '여행 관리'),
                  _MenuCard(children: [
                    _MenuItem(icon: Icons.calendar_month_rounded, label: '내 여행 일정', onTap: () => context.go('/travel')),
                    _MenuItem(
                      icon: Icons.people_rounded,
                      label: _groupCount > 0 ? '그룹 여행 · $_groupCount개' : '그룹 여행',
                      onTap: () => context.push('/group-trip'),
                    ),
                    _MenuItem(icon: Icons.credit_card_rounded, label: '경비 관리', onTap: () => context.push('/budget')),
                    _MenuItem(icon: Icons.favorite_rounded, label: '찜한 여행지', onTap: () => context.push('/favorites'), showDivider: false),
                  ]),
                  const SizedBox(height: 20),

                  _SectionTitle(label: '숙소 운영'),
                  _HostMenuItem(
                    icon: _hostMenuIcon,
                    iconBg: _hostMenuIconBg,
                    iconColor: _hostMenuIconColor,
                    label: _hostMenuLabel,
                    desc: _hostMenuDesc,
                    onTap: () => context.push('/host-apply'),
                  ),
                  if (_isAdmin) ...[
                    const SizedBox(height: 10),
                    _HostMenuItem(
                      icon: Icons.verified_user_rounded,
                      iconBg: AppColors.blue50,
                      iconColor: AppColors.blue600,
                      label: '관리자 계정',
                      badge: 'ADMIN',
                      desc: '호스트 심사 관리',
                      onTap: () => context.push('/admin/hosts'),
                    ),
                  ],
                  const SizedBox(height: 20),

                  _SectionTitle(label: '편의 기능'),
                  _MenuCard(children: [
                    _MenuItem(icon: Icons.schedule_rounded, label: '교통 시간표', onTap: () => context.push('/schedule')),
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
                  const Center(child: Text('버전 1.0.0', style: TextStyle(fontSize: 13, color: AppColors.gray500))),
                  const SizedBox(height: 100),
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
        child: Stack(
          children: [
            Padding(
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
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 16,
              right: 24,
              child: _HeaderIconButton(
                icon: Icons.edit_rounded,
                onTap: () => context.push('/profile-edit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: Colors.white),
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
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _StatTile({required this.icon, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.blue600),
            const SizedBox(height: 6),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.gray900),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.gray500),
            ),
          ],
        ),
      ),
    );
  }
}

class _HostMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String desc;
  final String? badge;
  final VoidCallback onTap;

  const _HostMenuItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.desc,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.gray900))),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.blue50, borderRadius: BorderRadius.circular(999)),
                          child: Text(badge!, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.blue600)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(desc, style: const TextStyle(fontSize: 13, color: AppColors.gray500), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.gray300),
          ],
        ),
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
  final VoidCallback onTap;
  final bool showDivider;

  const _MenuItem({
    required this.icon,
    required this.label,
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
