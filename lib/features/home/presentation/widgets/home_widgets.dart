import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gia_pha/features/events/presentation/pages/event_sheet.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
import 'package:gia_pha/core/utils/lunar_calendar.dart';
import 'package:gia_pha/core/widgets/dragon_phoenix_banner.dart';
import 'package:gia_pha/core/widgets/ornaments/ornaments.dart';
import 'package:gia_pha/features/home/domain/services/anniversary_service.dart';

/// Băng rôn lướt ngang: rồng phụng + vài câu ca dao về cội nguồn.
class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({super.key, required this.memberCount});

  final int memberCount;

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = <Widget>[
      DragonPhoenixBanner(
        title: 'GIA PHẢ',
        subtitle: '${widget.memberCount} thành viên',
      ),
      const DragonPhoenixBanner(quote: 'Cây có cội,\nnước có nguồn'),
      const DragonPhoenixBanner(quote: 'Uống nước\nnhớ nguồn'),
    ];
    return Column(
      children: [
        SizedBox(
          height: 148,
          child: PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            children: slides,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < slides.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 16 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _page ? AppColors.red : AppColors.gold,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Thẻ ngày dương lịch / âm lịch hôm nay.
class HomeDateCard extends StatelessWidget {
  const HomeDateCard({super.key, required this.now});

  final DateTime now;

  static const _weekdays = [
    'Thứ hai', 'Thứ ba', 'Thứ tư', 'Thứ năm', 'Thứ sáu', 'Thứ bảy', 'Chủ nhật',
  ];

  @override
  Widget build(BuildContext context) {
    final lunar = LunarCalendar.fromSolar(now);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: OrnateCard(
        padding: EdgeInsets.zero,
        onTap: () => context.push('/calendar'),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _DateHalf(
                  header: 'DƯƠNG LỊCH',
                  icon: Icons.wb_sunny,
                  top: 'Tháng ${now.month}',
                  day: '${now.day}',
                  bottom: 'Năm ${now.year}',
                  note: _weekdays[now.weekday - 1],
                ),
              ),
              const VerticalDivider(width: 1, color: AppColors.gold),
              Expanded(
                child: _DateHalf(
                  header: 'ÂM LỊCH',
                  icon: Icons.nightlight_round,
                  top: 'Tháng ${lunar.month}${lunar.isLeap ? ' (nhuận)' : ''}',
                  day: '${lunar.day}',
                  bottom: 'Năm ${LunarCalendar.yearName(lunar.year)}',
                  note: 'Chạm để mở lịch',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateHalf extends StatelessWidget {
  const _DateHalf({
    required this.header,
    required this.icon,
    required this.top,
    required this.day,
    required this.bottom,
    required this.note,
  });

  final String header;
  final IconData icon;
  final String top;
  final String day;
  final String bottom;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.goldLight,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: AppColors.redDark),
              const SizedBox(width: 6),
              Text(
                header,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.redDark,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Text(top, style: const TextStyle(fontSize: 13, color: AppColors.ink)),
              Text(
                day,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w700,
                  fontSize: 36,
                  height: 1.1,
                  color: AppColors.red,
                ),
              ),
              Text(bottom, style: const TextStyle(fontSize: 13, color: AppColors.ink)),
              if (note.isNotEmpty)
                Text(note, style: const TextStyle(fontSize: 12, color: AppColors.goldDark)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Danh sách "Ngày kỷ niệm": sinh nhật, ngày giỗ (âm lịch), lễ quan trọng.
class HomeAnniversarySection extends StatelessWidget {
  const HomeAnniversarySection({super.key, required this.items, required this.today});

  final List<Anniversary> items;
  final DateTime today;

  static Color _tint(AnniversaryType t) => switch (t) {
        AnniversaryType.birthday => AppColors.goldDark,
        AnniversaryType.deathAnniversary => AppColors.ink,
        AnniversaryType.festival => AppColors.red,
        AnniversaryType.custom => const Color(0xFF1E88E5),
      };

  static String _countdown(int days) => switch (days) {
        0 => 'Hôm nay',
        1 => 'Ngày mai',
        _ => 'Còn $days ngày',
      };

  @override
  Widget build(BuildContext context) {
    final base = DateTime.utc(today.year, today.month, today.day);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 0, 4),
            child: Row(
              children: [
                const Text(
                  'Ngày kỷ niệm',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppColors.redDark,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => showEventSheet(context, initialDate: today),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm'),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            const OrnateCard(
              child: Text(
                'Chưa có ngày kỷ niệm sắp tới. Hãy nhập ngày sinh, ngày mất của các thành viên.',
                style: TextStyle(color: AppColors.goldDark),
              ),
            )
          else
            for (final a in items)
              OrnateCard(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                onTap: a.personId != null
                    ? () => context.push('/person/${a.personId}')
                    : a.event != null
                        ? () => showEventSheet(context, event: a.event)
                        : null,
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: _tint(a.type).withAlpha(26),
                        border: Border.all(color: _tint(a.type)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${a.date.day}',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                              height: 1.1,
                              color: _tint(a.type),
                            ),
                          ),
                          Text(
                            'Th${a.date.month}',
                            style: TextStyle(fontSize: 11, color: _tint(a.type)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.title,
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            a.subtitle,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.goldDark),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _countdown(a.date.difference(base).inDays),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.red,
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
