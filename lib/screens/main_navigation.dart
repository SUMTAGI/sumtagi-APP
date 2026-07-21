import 'dart:ui';
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
    if (location.startsWith('/my')) return 3;
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
      case 3: context.go('/my'); break;
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
      extendBody: true,
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const itemCount = 4;
            const barHeight = 76.0;
            const indicatorSize = 58.0;
            final itemWidth = constraints.maxWidth / itemCount;
            return Container(
              height: barHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(38),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(38),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(38),
                      border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          left: itemWidth * currentIndex + (itemWidth - indicatorSize) / 2,
                          top: (barHeight - indicatorSize) / 2,
                          width: indicatorSize,
                          height: indicatorSize,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.75),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2)),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _NavItem(
                                icon: Icons.home_rounded,
                                label: '홈',
                                isActive: currentIndex == 0,
                                onTap: () => _onTabTap(context, 0),
                              ),
                            ),
                            Expanded(
                              child: _NavItem(
                                icon: Icons.calendar_month_rounded,
                                label: '여행',
                                isActive: currentIndex == 1,
                                onTap: () => _onTabTap(context, 1),
                              ),
                            ),
                            Expanded(
                              child: _NavItem(
                                icon: Icons.location_on_rounded,
                                label: '섬',
                                isActive: currentIndex == 2,
                                onTap: () => _onTabTap(context, 2),
                              ),
                            ),
                            Expanded(
                              child: _NavItem(
                                icon: Icons.person_rounded,
                                label: '마이',
                                isActive: currentIndex == 3,
                                onTap: () => _onTabTap(context, 3),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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
    final color = isActive ? AppColors.blue600 : AppColors.gray500;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: color),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
}
