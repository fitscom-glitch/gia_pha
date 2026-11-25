import 'dart:io';
import 'dart:ui' as ui;

/// Tỉ lệ cao/rộng của một file ảnh (PNG, JPG, WebP, SVG). Mặc định 1.0 nếu không đọc được.
Future<double> imageAspect(String path) async {
  try {
    if (path.toLowerCase().endsWith('.svg')) {
      final text = await File(path).readAsString();
      final vb = RegExp(r'viewBox\s*=\s*"([^"]+)"').firstMatch(text);
      if (vb != null) {
        final n = vb.group(1)!.trim().split(RegExp(r'[\s,]+')).map(double.tryParse).toList();
        if (n.length == 4 && n[2] != null && n[3] != null && n[2]! > 0) return n[3]! / n[2]!;
      }
      final w = RegExp(r'\swidth\s*=\s*"([\d.]+)').firstMatch(text);
      final h = RegExp(r'\sheight\s*=\s*"([\d.]+)').firstMatch(text);
      final wv = w == null ? null : double.tryParse(w.group(1)!);
      final hv = h == null ? null : double.tryParse(h.group(1)!);
      if (wv != null && hv != null && wv > 0) return hv / wv;
      return 1.0;
    }
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final aspect = frame.image.height / frame.image.width;
    frame.image.dispose();
    codec.dispose();
    return aspect;
  } catch (_) {
    return 1.0;
  }
}
