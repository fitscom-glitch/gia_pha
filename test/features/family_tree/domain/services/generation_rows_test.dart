import 'package:flutter_test/flutter_test.dart';
import 'package:gia_pha/features/family_tree/domain/services/generation_rows.dart';

void main() {
  group('parseGenerationGroups', () {
    test('đọc nhiều nhóm, có hoặc không có đời đại diện', () {
      final g = parseGenerationGroups('2-5:3; 8-9');
      expect(g.length, 2);
      expect([g[0].from, g[0].to, g[0].representative], [2, 5, 3]);
      expect([g[1].from, g[1].to, g[1].representative], [8, 9, null]);
    });

    test('đời đại diện nằm ngoài nhóm thì bỏ qua', () {
      expect(parseGenerationGroups('2-5:9').single.representative, isNull);
    });

    test('bỏ qua phần không hợp lệ', () {
      final g = parseGenerationGroups('abc; 5-3; 0-2; 3-4');
      expect(g.map((e) => [e.from, e.to]), [[3, 4]]);
      expect(parseGenerationGroups(''), isEmpty);
    });

    test('ghi lại thành chuỗi', () {
      expect(
        formatGenerationGroups(const [GenerationGroup(2, 5, 3), GenerationGroup(8, 9)]),
        '2-5:3; 8-9',
      );
    });
  });

  group('buildGenerationRows', () {
    test('không gộp: mỗi đời một hàng', () {
      expect(buildGenerationRows(3, const []), [[1], [2], [3]]);
    });

    test('gộp đời 2-5 vào một hàng', () {
      expect(
        buildGenerationRows(8, const [GenerationGroup(2, 5)]),
        [[1], [2, 3, 4, 5], [6], [7], [8]],
      );
    });

    test('nhóm vượt quá số đời hiện có thì cắt bớt', () {
      expect(buildGenerationRows(4, const [GenerationGroup(3, 9)]), [[1], [2], [3, 4]]);
    });
  });

  test('đời bị ẩn khi nhóm có đời đại diện khác', () {
    const groups = [GenerationGroup(2, 5, 3), GenerationGroup(8, 9)];
    expect(isGenerationHidden(1, groups), isFalse);
    expect(isGenerationHidden(2, groups), isTrue);
    expect(isGenerationHidden(3, groups), isFalse);
    expect(isGenerationHidden(5, groups), isTrue);
    expect(isGenerationHidden(8, groups), isFalse); // nhóm không có đại diện: hiển thị hết
  });

  test('nhãn hàng', () {
    expect(generationRowLabel([7]), 'ĐỜI THỨ 7');
    expect(generationRowLabel([2, 3, 4, 5]), 'ĐỜI THỨ 2,3,4,5');
    expect(generationRowLabel([2, 3, 4, 5, 6, 7]), 'ĐỜI THỨ 2–7');
  });
}
