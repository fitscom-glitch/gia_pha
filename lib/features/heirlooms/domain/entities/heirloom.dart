class Heirloom {
  const Heirloom({
    required this.id,
    required this.name,
    required this.createdAt,
    this.description,
    this.imagePath,
    this.keeper,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final String? description;

  /// Đường dẫn file ảnh trong bộ nhớ riêng của ứng dụng.
  final String? imagePath;

  /// Người đang lưu giữ.
  final String? keeper;

  Heirloom withImage(String? path) => Heirloom(
        id: id,
        name: name,
        createdAt: createdAt,
        description: description,
        imagePath: path,
        keeper: keeper,
      );
}
