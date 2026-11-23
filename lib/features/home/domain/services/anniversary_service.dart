import 'package:gia_pha/core/utils/lunar_calendar.dart';
import 'package:gia_pha/features/events/domain/entities/custom_event.dart';
import 'package:gia_pha/features/members/domain/entities/family_data.dart';

enum AnniversaryType { birthday, deathAnniversary, festival, custom }

class Anniversary {
  const Anniversary({
    required this.type,
    required this.date,
    required this.title,
    required this.subtitle,
    this.personId,
    this.event,
  });

  final AnniversaryType type;

  /// Ngày dương lịch (UTC, chỉ có ngày).
  final DateTime date;
  final String title;
  final String subtitle;
  final String? personId;

  /// Có giá trị nếu là ngày kỷ niệm người dùng tự nhập (để sửa/xóa).
  final CustomEvent? event;
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

DateTime _utc(DateTime d) => DateTime.utc(d.year, d.month, d.day);

/// Mọi ngày kỷ niệm trong khoảng [from]..[to] (gồm cả hai đầu), theo thứ tự thời gian:
/// sinh nhật (dương lịch, người còn sống), ngày giỗ (âm lịch, người đã mất),
/// lễ quan trọng và các ngày do người dùng tự nhập ([events]).
List<Anniversary> anniversariesBetween(
  FamilyData data,
  DateTime from,
  DateTime to, {
  List<CustomEvent> events = const [],
}) {
  final start = _utc(from);
  final end = _utc(to);
  bool inRange(DateTime d) => !d.isBefore(start) && !d.isAfter(end);
  final out = <Anniversary>[];

  for (final p in data.persons) {
    final b = p.birthDate;
    if (b != null && p.deathDate == null) {
      for (var year = start.year; year <= end.year; year++) {
        final age = year - b.year;
        if (age < 1) continue;
        final day = (b.month == 2 && b.day == 29 && !_isLeapYear(year)) ? 28 : b.day;
        final d = DateTime.utc(year, b.month, day);
        if (inRange(d)) {
          out.add(Anniversary(
            type: AnniversaryType.birthday,
            date: d,
            title: p.fullName,
            subtitle: 'Sinh nhật · tròn $age tuổi',
            personId: p.id,
          ));
        }
      }
    }

    final death = p.deathDate;
    if (death != null) {
      final lunar = LunarCalendar.fromSolar(death);
      for (var ly = start.year - 1; ly <= end.year + 1; ly++) {
        final n = ly - lunar.year;
        if (n < 1) continue;
        final s = LunarCalendar.toSolar(lunar.day, lunar.month, ly);
        if (s == null) continue;
        final d = _utc(s);
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
    for (var ly = start.year - 1; ly <= end.year + 1; ly++) {
      final s = LunarCalendar.toSolar(day, month, ly);
      if (s == null) continue;
      final d = _utc(s);
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

  for (final e in events) {
    void add(DateTime d, int n) {
      if (!inRange(d)) return;
      final note = e.note?.trim() ?? '';
      final parts = [
        if (e.repeatYearly && n >= 1) 'Lần thứ $n',
        if (e.isLunar) '${e.day}/${e.month} ÂL',
        if (note.isNotEmpty) note,
      ];
      out.add(Anniversary(
        type: AnniversaryType.custom,
        date: d,
        title: e.title,
        subtitle: parts.isEmpty ? 'Ngày kỷ niệm' : parts.join(' · '),
        event: e,
      ));
    }

    if (e.isLunar) {
      final years = e.repeatYearly
          ? [for (var y = start.year - 1; y <= end.year + 1; y++) y]
          : [e.year];
      for (final ly in years) {
        final s = LunarCalendar.toSolar(e.day, e.month, ly);
        if (s != null) add(_utc(s), ly - e.year);
      }
    } else {
      final years = e.repeatYearly
          ? [for (var y = start.year; y <= end.year; y++) y]
          : [e.year];
      for (final y in years) {
        final day = (e.month == 2 && e.day == 29 && !_isLeapYear(y)) ? 28 : e.day;
        final d = DateTime.utc(y, e.month, day);
        if (d.month == e.month && d.day == day) add(d, y - e.year);
      }
    }
  }

  out.sort((a, b) {
    final c = a.date.compareTo(b.date);
    return c != 0 ? c : a.title.compareTo(b.title);
  });
  return out;
}

/// Các ngày kỷ niệm sắp tới trong [withinDays] ngày kể từ [now].
List<Anniversary> upcomingAnniversaries(
  FamilyData data,
  DateTime now, {
  int withinDays = 365,
  int limit = 30,
  List<CustomEvent> events = const [],
}) {
  final today = _utc(now);
  return anniversariesBetween(
    data,
    today,
    today.add(Duration(days: withinDays)),
    events: events,
  ).take(limit).toList();
}
