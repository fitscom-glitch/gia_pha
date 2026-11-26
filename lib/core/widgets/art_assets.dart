import 'package:flutter/material.dart';

/// Hình nghệ thuật dùng chung (nằm trong `assets/images/`).
abstract final class ArtAssets {
  // --- Phả đồ ---
  /// Rồng nét (từ file Asian-Dragon-Line-Art.svg), đầu quay sang phải / trái.
  static const phaDoDragonFacingRight = 'assets/images/rong_phado_phai.webp';
  static const phaDoDragonFacingLeft = 'assets/images/rong_phado_trai.webp';
  static const phaDoDragonAspect = 1800 / 706;

  /// Cuốn thư (băng rôn), ảnh đã phóng to và làm nét.
  static const scroll = 'assets/images/cuon_thu.webp';
  static const scrollAspect = 4000 / 1514;

  /// Họa tiết khung bao (Gia_pha_3.cdr): một đoạn dải viền hồi văn lặp lại.
  static const frameTile = 'assets/images/khung_dai.webp';
  static const frameTileAspect = 484 / 249;

  // --- Các trang khác: rồng, phụng nét đen (R022.cdr), nền trong suốt, tô màu được ---
  /// Rồng đứng, đầu quay sang trái.
  static const dragonArt = 'assets/images/rong_dung.webp';
  static const dragonArtAspect = 700 / 1693;

  /// Phụng đứng, đầu quay sang phải.
  static const phoenixArt = 'assets/images/phung_dung.webp';
  static const phoenixArtAspect = 1000 / 1411;
}

/// Rồng trong phả đồ, tô màu vàng cam để nổi trên nền giấy vàng nhạt. [faceRight] = true: đầu rồng quay sang phải
/// (đặt bên trái, chầu vào giữa).
class PhaDoDragon extends StatelessWidget {
  const PhaDoDragon({
    super.key,
    this.faceRight = true,
    this.opacity = 1,
    this.fit = BoxFit.contain,
  });

  final bool faceRight;
  final double opacity;
  final BoxFit fit;

  /// Dải màu vàng cam: sáng ở trên, đậm dần xuống dưới.
  static const _gold = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF5A31A), Color(0xFFEE8200), Color(0xFFD45F00)],
  );

  @override
  Widget build(BuildContext context) {
    final image = ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (rect) => _gold.createShader(rect),
      child: Image.asset(
        faceRight ? ArtAssets.phaDoDragonFacingRight : ArtAssets.phaDoDragonFacingLeft,
        fit: fit,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
      ),
    );
    if (opacity >= 1) return image;
    return Opacity(opacity: opacity, child: image);
  }
}

/// Hình nét đơn sắc (nền trong suốt) tô theo [color].
class _TintedArt extends StatelessWidget {
  const _TintedArt({
    required this.asset,
    required this.color,
    required this.opacity,
    required this.fit,
    required this.alignment,
  });

  final String asset;
  final Color color;
  final double opacity;
  final BoxFit fit;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      asset,
      color: color,
      colorBlendMode: BlendMode.srcIn,
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
    );
    if (opacity >= 1) return image;
    return Opacity(opacity: opacity, child: image);
  }
}

/// Rồng đứng (đầu quay trái). Mặc định tô nâu đỏ đậm, đổi bằng [color].
class DragonArt extends StatelessWidget {
  const DragonArt({
    super.key,
    this.color = const Color(0xFF5B1A12),
    this.opacity = 1,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  final Color color;
  final double opacity;
  final BoxFit fit;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) => _TintedArt(
        asset: ArtAssets.dragonArt,
        color: color,
        opacity: opacity,
        fit: fit,
        alignment: alignment,
      );
}

/// Phụng đứng (đầu quay phải). Mặc định tô nâu đỏ đậm, đổi bằng [color].
class PhoenixArt extends StatelessWidget {
  const PhoenixArt({
    super.key,
    this.color = const Color(0xFF5B1A12),
    this.opacity = 1,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  final Color color;
  final double opacity;
  final BoxFit fit;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) => _TintedArt(
        asset: ArtAssets.phoenixArt,
        color: color,
        opacity: opacity,
        fit: fit,
        alignment: alignment,
      );
}
