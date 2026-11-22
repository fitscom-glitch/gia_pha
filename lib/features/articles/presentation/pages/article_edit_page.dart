import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:gia_pha/core/widgets/gold_app_bar.dart';
import 'package:gia_pha/core/widgets/ornaments/ornaments.dart';
import 'package:gia_pha/features/articles/domain/entities/article.dart';
import 'package:gia_pha/features/articles/presentation/pages/article_kind_ui.dart';
import 'package:gia_pha/features/articles/presentation/providers/article_providers.dart';

class ArticleEditPage extends ConsumerStatefulWidget {
  const ArticleEditPage({super.key, required this.kind, this.id});

  final ArticleKind kind;

  /// null = viết bài mới.
  final String? id;

  @override
  ConsumerState<ArticleEditPage> createState() => _ArticleEditPageState();
}

class _ArticleEditPageState extends ConsumerState<ArticleEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _body;
  Article? _existing;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      final list = ref.read(articlesProvider(widget.kind)).valueOrNull ?? const <Article>[];
      for (final a in list) {
        if (a.id == widget.id) _existing = a;
      }
    }
    _title = TextEditingController(text: _existing?.title ?? '');
    _body = TextEditingController(text: _existing?.body ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    await ref.read(articlesProvider(widget.kind).notifier).save(
          Article(
            id: _existing?.id ?? const Uuid().v4(),
            kind: widget.kind,
            title: _title.text.trim(),
            body: _body.text.trim(),
            createdAt: _existing?.createdAt ?? now,
            updatedAt: now,
          ),
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GoldAppBar(title: _existing == null ? 'Viết bài mới' : 'Sửa bài viết'),
      body: PatternBackground(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tiêu đề' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _body,
                minLines: 12,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: widget.kind.bodyHint,
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập nội dung' : null,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: const Text('Lưu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
