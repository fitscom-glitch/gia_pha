import 'package:gia_pha/features/honors/domain/entities/honor.dart';

class HonorModel extends Honor {
  const HonorModel({
    required super.id,
    required super.honoree,
    required super.title,
    super.personId,
    super.year,
    super.description,
  });

  factory HonorModel.fromEntity(Honor h) => HonorModel(
        id: h.id,
        honoree: h.honoree,
        title: h.title,
        personId: h.personId,
        year: h.year,
        description: h.description,
      );

  factory HonorModel.fromMap(Map<String, Object?> m) => HonorModel(
        id: m['id'] as String,
        honoree: m['honoree'] as String,
        title: m['title'] as String,
        personId: m['person_id'] as String?,
        year: m['year'] as int?,
        description: m['description'] as String?,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'person_id': personId,
        'honoree': honoree,
        'title': title,
        'year': year,
        'description': description,
      };
}
