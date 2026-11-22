import 'package:flutter_test/flutter_test.dart';
import 'package:gia_pha/features/home/domain/services/anniversary_service.dart';
import 'package:gia_pha/features/members/domain/entities/family_data.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';

void main() {
  final data = FamilyData([
    Person(
      id: 'a',
      fullName: 'Cụ A',
      birthDate: DateTime(1940, 1, 1),
      deathDate: DateTime(2015, 3, 16), // âm lịch 26/1/2015
    ),
    Person(id: 'b', fullName: 'Bé B', birthDate: DateTime(1990, 3, 20)),
  ], const []);

  final list = upcomingAnniversaries(data, DateTime(2025, 2, 1));

  test('ngày giỗ tính theo âm lịch, đúng lần thứ mấy', () {
    final death = list.firstWhere((a) => a.type == AnniversaryType.deathAnniversary);
    expect(death.title, 'Cụ A');
    expect(death.date, DateTime.utc(2025, 2, 23));
    expect(death.subtitle, contains('lần thứ 10'));
  });

  test('sinh nhật tính theo dương lịch, chỉ cho người còn sống', () {
    final birthdays = list.where((a) => a.type == AnniversaryType.birthday).toList();
    expect(birthdays.length, 1);
    expect(birthdays.first.title, 'Bé B');
    expect(birthdays.first.date, DateTime.utc(2025, 3, 20));
    expect(birthdays.first.subtitle, contains('35 tuổi'));
  });

  test('có lễ quan trọng theo âm lịch', () {
    final names = {for (final a in list.where((a) => a.type == AnniversaryType.festival)) a.title: a.date};
    expect(names['Rằm tháng Giêng'], DateTime.utc(2025, 2, 12));
    expect(names['Giỗ Tổ Hùng Vương'], DateTime.utc(2025, 4, 7));
  });

  test('sắp xếp theo thời gian và không có ngày đã qua', () {
    final today = DateTime.utc(2025, 2, 1);
    for (var i = 0; i < list.length; i++) {
      expect(list[i].date.isBefore(today), isFalse);
      if (i > 0) expect(list[i].date.isBefore(list[i - 1].date), isFalse);
    }
  });
}
