import 'package:flutter/painting.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';

/// Màu thẻ theo đời (0 = đời đầu) và giới: mỗi đời lệch nhẹ về sắc độ và độ sáng.
/// Nam: cam – vàng đất. Nữ: hồng – tím nhạt.
Color generationFill(int generation, Gender gender) {
  final g = generation < 0 ? 0 : generation;
  switch (gender) {
    case Gender.male:
      return HSLColor.fromAHSL(1, 22.0 + (g * 5) % 30, 0.88, 0.58 + ((g * 3) % 5) * 0.02)
          .toColor();
    case Gender.female:
      return HSLColor.fromAHSL(1, 318.0 + (g * 6) % 24, 0.62, 0.84 + ((g * 2) % 4) * 0.02)
          .toColor();
    case Gender.other:
      return HSLColor.fromAHSL(1, 45.0 + (g * 4) % 20, 0.35, 0.80 + ((g * 2) % 3) * 0.02)
          .toColor();
  }
}
