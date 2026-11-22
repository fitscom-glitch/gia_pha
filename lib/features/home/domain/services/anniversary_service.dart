import 'package:gia_pha/core/utils/lunar_calendar.dart';
import 'package:gia_pha/features/members/domain/entities/family_data.dart';

enum AnniversaryType { birthday, deathAnniversary, festival }

class Anniversary {
  const Anniversary({
    required this.type,
    required this.date,
    required this.title,
    required this.subtitle,
    this.personId,
  });

  final AnniversaryType type;

  /// Ngày dương lịch (UTC, chỉ có ngày).
  final DateTime date;
  final String title;
  final String subtitle;
  final String? personId;
}

/// Lễ quan trọng theo âm lịch: (ngày, tháng, tên).
const _festivals = [
  (1, 1, 'Tết Nguyên Đán'),
  (15, 1, 'Rằm tháng Giêng'),
  (10, 3, 'Giỗ Tổ Hùng Vương'),
  (15, 7, 'Lễ Vu Lan'),
  (15, 8, 'Tết Trung Thu'),
  (23, 12, 'Ông Công, Ông Táo'),
];

bool _isLeapYear(int y) => (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;

/// Sinh nhật (dương lịch, người còn sống), ngày giỗ (âm lịch, người đã mất) và
/// lễ quan trọng, trong [withinDays] ngày kể từ [now], theo thứ tự thời gian.
List<Anniversary> upcomingAnniversaries(
  FamilyData data,
  DateTime now, {
  int withinDays = 365,
  int limit = 30,
}) {
  final today = DateTime.utc(now.year, now.month, now.day);
  final end = today.add(Duration(days: withinDays));
  bool inRange(DateTime d) => !d.isBefore(today) && !d.isAfter(end);
  final out = <Anniversary>[];

  for (final p in data.persons) {
    final b = p.birthDate;
    if (b != null && p.deathDate == null) {
      for (final year in [today.year, today.year + 1]) {
        final day = (b.month == 2 && b.day == 29 && !_isLeapYear(year)) ? 28 : b.day;
        final d = DateTime.utc(year, b.month, day);
        if (inRange(d)) {
          out.add(Anniversary(
            type: AnniversaryType.birthday,
            date: d,
            title: p.fullName,
            subtitle: 'Sinh nhật · tròn ${year - b.year} tuổi',
            personId: p.id,
          ));
          break;
        }
      }
    }

    final death = p.deathDate;
    if (death != null) {
      final lunar = LunarCalendar.fromSolar(death);
      for (final ly in [today.year - 1, today.year, today.year + 1]) {
        final n = ly - lunar.year;
        if (n < 1) continue;
        final s = LunarCalendar.toSolar(lunar.day, lunar.month, ly);
        if (s == null) continue;
        final d = DateTime.utc(s.year, s.month, s.day);
        if (inRange(d)) {
          out.add(Anniversary(
            type: AnniversaryType.deathAnniversary,
            date: d,
            title: p.fullName,
            subtitle: 'Ngày giỗ lần thứ $n · ${lunar.day}/${lunar.month} ÂL',
            personId: p.id,
          ));
        }
      }
    }
  }

  for (final (day, month, name) in _festivals) {
    for (final ly in [today.year - 1, today.year, today.year + 1]) {
      final s = LunarCalendar.toSolar(day, month, ly);
      if (s == null) continue;
      final d = DateTime.utc(s.year, s.month, s.day);
      if (inRange(d)) {
        out.add(Anniversary(
          type: AnniversaryType.festival,
          date: d,
          title: name,
          subtitle: 'Lễ · $day/$month ÂL',
        ));
      }
    }
  }

  out.sort((a, b) {
    final c = a.date.compareTo(b.date);
    return c != 0 ? c : a.title.compareTo(b.title);
  });
  return out.take(limit).toList();
}
