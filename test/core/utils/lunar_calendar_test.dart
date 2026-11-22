import 'package:flutter_test/flutter_test.dart';
import 'package:gia_pha/core/utils/lunar_calendar.dart';

void main() {
  group('LunarCalendar.fromSolar', () {
    void expectLunar(DateTime solar, int d, int m, int y, {bool leap = false}) {
      final l = LunarCalendar.fromSolar(solar);
      expect([l.day, l.month, l.year, l.isLeap], [d, m, y, leap], reason: '$solar');
    }

    test('mùng 1 Tết các năm', () {
      expectLunar(DateTime(2023, 1, 22), 1, 1, 2023);
      expectLunar(DateTime(2024, 2, 10), 1, 1, 2024);
      expectLunar(DateTime(2025, 1, 29), 1, 1, 2025);
      expectLunar(DateTime(2026, 2, 17), 1, 1, 2026);
    });

    test('ngày thường', () {
      expectLunar(DateTime(2025, 3, 16), 17, 2, 2025);
      expectLunar(DateTime(2000, 1, 1), 25, 11, 1999);
    });

    test('tháng nhuận', () {
      expectLunar(DateTime(2023, 3, 22), 1, 2, 2023, leap: true);
    });
  });

  group('LunarCalendar.toSolar', () {
    test('đổi ngược về dương lịch', () {
      expect(LunarCalendar.toSolar(17, 2, 2025), DateTime.utc(2025, 3, 16));
      expect(LunarCalendar.toSolar(1, 1, 2026), DateTime.utc(2026, 2, 17));
    });

    test('tháng nhuận không tồn tại thì trả về null', () {
      expect(LunarCalendar.toSolar(1, 5, 2025, isLeap: true), isNull);
    });

    test('đổi đi đổi lại đúng với mọi ngày trong năm 2024', () {
      var d = DateTime.utc(2024, 1, 1);
      while (d.year == 2024) {
        final l = LunarCalendar.fromSolar(d);
        final back = LunarCalendar.toSolar(l.day, l.month, l.year, isLeap: l.isLeap);
        expect(back, d, reason: 'ngày $d');
        d = d.add(const Duration(days: 1));
      }
    });
  });

  test('tên năm can chi', () {
    expect(LunarCalendar.yearName(2025), 'Ất Tỵ');
    expect(LunarCalendar.yearName(2026), 'Bính Ngọ');
  });
}
