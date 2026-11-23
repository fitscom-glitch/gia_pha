import 'package:gia_pha/features/members/domain/entities/family_data.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';

/// "Vợ", "Chồng" hoặc "Vợ/chồng" tùy giới tính của người vợ/chồng đó.
String spouseLabel(Gender spouseGender) => switch (spouseGender) {
      Gender.female => 'Vợ',
      Gender.male => 'Chồng',
      Gender.other => 'Vợ/chồng',
    };

/// Ghi chú nhỏ dưới tên: "Vợ: A, B · Con của: C & D". Null nếu chưa có quan hệ nào.
String? relationNote(FamilyData data, Person p, {bool includeParents = true}) {
  final parts = <String>[];
  final byLabel = <String, List<String>>{};
  for (final s in data.spousesOf(p.id)) {
    byLabel.putIfAbsent(spouseLabel(s.gender), () => []).add(s.fullName);
  }
  byLabel.forEach((label, names) => parts.add('$label: ${names.join(', ')}'));
  if (includeParents) {
    final parents = data.parentsOf(p.id);
    if (parents.isNotEmpty) {
      parts.add('Con của: ${parents.map((e) => e.fullName).join(' & ')}');
    }
  }
  return parts.isEmpty ? null : parts.join(' · ');
}
