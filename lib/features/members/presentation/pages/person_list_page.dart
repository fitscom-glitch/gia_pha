import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:gia_pha/core/utils/file_saver.dart';
import 'package:gia_pha/features/members/presentation/export/member_export_rows.dart';
import 'package:gia_pha/features/members/presentation/export/member_list_pdf.dart';
import 'package:gia_pha/features/members/presentation/export/members_xlsx.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
import 'package:gia_pha/core/widgets/art_assets.dart';
import 'package:gia_pha/core/widgets/gold_app_bar.dart';
import 'package:gia_pha/core/widgets/ornaments/ornaments.dart';
import 'package:gia_pha/features/members/domain/entities/family_data.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/members/presentation/providers/family_providers.dart';
import 'package:gia_pha/features/members/presentation/widgets/person_avatar.dart';
import 'package:gia_pha/features/members/presentation/widgets/relation_note.dart';

enum _SortMode { relation, generation, name }

class PersonListPage extends ConsumerStatefulWidget {
  const PersonListPage({super.key});

  @override
  ConsumerState<PersonListPage> createState() => _PersonListPageState();
}

class _PersonListPageState extends ConsumerState<PersonListPage> {
  String _query = '';
  _SortMode _sort = _SortMode.relation;

  /// Các thành viên đang được mở rộng để xem người có quan hệ trực tiếp.
  final Set<String> _expanded = {};

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Xuất toàn bộ danh sách thành viên ra Excel hoặc PDF, cho chọn nơi lưu.
  Future<void> _exportList({required bool pdf}) async {
    final data = ref.read(familyProvider).valueOrNull;
    if (data == null || data.persons.isEmpty) {
      _toast('Chưa có thành viên để xuất');
      return;
    }
    _toast('Đang tạo file...');
    try {
      final rows = buildMemberExportRows(data);
      final stamp = DateFormat('yyyyMMdd').format(DateTime.now());
      final Uint8List bytes;
      final String ext;
      if (pdf) {
        bytes = await buildMemberListPdf(rows, title: 'DANH SÁCH THÀNH VIÊN');
        ext = 'pdf';
      } else {
        bytes = buildMemberXlsx(rows);
        ext = 'xlsx';
      }
      final saved = await saveFileWithPicker(
        fileName: 'danh-sach-thanh-vien-$stamp.$ext',
        bytes: bytes,
        extensions: [ext],
        dialogTitle: 'Chọn nơi lưu danh sách',
      );
      _toast(saved ? 'Đã lưu danh sách (${rows.length} thành viên)' : 'Đã hủy, chưa lưu file');
    } catch (e) {
      _toast('Không xuất được: $e');
    }
  }

  /// Theo tên gọi (từ cuối), rồi họ tên đầy đủ.
  static int _byName(Person a, Person b) {
    String given(Person p) =>
        p.fullName.trim().split(RegExp(r'\s+')).last.toLowerCase();
    final c = given(a).compareTo(given(b));
    return c != 0 ? c : a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final family = ref.watch(familyProvider);
    return Scaffold(
      appBar: GoldAppBar(
        title: 'Gia phả',
        actions: [
          PopupMenuButton<_SortMode>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sắp xếp',
            initialValue: _sort,
            onSelected: (m) => setState(() => _sort = m),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _SortMode.relation,
                child: Text('Theo mối quan hệ (vợ chồng, con, cháu...)'),
              ),
              PopupMenuItem(
                value: _SortMode.generation,
                child: Text('Theo đời (vợ chồng liền kề)'),
              ),
              PopupMenuItem(value: _SortMode.name, child: Text('Tên A–Z')),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Xuất danh sách',
            onSelected: (v) => _exportList(pdf: v == 'pdf'),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'xlsx', child: Text('Xuất Excel (.xlsx)')),
              PopupMenuItem(value: 'pdf', child: Text('Xuất PDF')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Thống kê',
            onPressed: () => context.push('/stats'),
          ),
          IconButton(
            icon: const Icon(Icons.account_tree),
            tooltip: 'Phả đồ',
            onPressed: () => context.push('/tree'),
          ),
        ],
      ),
      body: PatternBackground(
        child: family.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Lỗi: $e')),
          data: (data) {
            final gens = data.generations();
            final q = _query.trim().toLowerCase();
            // Thứ tự theo mối quan hệ: người, vợ/chồng liền sau, rồi con cháu.
            final order = data.relationOrder();
            final indexOf = {
              for (var i = 0; i < order.length; i++) order[i].person.id: i,
            };
            final depthOf = {for (final e in order) e.person.id: e.depth};
            final people = <Person>[
              for (final e in order)
                if (q.isEmpty || e.person.fullName.toLowerCase().contains(q)) e.person,
            ];
            switch (_sort) {
              case _SortMode.relation:
                break;
              case _SortMode.generation:
                // Cùng đời thì giữ thứ tự theo mối quan hệ nên vợ chồng luôn liền kề nhau.
                people.sort((a, b) {
                  final c = (gens[a.id] ?? 0).compareTo(gens[b.id] ?? 0);
                  return c != 0 ? c : (indexOf[a.id] ?? 0).compareTo(indexOf[b.id] ?? 0);
                });
              case _SortMode.name:
                people.sort(_byName);
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: AppColors.goldDark),
                      hintText: 'Tìm theo tên (${data.persons.length} thành viên)',
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
                          itemBuilder: (_, i) => _buildItem(
                            context,
                            data,
                            gens,
                            people[i],
                            _sort == _SortMode.relation ? (depthOf[people[i].id] ?? 0) : 0,
                          ),
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

  Widget _buildItem(
    BuildContext context,
    FamilyData data,
    Map<String, int> gens,
    Person p,
    int depth,
  ) {
    final indent = (depth > 5 ? 5 : depth) * 10.0;
    final g = gens[p.id];
    final order = birthOrderLabel(p.birthOrder);
    final sub = [
      if (g != null) 'Đời ${g + 1}',
      if (order != null) order,
      if (p.lifespan.isNotEmpty) p.lifespan,
    ].join(' · ');
    final note = relationNote(data, p);
    final spouses = data.spousesOf(p.id);
    final kids = data.childrenOfUnit(p.id);
    final hasRelated = spouses.isNotEmpty || kids.isNotEmpty;
    final open = _expanded.contains(p.id);

    return Column(
      children: [
        OrnateCard(
          margin: EdgeInsets.fromLTRB(12 + indent, 5, 12, 5),
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
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
                    if (sub.isNotEmpty)
                      Text(sub, style: const TextStyle(fontSize: 13, color: AppColors.redDark)),
                    if (note != null)
                      Text(
                        note,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: AppColors.goldDark,
                        ),
                      ),
                  ],
                ),
              ),
              if (hasRelated)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: open ? 'Thu gọn' : 'Xem vợ/chồng và con',
                  icon: Icon(
                    open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.red,
                  ),
                  onPressed: () => setState(() {
                    if (!_expanded.remove(p.id)) _expanded.add(p.id);
                  }),
                )
              else
                const SizedBox(width: 8),
            ],
          ),
        ),
        if (open && hasRelated)
          Container(
            margin: EdgeInsets.only(left: 32 + indent, right: 14, bottom: 4),
            padding: const EdgeInsets.only(left: 8),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: AppColors.gold, width: 2)),
            ),
            child: Column(
              children: [
                for (final s in spouses) _relatedTile(context, s, spouseLabel(s.gender)),
                for (final c in kids)
                  _relatedTile(context, c, birthOrderLabel(c.birthOrder) ?? 'Con'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _relatedTile(BuildContext context, Person p, String role) {
    return InkWell(
      onTap: () => context.push('/person/${p.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            PersonAvatar(p, radius: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                p.fullName,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  color: AppColors.ink,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gold),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(role, style: const TextStyle(fontSize: 11.5, color: AppColors.goldDark)),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.goldDark),
          ],
        ),
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
              SizedBox(width: 140, height: 66, child: DragonImage(faceRight: true)),
              SizedBox(width: 8),
              SizedBox(width: 72, height: 72, child: PhoenixImage(faceRight: false)),
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
