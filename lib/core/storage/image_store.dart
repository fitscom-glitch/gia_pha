import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Lưu ảnh vào bộ nhớ riêng của ứng dụng (thư mục con [folder]).
class ImageStore {
  const ImageStore({required this.folder});

  final String folder;

  Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$folder');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static String extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    return dot >= 0 && path.length - dot <= 6 ? path.substring(dot) : '.jpg';
  }

  /// Chép file ảnh người dùng chọn vào thư mục của ứng dụng, trả về đường dẫn mới.
  Future<String> saveCopy(String sourcePath, String id) async {
    final dir = await _dir();
    final target =
        '${dir.path}/${id}_${DateTime.now().millisecondsSinceEpoch}${extensionOf(sourcePath)}';
    await File(sourcePath).copy(target);
    return target;
  }

  Future<String> saveBytes(List<int> bytes, String id, {String ext = '.jpg'}) async {
    final dir = await _dir();
    final target = '${dir.path}/${id}_${DateTime.now().millisecondsSinceEpoch}$ext';
    await File(target).writeAsBytes(bytes);
    return target;
  }

  Future<void> delete(String? path) async {
    if (path == null) return;
    final f = File(path);
    if (await f.exists()) await f.delete();
  }

  Future<String> directoryPath() async => (await _dir()).path;

  Future<void> saveNamed(List<int> bytes, String name) async {
    final dir = await _dir();
    await File('${dir.path}/$name').writeAsBytes(bytes);
  }

  Future<void> deleteNamed(String name) async {
    final dir = await _dir();
    final f = File('${dir.path}/$name');
    if (await f.exists()) await f.delete();
  }
}
