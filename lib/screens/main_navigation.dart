import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class MainNavigation extends StatefulWidget {
  final Widget child;
  const MainNavigation({super.key, required this.child});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  bool _isMovingForward = true;
  String _currentLocation = '/';

  int _locationToIndex(String location) {
    if (location == '/') return 0;
    if (location.startsWith('/travel')) return 1;
    if (location.startsWith('/islands') || location.startsWith('/island')) return 2;
    if (location.startsWith('/map')) return 3;
    if (location.startsWith('/my')) return 4;
    return 0;
  }

  void _onTabTap(BuildContext context, int newIndex) {
    final currentIdx = _locationToIndex(_currentLocation);
    if (newIndex == currentIdx) return;
    _isMovingForward = newIndex > currentIdx;
    switch (newIndex) {
      case 0: context.go('/'); break;
      case 1: context.go('/travel'); break;
      case 2: context.go('/islands'); break;
      case 3: context.go('/map'); break;
      case 4: context.go('/my'); break;
    }
  }

  Widget _buildTransition(Widget child, Animation<double> animation) {
    final isIncoming = child.key == ValueKey(_currentLocation);
    final slideBegin = isIncoming
        ? (_isMovingForward ? const Offset(1, 0) : const Offset(-1, 0))
        : (_isMovingForward ? const Offset(-1, 0) : const Offset(1, 0));

    return SlideTransition(
      position: Tween<Offset>(begin: slideBegin, end: Offset.zero)
          .animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    _currentLocation = location;
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: _buildTransition,
        child: KeyedSubtree(
          key: ValueKey(location),
          child: widget.child,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.gray200, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: '홈',
                  isActive: currentIndex == 0,
                  onTap: () => _onTabTap(context, 0),
                ),
                _NavItem(
                  icon: Icons.calendar_month_rounded,
                  label: '여행',
                  isActive: currentIndex == 1,
                  onTap: () => _onTabTap(context, 1),
                ),
                _NavItem(
                  icon: Icons.location_on_rounded,
                  label: '섬',
                  isActive: currentIndex == 2,
                  onTap: () => _onTabTap(context, 2),
                ),
                _NavItem(
                  icon: Icons.explore_rounded,
                  label: '지도',
                  isActive: currentIndex == 3,
                  onTap: () => _onTabTap(context, 3),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: '마이',
                  isActive: currentIndex == 4,
                  onTap: () => _onTabTap(context, 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? AppColors.blue600 : AppColors.gray500,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isActive ? AppColors.blue600 : AppColors.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
