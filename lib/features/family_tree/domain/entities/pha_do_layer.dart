enum PhaDoLayerKind { background, decor }

/// Một hình do người dùng thêm vào phả đồ (PNG nền trong suốt, JPG, WebP, SVG...).
/// Vị trí và kích thước tính theo tỉ lệ so với khung phả đồ nên không lệch khi cây thay đổi.
class PhaDoLayer {
  const PhaDoLayer({
    required this.id,
    required this.path,
    required this.kind,
    this.cx = 0.5,
    this.cy = 0.5,
    this.w = 0.3,
    this.aspect = 1,
    this.rotation = 0,
    this.opacity = 1,
    this.front = false,
    this.z = 0,
  });

  final String id;
  final String path;
  final PhaDoLayerKind kind;

  /// Tâm hình, theo tỉ lệ 0..1 của chiều rộng/cao khung.
  final double cx;
  final double cy;

  /// Chiều rộng hình theo tỉ lệ chiều rộng khung.
  final double w;

  /// Cao / rộng của hình gốc.
  final double aspect;

  /// Góc xoay (độ).
  final double rotation;
  final double opacity;

  /// true: vẽ đè lên cây gia phả; false: nằm dưới cây.
  final bool front;

  /// Thứ tự lớp (nhỏ nằm dưới).
  final int z;

  PhaDoLayer copyWith({
    double? cx,
    double? cy,
    double? w,
    double? rotation,
    double? opacity,
    bool? front,
    int? z,
  }) =>
      PhaDoLayer(
        id: id,
        path: path,
        kind: kind,
        cx: cx ?? this.cx,
        cy: cy ?? this.cy,
        w: w ?? this.w,
        aspect: aspect,
        rotation: rotation ?? this.rotation,
        opacity: opacity ?? this.opacity,
        front: front ?? this.front,
        z: z ?? this.z,
      );
}
