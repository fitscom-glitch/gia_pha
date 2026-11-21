import 'package:flutter_test/flutter_test.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';

void main() {
  group('Person.lifespan', () {
    test('rỗng khi chưa có ngày sinh/mất', () {
      const p = Person(id: '1', fullName: 'A');
      expect(p.lifespan, isEmpty);
      expect(p.isDeceased, isFalse);
    });

    test('chỉ có ngày sinh', () {
      final p = Person(id: '1', fullName: 'A', birthDate: DateTime(1990, 5, 1));
      expect(p.lifespan, 'sinh 1990');
    });

    test('có cả ngày sinh và ngày mất', () {
      final p = Person(
        id: '1',
        fullName: 'A',
        birthDate: DateTime(1950, 1, 1),
        deathDate: DateTime(2020, 2, 2),
      );
      expect(p.lifespan, '1950 – 2020');
      expect(p.isDeceased, isTrue);
    });

    test('có ngày mất nhưng chưa rõ ngày sinh', () {
      final p = Person(id: '1', fullName: 'A', deathDate: DateTime(2020, 2, 2));
      expect(p.lifespan, '? – 2020');
    });
  });
}
