import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
import 'package:gia_pha/core/widgets/gold_app_bar.dart';
import 'package:gia_pha/core/widgets/ornaments/ornaments.dart';
import 'package:gia_pha/features/articles/domain/entities/article.dart';
import 'package:gia_pha/features/articles/presentation/providers/article_providers.dart';
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
  final _intro = TextEditingController();
  bool _loaded = false;

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
          _intro.text = s.clanIntro;
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _intro.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveInfo() async {
    await ref.read(settingsProvider.notifier).save(
          AppSettings(clanName: _name.text.trim(), clanIntro: _intro.text.trim()),
        );
    _toast('Đã lưu thông tin dòng họ');
  }

  Future<void> _export() async {
    final json = await ref.read(backupRepositoryProvider).exportJson();
    await Clipboard.setData(ClipboardData(text: json));
    _toast('Đã sao chép ${json.length} ký tự. Hãy dán vào một ghi chú hoặc tin nhắn để cất giữ.');
  }

  Future<void> _import() async {
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clip?.text?.trim() ?? '';
    if (text.isEmpty) {
      _toast('Bộ nhớ tạm đang trống. Hãy sao chép nội dung sao lưu trước.');
      return;
    }
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Khôi phục dữ liệu?'),
        content: const Text(
          'Toàn bộ dữ liệu hiện có sẽ bị thay thế bằng nội dung sao lưu. '
          'Ảnh di sản không nằm trong bản sao lưu.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Khôi phục')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(backupRepositoryProvider).importJson(text);
    } on FormatException catch (e) {
      _toast(e.message);
      return;
    }
    ref
      ..invalidate(familyProvider)
      ..invalidate(settingsProvider)
      ..invalidate(honorsProvider)
      ..invalidate(heirloomsProvider);
    for (final kind in ArticleKind.values) {
      ref.invalidate(articlesProvider(kind));
    }
    _loaded = false;
    _toast('Đã khôi phục dữ liệu');
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
                    controller: _intro,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Lời giới thiệu ngắn',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(onPressed: _saveInfo, child: const Text('Lưu')),
                  ),
                ],
              ),
            ),
            const _SectionLabel('Sao lưu & khôi phục'),
            OrnateCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.copy_all, color: AppColors.red),
                    title: const Text('Sao chép dữ liệu (JSON)'),
                    subtitle: const Text('Thành viên, quan hệ, tư liệu, vinh danh...'),
                    onTap: _export,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.restore, color: AppColors.red),
                    title: const Text('Khôi phục từ bộ nhớ tạm'),
                    subtitle: const Text('Dán nội dung đã sao lưu rồi bấm vào đây'),
                    onTap: _import,
                  ),
                ],
              ),
            ),
            const _SectionLabel('Giới thiệu'),
            const OrnateCard(
              child: Text(
                'Gia phả · phiên bản 0.1.0\nDữ liệu lưu trên máy này. '
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
