import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gia_pha/features/members/presentation/widgets/person_avatar.dart';
import 'package:gia_pha/features/members/presentation/providers/family_providers.dart';

class PersonListPage extends ConsumerStatefulWidget {
  const PersonListPage({super.key});

  @override
  ConsumerState<PersonListPage> createState() => _PersonListPageState();
}

class _PersonListPageState extends ConsumerState<PersonListPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final family = ref.watch(familyProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gia phả'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree),
            tooltip: 'Sơ đồ cây',
            onPressed: () => context.push('/tree'),
          ),
        ],
      ),
      body: family.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (data) {
          final q = _query.trim().toLowerCase();
          final people = q.isEmpty
              ? data.persons
              : data.persons
                  .where((p) => p.fullName.toLowerCase().contains(q))
                  .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Tìm theo tên',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: people.isEmpty
                    ? Center(
                        child: Text(
                          data.persons.isEmpty
                              ? 'Chưa có thành viên nào.\nNhấn "Thêm" để bắt đầu.'
                              : 'Không tìm thấy.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: people.length,
                        itemBuilder: (_, i) {
                          final p = people[i];
                          return ListTile(
                            leading: PersonAvatar(p),
                            title: Text(p.fullName),
                            subtitle:
                                p.lifespan.isEmpty ? null : Text(p.lifespan),
                            onTap: () => context.push('/person/${p.id}'),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/form'),
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm'),
      ),
    );
  }
}
