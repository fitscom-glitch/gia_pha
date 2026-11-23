import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
import 'package:gia_pha/core/widgets/gold_app_bar.dart';
import 'package:gia_pha/features/family_tree/domain/services/generation_rows.dart';
import 'package:gia_pha/features/family_tree/domain/services/tree_builder.dart';
import 'package:gia_pha/features/family_tree/domain/services/tree_layout.dart';
import 'package:gia_pha/features/family_tree/presentation/widgets/pha_do_canvas.dart';
import 'package:gia_pha/features/members/domain/entities/family_data.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/members/presentation/providers/family_providers.dart';
import 'package:gia_pha/features/settings/domain/entities/app_settings.dart';
import 'package:gia_pha/features/settings/presentation/providers/settings_providers.dart';

class TreePage extends ConsumerStatefulWidget {
  const TreePage({super.key, this.initialRootId});

  final String? initialRootId;

  @override
  ConsumerState<TreePage> createState() => _TreePageState();
}

class _TreePageState extends ConsumerState<TreePage> {
  String? _rootId;

  @override
  void initState() {
    super.initState();
    _rootId = widget.initialRootId;
  }

  /// Gốc mặc định: người không có cha mẹ, ưu tiên người có con và nhập trước.
  String? _defaultRoot(FamilyData d) {
    if (d.persons.isEmpty) return null;
    final roots = d.persons.where((p) => d.parentsOf(p.id).isEmpty).toList();
    final pool = [...(roots.isEmpty ? d.persons : roots)];
    pool.sort((a, b) {
      final ha = d.childrenOf(a.id).isNotEmpty;
      final hb = d.childrenOf(b.id).isNotEmpty;
      if (ha != hb) return ha ? -1 : 1;
      return a.seq.compareTo(b.seq);
    });
    return pool.first.id;
  }

  Future<void> _editGroups() async {
    final settings = ref.read(settingsProvider).valueOrNull ?? const AppSettings();
    final controller = TextEditingController(text: settings.generationGroups);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gộp đời vào một hàng'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Vd: 2-5; 8-9',
            helperText: 'Các đời trong cùng nhóm nằm chung một hàng. Để trống = mỗi đời một hàng.',
            helperMaxLines: 3,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(settingsProvider.notifier)
          .save(settings.copyWith(generationGroups: controller.text.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final family = ref.watch(familyProvider);
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    return Scaffold(
      appBar: GoldAppBar(
        title: 'Phả đồ',
        actions: [
          IconButton(
            icon: const Icon(Icons.view_agenda_outlined),
            tooltip: 'Gộp đời vào một hàng',
            onPressed: _editGroups,
          ),
          family.maybeWhen(
            data: (d) => PopupMenuButton<String>(
              icon: const Icon(Icons.person_search),
              tooltip: 'Chọn người gốc',
              onSelected: (id) => setState(() => _rootId = id),
              itemBuilder: (_) => [
                for (final p in d.persons)
                  PopupMenuItem(value: p.id, child: Text(p.fullName)),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: ColoredBox(
        color: AppColors.paperDark,
        child: family.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Lỗi: $e')),
          data: (d) {
            final rootId = _rootId ?? _defaultRoot(d);
            final tree = rootId == null ? null : buildDescendantTree(d, rootId);
            if (tree == null) {
              return const Center(child: Text('Chưa có thành viên để hiển thị'));
            }
            final gens = d.generations();
            final rows = buildGenerationRows(
              d.generationCount,
              parseGenerationGroups(settings.generationGroups),
            );
            final rowOfGen = {
              for (var r = 0; r < rows.length; r++)
                for (final g in rows[r]) g: r,
            };
            int rowOf(Person p) => rowOfGen[(gens[p.id] ?? 0) + 1] ?? 0;
            final layout = layoutTree(tree, rowOf: rowOf);
            return _ZoomableCanvas(
              size: PhaDoCanvas.sizeOf(layout),
              child: PhaDoCanvas(
                layout: layout,
                data: d,
                generations: gens,
                rows: rows,
                clanName: settings.clanName,
                place: settings.clanPlace,
                onOpenPerson: (id) => context.push('/person/$id'),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Phóng to/thu nhỏ bằng hai ngón; lúc đầu tự thu nhỏ vừa chiều rộng màn hình.
class _ZoomableCanvas extends StatefulWidget {
  const _ZoomableCanvas({required this.size, required this.child});

  final Size size;
  final Widget child;

  @override
  State<_ZoomableCanvas> createState() => _ZoomableCanvasState();
}

class _ZoomableCanvasState extends State<_ZoomableCanvas> {
  final _controller = TransformationController();
  bool _fitted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!_fitted && constraints.maxWidth.isFinite) {
          _fitted = true;
          final scale = (constraints.maxWidth / widget.size.width).clamp(0.05, 1.0).toDouble();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _controller.value = Matrix4.diagonal3Values(scale, scale, 1);
          });
        }
        return InteractiveViewer(
          transformationController: _controller,
          constrained: false,
          minScale: 0.05,
          maxScale: 3,
          boundaryMargin: const EdgeInsets.all(400),
          child: widget.child,
        );
      },
    );
  }
}
