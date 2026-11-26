import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
import 'package:gia_pha/core/widgets/art_assets.dart';
import 'package:gia_pha/core/widgets/gold_app_bar.dart';
import 'package:gia_pha/core/widgets/ornaments/ornaments.dart';
import 'package:gia_pha/features/heirlooms/domain/entities/heirloom.dart';
import 'package:gia_pha/features/heirlooms/presentation/providers/heirloom_providers.dart';

/// Kho ảnh Di sản & Kỷ vật; cũng là nội dung tab "Tư liệu".
class HeirloomsPage extends ConsumerWidget {
  const HeirloomsPage({super.key, this.title = 'Di sản & Kỷ vật'});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(heirloomsProvider);
    return Scaffold(
      appBar: GoldAppBar(title: title),
      body: PatternBackground(
        child: items.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Lỗi: $e')),
          data: (list) {
            if (list.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.museum, size: 56, color: AppColors.gold),
                      SizedBox(height: 12),
                      Text(
                        'Chưa có tư liệu nào.\nHãy chụp lại gia bảo, sắc phong, ảnh cũ, đồ thờ tự...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
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
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 92),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.85,
              ),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final h = list[i];
                return OrnateCard(
                  padding: EdgeInsets.zero,
                  onTap: () => _showView(context, h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: HeirloomImage(path: h.imagePath)),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          h.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.ink,
                          ),
                        ),
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
        onPressed: () => showHeirloomForm(context),
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Thêm'),
      ),
    );
  }

  void _showView(BuildContext context, Heirloom h) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.paper,
      builder: (_) => _HeirloomView(item: h),
    );
  }
}

/// Ảnh vuông bo góc; nếu không có ảnh thì hiện hình rồng mờ.
class HeirloomImage extends StatelessWidget {
  const HeirloomImage({super.key, required this.path, this.fit = BoxFit.cover});

  final String? path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final p = path;
    if (p != null && File(p).existsSync()) {
      return Image.file(File(p), fit: fit, width: double.infinity, cacheWidth: 800);
    }
    return Container(
      color: AppColors.paperDark,
      padding: const EdgeInsets.all(16),
      child: const DragonArt(color: Color(0xFF9C7A12), opacity: 0.8),
    );
  }
}

class _HeirloomView extends ConsumerWidget {
  const _HeirloomView({required this.item});

  final Heirloom item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(aspectRatio: 4 / 3, child: HeirloomImage(path: item.imagePath)),
          ),
          const SizedBox(height: 12),
          Text(
            item.name,
            style: const TextStyle(
              fontFamily: 'serif',
              fontWeight: FontWeight.w700,
              fontSize: 21,
              color: AppColors.redDark,
            ),
          ),
          if (item.keeper != null && item.keeper!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Người lưu giữ: ${item.keeper}',
                style: const TextStyle(color: AppColors.goldDark),
              ),
            ),
          if (item.description != null && item.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                item.description!,
                style: const TextStyle(fontSize: 15.5, height: 1.5, color: AppColors.ink),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton.icon(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Xóa tư liệu?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Hủy'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Xóa'),
                        ),
                      ],
                    ),
                  );
                  if (ok != true) return;
                  await ref.read(heirloomsProvider.notifier).remove(item);
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Xóa'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showHeirloomForm(context, item: item);
                },
                icon: const Icon(Icons.edit),
                label: const Text('Sửa'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Thêm mới hoặc sửa một tư liệu.
Future<void> showHeirloomForm(BuildContext context, {Heirloom? item}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.paper,
    builder: (_) => _HeirloomForm(item: item),
  );
}

class _HeirloomForm extends ConsumerStatefulWidget {
  const _HeirloomForm({this.item});

  final Heirloom? item;

  @override
  ConsumerState<_HeirloomForm> createState() => _HeirloomFormState();
}

class _HeirloomFormState extends ConsumerState<_HeirloomForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _keeper;
  late final TextEditingController _desc;
  String? _pickedPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final h = widget.item;
    _name = TextEditingController(text: h?.name ?? '');
    _keeper = TextEditingController(text: h?.keeper ?? '');
    _desc = TextEditingController(text: h?.description ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _keeper.dispose();
    _desc.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();

  Future<void> _pick() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 82,
    );
    if (x != null) setState(() => _pickedPath = x.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final old = widget.item;
    await ref.read(heirloomsProvider.notifier).save(
          Heirloom(
            id: old?.id ?? const Uuid().v4(),
            name: _name.text.trim(),
            createdAt: old?.createdAt ?? DateTime.now(),
            description: _nullIfEmpty(_desc.text),
            keeper: _nullIfEmpty(_keeper.text),
            imagePath: old?.imagePath,
          ),
          newImageSourcePath: _pickedPath,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final preview = _pickedPath ?? widget.item?.imagePath;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.item == null ? 'Thêm tư liệu' : 'Sửa tư liệu',
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w700,
                  fontSize: 19,
                  color: AppColors.redDark,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pick,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        HeirloomImage(path: preview),
                        const Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircleAvatar(
                              backgroundColor: AppColors.red,
                              child: Icon(Icons.photo_library, color: AppColors.goldLight),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Tên tư liệu / kỷ vật *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tên' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _keeper,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Người lưu giữ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Mô tả, nguồn gốc',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: const Text('Lưu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
