import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Đặt ảnh PNG độ phân giải cao vào một trang PDF có đúng tỉ lệ phả đồ
/// (cạnh dài 1190 pt, tương đương khổ A3).
Future<Uint8List> pngToPdf(Uint8List png, Size logicalSize) async {
  final scale = 1190 / math.max(logicalSize.width, logicalSize.height);
  final format = PdfPageFormat(logicalSize.width * scale, logicalSize.height * scale);
  final doc = pw.Document(title: 'Phả đồ');
  final image = pw.MemoryImage(png);
  doc.addPage(
    pw.Page(
      pageFormat: format,
      margin: pw.EdgeInsets.zero,
      build: (_) => pw.Image(image, fit: pw.BoxFit.fill),
    ),
  );
  return doc.save();
}
