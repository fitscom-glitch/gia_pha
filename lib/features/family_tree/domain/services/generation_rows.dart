/// Một nhóm đời gộp chung một hàng trên phả đồ.
/// [representative] (nếu có) là đời duy nhất được hiển thị trong nhóm; các đời còn lại bị ẩn.
class GenerationGroup {
  const GenerationGroup(this.from, this.to, [this.representative]);

  final int from;
  final int to;
  final int? representative;

  bool contains(int generation) => generation >= from && generation <= to;
}

/// Đọc cấu hình, vd "2-5:3; 8-9" = gộp đời 2–5 (chỉ hiển thị đời 3) và gộp đời 8–9 (hiển thị cả hai).
/// Bỏ qua phần không hợp lệ.
List<GenerationGroup> parseGenerationGroups(String text) {
  final out = <GenerationGroup>[];
  for (final part in text.split(RegExp(r'[;,\n]'))) {
    final m = RegExp(r'^\s*(\d+)\s*(?:-|–|~)\s*(\d+)\s*(?::\s*(\d+))?\s*$').firstMatch(part);
    if (m == null) continue;
    final a = int.parse(m.group(1)!);
    final b = int.parse(m.group(2)!);
    if (a < 1 || b <= a) continue;
    final rep = m.group(3) == null ? null : int.parse(m.group(3)!);
    out.add(GenerationGroup(a, b, (rep != null && rep >= a && rep <= b) ? rep : null));
  }
  return out;
}

String formatGenerationGroups(List<GenerationGroup> groups) => groups
    .map((g) => '${g.from}-${g.to}${g.representative == null ? '' : ':${g.representative}'}')
    .join('; ');

GenerationGroup? _groupOf(int generation, List<GenerationGroup> groups) {
  for (final g in groups) {
    if (g.contains(generation)) return g;
  }
  return null;
}

/// Đời [generation] (tính từ 1) có bị ẩn không: nhóm chứa nó có đời đại diện khác.
bool isGenerationHidden(int generation, List<GenerationGroup> groups) {
  final g = _groupOf(generation, groups);
  return g != null && g.representative != null && g.representative != generation;
}

/// Chia các đời 1..[maxGeneration] thành các hàng. Mỗi hàng là danh sách đời (tính từ 1);
/// các đời nằm trong cùng một nhóm được gộp vào một hàng.
List<List<int>> buildGenerationRows(int maxGeneration, List<GenerationGroup> groups) {
  final rows = <List<int>>[];
  var g = 1;
  while (g <= maxGeneration) {
    final group = _groupOf(g, groups);
    final last = group == null ? g : (group.to < maxGeneration ? group.to : maxGeneration);
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
