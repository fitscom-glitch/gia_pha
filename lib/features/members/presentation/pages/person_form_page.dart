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
import 'package:gia_pha/features/members/domain/entities/family_data.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/members/domain/entities/relationship.dart';
import 'package:gia_pha/features/members/presentation/widgets/person_picker.dart';
import 'package:gia_pha/features/members/presentation/widgets/relation_note.dart';

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

  // --- Quan hệ cha mẹ / con ---
  FamilyData? _data;
  Map<String, int> _gens = const {};

  /// Cha/mẹ (người trong cây) và người còn lại (một trong các vợ/chồng của người đó).
  Person? _parentA;
  Person? _parentB;

  /// Khi thêm con cho một người đã có vợ/chồng: người còn lại cùng làm cha/mẹ (null = con riêng).
  String? _coParentId;

  /// Các con của người đang sửa, kèm người cha/mẹ còn lại của từng con.
  final List<_ChildRow> _children = [];

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
    final data = ref.read(familyProvider).valueOrNull;
    _data = data;
    if (data != null) {
      _gens = data.generations();
      if (existing != null) {
        _initParents(data, existing);
        _initChildren(data, existing);
      } else if (widget.addAs == AddAs.child && widget.anchorId != null) {
        final sp = data.spousesOf(widget.anchorId!);
        if (sp.length == 1) _coParentId = sp.first.id; // chỉ một vợ/chồng: mặc định là con chung
      }
    }
  }

  void _initParents(FamilyData data, Person me) {
    final ps = data.parentsOf(me.id);
    if (ps.isEmpty) return;
    if (ps.length >= 2) {
      final a = ps[0];
      final b = ps[1];
      if (data.spousesOf(b.id).any((e) => e.id == a.id) &&
          !data.spousesOf(a.id).any((e) => e.id == b.id)) {
        _parentA = b;
        _parentB = a;
      } else {
        _parentA = a;
        _parentB = b;
      }
    } else {
      _parentA = ps.first;
    }
  }

  void _initChildren(FamilyData data, Person me) {
    final spouseIds = data.spousesOf(me.id).map((e) => e.id).toSet();
    for (final c in data.childrenOf(me.id)) {
      String? co;
      for (final p in data.parentsOf(c.id)) {
        if (spouseIds.contains(p.id)) {
          co = p.id;
          break;
        }
      }
      _children.add(_ChildRow(c, co));
    }
  }

  static Set<String> _descendantsOf(FamilyData d, String id) {
    final seen = <String>{};
    final queue = [id];
    while (queue.isNotEmpty) {
      for (final c in d.childrenOf(queue.removeLast())) {
        if (seen.add(c.id)) queue.add(c.id);
      }
    }
    return seen;
  }

  static Set<String> _ancestorsOf(FamilyData d, String id) {
    final seen = <String>{};
    final queue = [id];
    while (queue.isNotEmpty) {
      for (final p in d.parentsOf(queue.removeLast())) {
        if (seen.add(p.id)) queue.add(p.id);
      }
    }
    return seen;
  }

  Future<void> _pickParent() async {
    final data = _data;
    if (data == null) return;
    final me = widget.personId;
    final banned = <String>{if (me != null) me, if (me != null) ..._descendantsOf(data, me)};
    final picked = await showPersonPicker(
      context,
      title: 'Chọn cha/mẹ',
      candidates: [for (final p in data.persons) if (!banned.contains(p.id)) p],
      generations: _gens,
    );
    if (picked == null) return;
    final sp = data.spousesOf(picked.id);
    setState(() {
      _parentA = picked;
      _parentB = sp.length == 1 ? sp.first : null; // 2 vợ/chồng trở lên: để người dùng chọn
    });
  }

  Future<void> _addChild() async {
    final data = _data;
    final me = widget.personId;
    if (data == null || me == null) return;
    final banned = <String>{
      me,
      ..._ancestorsOf(data, me),
      for (final r in _children) r.child.id,
    };
    final picked = await showPersonPicker(
      context,
      title: 'Chọn người làm con',
      candidates: [for (final p in data.persons) if (!banned.contains(p.id)) p],
      generations: _gens,
    );
    if (picked == null) return;
    final sp = data.spousesOf(me);
    setState(() => _children.add(_ChildRow(picked, sp.length == 1 ? sp.first.id : null)));
  }

  /// Ô chọn "người cha/mẹ còn lại" trong số vợ/chồng của [ownerId]; từ 2 vợ/chồng thì đánh số ①②.
  Widget _coParentDropdown({
    required String ownerId,
    required String? value,
    required String noneLabel,
    required ValueChanged<String?> onChanged,
    String label = 'Con của',
  }) {
    final sp = _data!.spousesOf(ownerId);
    if (sp.isEmpty) return const SizedBox.shrink();
    final numbered = sp.length >= 2;
    final current = sp.any((e) => e.id == value) ? value : null;
    return DropdownButtonFormField<String?>(
      value: current,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text(noneLabel, overflow: TextOverflow.ellipsis),
        ),
        for (var i = 0; i < sp.length; i++)
          DropdownMenuItem<String?>(
            value: sp[i].id,
            child: Text(
              '${numbered ? '${circledNumber(i + 1)} ' : ''}${spouseLabel(sp[i].gender)}: ${sp[i].fullName}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }

  Widget _sectionTitle(String text, {String? hint}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontFamily: 'serif',
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: AppColors.redDark,
              ),
            ),
            if (hint != null)
              Text(hint, style: const TextStyle(fontSize: 12, color: AppColors.goldDark)),
          ],
        ),
      );

  List<Widget> _relationSections() {
    final data = _data;
    if (data == null) return const [];
    final out = <Widget>[];

    // Cha mẹ (khi sửa hoặc thêm thành viên độc lập)
    if (widget.addAs == null) {
      out.add(_sectionTitle(
        'Cha mẹ',
        hint: 'Chọn cha/mẹ trong gia phả; nếu người đó có nhiều vợ/chồng thì chọn tiếp người còn lại.',
      ));
      out.add(InkWell(
        onTap: _pickParent,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Cha/mẹ',
            border: const OutlineInputBorder(),
            suffixIcon: _parentA == null
                ? const Icon(Icons.arrow_drop_down)
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _parentA = null;
                      _parentB = null;
                    }),
                  ),
          ),
          child: Text(_parentA?.fullName ?? ''),
        ),
      ));
      if (_parentA != null) {
        final a = _parentA!;
        final sp = data.spousesOf(a.id);
        if (sp.isNotEmpty || _parentB != null) {
          out.add(const SizedBox(height: 12));
          // Nếu người còn lại đã lưu không phải vợ/chồng của A thì vẫn hiển thị để không mất dữ liệu.
          final extra = (_parentB != null && !sp.any((e) => e.id == _parentB!.id)) ? _parentB : null;
          final numbered = sp.length >= 2;
          out.add(DropdownButtonFormField<String?>(
            value: _parentB?.id,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Cha/mẹ còn lại',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text('Chỉ ${a.fullName} (không ghi người còn lại)',
                    overflow: TextOverflow.ellipsis),
              ),
              for (var i = 0; i < sp.length; i++)
                DropdownMenuItem<String?>(
                  value: sp[i].id,
                  child: Text(
                    '${numbered ? '${circledNumber(i + 1)} ' : ''}${spouseLabel(sp[i].gender)}: ${sp[i].fullName}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (extra != null)
                DropdownMenuItem<String?>(
                  value: extra.id,
                  child: Text(extra.fullName, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() {
              _parentB = v == null ? null : data.byId(v);
            }),
          ));
        }
      }
      out.add(const SizedBox(height: 16));
    }

    // Thêm con cho một người đã có vợ/chồng: con chung hay con riêng
    if (widget.addAs == AddAs.child && widget.anchorId != null) {
      final anchor = data.byId(widget.anchorId!);
      if (anchor != null && data.spousesOf(anchor.id).isNotEmpty) {
        out.add(_sectionTitle(
          'Con chung / con riêng',
          hint: 'Chọn người cùng là cha/mẹ của con này, hoặc "Chỉ ${anchor.fullName}" nếu là con riêng.',
        ));
        out.add(_coParentDropdown(
          ownerId: anchor.id,
          value: _coParentId,
          noneLabel: 'Chỉ ${anchor.fullName} (con riêng)',
          onChanged: (v) => setState(() => _coParentId = v),
        ));
        out.add(const SizedBox(height: 16));
      }
    }

    // Các con (khi sửa)
    if (widget.personId != null) {
      final me = data.byId(widget.personId!);
      out.add(_sectionTitle(
        'Con',
        hint: 'Với người có nhiều vợ/chồng: chọn mỗi người con là con của ai (con chung hay con riêng).',
      ));
      for (final r in _children) {
        out.add(Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.child.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Bỏ khỏi danh sách con',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _children.remove(r)),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _coParentDropdown(
                    ownerId: widget.personId!,
                    value: r.co,
                    noneLabel: 'Chỉ ${me?.fullName ?? 'người này'} (con riêng)',
                    onChanged: (v) => setState(() => r.co = v),
                  ),
                ),
              ],
            ),
          ),
        ));
      }
      out.add(Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _addChild,
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Chọn thêm con có sẵn'),
        ),
      ));
      out.add(const SizedBox(height: 8));
    }
    return out;
  }

  static bool _sameIds(Iterable<String> a, Iterable<String> b) {
    final x = a.toSet();
    final y = b.toSet();
    return x.length == y.length && x.containsAll(y);
  }

  /// Ghi lại cha/mẹ của các con theo danh sách đang chọn.
  Future<void> _syncChildren(FamilyNotifier notifier, FamilyData data) async {
    final me = widget.personId!;
    final unit = <String>{me, ...data.spousesOf(me).map((e) => e.id)};
    final keep = {for (final r in _children) r.child.id};
    for (final c in data.childrenOf(me)) {
      if (keep.contains(c.id)) continue;
      final others = data.parentsOf(c.id).map((e) => e.id).where((id) => !unit.contains(id));
      await notifier.setParents(c.id, others.toList());
    }
    for (final r in _children) {
      final current = data.parentsOf(r.child.id).map((e) => e.id).toList();
      final others = current.where((id) => !unit.contains(id)).toList();
      final desired = [...others, me, if (r.co != null) r.co!];
      if (!_sameIds(current, desired)) await notifier.setParents(r.child.id, desired);
    }
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
    final notifier = ref.read(familyProvider.notifier);
    await notifier.saveMember(
      person,
      anchorId: widget.anchorId,
      addAs: widget.addAs,
      newPhotoSourcePath: _pickedPhoto,
      removePhoto: _removePhoto && _pickedPhoto == null,
    );
    final data = _data;
    if (data != null) {
      if (widget.addAs == AddAs.child && widget.anchorId != null && _coParentId != null) {
        await notifier.setParents(person.id, [widget.anchorId!, _coParentId!]);
      }
      if (widget.addAs == null) {
        final ids = [if (_parentA != null) _parentA!.id, if (_parentB != null) _parentB!.id];
        final old = data.parentsOf(person.id).map((e) => e.id);
        if (!_sameIds(ids, old)) await notifier.setParents(person.id, ids);
      }
      if (widget.personId != null) await _syncChildren(notifier, data);
    }
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
            ..._relationSections(),
            const SizedBox(height: 8),
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

class _ChildRow {
  _ChildRow(this.child, this.co);

  final Person child;

  /// Id người cha/mẹ còn lại (một trong các vợ/chồng); null = con riêng / không ghi.
  String? co;
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
