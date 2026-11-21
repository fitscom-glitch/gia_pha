import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
import 'package:gia_pha/core/widgets/dragon_phoenix_banner.dart';
import 'package:gia_pha/core/widgets/gold_app_bar.dart';
import 'package:gia_pha/core/widgets/ornaments/motif_data.dart';
import 'package:gia_pha/core/widgets/ornaments/motif_painter.dart';
import 'package:gia_pha/core/widgets/ornaments/ornaments.dart';
import 'package:gia_pha/features/members/presentation/providers/family_providers.dart';
import 'package:gia_pha/features/members/presentation/widgets/person_avatar.dart';

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
      appBar: GoldAppBar(
        title: 'Gia phả dòng họ',
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree),
            tooltip: 'Sơ đồ cây',
            onPressed: () => context.push('/tree'),
          ),
        ],
      ),
      body: PatternBackground(
        child: family.when(
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
                DragonPhoenixBanner(
                  title: 'GIA PHẢ',
                  subtitle: '${data.persons.length} thành viên',
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: AppColors.goldDark),
                      hintText: 'Tìm theo tên',
                      filled: true,
                      fillColor: AppColors.card,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.gold),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.red, width: 1.6),
                      ),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Expanded(
                  child: people.isEmpty
                      ? _EmptyState(noMembers: data.persons.isEmpty)
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 4, bottom: 92),
                          itemCount: people.length,
                          itemBuilder: (_, i) {
                            final p = people[i];
                            return OrnateCard(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              onTap: () => context.push('/person/${p.id}'),
                              child: Row(
                                children: [
                                  PersonAvatar(p, radius: 24),
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
                                        if (p.lifespan.isNotEmpty)
                                          Text(
                                            p.lifespan,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.redDark,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: AppColors.goldDark,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/form'),
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.noMembers});

  final bool noMembers;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 110,
                height: 64,
                child: MotifView(motif: dragonMotif, color: Color(0x889C7A12)),
              ),
              SizedBox(width: 8),
              SizedBox(
                width: 110,
                height: 70,
                child: MotifView(
                  motif: phoenixMotif,
                  color: Color(0x889C7A12),
                  flipX: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            noMembers
                ? 'Chưa có thành viên nào.\nNhấn "Thêm" để bắt đầu.'
                : 'Không tìm thấy.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 16,
              color: AppColors.redDark,
            ),
          ),
        ],
      ),
    );
  }
}
