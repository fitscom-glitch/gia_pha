import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gia_pha/core/widgets/ornaments/motif_data.dart';

final _pathCache = <MotifData, Path>{};

Path _motifPath(MotifData m) {
  return _pathCache.putIfAbsent(m, () {
    final path = Path();
    for (final poly in m.polygons) {
      path.moveTo(poly[0], poly[1]);
      for (var i = 2; i + 1 < poly.length; i += 2) {
        path.lineTo(poly[i], poly[i + 1]);
      }
      path.close();
    }
    return path;
  });
}

/// Vẽ hình rồng/phụng (silhouette) vừa khít khung, một màu.
/// [flipX] để lật ngang (phụng quay mặt vào giữa).
class MotifPainter extends CustomPainter {
  const MotifPainter(this.motif, this.color, {this.flipX = false});

  final MotifData motif;
  final Color color;
  final bool flipX;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / motif.width, size.height / motif.height);
    final dx = (size.width - motif.width * scale) / 2;
    final dy = (size.height - motif.height * scale) / 2;
    canvas.save();
    canvas.translate(dx, dy);
    if (flipX) {
      canvas.translate(motif.width * scale, 0);
      canvas.scale(-1, 1);
    }
    canvas.scale(scale);
    canvas.drawPath(
      _motifPath(motif),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(MotifPainter old) =>
      old.motif != motif || old.color != color || old.flipX != flipX;
}

/// Widget bọc [MotifPainter]; luôn đặt trong khung có kích thước xác định.
class MotifView extends StatelessWidget {
  const MotifView({
    super.key,
    required this.motif,
    required this.color,
    this.flipX = false,
  });

  final MotifData motif;
  final Color color;
  final bool flipX;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: MotifPainter(motif, color, flipX: flipX),
    );
  }
}
