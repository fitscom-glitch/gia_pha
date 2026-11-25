import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:gia_pha/features/members/presentation/export/member_export_rows.dart';

class _Col {
  const _Col(this.title, this.width);

  final String title;
  final double width;
}

/// Danh sách thành viên dạng bảng, mỗi trang A4 ngang. Bảng được vẽ bằng Flutter rồi
/// đặt vào PDF dưới dạng ảnh để hiển thị đúng chữ tiếng Việt bằng phông của máy.
Future<Uint8List> buildMemberListPdf(List<MemberExportRow> rows, {required String title}) async {
  const pageW = 1754.0;
  const pageH = 1240.0;
  const margin = 56.0;
  const pad = 8.0;
  const ink = ui.Color(0xFF3A1810);
  const red = ui.Color(0xFF7F0E14);
  const cols = [
    _Col('STT', 56),
    _Col('Họ và tên', 330),
    _Col('Giới', 84),
    _Col('Đời', 60),
    _Col('Ngày sinh', 140),
    _Col('Ngày mất', 140),
    _Col('Quan hệ', 430),
    _Col('Liên hệ', 398),
  ];

  TextPainter paint(String text, double width, {bool bold = false, ui.Color color = ink, double size = 21}) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          height: 1.25,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: color,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: width - 2 * pad);
  }

  String joinNonEmpty(List<String> parts) => parts.where((s) => s.isNotEmpty).join('\n');

  // Đo trước chiều cao từng dòng.
  final headerCells = [for (final c in cols) paint(c.title, c.width, bold: true, color: red)];
  final headerH = headerCells.map((p) => p.height).reduce(math.max) + 2 * pad;
  final cells = <List<TextPainter>>[];
  final heights = <double>[];
  for (final r in rows) {
    final texts = [
      '${r.index}',
      joinNonEmpty([r.name, r.order]),
      r.gender,
      r.generation,
      r.birth,
      r.death,
      joinNonEmpty([r.spouses, r.parents.isEmpty ? '' : 'Con của: ${r.parents}']),
      joinNonEmpty([r.phone, r.address, r.email]),
    ];
    final ps = [for (var i = 0; i < cols.length; i++) paint(texts[i], cols[i].width, bold: i == 1)];
    cells.add(ps);
    heights.add(ps.map((p) => p.height).reduce(math.max) + 2 * pad);
  }

  // Chia trang.
  const titleBlock = 110.0;
  const bottom = pageH - margin - 40;
  final pages = <List<int>>[];
  var current = <int>[];
  var y = margin + titleBlock + headerH;
  for (var i = 0; i < rows.length; i++) {
    if (y + heights[i] > bottom && current.isNotEmpty) {
      pages.add(current);
      current = [];
      y = margin + headerH;
    }
    current.add(i);
    y += heights[i];
  }
  pages.add(current);

  final stamp = DateFormat('dd/MM/yyyy').format(DateTime.now());
  final pngs = <Uint8List>[];
  for (var pi = 0; pi < pages.length; pi++) {
    final rec = ui.PictureRecorder();
    final canvas = ui.Canvas(rec, const ui.Rect.fromLTWH(0, 0, pageW, pageH));
    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, pageW, pageH),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );
    var top = margin;
    if (pi == 0) {
      paint(title, pageW - 2 * margin, bold: true, color: red, size: 36)
          .paint(canvas, ui.Offset(margin, top));
      paint('Tổng cộng ${rows.length} thành viên · Ngày xuất: $stamp', pageW - 2 * margin, size: 22)
          .paint(canvas, ui.Offset(margin, top + 56));
      top += titleBlock;
    }

    void drawRow(List<TextPainter> ps, double h, {bool header = false}) {
      var x = margin;
      for (var i = 0; i < cols.length; i++) {
        final rect = ui.Rect.fromLTWH(x, top, cols[i].width, h);
        if (header) {
          canvas.drawRect(rect, ui.Paint()..color = const ui.Color(0xFFF6DE94));
        }
        canvas.drawRect(
          rect,
          ui.Paint()
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = const ui.Color(0xFF999999),
        );
        ps[i].paint(canvas, ui.Offset(x + pad, top + pad));
        x += cols[i].width;
      }
      top += h;
    }

    drawRow(headerCells, headerH, header: true);
    for (final i in pages[pi]) {
      drawRow(cells[i], heights[i]);
    }
    paint('Trang ${pi + 1}/${pages.length}', 300, size: 19, color: const ui.Color(0xFF777777))
        .paint(canvas, const ui.Offset(pageW - margin - 120, pageH - margin - 8));

    final image = await rec.endRecording().toImage(pageW.toInt(), pageH.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) throw StateError('Không tạo được trang PDF');
    pngs.add(data.buffer.asUint8List());
  }

  final doc = pw.Document(title: title);
  for (final png in pngs) {
    final image = pw.MemoryImage(png);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Image(image, fit: pw.BoxFit.fill),
      ),
    );
  }
  return doc.save();
}
