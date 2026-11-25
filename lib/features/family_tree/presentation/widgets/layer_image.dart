import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Hiển thị file ảnh của một lớp: PNG/JPG/WebP hoặc SVG (vector).
class LayerImage extends StatelessWidget {
  const LayerImage({super.key, required this.path, this.fit = BoxFit.contain});

  final String path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    if (!file.existsSync()) return const SizedBox.shrink();
    if (path.toLowerCase().endsWith('.svg')) {
      return SvgPicture.file(file, fit: fit);
    }
    return Image.file(file, fit: fit);
  }
}
