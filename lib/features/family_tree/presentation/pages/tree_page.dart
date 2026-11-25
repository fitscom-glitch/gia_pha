import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
import 'package:gia_pha/core/utils/file_saver.dart';
import 'package:gia_pha/core/widgets/gold_app_bar.dart';
import 'package:gia_pha/features/family_tree/domain/entities/pha_do_layer.dart';
import 'package:gia_pha/features/family_tree/presentation/export/pha_do_export.dart';
import 'package:gia_pha/features/family_tree/presentation/providers/pha_do_providers.dart';
import 'package:gia_pha/features/family_tree/presentation/widgets/generation_groups_dialog.dart';
import 'package:gia_pha/features/family_tree/presentation/widgets/pha_do_canvas.dart';
import 'package:gia_pha/features/family_tree/presentation/widgets/pha_do_model.dart';
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
  final _canvasKey = GlobalKey();
  final _viewerKey = GlobalKey<_ZoomableCanvasState>();
  PhaDoModel? _model;

  /// null = tự động (màn hình dọc thì xoay phả đồ dọc cho to, dễ đọc).
  bool? _rotated;

  @override
  void initState() {
    super.initState();
    _rootId = widget.initialRootId;
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editGroups() async {
    final model = _model;
    final settings = ref.read(settingsProvider).valueOrNull ?? const AppSettings();
    final result = await showGenerationGroupsDialog(
      context,
      initial: settings.generationGroups,
      maxGeneration: model?.data.generationCount ?? 0,
    );
    if (result != null) {
      await ref.read(settingsProvider.notifier).save(settings.copyWith(generationGroups: result));
    }
  }

  /// Chụp phả đồ thành ảnh PNG độ phân giải cao hoặc PDF rồi cho chọn nơi lưu.
  Future<void> _export() async {
    final model = _model;
    if (model == null) return;
    final opts = await showDialog<_ExportOptions>(
      context: context,
      builder: (_) => const _ExportDialog(),
    );
    if (opts == null || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    var progressOpen = true;
    String message;
    try {
      final boundary = _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('Phả đồ chưa sẵn sàng');
      final size = model.size;
      final maxPixels = opts.pdf ? 12e6 : 36e6;
      final maxSide = opts.pdf ? 6000.0 : 9000.0;
      final wanted = switch (opts.quality) {
        1 => 1.0,
        2 => 2.0,
        3 => 3.0,
        _ => 100.0,
      };
      final ratio = math.min(
        wanted,
        math.min(
          maxSide / math.max(size.width, size.height),
          math.sqrt(maxPixels / (size.width * size.height)),
        ),
      );
      final image = await boundary.toImage(pixelRatio: ratio);
      final px = '${image.width}×${image.height} px';
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) throw StateError('Không tạo được ảnh');
      var bytes = data.buffer.asUint8List();
      if (opts.pdf) bytes = await pngToPdf(bytes, size);
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        progressOpen = false;
      }
      final stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
      final ext = opts.pdf ? 'pdf' : 'png';
      final saved = await saveFileWithPicker(
        fileName: 'pha-do-$stamp.$ext',
        bytes: bytes,
        extensions: [ext],
        dialogTitle: 'Chọn nơi lưu phả đồ',
      );
      message = saved ? 'Đã lưu phả đồ ($px)' : 'Đã hủy, chưa lưu file';
    } catch (e) {
      message = 'Không xuất được: $e';
    } finally {
      if (progressOpen && mounted) Navigator.of(context, rootNavigator: true).pop();
    }
    _toast(message);
  }

  @override
  Widget build(BuildContext context) {
    final family = ref.watch(familyProvider);
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final layers = ref.watch(phaDoLayersProvider).valueOrNull ?? const <PhaDoLayer>[];
    return Scaffold(
      appBar: GoldAppBar(
        title: 'Phả đồ',
        actions: [
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Tùy chọn phả đồ',
            onSelected: (v) {
              switch (v) {
                case 'decor':
                  context.push('/tree/decor${_rootId == null ? '' : '?root=$_rootId'}');
                case 'groups':
                  _editGroups();
                case 'export':
                  _export();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'decor',
                child: ListTile(
                  leading: Icon(Icons.palette_outlined),
                  title: Text('Trang trí phả đồ'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'groups',
                child: ListTile(
                  leading: Icon(Icons.view_agenda_outlined),
                  title: Text('Gộp đời vào một hàng'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.ios_share),
                  title: Text('Xuất ảnh / PDF'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: ColoredBox(
        color: AppColors.paperDark,
        child: family.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Lỗi: $e')),
          data: (d) {
            final model = PhaDoModel.build(d, settings, _rootId);
            _model = model;
            if (model == null) {
              return const Center(child: Text('Chưa có thành viên để hiển thị'));
            }
            final size = model.size;
            final portrait = MediaQuery.orientationOf(context) == Orientation.portrait;
            // Phả đồ nằm ngang (rộng hơn cao) thì xoay dọc để lấp đầy màn hình điện thoại.
            final rotated = _rotated ?? (portrait && size.width > size.height);
            return Stack(
              children: [
                Positioned.fill(
                  child: _ZoomableCanvas(
                    key: _viewerKey,
                    size: size,
                    rotated: rotated,
                    child: RotatedBox(
                      quarterTurns: rotated ? 1 : 0,
                      child: RepaintBoundary(
                        key: _canvasKey,
                        child: PhaDoCanvas(
                          layout: model.layout,
                          data: d,
                          generations: model.generations,
                          rows: model.rows,
                          clanName: settings.clanName,
                          place: settings.clanPlace,
                          onOpenPerson: (id) => context.push('/person/$id'),
                          layers: layers,
                          showFrame: settings.phadoFrame,
                          showBanner: settings.phadoBanner,
                          showWatermark: settings.phadoWatermark,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.small(
                        heroTag: null,
                        tooltip: rotated ? 'Xoay ngang phả đồ' : 'Xoay dọc phả đồ',
                        backgroundColor: AppColors.card,
                        foregroundColor: AppColors.redDark,
                        onPressed: () => setState(() => _rotated = !rotated),
                        child: const Icon(Icons.screen_rotation),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: null,
                        tooltip: 'Vừa khung nhìn',
                        backgroundColor: AppColors.card,
                        foregroundColor: AppColors.redDark,
                        onPressed: () => _viewerKey.currentState?.fit(),
                        child: const Icon(Icons.fit_screen),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ExportOptions {
  const _ExportOptions({required this.pdf, required this.quality});

  final bool pdf;

  /// 1, 2, 3 = hệ số phóng; 0 = tối đa.
  final int quality;
}

class _ExportDialog extends StatefulWidget {
  const _ExportDialog();

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  bool _pdf = false;
  int _quality = 2;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Xuất phả đồ'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Ảnh PNG'), icon: Icon(Icons.image)),
                ButtonSegment(value: true, label: Text('PDF'), icon: Icon(Icons.picture_as_pdf)),
              ],
              selected: {_pdf},
              onSelectionChanged: (s) => setState(() => _pdf = s.first),
            ),
            const SizedBox(height: 12),
            const Text('Độ phân giải', style: TextStyle(fontWeight: FontWeight.w600)),
            Wrap(
              spacing: 8,
              children: [
                for (final (value, label) in const [
                  (1, 'Chuẩn x1'),
                  (2, 'Cao x2'),
                  (3, 'Rất cao x3'),
                  (0, 'Tối đa'),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _quality == value,
                    onSelected: (_) => setState(() => _quality = value),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Phả đồ lớn sẽ tự giảm độ phân giải để không làm tràn bộ nhớ.',
              style: TextStyle(fontSize: 12, color: AppColors.goldDark),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _ExportOptions(pdf: _pdf, quality: _quality)),
          child: const Text('Xuất'),
        ),
      ],
    );
  }
}

/// Phóng to/thu nhỏ không giới hạn bằng hai ngón (hoặc con lăn chuột), kéo thả tự do.
/// Lúc đầu (và mỗi khi đổi hướng xoay) tự vừa chiều rộng khung nhìn.
/// [size] là kích thước phả đồ chưa xoay; [rotated] = true khi [child] đã xoay 90°.
class _ZoomableCanvas extends StatefulWidget {
  const _ZoomableCanvas({
    super.key,
    required this.size,
    required this.rotated,
    required this.child,
  });

  final Size size;
  final bool rotated;
  final Widget child;

  @override
  State<_ZoomableCanvas> createState() => _ZoomableCanvasState();
}

class _ZoomableCanvasState extends State<_ZoomableCanvas> {
  final _controller = TransformationController();
  Size _viewport = Size.zero;
  bool? _fittedRotated;
  Size? _fittedSize;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Size get _display =>
      widget.rotated ? Size(widget.size.height, widget.size.width) : widget.size;

  /// Thu phóng cho vừa chiều rộng khung nhìn, căn giữa.
  void fit() {
    final v = _viewport;
    final d = _display;
    if (v.isEmpty || d.isEmpty) return;
    final s = (v.width / d.width).clamp(0.001, 8.0).toDouble();
    final dx = (v.width - d.width * s) / 2;
    final dy = math.max(0.0, (v.height - d.height * s) / 2);
    // Ma trận (cột chính): tỉ lệ s rồi tịnh tiến (dx, dy).
    _controller.value = Matrix4(
      s, 0, 0, 0, //
      0, s, 0, 0, //
      0, 0, 1, 0, //
      dx, dy, 0, 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.hasBoundedWidth && constraints.hasBoundedHeight) {
          _viewport = constraints.biggest;
          if (_fittedRotated != widget.rotated || _fittedSize != widget.size) {
            _fittedRotated = widget.rotated;
            _fittedSize = widget.size;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) fit();
            });
          }
        }
        return InteractiveViewer(
          transformationController: _controller,
          constrained: false,
          // Zoom vào không giới hạn; thu nhỏ xuống rất nhỏ; kéo ra ngoài biên tự do.
          minScale: 0.001,
          maxScale: double.infinity,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          child: widget.child,
        );
      },
    );
  }
}
