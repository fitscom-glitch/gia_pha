import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
import 'package:gia_pha/core/widgets/gold_app_bar.dart';
import 'package:gia_pha/core/widgets/ornaments/ornaments.dart';
import 'package:gia_pha/features/members/domain/entities/family_data.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/members/presentation/providers/family_providers.dart';
import 'package:gia_pha/features/members/presentation/widgets/person_avatar.dart';

/// Kéo thả để đặt thứ tự anh em của các con (người đầu = con trưởng).
class SiblingOrderPage extends ConsumerStatefulWidget {
  const SiblingOrderPage({super.key, required this.parentId});

  final String parentId;

  @override
  ConsumerState<SiblingOrderPage> createState() => _SiblingOrderPageState();
}

class _SiblingOrderPageState extends ConsumerState<SiblingOrderPage> {
  late List<Person> _items;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final data = ref.read(familyProvider).valueOrNull;
    _items = data == null ? <Person>[] : data.childrenOfUnit(widget.parentId);
  }

  void _sortByBirthDate() {
    setState(() => _items = [..._items]..sort(compareByBirth));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref
        .read(familyProvider.notifier)
        .reorderSiblings([for (final p in _items) p.id]);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GoldAppBar(
        title: 'Thứ tự anh em',
        actions: [
          IconButton(
            icon: const Icon(Icons.cake),
            tooltip: 'Xếp theo ngày sinh',
            onPressed: _sortByBirthDate,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Lưu',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: PatternBackground(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'Kéo thả để sắp xếp. Người trên cùng là con trưởng. '
                'Bấm biểu tượng bánh sinh nhật để xếp theo ngày sinh, rồi bấm ✓ để lưu.',
                style: TextStyle(color: AppColors.goldDark, fontSize: 13),
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                buildDefaultDragHandles: false,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                itemCount: _items.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _items.removeAt(oldIndex);
                    _items.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, i) {
                  final p = _items[i];
                  return Padding(
                    key: ValueKey(p.id),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: OrnateCard(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          PersonAvatar(p, radius: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.fullName,
                                  style: const TextStyle(
                                    fontFamily: 'serif',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Text(
                                  [
                                    birthOrderLabel(i + 1),
                                    if (p.lifespan.isNotEmpty) p.lifespan,
                                  ].join(' · '),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.redDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ReorderableDragStartListener(
                            index: i,
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.drag_handle, color: AppColors.goldDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
