import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

class _SlideData {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;
  final String emoji;

  const _SlideData({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    required this.emoji,
  });
}

const _slides = [
  _SlideData(
    icon: Icons.directions_boat_rounded,
    title: '인천 섬 여행의 시작',
    description: '여객선 운항 정보를 기반으로\n실제 이동 가능한 여행 일정을\n자동으로 생성합니다',
    gradient: [Color(0xFF60A5FA), Color(0xFF2563EB)],
    emoji: '⛴️',
  ),
  _SlideData(
    icon: Icons.calendar_month_rounded,
    title: '맞춤형 일정 생성',
    description: '여행 기간, 인원, 취향을 입력하면\nAI가 최적의 일정을\n자동으로 계획해드립니다',
    gradient: [Color(0xFFC084FC), Color(0xFF9333EA)],
    emoji: '✨',
  ),
  _SlideData(
    icon: Icons.location_on_rounded,
    title: '스마트 관광지 추천',
    description: '혼잡도 분석과 날씨 정보로\n가장 쾌적한 시간대와 장소를\n추천해드립니다',
    gradient: [Color(0xFF4ADE80), Color(0xFF16A34A)],
    emoji: '🗺️',
  ),
  _SlideData(
    icon: Icons.auto_awesome_rounded,
    title: '통합 예약 관리',
    description: '여객선, 숙박, 체험까지\n모든 예약을 한 곳에서\n간편하게 관리하세요',
    gradient: [Color(0xFFFB923C), Color(0xFFEA580C)],
    emoji: '🎉',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentSlide = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() async {
    if (_currentSlide < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenOnboarding', true);
      if (mounted) context.go('/login');
    }
  }

  void _goPrev() {
    if (_currentSlide > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (mounted) context.go('/login');
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentSlide];
    final bgColor = slide.gradient[0].withOpacity(0.08);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgColor, bgColor.withOpacity(0.05), bgColor],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top navigation
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentSlide > 0)
                      GestureDetector(
                        onTap: _goPrev,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
                            ],
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.chevron_left, size: 16, color: AppColors.gray500),
                              SizedBox(width: 4),
                              Text('이전', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray500)),
                            ],
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 80),
                    if (_currentSlide < _slides.length - 1)
                      GestureDetector(
                        onTap: _skip,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
                            ],
                          ),
                          child: const Text(
                            '건너뛰기',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray500),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) => setState(() => _currentSlide = index),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final s = _slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 168,
                              height: 168,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [s.gradient[0].withOpacity(0.3), s.gradient[1].withOpacity(0.1)],
                                ),
                              ),
                            ),
                            Container(
                              width: 152,
                              height: 152,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: s.gradient,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: s.gradient[1].withOpacity(0.4),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(s.icon, size: 72, color: Colors.white),
                            )
                                .animate()
                                .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1), duration: 400.ms, curve: Curves.easeOut)
                                .fadeIn(),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Text(
                                s.emoji,
                                style: const TextStyle(fontSize: 40),
                              )
                                  .animate(onPlay: (c) => c.repeat(reverse: true))
                                  .moveY(begin: 0, end: -8, duration: 1500.ms, curve: Curves.easeInOut),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),

                        // Title
                        Text(
                          s.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray900,
                            height: 1.3,
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 16),

                        // Description
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            s.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.gray600,
                              height: 1.7,
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 150.ms, duration: 400.ms),

                        if (index == _slides.length - 1) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('🎉', style: TextStyle(fontSize: 20)),
                                SizedBox(width: 8),
                                Text(
                                  '준비 완료! 지금 바로 시작하세요',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.gray900),
                                ),
                                SizedBox(width: 8),
                                Text('✨', style: TextStyle(fontSize: 20)),
                              ],
                            ),
                          ).animate().slideY(begin: 0.3, end: 0, duration: 400.ms).fadeIn(),
                        ],
                      ],
                    );
                  },
                ),
              ),

              // Bottom navigation
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (i) => GestureDetector(
                          onTap: () => _goToPage(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: i == _currentSlide ? 40 : 10,
                            height: 10,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              gradient: i == _currentSlide
                                  ? LinearGradient(colors: slide.gradient)
                                  : null,
                              color: i != _currentSlide ? AppColors.gray300 : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Next button
                    GestureDetector(
                      onTap: _goNext,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: slide.gradient),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: slide.gradient[1].withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_currentSlide == _slides.length - 1)
                              const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                            if (_currentSlide == _slides.length - 1) const SizedBox(width: 8),
                            Text(
                              _currentSlide < _slides.length - 1 ? '다음' : '시작하기',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right, color: Colors.white, size: 22),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
