class AppSettings {
  const AppSettings({
    this.clanName = '',
    this.clanIntro = '',
    this.clanPlace = '',
    this.generationGroups = '',
  });

  /// Tên dòng họ, vd "Nguyễn Văn".
  final String clanName;
  final String clanIntro;

  /// Địa danh hiện trên băng rôn phả đồ.
  final String clanPlace;

  /// Các nhóm đời gộp chung một hàng trên phả đồ, vd "2-5; 8-9".
  final String generationGroups;

  AppSettings copyWith({
    String? clanName,
    String? clanIntro,
    String? clanPlace,
    String? generationGroups,
  }) =>
      AppSettings(
        clanName: clanName ?? this.clanName,
        clanIntro: clanIntro ?? this.clanIntro,
        clanPlace: clanPlace ?? this.clanPlace,
        generationGroups: generationGroups ?? this.generationGroups,
      );
}
