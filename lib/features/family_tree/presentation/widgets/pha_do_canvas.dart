import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
import 'package:gia_pha/core/widgets/art_assets.dart';
import 'package:gia_pha/features/family_tree/domain/entities/pha_do_layer.dart';
import 'package:gia_pha/features/family_tree/domain/services/generation_rows.dart';
import 'package:gia_pha/features/family_tree/domain/services/tree_layout.dart';
import 'package:gia_pha/features/family_tree/presentation/widgets/generation_colors.dart';
import 'package:gia_pha/features/family_tree/presentation/widgets/layer_image.dart';
import 'package:gia_pha/features/members/domain/entities/family_data.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/members/presentation/widgets/person_avatar.dart';
import 'package:gia_pha/features/members/presentation/widgets/relation_note.dart';

const _navy = Color(0xFF1A237E);

/// Phả đồ dạng tranh treo: khung hồi văn cam, hai rồng chầu, cuốn thư tên dòng họ,
/// nhãn "ĐỜI THỨ N" bên trái và cây gia phả ở giữa.
class PhaDoCanvas extends StatelessWidget {
  const PhaDoCanvas({
    super.key,
    required this.layout,
    required this.data,
    required this.generations,
    required this.rows,
    required this.clanName,
    required this.place,
    required this.onOpenPerson,
    this.layers = const [],
    this.showFrame = true,
    this.showBanner = true,
    this.showWatermark = true,
  });

  final TreeLayoutResult layout;
  final FamilyData data;

  /// Đời (0-based) của từng người.
  final Map<String, int> generations;

  /// Các hàng của toàn gia phả; mỗi hàng là danh sách đời (tính từ 1).
  final List<List<int>> rows;
  final String clanName;
  final String place;
  final void Function(String personId) onOpenPerson;

  /// Hình nền / họa tiết do người dùng thêm (đã sắp theo thứ tự lớp).
  final List<PhaDoLayer> layers;
  final bool showFrame;
  final bool showBanner;
  final bool showWatermark;

  static const double _band = 58;
  static const double _labelW = 130;
  static const double _sideW = 24;
  static const double _footer = 80;
  static const double _minTreeH = 440;
  static const double _minWidth = 1400;

  /// Hình học phần đầu (băng rôn + hai rồng): mọi kích thước tỉ lệ theo chiều rộng phả đồ,
  /// nên phả đồ càng lớn thì băng rôn và rồng càng to.
  static _HeaderGeom _geom(double canvasWidth) =>
      _HeaderGeom(canvasWidth, _band + 10, _band);

  static Size sizeOf(TreeLayoutResult layout) {
    final w0 = layout.width + 2 * (_band + _sideW) + _labelW;
    final w = w0 < _minWidth ? _minWidth : w0;
    final h = 2 * _band +
        _geom(w).height +
        (layout.height < _minTreeH ? _minTreeH : layout.height) +
        _footer;
    return Size(w, h);
  }

  @override
  Widget build(BuildContext context) {
    final size = sizeOf(layout);
    final contentLeft = _band + _sideW + _labelW;
    final innerW = size.width - contentLeft - _sideW - _band;
    final treeX = contentLeft + (innerW - layout.width) / 2;
    final geom = _geom(size.width);
    final treeY = _band + geom.height;
    final cfg = layout.config;
    final trimmed = clanName.trim();
    final title = trimmed.isEmpty ? 'GIA TỘC' : '${trimmed.toUpperCase()} TỘC';

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        children: [
          if (showFrame)
            const Positioned.fill(child: _Frame())
          else
            const Positioned.fill(child: ColoredBox(color: Color(0xFFFFFDE7))),
          // hình nền do người dùng thêm
          for (final l in layers.where((l) => l.kind == PhaDoLayerKind.background))
            Positioned.fill(
              child: Opacity(
                opacity: l.opacity,
                child: LayerImage(path: l.path, fit: BoxFit.cover),
              ),
            ),
          // hình rồng chìm: phủ cả nền trong khung, tự co dãn theo kích thước phả đồ
          if (showWatermark) ..._watermark(geom, size),
          for (final l in layers.where((l) => l.kind == PhaDoLayerKind.decor && !l.front))
            _decor(l, size),
          if (showBanner) ..._buildHeader(geom, size, title),
          // nhãn các đời
          for (final r in layout.rows)
            Positioned(
              left: _band + _sideW + 4,
              top: treeY + r.y + (cfg.cardH - 28) / 2,
              width: _labelW - 12,
              height: 28,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black54),
                ),
                child: Text(
                  r.row < rows.length ? generationRowLabel(rows[r.row]) : '',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          // nét nối
          Positioned(
            left: treeX,
            top: treeY,
            width: layout.width,
            height: layout.height,
            child: CustomPaint(painter: _EdgePainter(layout.childEdges, layout.spouseLinks)),
          ),
          // thẻ thành viên
          for (final u in layout.units)
            for (final (i, p) in [u.node.person, ...u.node.spouses].indexed)
              Positioned(
                left: treeX + u.x + i * (cfg.cardW + cfg.spouseGap),
                top: treeY + u.y,
                width: cfg.cardW,
                height: cfg.cardH,
                child: _PhaCard(
                  person: p,
                  fill: generationFill(generations[p.id] ?? generations[u.node.person.id] ?? 0, p.gender),
                  note: relationNote(data, p, includeParents: false),
                  onTap: () => onOpenPerson(p.id),
                ),
              ),
          for (final l in layers.where((l) => l.kind == PhaDoLayerKind.decor && l.front))
            _decor(l, size),
        ],
      ),
    );
  }

  /// Rồng chìm: một hoặc vài con rồng (xen kẽ quay trái/phải) lấp đầy phần nền bên dưới băng rôn,
  /// bắt đầu từ chỗ băng rôn kết thúc để không bị băng rôn che khuất.
  List<Widget> _watermark(_HeaderGeom g, Size size) {
    const edge = _band + 8.0;
    final top = _band + g.height - g.bannerH * 0.08;
    final areaW = size.width - 2 * edge;
    final areaH = size.height - top - edge;
    if (areaH <= 0) return const [];
    final n = math.max(1, (areaW / (areaH * ArtAssets.phaDoDragonAspect)).round());
    final w = areaW / n;
    return [
      for (var i = 0; i < n; i++)
        Positioned(
          left: edge + i * w,
          top: top,
          width: w,
          height: areaH,
          child: PhaDoDragon(faceRight: i.isEven, opacity: 0.16),
        ),
    ];
  }

  /// Băng rôn ở giữa, hai rồng chầu hai bên (không đè lên nhau, thấy đủ đầu rồng).
  List<Widget> _buildHeader(_HeaderGeom g, Size size, String title) {
    final cx = size.width / 2;
    final dragonTop = g.top + (g.bannerH - g.dragonH) / 2 + g.bannerH * 0.04;
    return [
      Positioned(
        left: cx - g.bannerW / 2 - g.dragonW,
        top: dragonTop,
        width: g.dragonW,
        height: g.dragonH,
        child: const PhaDoDragon(faceRight: true),
      ),
      Positioned(
        left: cx + g.bannerW / 2,
        top: dragonTop,
        width: g.dragonW,
        height: g.dragonH,
        child: const PhaDoDragon(faceRight: false),
      ),
      Positioned(
        left: cx - g.bannerW / 2,
        top: g.top,
        width: g.bannerW,
        height: g.bannerH,
        child: _ImageBanner(title: title, place: place),
      ),
    ];
  }

  /// Khung chữ nhật (chưa xoay) của một lớp họa tiết trên khung phả đồ [canvas].
  static Rect layerRect(PhaDoLayer l, Size canvas) {
    final w = l.w * canvas.width;
    return Rect.fromCenter(
      center: Offset(l.cx * canvas.width, l.cy * canvas.height),
      width: w,
      height: w * l.aspect,
    );
  }

  Widget _decor(PhaDoLayer l, Size canvas) {
    final r = layerRect(l, canvas);
    return Positioned(
      left: r.left,
      top: r.top,
      width: r.width,
      height: r.height,
      child: Opacity(
        opacity: l.opacity,
        child: Transform.rotate(
          angle: l.rotation * math.pi / 180,
          child: LayerImage(path: l.path),
        ),
      ),
    );
  }
}

/// Kích thước phần đầu phả đồ, tỉ lệ theo chiều rộng canvas.
class _HeaderGeom {
  _HeaderGeom(double canvasWidth, double sideInset, double band) {
    final inner = canvasWidth - 2 * sideInset;
    final span = math.min(inner, 3600.0);
    bannerW = span * 0.36;
    bannerH = bannerW / ArtAssets.scrollAspect;
    dragonW = span * 0.32;
    dragonH = dragonW / ArtAssets.phaDoDragonAspect;
    top = band + math.max(14.0, bannerH * 0.06);
    // chiều cao từ mép trên canvas đến chỗ bắt đầu cây (tính cả hai lề khung `band`)
    height = (top - band) + bannerH + math.max(24.0, bannerH * 0.10);
  }

  late final double bannerW, bannerH, dragonW, dragonH, top, height;
}

/// Cuốn thư; chữ "PHẢ ĐỒ" + tên dòng họ + địa danh uốn cong theo vòm băng rôn.
class _ImageBanner extends StatelessWidget {
  const _ImageBanner({required this.title, required this.place});

  final String title;
  final String place;

  static const _shadow = [
    Shadow(color: Color(0xAA000000), blurRadius: 3, offset: Offset(0, 1.5)),
  ];

  @override
  Widget build(BuildContext context) {
    // Dải đỏ của cuốn thư dày ~0.38 chiều cao. Ba dòng cách nhau đủ rộng
    // (kể cả dấu mũ/dấu hỏi của chữ hoa tiếng Việt) để dòng trên không đè dòng dưới.
    final lines = <_CurvedLine>[
      const _CurvedLine(
        text: 'PHẢ ĐỒ',
        size: 0.050,
        dy: -0.132,
        weight: FontWeight.w700,
        color: AppColors.goldLight,
        spacing: 0.22,
      ),
      _CurvedLine(
        text: title,
        size: 0.108,
        dy: 0.004,
        weight: FontWeight.w900,
        color: AppColors.gold,
        spacing: 0.02,
      ),
      if (place.trim().isNotEmpty)
        _CurvedLine(
          text: place.trim().toUpperCase(),
          size: 0.040,
          dy: 0.128,
          weight: FontWeight.w700,
          color: AppColors.goldLight,
          spacing: 0.05,
        ),
    ];
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          ArtAssets.scroll,
          fit: BoxFit.fill,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
        ),
        CustomPaint(painter: _CurvedBannerTextPainter(lines, _shadow)),
      ],
    );
  }
}

/// Một dòng chữ trên băng rôn. Các số đều là tỉ lệ theo chiều cao băng rôn.
class _CurvedLine {
  const _CurvedLine({
    required this.text,
    required this.size,
    required this.dy,
    required this.weight,
    required this.color,
    required this.spacing,
  });

  final String text;

  /// Cỡ chữ tối đa (tỉ lệ chiều cao băng rôn); tự nhỏ lại nếu dòng quá dài.
  final double size;

  /// Lệch dọc so với đường giữa của dải đỏ.
  final double dy;
  final FontWeight weight;
  final Color color;

  /// Khoảng cách chữ (tỉ lệ cỡ chữ).
  final double spacing;
}

/// Vẽ từng chữ cái dọc theo vòm của dải đỏ trên ảnh băng rôn.
/// Đường giữa dải đỏ đo trên ảnh cuốn thư: y/H ≈ 0.398 + 1.72·(x/W − 0.5)².
class _CurvedBannerTextPainter extends CustomPainter {
  _CurvedBannerTextPainter(this.lines, this.shadows);

  final List<_CurvedLine> lines;
  final List<Shadow> shadows;

  static const double _top = 0.398;
  static const double _k = 1.72;

  /// Phần ngang của dải đỏ dùng được (không đè lên hai trục cuộn).
  static const double _x0 = 0.27;
  static const double _x1 = 0.73;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    double yAt(double x) => h * (_top + _k * math.pow(x / w - 0.5, 2));
    double slopeAt(double x) => h * _k * 2 * (x / w - 0.5) / w;

    // Bảng độ dài cung tính từ tâm (x = w/2), để đổi "khoảng cách dọc cung" -> x.
    const n = 400;
    final xs = List<double>.generate(n + 1, (i) => w * i / n);
    final arc = List<double>.filled(n + 1, 0);
    for (var i = 1; i <= n; i++) {
      final dx = xs[i] - xs[i - 1];
      final dy = yAt(xs[i]) - yAt(xs[i - 1]);
      arc[i] = arc[i - 1] + math.sqrt(dx * dx + dy * dy);
    }
    final centerArc = arc[n ~/ 2];
    double xAtArc(double a) {
      final target = centerArc + a;
      var lo = 0;
      var hi = n;
      while (hi - lo > 1) {
        final mid = (lo + hi) ~/ 2;
        if (arc[mid] <= target) {
          lo = mid;
        } else {
          hi = mid;
        }
      }
      final span = arc[hi] - arc[lo];
      final t = span <= 0 ? 0.0 : (target - arc[lo]) / span;
      return xs[lo] + (xs[hi] - xs[lo]) * t;
    }

    final maxArc = (arc[(n * _x1).round()] - arc[(n * _x0).round()]);

    for (final line in lines) {
      if (line.text.trim().isEmpty) continue;
      var fontSize = line.size * h;
      List<TextPainter> build(double fs) => [
            for (final ch in line.text.characters)
              TextPainter(
                text: TextSpan(
                  text: ch,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontWeight: line.weight,
                    fontSize: fs,
                    letterSpacing: fs * line.spacing,
                    color: line.color,
                    shadows: shadows,
                  ),
                ),
                textDirection: TextDirection.ltr,
              )..layout(),
          ];

      var glyphs = build(fontSize);
      var total = glyphs.fold<double>(0, (sum, g) => sum + g.width);
      if (total > maxArc) {
        fontSize *= maxArc / total;
        for (final g in glyphs) {
          g.dispose();
        }
        glyphs = build(fontSize);
        total = glyphs.fold<double>(0, (sum, g) => sum + g.width);
      }

      var pos = -total / 2;
      for (final g in glyphs) {
        final x = xAtArc(pos + g.width / 2);
        final y = yAt(x) + line.dy * h;
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(math.atan(slopeAt(x)));
        g.paint(canvas, Offset(-g.width / 2, -g.height / 2));
        canvas.restore();
        pos += g.width;
        g.dispose();
      }
    }
  }

  @override
  bool shouldRepaint(_CurvedBannerTextPainter old) =>
      old.lines.length != lines.length ||
      [for (final l in old.lines) l.text].join('|') != [for (final l in lines) l.text].join('|');
}

/// Khung bao bản lớn: dải viền rộng nền vàng, họa tiết hồi văn cam (từ Gia_pha_3.cdr) chạy
/// liên tục cả bốn cạnh (cạnh dọc xoay 90°), bốn góc có ô vuông cam; nền giấy vàng nhạt.
class _Frame extends StatelessWidget {
  const _Frame();

  /// Cách mép canvas và độ dày dải viền (đơn vị logic); `inset + thickness` = lề `_band`.
  static const double _inset = 10;
  static const double _thickness = 48;
  static const _orange = Color(0xFFF07C00);
  static const _bandFill = Color(0xFFFFE08A);

  // Ảnh dải viền: 484×249px.
  static const double _tileW = _thickness * 484 / 249;

  /// Một dải viền nằm ngang dài [length], gồm [n] ô hồi văn nối nhau.
  Widget _strip(double length, int n) {
    final w = length / n;
    return SizedBox(
      width: length,
      height: _thickness,
      child: ClipRect(
        child: Stack(
          children: [
            for (var i = 0; i < n; i++)
              Positioned(
                left: i * w,
                top: 0,
                // chồng 1px lên ô kế tiếp để không lộ khe hở khi làm tròn
                width: w + 1,
                height: _thickness,
                child: Image.asset(
                  ArtAssets.frameTile,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Ô vuông ở góc: viền cam, ô trong vàng, chấm cam giữa.
  Widget _cornerStone() {
    return SizedBox(
      width: _thickness,
      height: _thickness,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: _orange),
        child: Padding(
          padding: const EdgeInsets.all(_thickness * 0.16),
          child: DecoratedBox(
            decoration: const BoxDecoration(color: _bandFill),
            child: Padding(
              padding: const EdgeInsets.all(_thickness * 0.17),
              child: const DecoratedBox(decoration: BoxDecoration(color: _orange)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        const t = _thickness;
        final hLen = math.max(0.0, w - 2 * _inset - 2 * t);
        final vLen = math.max(0.0, h - 2 * _inset - 2 * t);
        final hn = math.max(1, (hLen / _tileW).round());
        final vn = math.max(1, (vLen / _tileW).round());
        final outer = Rect.fromLTWH(_inset, _inset, w - 2 * _inset, h - 2 * _inset);
        return Stack(
          children: [
            // nền giấy vàng nhạt
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFF59D), Color(0xFFFFFDE7), Color(0xFFFFF59D)],
                  ),
                ),
              ),
            ),
            // dải viền rộng nền vàng
            Positioned.fromRect(
              rect: outer,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: _bandFill, width: t),
                ),
              ),
            ),
            // trên (đầu cạnh hướng ra ngoài)
            Positioned(left: _inset + t, top: _inset, child: _strip(hLen, hn)),
            // dưới (lật dọc)
            Positioned(
              left: _inset + t,
              bottom: _inset,
              child: Transform.flip(flipY: true, child: _strip(hLen, hn)),
            ),
            // trái (xoay ngược chiều kim đồng hồ để đầu cạnh hướng ra ngoài)
            Positioned(
              left: _inset,
              top: _inset + t,
              width: t,
              height: vLen,
              child: RotatedBox(quarterTurns: 3, child: _strip(vLen, vn)),
            ),
            // phải
            Positioned(
              right: _inset,
              top: _inset + t,
              width: t,
              height: vLen,
              child: RotatedBox(quarterTurns: 1, child: _strip(vLen, vn)),
            ),
            // bốn góc
            Positioned(left: _inset, top: _inset, child: _cornerStone()),
            Positioned(right: _inset, top: _inset, child: _cornerStone()),
            Positioned(left: _inset, bottom: _inset, child: _cornerStone()),
            Positioned(right: _inset, bottom: _inset, child: _cornerStone()),
            // đường viền mảnh ở mép trong và mép ngoài của dải
            Positioned.fromRect(
              rect: outer,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(border: Border.all(color: _orange, width: 2)),
                ),
              ),
            ),
            Positioned.fromRect(
              rect: outer.deflate(t),
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(border: Border.all(color: _orange, width: 2)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EdgePainter extends CustomPainter {
  const _EdgePainter(this.childEdges, this.spouseLinks);

  final List<TreeEdge> childEdges;
  final List<TreeEdge> spouseLinks;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0xFF222222)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    for (final e in childEdges) {
      final midY = (e.fromY + e.toY) / 2;
      canvas.drawPath(
        Path()
          ..moveTo(e.fromX, e.fromY)
          ..lineTo(e.fromX, midY)
          ..lineTo(e.toX, midY)
          ..lineTo(e.toX, e.toY),
        line,
      );
    }
    final coinFill = Paint()..color = AppColors.red;
    final coinRing = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final e in spouseLinks) {
      canvas.drawLine(Offset(e.fromX, e.fromY), Offset(e.toX, e.toY), line);
      final c = Offset((e.fromX + e.toX) / 2, e.fromY);
      canvas.drawCircle(c, 5.2, coinFill);
      canvas.drawCircle(c, 5.2, coinRing);
    }
  }

  @override
  bool shouldRepaint(_EdgePainter old) =>
      old.childEdges != childEdges || old.spouseLinks != spouseLinks;
}

/// Thẻ chữ nhật tô màu theo đời: tên in hoa đậm, ghi chú quan hệ nhỏ bên dưới.
class _PhaCard extends StatelessWidget {
  const _PhaCard({
    required this.person,
    required this.fill,
    required this.note,
    required this.onTap,
  });

  final Person person;
  final Color fill;
  final String? note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final photo = personPhotoFile(person);
    return Material(
      color: fill,
      elevation: 1.5,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(3)),
        side: BorderSide(color: Colors.white, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              if (photo != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ClipOval(
                    child: Image.file(
                      File(photo.path),
                      width: 30,
                      height: 30,
                      fit: BoxFit.cover,
                      cacheWidth: 90,
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Tên dài quá ô thì tự thu nhỏ chữ để vẫn nằm trên một hàng.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        person.fullName.toUpperCase(),
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          height: 1.15,
                          color: _navy,
                        ),
                      ),
                    ),
                    if (note != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          note!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 9.5,
                            height: 1.1,
                            color: Color(0xFF3E2723),
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
