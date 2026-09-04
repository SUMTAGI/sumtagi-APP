import 'package:flutter/material.dart';

// 홈 퀵메뉴용 일러스트 아이콘.
// 금융앱처럼 단순·클린한 면 구성. 외곽선 없음, 장식 최소화.
// 팔레트는 상단 그라데이션 배경과 같은 계열 3색으로 제한.
class IllustPalette {
  static const Color blue = Color(0xFF2563EB); // 그라데이션 상단
  static const Color blueMid = Color(0xFF3B82F6); // 그라데이션 중간
  static const Color bluePale = Color(0xFFD5F0FF); // 그라데이션 하단
}

class ChecklistIllust extends StatelessWidget {
  final double size;
  const ChecklistIllust({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _ChecklistPainter());
}

class BudgetIllust extends StatelessWidget {
  final double size;
  const BudgetIllust({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _BudgetPainter());
}

class FavoriteIllust extends StatelessWidget {
  final double size;
  const FavoriteIllust({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _FavoritePainter());
}

class ReviewIllust extends StatelessWidget {
  final double size;
  const ReviewIllust({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _ReviewPainter());
}

/// 날씨 일러스트 — 빠른 메뉴와 같은 납작한 면 구성이지만 색은 날씨에 맞게 자유롭게 사용
class WeatherIllust extends StatelessWidget {
  final String condition; // '맑음' | '구름조금' | '흐림' | '비'
  final double size;
  const WeatherIllust({super.key, required this.condition, this.size = 76});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _WeatherPainter(condition));
}

// 모든 페인터는 56x56 기준 좌표로 그리고 실제 크기에 맞춰 스케일
abstract class _ScaledPainter extends CustomPainter {
  static const double base = 56;

  void draw(Canvas canvas);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / base, size.height / base);
    draw(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 체크리스트: 연파랑 문서 + 파란 항목 줄 + 체크 하나
class _ChecklistPainter extends _ScaledPainter {
  @override
  void draw(Canvas c) {
    c.drawRRect(
      RRect.fromLTRBR(10, 8, 46, 48, const Radius.circular(10)),
      Paint()..color = IllustPalette.bluePale,
    );

    final line = Paint()
      ..color = IllustPalette.blueMid
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(26, 21), const Offset(38, 21), line);
    c.drawLine(const Offset(26, 30), const Offset(38, 30), line);
    c.drawLine(const Offset(26, 39), const Offset(34, 39), line);

    // 항목 앞 체크 — 첫 줄만 완료 표시
    final check = Paint()
      ..color = IllustPalette.blue
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    c.drawPath(
      Path()
        ..moveTo(16, 21.5)
        ..lineTo(19, 24.5)
        ..lineTo(23.5, 18.5),
      check,
    );
    final dot = Paint()..color = IllustPalette.blueMid;
    c.drawCircle(const Offset(19.5, 30), 2.2, dot);
    c.drawCircle(const Offset(19.5, 39), 2.2, dot);
  }
}

// 경비관리: 카드 형태 — 파란 카드 + 중간톤 스트라이프 + 연파랑 칩
class _BudgetPainter extends _ScaledPainter {
  @override
  void draw(Canvas c) {
    c.drawRRect(
      RRect.fromLTRBR(6, 13, 50, 43, const Radius.circular(8)),
      Paint()..color = IllustPalette.blue,
    );
    // 마그네틱 스트라이프
    c.drawRect(const Rect.fromLTRB(6, 20, 50, 26), Paint()..color = IllustPalette.blueMid);
    // 칩
    c.drawRRect(
      RRect.fromLTRBR(12, 31, 22, 38, const Radius.circular(2)),
      Paint()..color = IllustPalette.bluePale,
    );
  }
}

// 즐겨찾기: 하트 — 두 개의 원 + 아래 꼭짓점으로 만든 단순한 면
class _FavoritePainter extends _ScaledPainter {
  @override
  void draw(Canvas c) {
    final heart = Path()
      ..moveTo(28, 47)
      ..cubicTo(28, 47, 7, 34, 7, 20.5)
      ..cubicTo(7, 13.5, 12.3, 9, 18.3, 9)
      ..cubicTo(22.6, 9, 26.2, 11.4, 28, 15)
      ..cubicTo(29.8, 11.4, 33.4, 9, 37.7, 9)
      ..cubicTo(43.7, 9, 49, 13.5, 49, 20.5)
      ..cubicTo(49, 34, 28, 47, 28, 47)
      ..close();
    c.drawPath(heart, Paint()..color = IllustPalette.blueMid);
  }
}

class _WeatherPainter extends _ScaledPainter {
  final String condition;
  _WeatherPainter(this.condition);

  static const _sun = Color(0xFFFBBF24);
  static const _sunCore = Color(0xFFFDE68A);
  static const _cloudLight = Color(0xFFFFFFFF);
  static const _cloudMid = Color(0xFFE5E7EB);
  static const _cloudDark = Color(0xFFCBD5E1);
  static const _rain = Color(0xFF60A5FA);

  @override
  void draw(Canvas c) {
    switch (condition) {
      case '구름조금':
        _drawSun(c, const Offset(22, 22), 12);
        _drawCloud(c, const Offset(31, 34), 1.0, _cloudLight);
        break;
      case '흐림':
        _drawCloud(c, const Offset(30, 24), 0.9, _cloudDark);
        _drawCloud(c, const Offset(26, 34), 1.0, _cloudMid);
        break;
      case '비':
        _drawCloud(c, const Offset(28, 24), 1.0, _cloudMid);
        final drop = Paint()
          ..color = _rain
          ..strokeWidth = 3.4
          ..strokeCap = StrokeCap.round;
        for (final x in [18.0, 28.0, 38.0]) {
          c.drawLine(Offset(x + 1, 38), Offset(x - 1, 47), drop);
        }
        break;
      default: // 맑음
        _drawSun(c, const Offset(28, 28), 16);
    }
  }

  // 해: 노란 원 + 살짝 밝은 중심 (광선 없이 단순하게)
  void _drawSun(Canvas c, Offset center, double r) {
    c.drawCircle(center, r, Paint()..color = _sun);
    c.drawCircle(center, r * 0.55, Paint()..color = _sunCore);
  }

  // 구름: 원 3개 + 아래 둥근 사각형을 겹쳐 하나의 면으로
  void _drawCloud(Canvas c, Offset center, double s, Color color) {
    final p = Paint()..color = color;
    final cx = center.dx, cy = center.dy;
    c.drawCircle(Offset(cx - 9 * s, cy + 2 * s), 7 * s, p);
    c.drawCircle(Offset(cx, cy - 4 * s), 9.5 * s, p);
    c.drawCircle(Offset(cx + 9 * s, cy + 2 * s), 7 * s, p);
    c.drawRRect(
      RRect.fromLTRBR(cx - 16 * s, cy + 1 * s, cx + 16 * s, cy + 9 * s, Radius.circular(5 * s)),
      p,
    );
  }
}

// 리뷰: 말풍선 + 점 세 개
class _ReviewPainter extends _ScaledPainter {
  @override
  void draw(Canvas c) {
    final bubble = Paint()..color = IllustPalette.blueMid;
    c.drawRRect(RRect.fromLTRBR(6, 9, 50, 41, const Radius.circular(12)), bubble);
    c.drawPath(
      Path()
        ..moveTo(14, 39)
        ..lineTo(11, 49)
        ..lineTo(24, 40)
        ..close(),
      bubble,
    );

    final dot = Paint()..color = IllustPalette.bluePale;
    for (final x in [19.0, 28.0, 37.0]) {
      c.drawCircle(Offset(x, 25), 3, dot);
    }
  }
}
