import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
import 'package:gia_pha/core/widgets/gold_app_bar.dart';
import 'package:gia_pha/core/widgets/ornaments/ornaments.dart';
import 'package:gia_pha/features/articles/domain/entities/article.dart';
import 'package:gia_pha/features/articles/presentation/providers/article_providers.dart';
import 'package:gia_pha/features/events/presentation/providers/event_providers.dart';
import 'package:gia_pha/features/heirlooms/presentation/providers/heirloom_providers.dart';
import 'package:gia_pha/features/honors/presentation/providers/honor_providers.dart';
import 'package:gia_pha/features/members/presentation/providers/family_providers.dart';
import 'package:gia_pha/features/settings/domain/entities/app_settings.dart';
import 'package:gia_pha/features/settings/presentation/providers/settings_providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _name = TextEditingController();
  final _place = TextEditingController();
  final _intro = TextEditingController();
  final _groups = TextEditingController();
  bool _loaded = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual<AsyncValue<AppSettings>>(
      settingsProvider,
      (_, next) {
        final s = next.valueOrNull;
        if (s != null && !_loaded) {
          _loaded = true;
          _name.text = s.clanName;
          _place.text = s.clanPlace;
          _intro.text = s.clanIntro;
          _groups.text = s.generationGroups;
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _place.dispose();
    _intro.dispose();
    _groups.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveInfo() async {
    await ref.read(settingsProvider.notifier).save(
          (ref.read(settingsProvider).valueOrNull ?? const AppSettings()).copyWith(
            clanName: _name.text.trim(),
            clanPlace: _place.text.trim(),
            clanIntro: _intro.text.trim(),
            generationGroups: _groups.text.trim(),
          ),
        );
    _toast('Đã lưu cài đặt');
  }

  /// Gói dữ liệu + hình ảnh thành file .zip và cho chọn nơi lưu trong máy.
  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final bytes = await ref.read(backupRepositoryProvider).exportArchive();
      final name = 'gia-pha-${DateFormat('yyyyMMdd-HHmm').format(DateTime.now())}.zip';
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Chọn nơi lưu bản sao lưu',
        fileName: name,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      _toast(path == null
          ? 'Đã hủy, chưa lưu file'
          : 'Đã lưu bản sao lưu (${(bytes.length / 1048576).toStringAsFixed(1)} MB)');
    } catch (e) {
      _toast('Không lưu được: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
    final file = result?.files.single;
    if (file == null) return;
    final bytes = file.bytes;
    if (bytes == null) {
      _toast('Không đọc được file đã chọn');
      return;
    }
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Khôi phục dữ liệu?'),
        content: Text(
          'Toàn bộ dữ liệu hiện có sẽ bị thay thế bằng nội dung file "${file.name}" '
          '(gồm cả hình ảnh).',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Khôi phục')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(backupRepositoryProvider).importArchive(bytes);
      _loaded = false;
      ref
        ..invalidate(familyProvider)
        ..invalidate(settingsProvider)
        ..invalidate(honorsProvider)
        ..invalidate(heirloomsProvider)
        ..invalidate(eventsProvider);
      for (final kind in ArticleKind.values) {
        ref.invalidate(articlesProvider(kind));
      }
      _toast('Đã khôi phục dữ liệu');
    } on FormatException catch (e) {
      _toast(e.message);
    } catch (e) {
      _toast('Khôi phục thất bại: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GoldAppBar(title: 'Cài đặt'),
      body: PatternBackground(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const _SectionLabel('Thông tin dòng họ'),
            OrnateCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Tên dòng họ (vd: Nguyễn Văn)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _place,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Địa danh (hiện trên phả đồ)',
                      hintText: 'Vd: Đồng Quang, Điện Hòa, Điện Bàn, Quảng Nam',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _intro,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Lời giới thiệu ngắn',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const _SectionLabel('Phả đồ'),
            OrnateCard(
              padding: const EdgeInsets.all(14),
              child: TextField(
                controller: _groups,
                decoration: const InputDecoration(
                  labelText: 'Gộp nhiều đời vào một hàng',
                  hintText: 'Vd: 2-5:3; 8-9',
                  helperText: '2-5:3 = đời 2 đến 5 chung một hàng, chỉ hiển thị đời 3. '
                      '8-9 = gộp đời 8 và 9, hiển thị cả hai. Cũng chỉnh nhanh được trong trang Phả đồ.',
                  helperMaxLines: 4,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OrnateCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.palette_outlined, color: AppColors.red),
                title: const Text('Trang trí phả đồ'),
                subtitle: const Text('Hình nền, họa tiết, băng rôn, biểu ngữ từ file PNG/SVG...'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/tree/decor'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _saveInfo, child: const Text('Lưu cài đặt')),
            ),
            const _SectionLabel('Sao lưu & khôi phục'),
            OrnateCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    enabled: !_busy,
                    leading: const Icon(Icons.save_alt, color: AppColors.red),
                    title: const Text('Lưu ra file (.zip)'),
                    subtitle: const Text('Chọn nơi lưu trong máy. Gồm dữ liệu và cả hình ảnh.'),
                    onTap: _export,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    enabled: !_busy,
                    leading: const Icon(Icons.restore, color: AppColors.red),
                    title: const Text('Khôi phục từ file'),
                    subtitle: const Text('Chọn file .zip đã sao lưu trước đó.'),
                    onTap: _import,
                  ),
                  if (_busy) const LinearProgressIndicator(),
                ],
              ),
            ),
            const _SectionLabel('Giới thiệu'),
            const OrnateCard(
              child: Text(
                'Gia phả · phiên bản 0.3.0\nTác giả dự án: Trung Nguyễn\nDữ liệu lưu trên máy này. '
                'Hãy sao lưu định kỳ để không mất dữ liệu khi đổi máy.',
                style: TextStyle(color: AppColors.ink, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'serif',
          fontWeight: FontWeight.w700,
          fontSize: 17,
          color: AppColors.redDark,
        ),
      ),
    );
  }
}
