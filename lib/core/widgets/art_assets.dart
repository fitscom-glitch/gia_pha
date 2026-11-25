import 'package:flutter/material.dart';

/// Hình nghệ thuật dùng chung: hai con rồng (quay trái / quay phải) và băng rôn.
abstract final class ArtAssets {
  static const dragonFacingRight = 'assets/images/rong_quay_phai.webp';
  static const dragonFacingLeft = 'assets/images/rong_quay_trai.webp';
  static const phoenixFacingRight = 'assets/images/phung_quay_phai.webp';
  static const phoenixFacingLeft = 'assets/images/phung_quay_trai.webp';
  static const banner = 'assets/images/bang_ron.webp';

  /// Tỉ lệ rộng / cao của ảnh.
  static const dragonAspect = 1500 / 704;
  static const phoenixAspect = 1300 / 939;
  static const bannerAspect = 1800 / 681;

  static String dragon({required bool faceRight}) =>
      faceRight ? dragonFacingRight : dragonFacingLeft;

  static String phoenix({required bool faceRight}) =>
      faceRight ? phoenixFacingRight : phoenixFacingLeft;
}

/// Hình rồng. [faceRight] = true: đầu rồng quay sang phải (đặt ở bên trái,
/// chầu vào giữa); false: đầu quay sang trái (đặt ở bên phải).
class DragonImage extends StatelessWidget {
  const DragonImage({
    super.key,
    this.faceRight = true,
    this.opacity = 1,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  final bool faceRight;
  final double opacity;
  final BoxFit fit;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      ArtAssets.dragon(faceRight: faceRight),
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
    );
    if (opacity >= 1) return image;
    return Opacity(opacity: opacity, child: image);
  }
}

/// Hình chim phụng (nét cam, nền trong suốt). [faceRight] như [DragonImage].
class PhoenixImage extends StatelessWidget {
  const PhoenixImage({
    super.key,
    this.faceRight = true,
    this.opacity = 1,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  final bool faceRight;
  final double opacity;
  final BoxFit fit;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      ArtAssets.phoenix(faceRight: faceRight),
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
    );
    if (opacity >= 1) return image;
    return Opacity(opacity: opacity, child: image);
  }
}
