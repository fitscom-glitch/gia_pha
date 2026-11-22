import 'package:gia_pha/features/members/domain/entities/person.dart';

/// Person + chuyển đổi từ/đến dòng SQLite.
class PersonModel extends Person {
  const PersonModel({
    required super.id,
    required super.fullName,
    super.gender,
    super.birthDate,
    super.deathDate,
    super.birthPlace,
    super.occupation,
    super.bio,
    super.phone,
    super.address,
    super.email,
    super.seq,
    super.birthOrder,
  });

  factory PersonModel.fromEntity(Person p) => PersonModel(
        id: p.id,
        fullName: p.fullName,
        gender: p.gender,
        birthDate: p.birthDate,
        deathDate: p.deathDate,
        birthPlace: p.birthPlace,
        occupation: p.occupation,
        bio: p.bio,
        phone: p.phone,
        address: p.address,
        email: p.email,
        seq: p.seq,
        birthOrder: p.birthOrder,
      );

  factory PersonModel.fromMap(Map<String, Object?> m) => PersonModel(
        id: m['id'] as String,
        fullName: m['full_name'] as String,
        gender: Gender.values.byName(m['gender'] as String),
        birthDate: _date(m['birth_date']),
        deathDate: _date(m['death_date']),
        birthPlace: m['birth_place'] as String?,
        occupation: m['occupation'] as String?,
        bio: m['bio'] as String?,
        phone: m['phone'] as String?,
        address: m['address'] as String?,
        email: m['email'] as String?,
        seq: (m['seq'] as int?) ?? 0,
        birthOrder: m['birth_order'] as int?,
      );

  /// Không gồm `seq`: số thứ tự nhập do datasource cấp khi thêm mới.
  Map<String, Object?> toMap() => {
        'id': id,
        'full_name': fullName,
        'gender': gender.name,
        'birth_date': birthDate?.toIso8601String(),
        'death_date': deathDate?.toIso8601String(),
        'birth_place': birthPlace,
        'occupation': occupation,
        'bio': bio,
        'phone': phone,
        'address': address,
        'email': email,
        'birth_order': birthOrder,
      };

  static DateTime? _date(Object? v) =>
      v == null ? null : DateTime.parse(v as String);
}
