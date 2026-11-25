import 'package:flutter/material.dart';
import 'package:gia_pha/features/family_tree/domain/services/generation_rows.dart';

/// Chỉnh các nhóm đời gộp chung một hàng; mỗi nhóm có thể chọn một đời đại diện
/// (chỉ đời đó được hiển thị trên hàng). Trả về chuỗi cấu hình hoặc null nếu hủy.
Future<String?> showGenerationGroupsDialog(
  BuildContext context, {
  required String initial,
  required int maxGeneration,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _GroupsDialog(initial: initial, maxGeneration: maxGeneration),
  );
}

class _GroupRow {
  _GroupRow(int from, int to, this.rep)
      : from = TextEditingController(text: '$from'),
        to = TextEditingController(text: '$to');

  final TextEditingController from;
  final TextEditingController to;
  int? rep;
}

class _GroupsDialog extends StatefulWidget {
  const _GroupsDialog({required this.initial, required this.maxGeneration});

  final String initial;
  final int maxGeneration;

  @override
  State<_GroupsDialog> createState() => _GroupsDialogState();
}

class _GroupsDialogState extends State<_GroupsDialog> {
  late final List<_GroupRow> _rows;

  @override
  void initState() {
    super.initState();
    _rows = [
      for (final g in parseGenerationGroups(widget.initial))
        _GroupRow(g.from, g.to, g.representative),
    ];
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.from.dispose();
      r.to.dispose();
    }
    super.dispose();
  }

  int? _int(TextEditingController c) => int.tryParse(c.text.trim());

  String _result() {
    final groups = <GenerationGroup>[];
    for (final r in _rows) {
      final a = _int(r.from);
      final b = _int(r.to);
      if (a == null || b == null || a < 1 || b <= a) continue;
      final rep = (r.rep != null && r.rep! >= a && r.rep! <= b) ? r.rep : null;
      groups.add(GenerationGroup(a, b, rep));
    }
    return formatGenerationGroups(groups);
  }

  Widget _rowWidget(int index) {
    final r = _rows[index];
    final a = _int(r.from);
    final b = _int(r.to);
    final lo = a ?? 0;
    final hi = b ?? 0;
    final valid = lo >= 1 && hi > lo && hi - lo < 60;
    final rep = (valid && r.rep != null && r.rep! >= lo && r.rep! <= hi) ? r.rep : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: r.from,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Từ đời', isDense: true),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('đến')),
              Expanded(
                child: TextField(
                  controller: r.to,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'đời', isDense: true),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Xóa nhóm',
                onPressed: () => setState(() => _rows.removeAt(index)),
              ),
            ],
          ),
          if (valid)
            Row(
              children: [
                const Text('Hiển thị: '),
                Expanded(
                  child: DropdownButton<int?>(
                    isExpanded: true,
                    value: rep,
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Tất cả các đời trong nhóm')),
                      for (var g = lo; g <= hi; g++)
                        DropdownMenuItem<int?>(value: g, child: Text('Chỉ đời $g')),
                    ],
                    onChanged: (v) => setState(() => r.rep = v),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gộp đời vào một hàng'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gia phả hiện có ${widget.maxGeneration} đời. Các đời trong một nhóm nằm chung một hàng; '
                'chọn "Chỉ đời N" để hàng đó chỉ hiển thị đời N, các đời còn lại trong nhóm được ẩn.',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _rows.length; i++) _rowWidget(i),
              TextButton.icon(
                onPressed: () => setState(() => _rows.add(_GroupRow(2, 3, null))),
                icon: const Icon(Icons.add),
                label: const Text('Thêm nhóm'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(onPressed: () => Navigator.pop(context, _result()), child: const Text('Lưu')),
      ],
    );
  }
}
