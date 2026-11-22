import 'package:gia_pha/features/heirlooms/domain/entities/heirloom.dart';

class HeirloomModel extends Heirloom {
  const HeirloomModel({
    required super.id,
    required super.name,
    required super.createdAt,
    super.description,
    super.imagePath,
    super.keeper,
  });

  factory HeirloomModel.fromEntity(Heirloom h) => HeirloomModel(
        id: h.id,
        name: h.name,
        createdAt: h.createdAt,
        description: h.description,
        imagePath: h.imagePath,
        keeper: h.keeper,
      );

  factory HeirloomModel.fromMap(Map<String, Object?> m) => HeirloomModel(
        id: m['id'] as String,
        name: m['name'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
        description: m['description'] as String?,
        imagePath: m['image_path'] as String?,
        keeper: m['keeper'] as String?,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'image_path': imagePath,
        'keeper': keeper,
        'created_at': createdAt.toIso8601String(),
      };
}
