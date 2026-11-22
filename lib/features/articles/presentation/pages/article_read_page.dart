import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
import 'package:gia_pha/core/widgets/gold_app_bar.dart';
import 'package:gia_pha/core/widgets/ornaments/ornaments.dart';
import 'package:gia_pha/features/articles/domain/entities/article.dart';
import 'package:gia_pha/features/articles/presentation/pages/article_kind_ui.dart';
import 'package:gia_pha/features/articles/presentation/providers/article_providers.dart';

class ArticleReadPage extends ConsumerWidget {
  const ArticleReadPage({super.key, required this.kind, required this.id});

  final ArticleKind kind;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Article? article;
    for (final a in ref.watch(articlesProvider(kind)).valueOrNull ?? const <Article>[]) {
      if (a.id == id) article = a;
    }
    if (article == null) {
      return Scaffold(
        appBar: GoldAppBar(title: kind.title),
        body: const PatternBackground(child: Center(child: Text('Không tìm thấy bài viết'))),
      );
    }
    final a = article;
    return Scaffold(
      appBar: GoldAppBar(
        title: kind.title,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Sửa',
            onPressed: () => context.push('/articles/${kind.name}/$id/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Xóa',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: PatternBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
          children: [
            Text(
              a.title,
              style: const TextStyle(
                fontFamily: 'serif',
                fontWeight: FontWeight.w700,
                fontSize: 24,
                height: 1.25,
                color: AppColors.redDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Cập nhật ${DateFormat('dd/MM/yyyy').format(a.updatedAt)}',
              style: const TextStyle(fontSize: 12.5, color: AppColors.goldDark),
            ),
            const SizedBox(height: 10),
            const MeanderStrip(height: 10),
            const SizedBox(height: 16),
            SelectableText(
              a.body,
              style: const TextStyle(fontSize: 16.5, height: 1.65, color: AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa bài viết?'),
        content: const Text('Bài viết sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(articlesProvider(kind).notifier).remove(id);
    if (context.mounted) context.pop();
  }
}
