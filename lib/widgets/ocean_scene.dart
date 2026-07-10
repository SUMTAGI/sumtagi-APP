import 'dart:math' as math;
import 'package:flutter/material.dart';

// 히어로 배너 위에 얹는 장식용 바다 애니메이션(파도 + 배 + 물고기 + 물방울 + 초록 섬).
// sumtagi-WEB의 OceanScene.tsx와 같은 구성을 Flutter로 옮긴 것.
class OceanScene extends StatefulWidget {
  final Color waveColor;
  final Color creatureColor;
  final Color islandColor;
  final double waveHeight;
  final bool showWave;
  final bool showIsland;

  const OceanScene({
    super.key,
    this.waveColor = const Color(0xFFF5F6F8),
    this.creatureColor = const Color(0x8CFFFFFF),
    this.islandColor = const Color(0xFF2F9E5C),
    this.waveHeight = 40,
    this.showWave = true,
    this.showIsland = true,
  });

  @override
  State<OceanScene> createState() => _OceanSceneState();
}

class _OceanSceneState extends State<OceanScene> with TickerProviderStateMixin {
  late final AnimationController _boat;
  late final AnimationController _fish1;
  late final AnimationController _fish2;
  late final AnimationController _wave1;
  late final AnimationController _wave2;
  late final AnimationController _island;
  late final AnimationController _bubbles;

  @override
  void initState() {
    super.initState();
    _boat = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();
    _fish1 = AnimationController(vsync: this, duration: const Duration(seconds: 11))..repeat();
    _fish2 = AnimationController(vsync: this, duration: const Duration(seconds: 13))..repeat();
    _wave1 = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat();
    _wave2 = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
    _island = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _bubbles = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
  }

  @override
  void dispose() {
    _boat.dispose();
    _fish1.dispose();
    _fish2.dispose();
    _wave1.dispose();
    _wave2.dispose();
    _island.dispose();
    _bubbles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return ClipRect(
            child: Stack(
              children: [
                if (widget.showWave)
                  AnimatedBuilder(
                    animation: _wave1,
                    builder: (_, __) => Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: CustomPaint(
                        size: Size(w, widget.waveHeight),
                        painter: _WavePainter(
                          color: widget.waveColor.withOpacity(0.55),
                          phase: _wave1.value,
                          waveHeight: widget.waveHeight,
                        ),
                      ),
                    ),
                  ),

                _driftingIcon(
                  controller: _boat,
                  icon: Icons.directions_boat_filled_rounded,
                  size: 26,
                  top: h * 0.16,
                  width: w,
                  bobAmplitude: 5,
                  bobCycles: 2,
                ),
                _driftingIcon(
                  controller: _fish1,
                  icon: Icons.set_meal_rounded,
                  size: 18,
                  top: h * 0.42,
                  width: w,
                  bobAmplitude: 8,
                  bobCycles: 1,
                ),
                _driftingIcon(
                  controller: _fish2,
                  icon: Icons.set_meal_rounded,
                  size: 14,
                  top: h * 0.58,
                  width: w,
                  bobAmplitude: 6,
                  bobCycles: 1,
                  reverse: true,
                  opacity: 0.7,
                ),

                if (widget.showIsland)
                  AnimatedBuilder(
                    animation: _island,
                    builder: (_, __) => Positioned(
                      right: w * 0.1,
                      bottom: math.max(widget.waveHeight - 26, 2) + _island.value * 4,
                      child: _Island(color: widget.islandColor),
                    ),
                  ),

                ..._bubblePositions(w).map((b) => AnimatedBuilder(
                      animation: _bubbles,
                      builder: (_, __) {
                        final t = (_bubbles.value + b.delay) % 1.0;
                        return Positioned(
                          left: b.left,
                          bottom: b.bottom + t * 90,
                          child: Opacity(
                            opacity: (t < 0.15 ? t / 0.15 : (1 - t) / 0.85).clamp(0.0, 1.0) * 0.5,
                            child: Container(
                              width: b.size,
                              height: b.size,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            ),
                          ),
                        );
                      },
                    )),

                if (widget.showWave)
                  AnimatedBuilder(
                    animation: _wave2,
                    builder: (_, __) => Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: CustomPaint(
                        size: Size(w, widget.waveHeight),
                        painter: _WavePainter(
                          color: widget.waveColor,
                          phase: _wave2.value,
                          waveHeight: widget.waveHeight,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _driftingIcon({
    required AnimationController controller,
    required IconData icon,
    required double size,
    required double top,
    required double width,
    required double bobAmplitude,
    required int bobCycles,
    bool reverse = false,
    double opacity = 1,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = reverse ? 1 - controller.value : controller.value;
        final x = -0.1 * width + t * (1.2 * width);
        final y = top + math.sin(t * 2 * math.pi * bobCycles) * bobAmplitude;
        return Positioned(
          left: x,
          top: y,
          child: Transform(
            alignment: Alignment.center,
            transform: reverse ? (Matrix4.identity()..scale(-1.0, 1.0)) : Matrix4.identity(),
            child: Icon(icon, size: size, color: widget.creatureColor.withOpacity(widget.creatureColor.opacity * opacity)),
          ),
        );
      },
    );
  }

  List<_Bubble> _bubblePositions(double w) => [
        _Bubble(left: w * 0.12, bottom: 8, size: 6, delay: 0.0),
        _Bubble(left: w * 0.38, bottom: 5, size: 4, delay: 0.3),
        _Bubble(left: w * 0.64, bottom: 10, size: 8, delay: 0.6),
        _Bubble(left: w * 0.85, bottom: 4, size: 6, delay: 0.15),
      ];
}

class _Bubble {
  final double left;
  final double bottom;
  final double size;
  final double delay;
  const _Bubble({required this.left, required this.bottom, required this.size, required this.delay});
}

class _Island extends StatelessWidget {
  final Color color;
  const _Island({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          CustomPaint(size: const Size(64, 24), painter: _IslandMoundPainter(color: color)),
          Positioned(
            bottom: 16,
            child: Icon(Icons.park_rounded, size: 26, color: color),
          ),
        ],
      ),
    );
  }
}

class _IslandMoundPainter extends CustomPainter {
  final Color color;
  const _IslandMoundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..cubicTo(size.width * 0.06, size.height * 0.4, size.width * 0.22, size.height * 0.1, size.width * 0.4, size.height * 0.25)
      ..cubicTo(size.width * 0.54, size.height * 0.35, size.width * 0.6, size.height * 0.05, size.width * 0.76, size.height * 0.2)
      ..cubicTo(size.width * 0.9, size.height * 0.3, size.width * 0.96, size.height * 0.6, size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _IslandMoundPainter oldDelegate) => oldDelegate.color != color;
}

class _WavePainter extends CustomPainter {
  final Color color;
  final double phase; // 0..1, one full horizontal cycle
  final double waveHeight;
  const _WavePainter({required this.color, required this.phase, required this.waveHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final amplitude = waveHeight * 0.32;
    final baseY = waveHeight * 0.5;
    final path = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 6) {
      final y = baseY + amplitude * math.sin((x / size.width) * 2 * math.pi + phase * 2 * math.pi);
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.color != color || oldDelegate.waveHeight != waveHeight;
}
