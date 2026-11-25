import 'package:gia_pha/features/members/domain/entities/family_data.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/members/domain/entities/relationship.dart';

/// Số liệu thống kê của cả gia phả.
class FamilyStats {
  const FamilyStats({
    required this.generations,
    required this.total,
    required this.male,
    required this.female,
    required this.unknownGender,
    required this.deceased,
    required this.alive,
    required this.directTotal,
    required this.directMale,
    required this.directFemale,
    required this.directUnknownGender,
  });

  /// Tổng số đời.
  final int generations;

  /// Tổng số người, nam, nữ, chưa rõ giới tính.
  final int total, male, female, unknownGender;

  /// Đã mất (có ngày mất) và còn sống.
  final int deceased, alive;

  /// Con cháu trực hệ: hậu duệ huyết thống của người đầu tiên (các đời gốc) theo quan hệ
  /// cha/mẹ - con. Không tính người gốc, và không tính dâu/rể (người vào gia đình do kết hôn).
  final int directTotal, directMale, directFemale, directUnknownGender;
}

/// Các đời gốc: người không có cha mẹ và không phải dâu/rể
/// (dâu/rể = không có cha mẹ nhưng vợ/chồng thì có).
List<Person> rootPersons(FamilyData d) {
  final hasParent = <String>{
    for (final r in d.relationships)
      if (r.type == RelationType.parentChild) r.personBId,
  };
  bool marriedIn(Person p) =>
      !hasParent.contains(p.id) &&
      d.spousesOf(p.id).any((s) => hasParent.contains(s.id));
  return [
    for (final p in d.persons)
      if (!hasParent.contains(p.id) && !marriedIn(p)) p,
  ];
}

/// Hậu duệ huyết thống (con, cháu, chắt...) của các đời gốc, không gồm chính họ.
List<Person> directDescendants(FamilyData d) {
  final roots = rootPersons(d);
  final rootIds = {for (final r in roots) r.id};
  final seen = <String>{...rootIds};
  final result = <Person>[];
  final queue = [...roots];
  while (queue.isNotEmpty) {
    final cur = queue.removeLast();
    for (final c in d.childrenOf(cur.id)) {
      if (seen.add(c.id)) {
        result.add(c);
        queue.add(c);
      }
    }
  }
  return result;
}

FamilyStats computeFamilyStats(FamilyData d) {
  int count(Iterable<Person> ps, bool Function(Person) test) => ps.where(test).length;
  final all = d.persons;
  final direct = directDescendants(d);
  final deceased = count(all, (p) => p.isDeceased);
  return FamilyStats(
    generations: d.generationCount,
    total: all.length,
    male: count(all, (p) => p.gender == Gender.male),
    female: count(all, (p) => p.gender == Gender.female),
    unknownGender: count(all, (p) => p.gender == Gender.other),
    deceased: deceased,
    alive: all.length - deceased,
    directTotal: direct.length,
    directMale: count(direct, (p) => p.gender == Gender.male),
    directFemale: count(direct, (p) => p.gender == Gender.female),
    directUnknownGender: count(direct, (p) => p.gender == Gender.other),
  );
}
