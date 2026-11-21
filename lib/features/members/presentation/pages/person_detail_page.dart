import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:gia_pha/features/members/presentation/widgets/person_avatar.dart';
import 'package:gia_pha/features/members/presentation/providers/family_providers.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';

class PersonDetailPage extends ConsumerWidget {
  const PersonDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(familyProvider).valueOrNull;
    final person = data?.byId(id);
    if (data == null || person == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Không tìm thấy thành viên')),
      );
    }
    final fmt = DateFormat('dd/MM/yyyy');
    String? d(DateTime? v) => v == null ? null : fmt.format(v);

    return Scaffold(
      appBar: AppBar(
        title: Text(person.fullName),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: PersonAvatar(person, radius: 40)),
          const SizedBox(height: 8),
          Center(
            child: Text(person.fullName,
                style: Theme.of(context).textTheme.headlineSmall),
          ),
          if (person.lifespan.isNotEmpty) Center(child: Text(person.lifespan)),
          const Divider(height: 32),
          _InfoRow(Icons.cake, 'Ngày sinh', d(person.birthDate)),
          _InfoRow(Icons.local_florist, 'Ngày mất', d(person.deathDate)),
          _InfoRow(Icons.place, 'Nơi sinh', person.birthPlace),
          _InfoRow(Icons.work, 'Nghề nghiệp', person.occupation),
          _InfoRow(Icons.notes, 'Tiểu sử', person.bio),
          const SizedBox(height: 8),
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
            people: data.childrenOf(id),
            onAdd: () => context.push('/form?anchor=$id&as=child'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Person person) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa thành viên?'),
        content: Text('Xóa "${person.fullName}" cùng các quan hệ của người này.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(familyProvider.notifier).deleteMember(person.id);
    if (context.mounted) context.pop();
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return ListTile(
      dense: true,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value!),
    );
  }
}

class _RelationSection extends StatelessWidget {
  const _RelationSection(
      {required this.title, required this.people, required this.onAdd});

  final String title;
  final List<Person> people;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Thêm'),
            ),
          ],
        ),
        for (final p in people)
          ListTile(
            dense: true,
            leading: PersonAvatar(p, radius: 16),
            title: Text(p.fullName),
            subtitle: p.lifespan.isEmpty ? null : Text(p.lifespan),
            onTap: () => context.push('/person/${p.id}'),
          ),
      ],
    );
  }
}
