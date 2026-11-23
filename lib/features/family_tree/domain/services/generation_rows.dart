/// Đọc cấu hình gộp đời, vd "2-5; 8-9" -> [(2, 5), (8, 9)]. Bỏ qua phần không hợp lệ.
List<(int, int)> parseGenerationGroups(String text) {
  final out = <(int, int)>[];
  for (final part in text.split(RegExp(r'[;,\n]'))) {
    final m = RegExp(r'^\s*(\d+)\s*(?:-|–|~)\s*(\d+)\s*$').firstMatch(part);
    if (m == null) continue;
    final a = int.parse(m.group(1)!);
    final b = int.parse(m.group(2)!);
    if (a >= 1 && b > a) out.add((a, b));
  }
  return out;
}

/// Chia các đời 1..[maxGeneration] thành các hàng. Mỗi hàng là danh sách đời (tính từ 1);
/// các đời nằm trong cùng một nhóm trong [groups] được gộp vào một hàng.
List<List<int>> buildGenerationRows(int maxGeneration, List<(int, int)> groups) {
  final rows = <List<int>>[];
  var g = 1;
  while (g <= maxGeneration) {
    (int, int)? group;
    for (final candidate in groups) {
      if (g >= candidate.$1 && g <= candidate.$2) {
        group = candidate;
        break;
      }
    }
    final last = group == null ? g : (group.$2 < maxGeneration ? group.$2 : maxGeneration);
    rows.add([for (var i = g; i <= last; i++) i]);
    g = last + 1;
  }
  return rows;
}

/// Nhãn của một hàng, vd "ĐỜI THỨ 7", "ĐỜI THỨ 2,3,4,5", "ĐỜI THỨ 2–8".
String generationRowLabel(List<int> gens) {
  if (gens.length == 1) return 'ĐỜI THỨ ${gens.first}';
  if (gens.length <= 5) return 'ĐỜI THỨ ${gens.join(',')}';
  return 'ĐỜI THỨ ${gens.first}–${gens.last}';
}
