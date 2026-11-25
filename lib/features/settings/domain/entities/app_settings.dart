class AppSettings {
  const AppSettings({
    this.clanName = '',
    this.clanIntro = '',
    this.clanPlace = '',
    this.generationGroups = '',
    this.phadoFrame = true,
    this.phadoBanner = true,
    this.phadoWatermark = true,
  });

  /// Tên dòng họ, vd "Nguyễn Văn".
  final String clanName;
  final String clanIntro;

  /// Địa danh hiện trên băng rôn phả đồ.
  final String clanPlace;

  /// Các nhóm đời gộp chung một hàng trên phả đồ, vd "2-5:3; 8-9"
  /// (đời 2–5 chung một hàng và chỉ hiển thị đời 3).
  final String generationGroups;

  /// Hiện khung viền / băng rôn / rồng mờ mặc định trên phả đồ.
  final bool phadoFrame;
  final bool phadoBanner;
  final bool phadoWatermark;

  AppSettings copyWith({
    String? clanName,
    String? clanIntro,
    String? clanPlace,
    String? generationGroups,
    bool? phadoFrame,
    bool? phadoBanner,
    bool? phadoWatermark,
  }) =>
      AppSettings(
        clanName: clanName ?? this.clanName,
        clanIntro: clanIntro ?? this.clanIntro,
        clanPlace: clanPlace ?? this.clanPlace,
        generationGroups: generationGroups ?? this.generationGroups,
        phadoFrame: phadoFrame ?? this.phadoFrame,
        phadoBanner: phadoBanner ?? this.phadoBanner,
        phadoWatermark: phadoWatermark ?? this.phadoWatermark,
      );
}
