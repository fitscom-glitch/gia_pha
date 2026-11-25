import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
import 'package:gia_pha/core/widgets/gold_app_bar.dart';
import 'package:gia_pha/features/family_tree/domain/entities/pha_do_layer.dart';
import 'package:gia_pha/features/family_tree/presentation/providers/pha_do_providers.dart';
import 'package:gia_pha/features/family_tree/presentation/widgets/layer_image.dart';
import 'package:gia_pha/features/family_tree/presentation/widgets/pha_do_canvas.dart';
import 'package:gia_pha/features/family_tree/presentation/widgets/pha_do_model.dart';
import 'package:gia_pha/features/members/presentation/providers/family_providers.dart';
import 'package:gia_pha/features/settings/domain/entities/app_settings.dart';
import 'package:gia_pha/features/settings/presentation/providers/settings_providers.dart';

/// Trang trí phả đồ: thêm hình nền, họa tiết, băng rôn, biểu ngữ từ file ngoài
/// (PNG nền trong suốt, JPG, WebP, SVG). Chạm để chọn, kéo để di chuyển.
class PhaDoDecorPage extends ConsumerStatefulWidget {
  const PhaDoDecorPage({super.key, this.rootId});

  final String? rootId;

  @override
  ConsumerState<PhaDoDecorPage> createState() => _PhaDoDecorPageState();
}

class _PhaDoDecorPageState extends ConsumerState<PhaDoDecorPage> {
  String? _selectedId;

  PhaDoLayersNotifier get _notifier => ref.read(phaDoLayersProvider.notifier);

  PhaDoLayer? _current(String id) {
    for (final l in ref.read(phaDoLayersProvider).valueOrNull ?? const <PhaDoLayer>[]) {
      if (l.id == id) return l;
    }
    return null;
  }

  Future<void> _addLayer() async {
    final kind = await showModalBottomSheet<PhaDoLayerKind>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.wallpaper),
              title: const Text('Hình nền (phủ kín phả đồ)'),
              onTap: () => Navigator.pop(ctx, PhaDoLayerKind.background),
            ),
            ListTile(
              leading: const Icon(Icons.filter_vintage),
              title: const Text('Họa tiết, băng rôn, biểu ngữ'),
              subtitle: const Text('Đặt tự do: kéo, đổi cỡ, xoay. PNG nền trong suốt, JPG, WebP, SVG'),
              onTap: () => Navigator.pop(ctx, PhaDoLayerKind.decor),
            ),
          ],
        ),
      ),
    );
    if (kind == null) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'svg'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    final id = await _notifier.add(sourcePath: path, kind: kind);
    if (mounted) setState(() => _selectedId = id);
  }

  void _move(PhaDoLayer l, Offset delta, double scale, Size canvas) {
    final cur = _current(l.id) ?? l;
    _notifier.updateLocal(cur.copyWith(
      cx: (cur.cx + delta.dx / scale / canvas.width).clamp(0.0, 1.0),
      cy: (cur.cy + delta.dy / scale / canvas.height).clamp(0.0, 1.0),
    ));
  }

  void _persist(String id) {
    final cur = _current(id);
    if (cur != null) _notifier.persist(cur);
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(familyProvider).valueOrNull;
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final layers = ref.watch(phaDoLayersProvider).valueOrNull ?? const <PhaDoLayer>[];
    final model = data == null ? null : PhaDoModel.build(data, settings, widget.rootId);
    PhaDoLayer? selected;
    for (final l in layers) {
      if (l.id == _selectedId) selected = l;
    }

    return Scaffold(
      appBar: GoldAppBar(
        title: 'Trang trí phả đồ',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            tooltip: 'Thêm hình',
            onPressed: _addLayer,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: model == null
                ? const Center(child: Text('Chưa có thành viên để xem trước'))
                : _preview(model, settings, layers),
          ),
          _controls(layers, selected, settings),
        ],
      ),
    );
  }

  Widget _preview(PhaDoModel model, AppSettings settings, List<PhaDoLayer> layers) {
    return Container(
      color: AppColors.paperDark,
      child: LayoutBuilder(
        builder: (context, c) {
          final size = model.size;
          final scale = math.min(c.maxWidth / size.width, c.maxHeight / size.height);
          return Center(
            child: SizedBox(
              width: size.width * scale,
              height: size.height * scale,
              child: FittedBox(
                fit: BoxFit.fill,
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: Stack(
                    children: [
                      PhaDoCanvas(
                        layout: model.layout,
                        data: model.data,
                        generations: model.generations,
                        rows: model.rows,
                        clanName: settings.clanName,
                        place: settings.clanPlace,
                        onOpenPerson: (_) {},
                        layers: layers,
                        showFrame: settings.phadoFrame,
                        showBanner: settings.phadoBanner,
                        showWatermark: settings.phadoWatermark,
                      ),
                      for (final l in layers.where((l) => l.kind == PhaDoLayerKind.decor))
                        _handle(l, size, scale),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Khung chạm/kéo phủ lên một họa tiết.
  Widget _handle(PhaDoLayer l, Size canvas, double scale) {
    final r = PhaDoCanvas.layerRect(l, canvas);
    final sel = l.id == _selectedId;
    return Positioned(
      left: r.left,
      top: r.top,
      width: r.width,
      height: r.height,
      child: Transform.rotate(
        angle: l.rotation * math.pi / 180,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _selectedId = l.id),
          onPanStart: (_) => setState(() => _selectedId = l.id),
          onPanUpdate: (d) => _move(l, d.delta, scale, canvas),
          onPanEnd: (_) => _persist(l.id),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: sel ? const Color(0xFF1E88E5) : const Color(0x33000000),
                width: (sel ? 3 : 1) / scale,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _controls(List<PhaDoLayer> layers, PhaDoLayer? sel, AppSettings settings) {
    final settingsNotifier = ref.read(settingsProvider.notifier);
    return Material(
      color: AppColors.card,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 72,
                  child: layers.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Chưa có hình nào. Bấm biểu tượng thêm hình ở góc trên bên phải.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.goldDark),
                            ),
                          ),
                        )
                      : ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.all(8),
                          children: [for (final l in layers) _chip(l)],
                        ),
                ),
                if (sel != null) ..._selectedControls(sel, layers),
                ExpansionTile(
                  title: const Text('Thành phần mặc định'),
                  children: [
                    SwitchListTile(
                      dense: true,
                      title: const Text('Khung viền vàng cam'),
                      value: settings.phadoFrame,
                      onChanged: (v) => settingsNotifier.save(settings.copyWith(phadoFrame: v)),
                    ),
                    SwitchListTile(
                      dense: true,
                      title: const Text('Băng rôn tên dòng họ'),
                      value: settings.phadoBanner,
                      onChanged: (v) => settingsNotifier.save(settings.copyWith(phadoBanner: v)),
                    ),
                    SwitchListTile(
                      dense: true,
                      title: const Text('Hình rồng mờ ở nền'),
                      value: settings.phadoWatermark,
                      onChanged: (v) => settingsNotifier.save(settings.copyWith(phadoWatermark: v)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(PhaDoLayer l) {
    final sel = l.id == _selectedId;
    return GestureDetector(
      onTap: () => setState(() => _selectedId = l.id),
      child: Container(
        width: 56,
        height: 56,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.paperDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: sel ? const Color(0xFF1E88E5) : AppColors.gold,
            width: sel ? 3 : 1,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            LayerImage(path: l.path),
            if (l.kind == PhaDoLayerKind.background)
              const Align(
                alignment: Alignment.bottomRight,
                child: Icon(Icons.wallpaper, size: 14, color: AppColors.red),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _selectedControls(PhaDoLayer sel, List<PhaDoLayer> layers) {
    final isDecor = sel.kind == PhaDoLayerKind.decor;
    final minZ = layers.map((l) => l.z).reduce(math.min);
    final maxZ = layers.map((l) => l.z).reduce(math.max);

    Widget slider(String label, double value, double min, double max, PhaDoLayer Function(PhaDoLayer, double) apply) {
      return Row(
        children: [
          SizedBox(width: 84, child: Padding(padding: const EdgeInsets.only(left: 16), child: Text(label, style: const TextStyle(fontSize: 13)))),
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: (v) => _notifier.updateLocal(apply(_current(sel.id) ?? sel, v)),
              onChangeEnd: (_) => _persist(sel.id),
            ),
          ),
        ],
      );
    }

    return [
      if (isDecor)
        slider('Kích thước', sel.w, 0.03, 1.0, (l, v) => l.copyWith(w: v)),
      if (isDecor)
        slider('Xoay', sel.rotation, -180, 180, (l, v) => l.copyWith(rotation: v)),
      slider('Độ đậm', sel.opacity, 0.1, 1.0, (l, v) => l.copyWith(opacity: v)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Wrap(
          spacing: 4,
          children: [
            if (isDecor)
              FilterChip(
                label: const Text('Đè lên cây'),
                selected: sel.front,
                onSelected: (v) => _notifier.persist(sel.copyWith(front: v)),
              ),
            TextButton.icon(
              onPressed: sel.z >= maxZ ? null : () => _notifier.persist(sel.copyWith(z: maxZ + 1)),
              icon: const Icon(Icons.flip_to_front, size: 18),
              label: const Text('Lên trên'),
            ),
            TextButton.icon(
              onPressed: sel.z <= minZ ? null : () => _notifier.persist(sel.copyWith(z: minZ - 1)),
              icon: const Icon(Icons.flip_to_back, size: 18),
              label: const Text('Xuống dưới'),
            ),
            TextButton.icon(
              onPressed: () async {
                await _notifier.remove(sel);
                if (mounted) setState(() => _selectedId = null);
              },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Xóa hình'),
            ),
          ],
        ),
      ),
    ];
  }
}
