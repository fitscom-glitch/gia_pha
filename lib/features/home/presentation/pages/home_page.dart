import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
import 'package:gia_pha/core/widgets/gold_app_bar.dart';
import 'package:gia_pha/core/widgets/ornaments/ornaments.dart';
import 'package:gia_pha/features/home/domain/services/anniversary_service.dart';
import 'package:gia_pha/features/home/presentation/widgets/home_widgets.dart';
import 'package:gia_pha/features/members/presentation/providers/family_providers.dart';
import 'package:gia_pha/features/settings/presentation/providers/settings_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(familyProvider).valueOrNull;
    final settings = ref.watch(settingsProvider).valueOrNull;
    final now = DateTime.now();
    final anniversaries = data == null
        ? const <Anniversary>[]
        : upcomingAnniversaries(data, now, limit: 8);

    return Scaffold(
      appBar: const GoldAppBar(title: 'Trang chủ'),
      body: PatternBackground(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _ClanTitle(
              name: (settings?.clanName ?? '').trim(),
              intro: (settings?.clanIntro ?? '').trim(),
            ),
            HomeBannerCarousel(memberCount: data?.persons.length ?? 0),
            const _FeatureGrid(),
            _StatCards(
              members: data?.persons.length ?? 0,
              generations: data?.generationCount ?? 0,
            ),
            HomeDateCard(now: now),
            HomeAnniversarySection(items: anniversaries, today: now),
          ],
        ),
      ),
    );
  }
}

class _ClanTitle extends StatelessWidget {
  const _ClanTitle({required this.name, required this.intro});

  final String name;
  final String intro;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        children: [
          if (name.isEmpty)
            TextButton.icon(
              onPressed: () => context.go('/settings'),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Đặt tên dòng họ'),
            )
          else
            Text(
              'GIA TỘC ${name.toUpperCase()}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'serif',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: 1,
                color: AppColors.red,
              ),
            ),
          if (intro.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                intro,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                  color: AppColors.goldDark,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  static const _items = [
    (Icons.menu_book, 'Lịch sử\ndòng họ', '/articles/history'),
    (Icons.emoji_events, 'Bảng\nvinh danh', '/honors'),
    (Icons.museum, 'Di sản &\nKỷ vật', '/heirlooms'),
    (Icons.auto_stories, 'Chuyện\ncổ kim', '/articles/stories'),
    (Icons.spa, 'Tộc ước &\nHương lễ', '/articles/rules'),
    (Icons.contacts, 'Danh bạ', '/contacts'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.12,
        children: [
          for (final (icon, label, route) in _items)
            OrnateCard(
              padding: const EdgeInsets.all(6),
              onTap: () => context.push(route),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 30, color: AppColors.red),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: AppColors.redDark,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCards extends StatelessWidget {
  const _StatCards({required this.members, required this.generations});

  final int members;
  final int generations;

  @override
  Widget build(BuildContext context) {
    Widget card(String label, int value) => Expanded(
          child: OrnateCard(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Text(label, style: const TextStyle(fontSize: 13, color: AppColors.ink)),
                Text(
                  '$value',
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontWeight: FontWeight.w700,
                    fontSize: 30,
                    color: AppColors.red,
                  ),
                ),
              ],
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          card('Thành viên', members),
          const SizedBox(width: 8),
          card('Số đời', generations),
        ],
      ),
    );
  }
}
