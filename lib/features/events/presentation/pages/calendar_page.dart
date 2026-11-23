import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
import 'package:gia_pha/core/utils/lunar_calendar.dart';
import 'package:gia_pha/core/widgets/gold_app_bar.dart';
import 'package:gia_pha/core/widgets/ornaments/ornaments.dart';
import 'package:gia_pha/features/events/domain/entities/custom_event.dart';
import 'package:gia_pha/features/events/presentation/pages/event_sheet.dart';
import 'package:gia_pha/features/events/presentation/providers/event_providers.dart';
import 'package:gia_pha/features/home/domain/services/anniversary_service.dart';
import 'package:gia_pha/features/members/domain/entities/family_data.dart';
import 'package:gia_pha/features/members/presentation/providers/family_providers.dart';

/// Lịch âm dương theo tháng; chạm vào một ngày để xem và thêm ngày kỷ niệm.
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late DateTime _month;
  late DateTime _selected;

  static const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  static const _weekdayNames = [
    'Thứ hai', 'Thứ ba', 'Thứ tư', 'Thứ năm', 'Thứ sáu', 'Thứ bảy', 'Chủ nhật',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
  }

  void _goMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _selected = DateTime(_month.year, _month.month, 1);
    });
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _month = DateTime(now.year, now.month);
      _selected = DateTime(now.year, now.month, now.day);
    });
  }

  static Color _dot(AnniversaryType t) => switch (t) {
        AnniversaryType.birthday => AppColors.goldDark,
        AnniversaryType.deathAnniversary => AppColors.ink,
        AnniversaryType.festival => AppColors.red,
        AnniversaryType.custom => const Color(0xFF1E88E5),
      };

  static IconData _icon(AnniversaryType t) => switch (t) {
        AnniversaryType.birthday => Icons.cake,
        AnniversaryType.deathAnniversary => Icons.local_florist,
        AnniversaryType.festival => Icons.celebration,
        AnniversaryType.custom => Icons.event,
      };

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(familyProvider).valueOrNull ?? const FamilyData([], []);
    final events = ref.watch(eventsProvider).valueOrNull ?? const <CustomEvent>[];
    final first = DateTime(_month.year, _month.month, 1);
    final daysIn = DateTime(_month.year, _month.month + 1, 0).day;
    final all = anniversariesBetween(
      data,
      first,
      DateTime(_month.year, _month.month, daysIn),
      events: events,
    );
    final byDay = <int, List<Anniversary>>{};
    for (final a in all) {
      byDay.putIfAbsent(a.date.day, () => []).add(a);
    }
    final today = DateTime.now();
    final lead = first.weekday - 1;
    final sel = _selected;
    final selLunar = LunarCalendar.fromSolar(sel);
    final selEvents = sel.year == _month.year && sel.month == _month.month
        ? byDay[sel.day] ?? const <Anniversary>[]
        : const <Anniversary>[];

    return Scaffold(
      appBar: GoldAppBar(
        title: 'Lịch âm dương',
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Hôm nay',
            onPressed: _goToday,
          ),
        ],
      ),
      body: PatternBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _goMonth(-1),
                ),
                Expanded(
                  child: Text(
                    'Tháng ${_month.month} / ${_month.year}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontWeight: FontWeight.w700,
                      fontSize: 19,
                      color: AppColors.redDark,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _goMonth(1),
                ),
              ],
            ),
            OrnateCard(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
              child: Column(
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: Center(
                            child: Text(
                              _weekdays[i],
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: i == 6 ? AppColors.red : AppColors.goldDark,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  GridView.count(
                    crossAxisCount: 7,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 0.78,
                    children: [
                      for (var i = 0; i < lead; i++) const SizedBox.shrink(),
                      for (var d = 1; d <= daysIn; d++)
                        _buildCell(
                          DateTime(_month.year, _month.month, d),
                          byDay[d] ?? const <Anniversary>[],
                          today,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '${_weekdayNames[sel.weekday - 1]}, ${sel.day}/${sel.month}/${sel.year}',
              style: const TextStyle(
                fontFamily: 'serif',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.redDark,
              ),
            ),
            Text(
              'Âm lịch: ${selLunar.day}/${selLunar.month}${selLunar.isLeap ? ' (nhuận)' : ''}'
              ' · năm ${LunarCalendar.yearName(selLunar.year)}',
              style: const TextStyle(color: AppColors.goldDark),
            ),
            const SizedBox(height: 10),
            if (selEvents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Chưa có ngày kỷ niệm nào trong ngày này.',
                  style: TextStyle(color: AppColors.ink),
                ),
              )
            else
              for (final a in selEvents)
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
                      Icon(_icon(a.type), color: _dot(a.type)),
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
                      if (a.event != null)
                        const Icon(Icons.edit, size: 18, color: AppColors.goldDark),
                    ],
                  ),
                ),
            const SizedBox(height: 6),
            FilledButton.icon(
              onPressed: () => showEventSheet(context, initialDate: _selected),
              icon: const Icon(Icons.add),
              label: const Text('Thêm ngày kỷ niệm vào ngày này'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(DateTime day, List<Anniversary> items, DateTime today) {
    final lunar = LunarCalendar.fromSolar(day);
    final isToday = day.year == today.year && day.month == today.month && day.day == today.day;
    final isSel = day.year == _selected.year &&
        day.month == _selected.month &&
        day.day == _selected.day;
    final isSunday = day.weekday == 7;
    final lunarText = lunar.day == 1 ? '${lunar.day}/${lunar.month}' : '${lunar.day}';
    final types = {for (final a in items) a.type}.toList();
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _selected = day),
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: isSel ? AppColors.red : null,
          borderRadius: BorderRadius.circular(8),
          border: isToday ? Border.all(color: AppColors.gold, width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: isSel
                    ? AppColors.goldLight
                    : (isSunday ? AppColors.red : AppColors.ink),
              ),
            ),
            Text(
              lunarText,
              style: TextStyle(
                fontSize: 10.5,
                color: isSel ? AppColors.goldLight : AppColors.goldDark,
              ),
            ),
            SizedBox(
              height: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final t in types.take(3))
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSel ? AppColors.goldLight : _dot(t),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
