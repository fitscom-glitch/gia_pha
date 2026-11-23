import 'package:flutter_test/flutter_test.dart';
import 'package:gia_pha/features/events/domain/entities/custom_event.dart';
import 'package:gia_pha/features/home/domain/services/anniversary_service.dart';
import 'package:gia_pha/features/members/domain/entities/family_data.dart';

CustomEvent _event({
  String title = 'Sự kiện',
  required int day,
  required int month,
  required int year,
  bool lunar = false,
  bool repeat = true,
}) =>
    CustomEvent(
      id: '$title$day$month$year',
      title: title,
      day: day,
      month: month,
      year: year,
      isLunar: lunar,
      repeatYearly: repeat,
      createdAt: DateTime(2020),
    );

void main() {
  const data = FamilyData([], []);
  final today = DateTime(2025, 2, 1);

  List<Anniversary> custom(List<CustomEvent> events) => upcomingAnniversaries(
        data,
        today,
        events: events,
      ).where((a) => a.type == AnniversaryType.custom).toList();

  test('ngày dương lặp hằng năm, tính "lần thứ N"', () {
    final r = custom([_event(title: 'Ngày cưới', day: 5, month: 6, year: 2020)]);
    expect(r.length, 1);
    expect(r.first.date, DateTime.utc(2025, 6, 5));
    expect(r.first.subtitle, contains('Lần thứ 5'));
    expect(r.first.event, isNotNull);
  });

  test('ngày âm lịch lặp hằng năm (15/8 âm lịch = Trung Thu 2025)', () {
    final r = custom([_event(title: 'Rằm', day: 15, month: 8, year: 2000, lunar: true)]);
    expect(r.length, 1);
    expect(r.first.date, DateTime.utc(2025, 10, 6));
    expect(r.first.subtitle, contains('15/8 ÂL'));
  });

  test('sự kiện không lặp: chỉ xuất hiện đúng ngày đó', () {
    final future = _event(title: 'Khánh thành', day: 20, month: 3, year: 2025, repeat: false);
    final past = _event(title: 'Đã qua', day: 20, month: 3, year: 2024, repeat: false);
    final r = custom([future, past]);
    expect(r.map((a) => a.title), ['Khánh thành']);
    expect(r.first.date, DateTime.utc(2025, 3, 20));
  });

  test('anniversariesBetween chỉ trả về ngày trong khoảng', () {
    final list = anniversariesBetween(
      data,
      DateTime(2025, 6, 1),
      DateTime(2025, 6, 30),
      events: [_event(day: 5, month: 6, year: 2020), _event(title: 'Khác', day: 5, month: 7, year: 2020)],
    );
    expect(list.map((a) => a.title), ['Sự kiện']);
  });
}
