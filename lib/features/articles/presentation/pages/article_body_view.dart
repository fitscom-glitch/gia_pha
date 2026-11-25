import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
import 'package:gia_pha/features/articles/domain/entities/article_content.dart';
import 'package:gia_pha/features/articles/presentation/providers/article_providers.dart';

/// Nội dung bài viết: văn bản xen kẽ ảnh. Chạm vào ảnh để xem lớn và phóng to.
class ArticleBodyView extends ConsumerWidget {
  const ArticleBodyView({super.key, required this.body});

  final String body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dir = ref.watch(articleImageDirProvider).valueOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final b in parseArticleBody(body))
          if (b.image != null)
            _image(context, dir, b.image!)
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SelectableText(
                b.text!,
                style: const TextStyle(fontSize: 16.5, height: 1.65, color: AppColors.ink),
              ),
            ),
      ],
    );
  }

  Widget _image(BuildContext context, String? dir, String name) {
    final file = dir == null ? null : File('$dir/$name');
    if (file == null || !file.existsSync()) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(Icons.broken_image_outlined, color: AppColors.goldDark),
            SizedBox(width: 8),
            Text('Không tìm thấy ảnh', style: TextStyle(color: AppColors.goldDark)),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => Dialog(
            insetPadding: const EdgeInsets.all(8),
            child: InteractiveViewer(child: Image.file(file)),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(file, width: double.infinity, fit: BoxFit.fitWidth),
        ),
      ),
    );
  }
}
