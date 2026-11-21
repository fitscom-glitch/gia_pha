import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gia_pha/core/theme/app_colors.dart';

/// Họa tiết vân mây xoắn, lát gạch xen kẽ.
class CloudPatternPainter extends CustomPainter {
  const CloudPatternPainter({required this.color, this.cell = 76});

  final Color color;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    final rowH = cell * 0.72;
    var row = 0;
    for (var y = rowH / 2; y < size.height + rowH; y += rowH) {
      final shift = row.isOdd ? cell / 2 : 0.0;
      for (var x = shift; x < size.width + cell; x += cell) {
        _cloud(canvas, paint, Offset(x, y), cell * 0.22, row.isOdd);
      }
      row++;
    }
  }

  void _cloud(Canvas canvas, Paint paint, Offset c, double s, bool flip) {
    final dir = flip ? -1.0 : 1.0;
    final path = Path();
    const steps = 36;
    var last = c;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final ang = t * 2.2 * 2 * math.pi;
      final r = s * (0.1 + 0.62 * t);
      final p = Offset(c.dx + dir * r * math.cos(ang), c.dy + r * math.sin(ang));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
      last = p;
    }
    path.cubicTo(
      last.dx + dir * s * 0.5,
      last.dy + s * 0.15,
      last.dx + dir * s * 0.9,
      last.dy - s * 0.4,
      last.dx + dir * s * 1.5,
      last.dy - s * 0.15,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CloudPatternPainter old) =>
      old.color != color || old.cell != cell;
}

/// Nền giấy dó có vân mây mờ; đặt làm `body` của Scaffold.
class PatternBackground extends StatelessWidget {
  const PatternBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.paper,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: CloudPatternPainter(color: AppColors.patternLine),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Dải hồi văn (móc vuông) vàng trên nền đỏ thẫm.
class MeanderStrip extends StatelessWidget {
  const MeanderStrip({
    super.key,
    this.height = 14,
    this.background = AppColors.redDeep,
    this.line = AppColors.gold,
  });

  final double height;
  final Color background;
  final Color line;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _MeanderPainter(background, line)),
    );
  }
}

class _MeanderPainter extends CustomPainter {
  const _MeanderPainter(this.background, this.line);

  final Color background;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final u = size.height / 6.5;
    final y0 = 0.5 * u;
    final paint = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, u * 0.5)
      ..strokeJoin = StrokeJoin.miter;
    for (var x = 0.0; x < size.width; x += 6 * u) {
      canvas.drawLine(
        Offset(x, y0 + 5.5 * u),
        Offset(x + 6 * u, y0 + 5.5 * u),
        paint,
      );
      final hook = Path()
        ..moveTo(x, y0 + 5 * u)
        ..lineTo(x, y0 + 0.5 * u)
        ..lineTo(x + 4 * u, y0 + 0.5 * u)
        ..lineTo(x + 4 * u, y0 + 4 * u)
        ..lineTo(x + 1.8 * u, y0 + 4 * u)
        ..lineTo(x + 1.8 * u, y0 + 2.2 * u)
        ..lineTo(x + 2.6 * u, y0 + 2.2 * u);
      canvas.drawPath(hook, paint);
    }
  }

  @override
  bool shouldRepaint(_MeanderPainter old) =>
      old.background != background || old.line != line;
}

/// Thẻ viền vàng, bốn góc có hoa văn móc; bấm được nếu có [onTap].
class OrnateCard extends StatelessWidget {
  const OrnateCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(12),
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Material(
        color: AppColors.card,
        elevation: 1.5,
        shadowColor: const Color(0x667F0E14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.gold, width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: CustomPaint(
            foregroundPainter: const _CornerPainter(),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppColors.goldDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final dot = Paint()..color = AppColors.red;
    const inset = 5.0;
    const len = 11.0;

    void corner(double x, double y, double dx, double dy) {
      canvas.drawPath(
        Path()
          ..moveTo(x + dx * len, y)
          ..lineTo(x, y)
          ..lineTo(x, y + dy * len),
        line,
      );
      canvas.drawCircle(Offset(x + dx * 4, y + dy * 4), 1.3, dot);
    }

    corner(inset, inset, 1, 1);
    corner(size.width - inset, inset, -1, 1);
    corner(inset, size.height - inset, 1, -1);
    corner(size.width - inset, size.height - inset, -1, -1);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}
