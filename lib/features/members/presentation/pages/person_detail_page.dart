import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
import 'package:gia_pha/core/widgets/art_assets.dart';
import 'package:gia_pha/core/widgets/gold_app_bar.dart';
import 'package:gia_pha/core/widgets/ornaments/ornaments.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/members/presentation/providers/family_providers.dart';
import 'package:gia_pha/features/members/presentation/widgets/person_avatar.dart';

class PersonDetailPage extends ConsumerWidget {
  const PersonDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(familyProvider).valueOrNull;
    final person = data?.byId(id);
    if (data == null || person == null) {
      return Scaffold(
        appBar: const GoldAppBar(title: 'Thành viên'),
        body: const PatternBackground(
          child: Center(child: Text('Không tìm thấy thành viên')),
        ),
      );
    }
    final fmt = DateFormat('dd/MM/yyyy');
    String? d(DateTime? v) => v == null ? null : fmt.format(v);

    final infoRows = <_InfoRow>[
      _InfoRow(Icons.cake, 'Ngày sinh', d(person.birthDate)),
      _InfoRow(Icons.local_florist, 'Ngày mất', d(person.deathDate)),
      _InfoRow(Icons.place, 'Nơi sinh', person.birthPlace),
      _InfoRow(Icons.work, 'Nghề nghiệp', person.occupation),
      _InfoRow(Icons.notes, 'Tiểu sử', person.bio),
    ].where((w) => w.value?.isNotEmpty ?? false).toList();

    return Scaffold(
      appBar: GoldAppBar(
        title: 'Thông tin thành viên',
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree),
            tooltip: 'Xem cây từ người này',
            onPressed: () => context.push('/tree?root=$id'),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Sửa',
            onPressed: () => context.push('/form?id=$id'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Xóa',
            onPressed: () => _confirmDelete(context, ref, person),
          ),
        ],
      ),
      body: PatternBackground(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _Header(person),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (infoRows.isNotEmpty)
                    OrnateCard(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                      child: Column(children: infoRows),
                    ),
                  _RelationSection(
                    title: 'Cha mẹ',
                    people: data.parentsOf(id),
                    onAdd: () => context.push('/form?anchor=$id&as=parent'),
                  ),
                  _RelationSection(
                    title: 'Vợ/chồng',
                    people: data.spousesOf(id),
                    onAdd: () => context.push('/form?anchor=$id&as=spouse'),
                  ),
                  _RelationSection(
                    title: 'Con',
                    people: data.childrenOfUnit(id),
                    onAdd: () => context.push('/form?anchor=$id&as=child'),
                    onReorder: data.childrenOfUnit(id).length > 1
                        ? () => context.push('/person/$id/children')
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Person person,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa thành viên?'),
        content: Text('Xóa "${person.fullName}" cùng các quan hệ của người này.'),
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
    await ref.read(familyProvider.notifier).deleteMember(person.id);
    if (context.mounted) context.pop();
  }
}

class _Header extends StatelessWidget {
  const _Header(this.person);

  final Person person;

  @override
  Widget build(BuildContext context) {
    final isFemale = person.gender == Gender.female;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.red, AppColors.redDark],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 6,
            top: 12,
            width: 130,
            height: 84,
            child: isFemale
                ? const PhoenixImage(faceRight: false, opacity: 0.6)
                : const DragonImage(faceRight: false, opacity: 0.5),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                child: Column(
                  children: [
                    PersonAvatar(person, radius: 44),
                    const SizedBox(height: 10),
                    Text(
                      person.fullName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: AppColors.goldLight,
                      ),
                    ),
                    if (person.lifespan.isNotEmpty)
                      Text(
                        person.lifespan,
                        style: const TextStyle(fontSize: 14, color: AppColors.gold),
                      ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.gold),
                      ),
                      child: Text(
                        _chipText(person),
                        style: const TextStyle(fontSize: 12.5, color: AppColors.goldLight),
                      ),
                    ),
                  ],
                ),
              ),
              const MeanderStrip(height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.goldDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppColors.goldDark),
                ),
                Text(
                  value ?? '',
                  style: const TextStyle(fontSize: 15, color: AppColors.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Diamond extends StatelessWidget {
  const _Diamond();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: AppColors.gold,
          border: Border.all(color: AppColors.red, width: 1.2),
        ),
      ),
    );
  }
}

class _RelationSection extends StatelessWidget {
  const _RelationSection({
    required this.title,
    required this.people,
    required this.onAdd,
    this.onReorder,
  });

  final String title;
  final List<Person> people;
  final VoidCallback onAdd;
  final VoidCallback? onReorder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Row(
            children: [
              const SizedBox(width: 4),
              const _Diamond(),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: AppColors.redDark,
                ),
              ),
              const Spacer(),
              if (onReorder != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Sắp xếp thứ tự anh em',
                  icon: const Icon(Icons.swap_vert, color: AppColors.red),
                  onPressed: onReorder,
                ),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Thêm'),
              ),
            ],
          ),
        ),
        OrnateCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: people.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Chưa có',
                    style: TextStyle(color: AppColors.goldDark),
                  ),
                )
              : Column(
                  children: [
                    for (final p in people)
                      ListTile(
                        dense: true,
                        leading: PersonAvatar(p, radius: 17),
                        title: Text(
                          p.fullName,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        subtitle: personSubtitle(p).isEmpty ? null : Text(personSubtitle(p)),
                        onTap: () => context.push('/person/${p.id}'),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

String _chipText(Person p) {
  final order = birthOrderLabel(p.birthOrder);
  return order == null ? genderLabel(p.gender) : '${genderLabel(p.gender)} · $order';
}
