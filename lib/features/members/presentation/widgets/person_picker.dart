import 'package:flutter/material.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/members/presentation/widgets/person_avatar.dart';

/// Hộp chọn một thành viên trong gia phả (có ô tìm theo tên). Trả về null nếu bỏ qua.
Future<Person?> showPersonPicker(
  BuildContext context, {
  required String title,
  required List<Person> candidates,
  Map<String, int>? generations,
}) {
  return showModalBottomSheet<Person>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _PickerSheet(
      title: title,
      candidates: candidates,
      generations: generations,
    ),
  );
}

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({
    required this.title,
    required this.candidates,
    required this.generations,
  });

  final String title;
  final List<Person> candidates;
  final Map<String, int>? generations;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final list = [
      for (final p in widget.candidates)
        if (q.isEmpty || p.fullName.toLowerCase().contains(q)) p,
    ];
    final height = MediaQuery.sizeOf(context).height * 0.75;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.redDark,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: false,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Tìm theo tên',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? const Center(child: Text('Không có thành viên phù hợp'))
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final p = list[i];
                        final g = widget.generations?[p.id];
                        final sub = [
                          if (g != null) 'Đời ${g + 1}',
                          if (p.lifespan.isNotEmpty) p.lifespan,
                        ].join(' · ');
                        return ListTile(
                          leading: PersonAvatar(p, radius: 20),
                          title: Text(p.fullName),
                          subtitle: sub.isEmpty ? null : Text(sub),
                          onTap: () => Navigator.of(context).pop(p),
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

/// Như [showPersonPicker] nhưng cho chọn nhiều người một lần (đánh dấu ô vuông, bấm "Xong").
/// Trả về null nếu bỏ qua, danh sách (có thể rỗng) nếu bấm "Xong".
Future<List<Person>?> showPersonMultiPicker(
  BuildContext context, {
  required String title,
  required List<Person> candidates,
  Map<String, int>? generations,
}) {
  return showModalBottomSheet<List<Person>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _MultiPickerSheet(
      title: title,
      candidates: candidates,
      generations: generations,
    ),
  );
}

class _MultiPickerSheet extends StatefulWidget {
  const _MultiPickerSheet({
    required this.title,
    required this.candidates,
    required this.generations,
  });

  final String title;
  final List<Person> candidates;
  final Map<String, int>? generations;

  @override
  State<_MultiPickerSheet> createState() => _MultiPickerSheetState();
}

class _MultiPickerSheetState extends State<_MultiPickerSheet> {
  String _query = '';
  final _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final list = [
      for (final p in widget.candidates)
        if (q.isEmpty || p.fullName.toLowerCase().contains(q)) p,
    ];
    final height = MediaQuery.sizeOf(context).height * 0.8;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: AppColors.redDark,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop([
                      for (final p in widget.candidates)
                        if (_selected.contains(p.id)) p,
                    ]),
                    child: Text(_selected.isEmpty ? 'Xong' : 'Xong (${_selected.length})'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Tìm theo tên',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? const Center(child: Text('Không có thành viên phù hợp'))
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final p = list[i];
                        final g = widget.generations?[p.id];
                        final sub = [
                          if (g != null) 'Đời ${g + 1}',
                          if (p.lifespan.isNotEmpty) p.lifespan,
                        ].join(' · ');
                        final on = _selected.contains(p.id);
                        return CheckboxListTile(
                          value: on,
                          controlAffinity: ListTileControlAffinity.leading,
                          secondary: PersonAvatar(p, radius: 20),
                          title: Text(p.fullName),
                          subtitle: sub.isEmpty ? null : Text(sub),
                          onChanged: (v) => setState(() {
                            if (v ?? false) {
                              _selected.add(p.id);
                            } else {
                              _selected.remove(p.id);
                            }
                          }),
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
