import 'dart:typed_data';

import 'package:gia_pha/core/utils/xlsx_writer.dart';
import 'package:gia_pha/features/members/presentation/export/member_export_rows.dart';

Uint8List buildMemberXlsx(List<MemberExportRow> rows) {
  return buildXlsx(
    sheetName: 'Thành viên',
    headers: const [
      'STT', 'Họ và tên', 'Giới tính', 'Đời', 'Thứ tự anh em', 'Ngày sinh', 'Ngày mất',
      'Nơi sinh', 'Nghề nghiệp', 'Vợ/chồng', 'Cha mẹ', 'Số điện thoại', 'Địa chỉ', 'Email', 'Tiểu sử',
    ],
    widths: const [6, 28, 10, 6, 14, 12, 12, 20, 18, 28, 28, 15, 28, 22, 40],
    rows: [
      for (final r in rows)
        [
          r.index, r.name, r.gender, r.generation, r.order, r.birth, r.death,
          r.birthPlace, r.occupation, r.spouses, r.parents, r.phone, r.address, r.email, r.bio,
        ],
    ],
  );
}
