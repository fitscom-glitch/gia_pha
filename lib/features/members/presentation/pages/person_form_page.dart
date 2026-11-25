import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
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
  late final TextEditingController _order;
  late Gender _gender;
  DateTime? _birth;
  DateTime? _death;
  bool _saving = false;
  String? _pickedPhoto;
  bool _removePhoto = false;
  Person? _existing;

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
    _order = TextEditingController(text: existing?.birthOrder?.toString() ?? '');
    _existing = existing;
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
    _order.dispose();
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

  Future<void> _pickPhoto() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (x != null) {
      setState(() {
        _pickedPhoto = x.path;
        _removePhoto = false;
      });
    }
  }

  Widget _photoPicker() {
    final existing = _removePhoto ? null : _existing?.photoPath;
    ImageProvider? image;
    if (_pickedPhoto != null) {
      image = FileImage(File(_pickedPhoto!));
    } else if (existing != null && File(existing).existsSync()) {
      image = FileImage(File(existing));
    }
    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: _pickPhoto,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.paperDark,
                  backgroundImage: image,
                  child: image == null
                      ? const Icon(Icons.person, size: 48, color: AppColors.goldDark)
                      : null,
                ),
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.red,
                    child: Icon(Icons.camera_alt, size: 18, color: AppColors.goldLight),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (image != null)
          TextButton.icon(
            onPressed: () => setState(() {
              _pickedPhoto = null;
              _removePhoto = true;
            }),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Xóa ảnh đại diện'),
          ),
      ],
    );
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
      phone: _existing?.phone,
      address: _existing?.address,
      email: _existing?.email,
      seq: _existing?.seq ?? 0,
      photoPath: _removePhoto ? null : _existing?.photoPath,
      birthOrder: int.tryParse(_order.text.trim()),
    );
    await ref.read(familyProvider.notifier).saveMember(
          person,
          anchorId: widget.anchorId,
          addAs: widget.addAs,
          newPhotoSourcePath: _pickedPhoto,
          removePhoto: _removePhoto && _pickedPhoto == null,
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
            _photoPicker(),
            const SizedBox(height: 16),
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
              controller: _order,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Con thứ mấy trong anh chị em',
                helperText: 'Để trống = xếp theo thứ tự nhập. 1 = con trưởng.',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return null;
                final n = int.tryParse(t);
                return (n == null || n < 1) ? 'Nhập số từ 1 trở lên' : null;
              },
            ),
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
