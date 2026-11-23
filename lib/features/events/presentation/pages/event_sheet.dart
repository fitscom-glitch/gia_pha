import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
import 'package:gia_pha/core/utils/lunar_calendar.dart';
import 'package:gia_pha/features/events/domain/entities/custom_event.dart';
import 'package:gia_pha/features/events/presentation/providers/event_providers.dart';

/// Thêm hoặc sửa một ngày kỷ niệm (nhập ngày bất kỳ, dương hoặc âm lịch).
/// [initialDate] là ngày dương lịch gợi ý khi thêm mới.
Future<void> showEventSheet(
  BuildContext context, {
  CustomEvent? event,
  DateTime? initialDate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.paper,
    builder: (_) => _EventSheet(event: event, initialDate: initialDate ?? DateTime.now()),
  );
}

class _EventSheet extends ConsumerStatefulWidget {
  const _EventSheet({this.event, required this.initialDate});

  final CustomEvent? event;
  final DateTime initialDate;

  @override
  ConsumerState<_EventSheet> createState() => _EventSheetState();
}

class _EventSheetState extends ConsumerState<_EventSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _note;
  late final TextEditingController _day;
  late final TextEditingController _month;
  late final TextEditingController _year;
  bool _isLunar = false;
  bool _repeat = true;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    final d = widget.initialDate;
    _title = TextEditingController(text: e?.title ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    _day = TextEditingController(text: '${e?.day ?? d.day}');
    _month = TextEditingController(text: '${e?.month ?? d.month}');
    _year = TextEditingController(text: '${e?.year ?? d.year}');
    _isLunar = e?.isLunar ?? false;
    _repeat = e?.repeatYearly ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _day.dispose();
    _month.dispose();
    _year.dispose();
    super.dispose();
  }

  /// Đổi loại lịch và quy đổi ngày đang nhập sang lịch mới.
  void _setLunar(bool lunar) {
    if (lunar == _isLunar) return;
    final d = int.tryParse(_day.text);
    final m = int.tryParse(_month.text);
    final y = int.tryParse(_year.text);
    if (d != null && m != null && y != null) {
      if (lunar) {
        final s = DateTime(y, m, d);
        if (s.year == y && s.month == m && s.day == d) {
          final l = LunarCalendar.fromSolar(s);
          _day.text = '${l.day}';
          _month.text = '${l.month}';
          _year.text = '${l.year}';
        }
      } else {
        final s = LunarCalendar.toSolar(d, m, y);
        if (s != null) {
          _day.text = '${s.day}';
          _month.text = '${s.month}';
          _year.text = '${s.year}';
        }
      }
    }
    setState(() => _isLunar = lunar);
  }

  String? _validateDate() {
    final d = int.tryParse(_day.text.trim());
    final m = int.tryParse(_month.text.trim());
    final y = int.tryParse(_year.text.trim());
    if (d == null || m == null || y == null) return 'Nhập đủ ngày, tháng, năm';
    if (y < 1900 || y > 2200) return 'Năm từ 1900 đến 2200';
    if (m < 1 || m > 12) return 'Tháng từ 1 đến 12';
    if (_isLunar) {
      if (d < 1 || d > 30) return 'Ngày âm lịch từ 1 đến 30';
    } else {
      final s = DateTime(y, m, d);
      if (d < 1 || s.month != m || s.day != d) return 'Ngày dương lịch không tồn tại';
    }
    return null;
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final dateError = _validateDate();
    if (title.isEmpty || dateError != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(title.isEmpty ? 'Nhập tên ngày kỷ niệm' : dateError!)));
      return;
    }
    final note = _note.text.trim();
    await ref.read(eventsProvider.notifier).save(
          CustomEvent(
            id: widget.event?.id ?? const Uuid().v4(),
            title: title,
            note: note.isEmpty ? null : note,
            day: int.parse(_day.text.trim()),
            month: int.parse(_month.text.trim()),
            year: int.parse(_year.text.trim()),
            isLunar: _isLunar,
            repeatYearly: _repeat,
            createdAt: widget.event?.createdAt ?? DateTime.now(),
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa ngày kỷ niệm?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(eventsProvider.notifier).remove(widget.event!.id);
    if (mounted) Navigator.pop(context);
  }

  Widget _num(TextEditingController c, String label) => Expanded(
        child: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.event == null ? 'Thêm ngày kỷ niệm' : 'Sửa ngày kỷ niệm',
              style: const TextStyle(
                fontFamily: 'serif',
                fontWeight: FontWeight.w700,
                fontSize: 19,
                color: AppColors.redDark,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Tên ngày kỷ niệm *',
                hintText: 'Vd: Ngày cưới, Ngày khai hoang...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Dương lịch'), icon: Icon(Icons.wb_sunny)),
                ButtonSegment(value: true, label: Text('Âm lịch'), icon: Icon(Icons.nightlight_round)),
              ],
              selected: {_isLunar},
              onSelectionChanged: (s) => _setLunar(s.first),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _num(_day, 'Ngày'),
                const SizedBox(width: 8),
                _num(_month, 'Tháng'),
                const SizedBox(width: 8),
                _num(_year, 'Năm'),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Lặp lại hằng năm'),
              subtitle: Text(
                _isLunar
                    ? 'Theo ngày/tháng âm lịch (tháng thường, không nhuận)'
                    : 'Theo ngày/tháng dương lịch',
                style: const TextStyle(fontSize: 12),
              ),
              value: _repeat,
              onChanged: (v) => setState(() => _repeat = v),
            ),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (widget.event != null)
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
    );
  }
}
