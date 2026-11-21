enum Gender { male, female, other }

class Person {
  const Person({
    required this.id,
    required this.fullName,
    this.gender = Gender.other,
    this.birthDate,
    this.deathDate,
    this.birthPlace,
    this.occupation,
    this.bio,
  });

  final String id;
  final String fullName;
  final Gender gender;
  final DateTime? birthDate;
  final DateTime? deathDate;
  final String? birthPlace;
  final String? occupation;
  final String? bio;

  bool get isDeceased => deathDate != null;

  /// Vd: "1950 – 2020", "sinh 1990". Rỗng nếu chưa có ngày sinh/mất.
  String get lifespan {
    final b = birthDate?.year.toString() ?? '?';
    if (deathDate != null) return '$b – ${deathDate!.year}';
    return birthDate != null ? 'sinh $b' : '';
  }
}
