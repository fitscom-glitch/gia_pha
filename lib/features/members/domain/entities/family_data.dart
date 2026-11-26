import 'dart:math' as math;

import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/members/domain/entities/relationship.dart';

/// Thứ tự anh em: người đã đặt "con thứ mấy" xếp trước (số nhỏ trước),
/// người chưa đặt xếp sau; còn lại theo thứ tự nhập vào ([Person.seq]).
int compareSiblings(Person a, Person b) {
  final x = a.birthOrder, y = b.birthOrder;
  if (x != null && y != null) {
    final c = x.compareTo(y);
    if (c != 0) return c;
  } else if (x != null) {
    return -1;
  } else if (y != null) {
    return 1;
  }
  return a.seq.compareTo(b.seq);
}

/// Sắp theo [compareSiblings], ổn định (bằng nhau thì giữ nguyên thứ tự gặp).
List<Person> sortedSiblings(Iterable<Person> people) {
  final list = people.toList();
  final index = {for (var i = 0; i < list.length; i++) list[i].id: i};
  list.sort((a, b) {
    final c = compareSiblings(a, b);
    return c != 0 ? c : index[a.id]!.compareTo(index[b.id]!);
  });
  return list;
}

/// Theo ngày sinh (chưa có ngày sinh xếp sau), bằng nhau thì theo thứ tự nhập.
int compareByBirth(Person a, Person b) {
  final x = a.birthDate, y = b.birthDate;
  if (x != null && y != null) {
    final c = x.compareTo(y);
    if (c != 0) return c;
  } else if (x != null) {
    return -1;
  } else if (y != null) {
    return 1;
  }
  return a.seq.compareTo(b.seq);
}

/// Toàn bộ dữ liệu gia phả trong bộ nhớ + các truy vấn quan hệ.
class FamilyData {
  const FamilyData(this.persons, this.relationships);

  final List<Person> persons;
  final List<Relationship> relationships;

  Person? byId(String id) {
    for (final p in persons) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<Person> _resolve(Iterable<String> ids) =>
      ids.map(byId).whereType<Person>().toList();

  List<Person> parentsOf(String id) => _resolve(relationships
      .where((r) => r.type == RelationType.parentChild && r.personBId == id)
      .map((r) => r.personAId));

  /// Con của một người, theo thứ tự anh em.
  List<Person> childrenOf(String id) => sortedSiblings(_resolve(relationships
      .where((r) => r.type == RelationType.parentChild && r.personAId == id)
      .map((r) => r.personBId)));

  List<Person> spousesOf(String id) => _resolve(relationships
      .where((r) =>
          r.type == RelationType.spouse &&
          (r.personAId == id || r.personBId == id))
      .map((r) => r.personAId == id ? r.personBId : r.personAId));

  /// Con của một người và của các vợ/chồng, gộp lại, theo thứ tự anh em.
  ///
  /// Trường hợp một người vợ/chồng của [id] lại có từ 2 vợ/chồng (vd [id] là bà thứ hai của một
  /// ông có hai bà): con của ông chỉ được tính cho [id] khi [id] cũng là cha/mẹ của con đó
  /// (con đã đánh dấu 1 hoặc 2), nên con của bà kia không lẫn vào danh sách này.
  List<Person> childrenOfUnit(String id) {
    final seen = <String>{};
    final kids = <Person>[];
    for (final c in childrenOf(id)) {
      if (seen.add(c.id)) kids.add(c);
    }
    for (final s in spousesOf(id)) {
      final shared = spousesOf(s.id).length >= 2; // s có nhiều vợ/chồng: phải phân biệt
      for (final c in childrenOf(s.id)) {
        if (shared && !parentsOf(c.id).any((p) => p.id == id)) continue;
        if (seen.add(c.id)) kids.add(c);
      }
    }
    return sortedSiblings(kids);
  }

  /// Thứ tự theo mối quan hệ: mỗi người được theo sau bởi vợ/chồng, rồi đến các con
  /// (mỗi người con lại kèm vợ/chồng và con cháu của mình). [depth] là bậc so với gốc.
  List<({Person person, int depth})> relationOrder() {
    final result = <({Person person, int depth})>[];
    final visited = <String>{};
    final hasParent = <String>{
      for (final r in relationships)
        if (r.type == RelationType.parentChild) r.personBId,
    };

    void visit(Person p, int depth) {
      visited.add(p.id);
      result.add((person: p, depth: depth));
      for (final s in spousesOf(p.id)) {
        if (visited.add(s.id)) result.add((person: s, depth: depth));
      }
      for (final c in childrenOfUnit(p.id)) {
        if (!visited.contains(c.id)) visit(c, depth + 1);
      }
    }

    // Người vào làm dâu/rể (không có cha mẹ nhưng vợ/chồng có) đi kèm vợ/chồng, không làm gốc.
    bool marriedIn(Person p) =>
        !hasParent.contains(p.id) &&
        spousesOf(p.id).any((s) => hasParent.contains(s.id));

    for (final p in persons) {
      if (visited.contains(p.id) || hasParent.contains(p.id) || marriedIn(p)) continue;
      visit(p, 0);
    }
    for (final p in persons) {
      if (!visited.contains(p.id)) visit(p, 0); // dữ liệu thiếu/vòng: thêm vào cuối
    }
    return result;
  }

  /// Đời của từng người (0 = đời đầu). Người vào làm dâu/rể (không có cha mẹ)
  /// lấy cùng đời với vợ/chồng.
  Map<String, int> generations() {
    final hasParent = <String>{
      for (final r in relationships)
        if (r.type == RelationType.parentChild) r.personBId,
    };
    final gen = <String, int>{
      for (final p in persons)
        if (!hasParent.contains(p.id)) p.id: 0,
    };
    var changed = true;
    var guard = 0;
    while (changed && guard++ <= persons.length) {
      changed = false;
      for (final r in relationships) {
        final a = gen[r.personAId];
        final b = gen[r.personBId];
        if (r.type == RelationType.parentChild) {
          if (a != null && (b == null || b < a + 1)) {
            gen[r.personBId] = a + 1;
            changed = true;
          }
        } else if (a != null && b != null && a != b) {
          if (!hasParent.contains(r.personAId) && a < b) {
            gen[r.personAId] = b;
            changed = true;
          } else if (!hasParent.contains(r.personBId) && b < a) {
            gen[r.personBId] = a;
            changed = true;
          }
        }
      }
    }
    return gen;
  }

  int get generationCount {
    final values = generations().values;
    return values.isEmpty ? 0 : values.reduce(math.max) + 1;
  }
}
