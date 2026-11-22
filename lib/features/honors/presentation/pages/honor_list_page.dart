import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
import 'package:gia_pha/core/widgets/gold_app_bar.dart';
import 'package:gia_pha/core/widgets/ornaments/ornaments.dart';
import 'package:gia_pha/features/honors/domain/entities/honor.dart';
import 'package:gia_pha/features/honors/presentation/providers/honor_providers.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/members/presentation/providers/family_providers.dart';

class HonorListPage extends ConsumerWidget {
  const HonorListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(honorsProvider);
    return Scaffold(
      appBar: const GoldAppBar(title: 'Bảng vinh danh'),
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
                      Icon(Icons.emoji_events, size: 56, color: AppColors.gold),
                      SizedBox(height: 12),
                      Text(
                        'Chưa có ai được vinh danh.\nHãy ghi nhận con cháu học giỏi, thành đạt, có công với dòng họ...',
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
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 92),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final h = list[i];
                return OrnateCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  onTap: () => showHonorSheet(context, honor: h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.goldLight,
                          border: Border.all(color: AppColors.gold, width: 2),
                        ),
                        child: const Icon(Icons.emoji_events, color: AppColors.red),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h.honoree,
                              style: const TextStyle(
                                fontFamily: 'serif',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              h.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.red,
                              ),
                            ),
                            if (h.description != null && h.description!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  h.description!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.35,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (h.year != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.gold),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${h.year}',
                            style: const TextStyle(fontSize: 12.5, color: AppColors.goldDark),
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
        onPressed: () => showHonorSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Vinh danh'),
      ),
    );
  }
}

/// Thêm mới hoặc sửa một mục vinh danh.
Future<void> showHonorSheet(BuildContext context, {Honor? honor}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.paper,
    builder: (_) => _HonorSheet(honor: honor),
  );
}

class _HonorSheet extends ConsumerStatefulWidget {
  const _HonorSheet({this.honor});

  final Honor? honor;

  @override
  ConsumerState<_HonorSheet> createState() => _HonorSheetState();
}

class _HonorSheetState extends ConsumerState<_HonorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _honoree;
  late final TextEditingController _title;
  late final TextEditingController _year;
  late final TextEditingController _desc;
  String? _personId;

  @override
  void initState() {
    super.initState();
    final h = widget.honor;
    _honoree = TextEditingController(text: h?.honoree ?? '');
    _title = TextEditingController(text: h?.title ?? '');
    _year = TextEditingController(text: h?.year?.toString() ?? '');
    _desc = TextEditingController(text: h?.description ?? '');
    _personId = h?.personId;
  }

  @override
  void dispose() {
    _honoree.dispose();
    _title.dispose();
    _year.dispose();
    _desc.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(honorsProvider.notifier).save(
          Honor(
            id: widget.honor?.id ?? const Uuid().v4(),
            personId: _personId,
            honoree: _honoree.text.trim(),
            title: _title.text.trim(),
            year: int.tryParse(_year.text.trim()),
            description: _nullIfEmpty(_desc.text),
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa mục vinh danh?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(honorsProvider.notifier).remove(widget.honor!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final persons = ref.watch(familyProvider).valueOrNull?.persons ?? const <Person>[];
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
                widget.honor == null ? 'Thêm vinh danh' : 'Sửa vinh danh',
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w700,
                  fontSize: 19,
                  color: AppColors.redDark,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _honoree,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Người được vinh danh *',
                  border: const OutlineInputBorder(),
                  suffixIcon: persons.isEmpty
                      ? null
                      : PopupMenuButton<Person>(
                          icon: const Icon(Icons.person_search),
                          tooltip: 'Chọn từ gia phả',
                          onSelected: (p) => setState(() {
                            _honoree.text = p.fullName;
                            _personId = p.id;
                          }),
                          itemBuilder: (_) => [
                            for (final p in persons)
                              PopupMenuItem(value: p, child: Text(p.fullName)),
                          ],
                        ),
                ),
                onChanged: (_) => _personId = null,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tên' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Danh hiệu / thành tích *',
                  hintText: 'Vd: Thủ khoa đại học, Bác sĩ ưu tú...',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập danh hiệu' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _year,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Năm',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (widget.honor != null)
                    TextButton.icon(
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Xóa'),
                    ),
                  const Spacer(),
                  FilledButton(onPressed: _save, child: const Text('Lưu')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
