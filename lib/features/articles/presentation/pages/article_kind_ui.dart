import 'package:flutter/material.dart';
import 'package:gia_pha/features/articles/domain/entities/article.dart';

extension ArticleKindUi on ArticleKind {
  String get title => switch (this) {
        ArticleKind.history => 'Lịch sử dòng họ',
        ArticleKind.rules => 'Tộc ước & Hương lễ',
        ArticleKind.stories => 'Chuyện cổ kim',
      };

  IconData get icon => switch (this) {
        ArticleKind.history => Icons.menu_book,
        ArticleKind.rules => Icons.spa,
        ArticleKind.stories => Icons.auto_stories,
      };

  String get emptyText => switch (this) {
        ArticleKind.history => 'Chưa có bài nào.\nHãy ghi lại nguồn gốc, các đời tổ tiên, nơi phát tích...',
        ArticleKind.rules => 'Chưa có bài nào.\nHãy ghi các điều tộc ước, quy định thờ cúng, lịch lễ trong năm...',
        ArticleKind.stories => 'Chưa có bài nào.\nHãy ghi lại những câu chuyện, giai thoại của dòng họ...',
      };

  String get bodyHint => switch (this) {
        ArticleKind.history => 'Nội dung: nguồn gốc dòng họ, các đời, công trạng...',
        ArticleKind.rules => 'Nội dung: điều lệ, quy định, nghi thức cúng lễ...',
        ArticleKind.stories => 'Nội dung câu chuyện...',
      };
}
