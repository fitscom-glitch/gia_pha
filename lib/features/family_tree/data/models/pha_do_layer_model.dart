import 'package:gia_pha/features/family_tree/domain/entities/pha_do_layer.dart';

class PhaDoLayerModel extends PhaDoLayer {
  const PhaDoLayerModel({
    required super.id,
    required super.path,
    required super.kind,
    super.cx,
    super.cy,
    super.w,
    super.aspect,
    super.rotation,
    super.opacity,
    super.front,
    super.z,
  });

  factory PhaDoLayerModel.fromEntity(PhaDoLayer l) => PhaDoLayerModel(
        id: l.id,
        path: l.path,
        kind: l.kind,
        cx: l.cx,
        cy: l.cy,
        w: l.w,
        aspect: l.aspect,
        rotation: l.rotation,
        opacity: l.opacity,
        front: l.front,
        z: l.z,
      );

  factory PhaDoLayerModel.fromMap(Map<String, Object?> m) => PhaDoLayerModel(
        id: m['id'] as String,
        path: m['path'] as String,
        kind: PhaDoLayerKind.values.byName(m['kind'] as String),
        cx: (m['cx'] as num).toDouble(),
        cy: (m['cy'] as num).toDouble(),
        w: (m['w'] as num).toDouble(),
        aspect: (m['aspect'] as num).toDouble(),
        rotation: (m['rotation'] as num).toDouble(),
        opacity: (m['opacity'] as num).toDouble(),
        front: (m['front'] as int? ?? 0) == 1,
        z: m['z'] as int? ?? 0,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'path': path,
        'kind': kind.name,
        'cx': cx,
        'cy': cy,
        'w': w,
        'aspect': aspect,
        'rotation': rotation,
        'opacity': opacity,
        'front': front ? 1 : 0,
        'z': z,
      };
}
