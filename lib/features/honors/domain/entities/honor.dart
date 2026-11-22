class Honor {
  const Honor({
    required this.id,
    required this.honoree,
    required this.title,
    this.personId,
    this.year,
    this.description,
  });

  final String id;

  /// Tên người được vinh danh.
  final String honoree;

  /// Danh hiệu / thành tích.
  final String title;

  /// Liên kết với thành viên trong gia phả (nếu có).
  final String? personId;
  final int? year;
  final String? description;
}
