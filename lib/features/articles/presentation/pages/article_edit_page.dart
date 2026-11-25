import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
import 'package:gia_pha/core/widgets/gold_app_bar.dart';
import 'package:gia_pha/core/widgets/ornaments/ornaments.dart';
import 'package:gia_pha/features/articles/domain/entities/article.dart';
import 'package:gia_pha/features/articles/domain/entities/article_content.dart';
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

  /// Chọn một hoặc nhiều ảnh và chèn vào vị trí con trỏ trong bài.
  Future<void> _insertImages() async {
    final files = await ImagePicker().pickMultiImage(maxWidth: 1600, imageQuality: 82);
    if (files.isEmpty) return;
    final store = ref.read(articleImageStoreProvider);
    final inserted = StringBuffer();
    for (final x in files) {
      final stored = await store.saveCopy(x.path, const Uuid().v4());
      inserted.write('\n${articleImageToken(p.basename(stored))}\n');
    }
    final text = _body.text;
    final sel = _body.selection;
    final pos = (sel.isValid && sel.start >= 0 && sel.start <= text.length) ? sel.start : text.length;
    _body.value = TextEditingValue(
      text: text.replaceRange(pos, pos, inserted.toString()),
      selection: TextSelection.collapsed(offset: pos + inserted.length),
    );
    if (mounted) setState(() {});
  }

  void _removeImage(String name) {
    _body.text = _body.text.replaceAll(articleImageToken(name), '');
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final body = _body.text.trim();
    await ref.read(articlesProvider(widget.kind).notifier).save(
          Article(
            id: _existing?.id ?? const Uuid().v4(),
            kind: widget.kind,
            title: _title.text.trim(),
            body: body,
            createdAt: _existing?.createdAt ?? now,
            updatedAt: now,
          ),
        );
    // Xóa file ảnh không còn được dùng trong bài.
    final store = ref.read(articleImageStoreProvider);
    final removed = articleImageNames(_existing?.body ?? '').difference(articleImageNames(body));
    for (final name in removed) {
      await store.deleteNamed(name);
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final dir = ref.watch(articleImageDirProvider).valueOrNull;
    final images = articleImageNames(_body.text).toList();
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
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _insertImages,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Chèn ảnh'),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Ảnh được chèn tại vị trí con trỏ trong bài.',
                      style: TextStyle(fontSize: 12, color: AppColors.goldDark),
                    ),
                  ),
                ],
              ),
              if (images.isNotEmpty && dir != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 84,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final name in images)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 84,
                                  height: 84,
                                  child: File('$dir/$name').existsSync()
                                      ? Image.file(File('$dir/$name'), fit: BoxFit.cover, cacheWidth: 250)
                                      : const ColoredBox(
                                          color: AppColors.paperDark,
                                          child: Icon(Icons.broken_image_outlined),
                                        ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () => _removeImage(name),
                                  child: const CircleAvatar(
                                    radius: 11,
                                    backgroundColor: AppColors.red,
                                    child: Icon(Icons.close, size: 14, color: AppColors.goldLight),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _body,
                minLines: 12,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
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
