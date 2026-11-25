import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
import 'package:gia_pha/core/widgets/gold_app_bar.dart';
import 'package:gia_pha/core/widgets/ornaments/ornaments.dart';
import 'package:gia_pha/features/articles/domain/entities/article.dart';
import 'package:gia_pha/features/articles/domain/entities/article_content.dart';
import 'package:gia_pha/features/articles/presentation/pages/article_kind_ui.dart';
import 'package:gia_pha/features/articles/presentation/providers/article_providers.dart';

class ArticleListPage extends ConsumerWidget {
  const ArticleListPage({super.key, required this.kind});

  final ArticleKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(articlesProvider(kind));
    final fmt = DateFormat('dd/MM/yyyy');
    return Scaffold(
      appBar: GoldAppBar(title: kind.title),
      body: PatternBackground(
        child: items.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Lỗi: $e')),
          data: (list) {
            if (list.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(kind.icon, size: 56, color: AppColors.gold),
                      const SizedBox(height: 12),
                      Text(
                        kind.emptyText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 16,
                          height: 1.4,
                          color: AppColors.redDark,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 92),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final a = list[i];
                return OrnateCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  onTap: () => context.push('/articles/${kind.name}/${a.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.title,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: AppColors.redDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stripArticleImageTokens(a.body).replaceAll(RegExp(r'\s+'), ' ').trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.ink, height: 1.35),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        fmt.format(a.updatedAt),
                        style: const TextStyle(fontSize: 12, color: AppColors.goldDark),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/articles/${kind.name}/new'),
        icon: const Icon(Icons.edit),
        label: const Text('Viết bài'),
      ),
    );
  }
}
