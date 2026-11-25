import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Mở hộp thoại chọn nơi lưu của hệ thống rồi ghi [bytes] vào đó.
/// Trả về false nếu người dùng hủy.
Future<bool> saveFileWithPicker({
  required String fileName,
  required Uint8List bytes,
  required List<String> extensions,
  String dialogTitle = 'Chọn nơi lưu',
}) async {
  final path = await FilePicker.platform.saveFile(
    dialogTitle: dialogTitle,
    fileName: fileName,
    bytes: bytes,
    type: FileType.custom,
    allowedExtensions: extensions,
  );
  return path != null;
}
