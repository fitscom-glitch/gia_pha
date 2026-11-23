import 'package:flutter_test/flutter_test.dart';
import 'package:gia_pha/features/family_tree/domain/services/generation_rows.dart';

void main() {
  group('parseGenerationGroups', () {
    test('đọc nhiều nhóm', () {
      expect(parseGenerationGroups('2-5; 8-9'), [(2, 5), (8, 9)]);
    });

    test('bỏ qua phần không hợp lệ', () {
      expect(parseGenerationGroups('abc; 5-3; 0-2; 3-4'), [(3, 4)]);
      expect(parseGenerationGroups(''), isEmpty);
    });
  });

  group('buildGenerationRows', () {
    test('không gộp: mỗi đời một hàng', () {
      expect(buildGenerationRows(3, const []), [[1], [2], [3]]);
    });

    test('gộp đời 2-5 vào một hàng', () {
      expect(
        buildGenerationRows(8, const [(2, 5)]),
        [[1], [2, 3, 4, 5], [6], [7], [8]],
      );
    });

    test('nhóm vượt quá số đời hiện có thì cắt bớt', () {
      expect(buildGenerationRows(4, const [(3, 9)]), [[1], [2], [3, 4]]);
    });
  });

  test('nhãn hàng', () {
    expect(generationRowLabel([7]), 'ĐỜI THỨ 7');
    expect(generationRowLabel([2, 3, 4, 5]), 'ĐỜI THỨ 2,3,4,5');
    expect(generationRowLabel([2, 3, 4, 5, 6, 7]), 'ĐỜI THỨ 2–7');
  });
}
