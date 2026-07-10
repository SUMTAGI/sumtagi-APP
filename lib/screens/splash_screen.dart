import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    setState(() => _visible = false);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    final session = Supabase.instance.client.auth.currentSession;

    if (!mounted) return;
    if (session != null) {
      context.go('/');
    } else if (!hasSeenOnboarding) {
      context.go('/onboarding');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB), Color(0xFF1D4ED8)],
              ),
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3B82F6), Color(0xFF2563EB), Color(0xFF1D4ED8)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 4,
                        ),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .rotate(duration: 20.seconds),
                    // Inner ring
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                    ),
                    // Icon container
                    Container(
                      width: 128,
                      height: 128,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x40000000),
                            blurRadius: 24,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_boat_rounded,
                        size: 64,
                        color: Color(0xFF2563EB),
                      ),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1, 1),
                          duration: 600.ms,
                          curve: Curves.elasticOut,
                        ),
                    // Sparkle top-right
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFBBF24),
                          shape: BoxShape.circle,
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat())
                          .fade(
                            begin: 0.6,
                            end: 1.0,
                            duration: 1.seconds,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // App name
                const Text(
                  '섬타기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideY(begin: 0.3, end: 0),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.waves, color: Color(0xFFBFDBFE), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '당신의 완벽한 섬 여행 파트너',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 400.ms),
                const SizedBox(height: 48),
                // Loading dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (i) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .moveY(
                          begin: 0,
                          end: -8,
                          delay: Duration(milliseconds: i * 100),
                          duration: 400.ms,
                          curve: Curves.easeInOut,
                        )
                        .then()
                        .moveY(begin: -8, end: 0, duration: 400.ms),
                  ),
                ).animate().fadeIn(delay: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
