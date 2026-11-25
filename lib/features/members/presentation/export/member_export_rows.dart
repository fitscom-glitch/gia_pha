import 'package:intl/intl.dart';
import 'package:gia_pha/features/members/domain/entities/family_data.dart';
import 'package:gia_pha/features/members/presentation/widgets/person_avatar.dart';
import 'package:gia_pha/features/members/presentation/widgets/relation_note.dart';

/// Một dòng của danh sách xuất ra Excel/PDF (toàn bộ là chuỗi đã định dạng).
class MemberExportRow {
  const MemberExportRow({
    required this.index,
    required this.name,
    required this.gender,
    required this.generation,
    required this.order,
    required this.birth,
    required this.death,
    required this.birthPlace,
    required this.occupation,
    required this.spouses,
    required this.parents,
    required this.phone,
    required this.address,
    required this.email,
    required this.bio,
  });

  final int index;
  final String name;
  final String gender;
  final String generation;
  final String order;
  final String birth;
  final String death;
  final String birthPlace;
  final String occupation;
  final String spouses;
  final String parents;
  final String phone;
  final String address;
  final String email;
  final String bio;
}

/// Danh sách theo thứ tự mối quan hệ (người, vợ/chồng liền sau, rồi con cháu).
List<MemberExportRow> buildMemberExportRows(FamilyData data) {
  final fmt = DateFormat('dd/MM/yyyy');
  final gens = data.generations();
  final rows = <MemberExportRow>[];
  var n = 0;
  for (final e in data.relationOrder()) {
    final p = e.person;
    n++;
    final g = gens[p.id];
    rows.add(MemberExportRow(
      index: n,
      name: p.fullName,
      gender: genderLabel(p.gender),
      generation: g == null ? '' : '${g + 1}',
      order: birthOrderLabel(p.birthOrder) ?? '',
      birth: p.birthDate == null ? '' : fmt.format(p.birthDate!),
      death: p.deathDate == null ? '' : fmt.format(p.deathDate!),
      birthPlace: p.birthPlace ?? '',
      occupation: p.occupation ?? '',
      spouses: relationNote(data, p, includeParents: false) ?? '',
      parents: data.parentsOf(p.id).map((x) => x.fullName).join(' & '),
      phone: p.phone ?? '',
      address: p.address ?? '',
      email: p.email ?? '',
      bio: p.bio ?? '',
    ));
  }
  return rows;
}
