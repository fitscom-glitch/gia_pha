import 'package:gia_pha/features/members/domain/entities/family_data.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';

/// "Vợ", "Chồng" hoặc "Vợ/chồng" tùy giới tính của người vợ/chồng đó.
String spouseLabel(Gender spouseGender) => switch (spouseGender) {
      Gender.female => 'Vợ',
      Gender.male => 'Chồng',
      Gender.other => 'Vợ/chồng',
    };

/// Số trong vòng tròn nhỏ: ① ② ③ ... (1–20), ngoài khoảng đó viết "(n)".
String circledNumber(int n) =>
    (n >= 1 && n <= 20) ? String.fromCharCode(0x2460 + n - 1) : '($n)';

/// Các dòng ghi chú nhỏ dưới tên, mỗi loại một dòng riêng:
/// "Vợ: A, B" (nếu có từ 2 vợ/chồng thì đánh số ① ② theo thứ tự) và "Con của: C & D".
List<String> relationNoteLines(FamilyData data, Person p, {bool includeParents = true}) {
  final lines = <String>[];
  final spouses = data.spousesOf(p.id);
  final numbered = spouses.length >= 2;
  final byLabel = <String, List<String>>{};
  for (var i = 0; i < spouses.length; i++) {
    final s = spouses[i];
    final name = numbered ? '${circledNumber(i + 1)} ${s.fullName}' : s.fullName;
    byLabel.putIfAbsent(spouseLabel(s.gender), () => []).add(name);
  }
  byLabel.forEach((label, names) => lines.add('$label: ${names.join(', ')}'));
  if (includeParents) {
    final parents = data.parentsOf(p.id);
    if (parents.isNotEmpty) {
      String nameOf(Person y) {
        // Nếu một người cha/mẹ có từ 2 vợ/chồng thì ghi số thứ tự của người còn lại.
        for (final x in parents) {
          if (x.id == y.id) continue;
          final sp = data.spousesOf(x.id);
          final i = sp.indexWhere((e) => e.id == y.id);
          if (sp.length >= 2 && i >= 0) return '${circledNumber(i + 1)} ${y.fullName}';
        }
        return y.fullName;
      }

      lines.add('Con của: ${parents.map(nameOf).join(' & ')}');
    }
  }
  return lines;
}

/// Ghi chú nhỏ dưới tên, các loại quan hệ nằm trên các dòng riêng (nối bằng '\n').
/// Null nếu chưa có quan hệ nào.
String? relationNote(FamilyData data, Person p, {bool includeParents = true}) {
  final lines = relationNoteLines(data, p, includeParents: includeParents);
  return lines.isEmpty ? null : lines.join('\n');
}
