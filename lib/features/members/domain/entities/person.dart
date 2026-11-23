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
    this.phone,
    this.address,
    this.email,
    this.seq = 0,
    this.birthOrder,
    this.photoPath,
  });

  final String id;
  final String fullName;
  final Gender gender;
  final DateTime? birthDate;
  final DateTime? deathDate;
  final String? birthPlace;
  final String? occupation;
  final String? bio;
  final String? phone;
  final String? address;
  final String? email;

  /// Số thứ tự nhập vào (do cơ sở dữ liệu cấp; nhỏ = nhập trước).
  final int seq;

  /// "Con thứ mấy" trong anh chị em (1 = con trưởng). Null = chưa đặt, xếp theo [seq].
  final int? birthOrder;

  /// Đường dẫn ảnh đại diện trong bộ nhớ của ứng dụng.
  final String? photoPath;

  bool get isDeceased => deathDate != null;

  /// Vd: "1950 – 2020", "sinh 1990". Rỗng nếu chưa có ngày sinh/mất.
  String get lifespan {
    final b = birthDate?.year.toString() ?? '?';
    if (deathDate != null) return '$b – ${deathDate!.year}';
    return birthDate != null ? 'sinh $b' : '';
  }

  /// Bản sao với thông tin liên hệ mới (cho phép đặt về null).
  Person withContact({String? phone, String? address, String? email}) => Person(
        id: id,
        fullName: fullName,
        gender: gender,
        birthDate: birthDate,
        deathDate: deathDate,
        birthPlace: birthPlace,
        occupation: occupation,
        bio: bio,
        phone: phone,
        address: address,
        email: email,
        seq: seq,
        birthOrder: birthOrder,
        photoPath: photoPath,
      );

  /// Bản sao với ảnh đại diện mới (cho phép đặt về null).
  Person withPhoto(String? path) => Person(
        id: id,
        fullName: fullName,
        gender: gender,
        birthDate: birthDate,
        deathDate: deathDate,
        birthPlace: birthPlace,
        occupation: occupation,
        bio: bio,
        phone: phone,
        address: address,
        email: email,
        seq: seq,
        birthOrder: birthOrder,
        photoPath: path,
      );
}
