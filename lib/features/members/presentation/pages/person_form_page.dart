import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:gia_pha/core/widgets/gold_app_bar.dart';

import 'package:gia_pha/features/members/presentation/providers/family_providers.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/members/domain/entities/relationship.dart';

class PersonFormPage extends ConsumerStatefulWidget {
  const PersonFormPage({super.key, this.personId, this.anchorId, this.addAs});

  /// Có giá trị => đang sửa người này.
  final String? personId;

  /// Người đã có, dùng khi thêm cha/mẹ/con/vợ-chồng cho người đó.
  final String? anchorId;
  final AddAs? addAs;

  @override
  ConsumerState<PersonFormPage> createState() => _PersonFormPageState();
}

class _PersonFormPageState extends ConsumerState<PersonFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _place;
  late final TextEditingController _job;
  late final TextEditingController _bio;
  late Gender _gender;
  DateTime? _birth;
  DateTime? _death;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.personId == null
        ? null
        : ref.read(familyProvider).valueOrNull?.byId(widget.personId!);
    _name = TextEditingController(text: existing?.fullName ?? '');
    _place = TextEditingController(text: existing?.birthPlace ?? '');
    _job = TextEditingController(text: existing?.occupation ?? '');
    _bio = TextEditingController(text: existing?.bio ?? '');
    _gender = existing?.gender ?? Gender.male;
    _birth = existing?.birthDate;
    _death = existing?.deathDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _place.dispose();
    _job.dispose();
    _bio.dispose();
    super.dispose();
  }

  String get _title {
    if (widget.personId != null) return 'Sửa thành viên';
    return switch (widget.addAs) {
      AddAs.parent => 'Thêm cha/mẹ',
      AddAs.child => 'Thêm con',
      AddAs.spouse => 'Thêm vợ/chồng',
      null => 'Thêm thành viên',
    };
  }

  String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final person = Person(
      id: widget.personId ?? const Uuid().v4(),
      fullName: _name.text.trim(),
      gender: _gender,
      birthDate: _birth,
      deathDate: _death,
      birthPlace: _nullIfEmpty(_place.text),
      occupation: _nullIfEmpty(_job.text),
      bio: _nullIfEmpty(_bio.text),
    );
    await ref.read(familyProvider.notifier).saveMember(
          person,
          anchorId: widget.anchorId,
          addAs: widget.addAs,
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GoldAppBar(title: _title),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Họ và tên *', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nhập họ tên' : null,
            ),
            const SizedBox(height: 16),
            SegmentedButton<Gender>(
              segments: const [
                ButtonSegment(value: Gender.male, label: Text('Nam')),
                ButtonSegment(value: Gender.female, label: Text('Nữ')),
                ButtonSegment(value: Gender.other, label: Text('Khác')),
              ],
              selected: {_gender},
              onSelectionChanged: (s) => setState(() => _gender = s.first),
            ),
            const SizedBox(height: 16),
            _DateField(
                label: 'Ngày sinh',
                value: _birth,
                onChanged: (v) => setState(() => _birth = v)),
            const SizedBox(height: 16),
            _DateField(
                label: 'Ngày mất (nếu có)',
                value: _death,
                onChanged: (v) => setState(() => _death = v)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _place,
              decoration: const InputDecoration(
                  labelText: 'Nơi sinh', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _job,
              decoration: const InputDecoration(
                  labelText: 'Nghề nghiệp', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bio,
              maxLines: 4,
              decoration: const InputDecoration(
                  labelText: 'Tiểu sử', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField(
      {required this.label, required this.value, required this.onChanged});

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime(1970),
          firstDate: DateTime(1000),
          lastDate: DateTime.now(),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: value == null
              ? const Icon(Icons.calendar_today)
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => onChanged(null)),
        ),
        child: Text(value == null ? '' : DateFormat('dd/MM/yyyy').format(value!)),
      ),
    );
  }
}
