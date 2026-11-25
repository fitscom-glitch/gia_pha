import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
import 'package:gia_pha/core/widgets/gold_app_bar.dart';
import 'package:gia_pha/core/widgets/ornaments/ornaments.dart';
import 'package:gia_pha/features/members/domain/services/family_stats.dart';
import 'package:gia_pha/features/members/presentation/providers/family_providers.dart';

/// Thống kê gia phả: số đời, số người, nam/nữ, còn sống/đã mất, con cháu trực hệ.
class FamilyStatsPage extends ConsumerWidget {
  const FamilyStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final family = ref.watch(familyProvider);
    return Scaffold(
      appBar: const GoldAppBar(title: 'Thống kê'),
      body: PatternBackground(
        child: family.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Lỗi: $e')),
          data: (d) {
            final s = computeFamilyStats(d);
            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                const _SectionTitle('Toàn gia phả'),
                _Grid([
                  _Stat('Tổng số đời', s.generations),
                  _Stat('Tổng số người', s.total),
                  _Stat('Nam', s.male),
                  _Stat('Nữ', s.female),
                  if (s.unknownGender > 0) _Stat('Chưa rõ giới tính', s.unknownGender),
                  _Stat('Còn sống', s.alive),
                  _Stat('Đã mất', s.deceased),
                ]),
                const SizedBox(height: 16),
                const _SectionTitle('Con cháu trực hệ'),
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Text(
                    'Hậu duệ huyết thống của đời đầu tiên, không tính dâu, rể.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.goldDark),
                  ),
                ),
                _Grid([
                  _Stat('Tổng con cháu', s.directTotal),
                  _Stat('Con cháu trai', s.directMale),
                  _Stat('Con cháu gái', s.directFemale),
                  if (s.directUnknownGender > 0)
                    _Stat('Chưa rõ giới tính', s.directUnknownGender),
                ]),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value);

  final String label;
  final int value;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'serif',
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: AppColors.redDark,
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid(this.stats);

  final List<_Stat> stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.9,
      children: [
        for (final s in stats)
          OrnateCard(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  s.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.ink),
                ),
                Text(
                  '${s.value}',
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontWeight: FontWeight.w700,
                    fontSize: 30,
                    height: 1.15,
                    color: AppColors.red,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
