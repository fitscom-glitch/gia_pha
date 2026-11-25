import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

String _col(int index) {
  var i = index + 1;
  var s = '';
  while (i > 0) {
    final m = (i - 1) % 26;
    s = String.fromCharCode(65 + m) + s;
    i = (i - 1) ~/ 26;
  }
  return s;
}

String _esc(String v) => v
    .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String _cell(int row, int col, Object? v, int style) {
  final ref = '${_col(col)}$row';
  if (v == null || (v is String && v.isEmpty)) return '<c r="$ref" s="$style"/>';
  if (v is num) return '<c r="$ref" s="$style"><v>$v</v></c>';
  return '<c r="$ref" s="$style" t="inlineStr"><is><t xml:space="preserve">${_esc('$v')}</t></is></c>';
}

/// Tạo file Excel (.xlsx) một trang tính: dòng đầu là tiêu đề (đậm, có màu, cố định khi cuộn).
Uint8List buildXlsx({
  required String sheetName,
  required List<String> headers,
  required List<List<Object?>> rows,
  List<double>? widths,
}) {
  final archive = Archive();
  void add(String name, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  const xml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';
  add(
    '[Content_Types].xml',
    '$xml<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
        '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
        '</Types>',
  );
  add(
    '_rels/.rels',
    '$xml<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
        '</Relationships>',
  );
  add(
    'xl/workbook.xml',
    '$xml<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        '<sheets><sheet name="${_esc(sheetName)}" sheetId="1" r:id="rId1"/></sheets></workbook>',
  );
  add(
    'xl/_rels/workbook.xml.rels',
    '$xml<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
        '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
        '</Relationships>',
  );
  add(
    'xl/styles.xml',
    '$xml<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><name val="Calibri"/></font></fonts>'
        '<fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill>'
        '<fill><patternFill patternType="solid"><fgColor rgb="FFF6DE94"/><bgColor indexed="64"/></patternFill></fill></fills>'
        '<borders count="2"><border><left/><right/><top/><bottom/><diagonal/></border>'
        '<border><left style="thin"><color rgb="FF999999"/></left><right style="thin"><color rgb="FF999999"/></right>'
        '<top style="thin"><color rgb="FF999999"/></top><bottom style="thin"><color rgb="FF999999"/></bottom><diagonal/></border></borders>'
        '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
        '<cellXfs count="3"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
        '<xf numFmtId="0" fontId="1" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment vertical="center" wrapText="1"/></xf>'
        '<xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>'
        '</cellXfs></styleSheet>',
  );

  final sheet = StringBuffer(
    '$xml<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
    '<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>'
    '<sheetFormatPr defaultRowHeight="15"/>',
  );
  if (widths != null) {
    sheet.write('<cols>');
    for (var i = 0; i < widths.length; i++) {
      sheet.write('<col min="${i + 1}" max="${i + 1}" width="${widths[i]}" customWidth="1"/>');
    }
    sheet.write('</cols>');
  }
  sheet.write('<sheetData><row r="1">');
  for (var c = 0; c < headers.length; c++) {
    sheet.write(_cell(1, c, headers[c], 1));
  }
  sheet.write('</row>');
  for (var r = 0; r < rows.length; r++) {
    sheet.write('<row r="${r + 2}">');
    for (var c = 0; c < rows[r].length; c++) {
      sheet.write(_cell(r + 2, c, rows[r][c], 2));
    }
    sheet.write('</row>');
  }
  sheet.write('</sheetData></worksheet>');
  add('xl/worksheets/sheet1.xml', sheet.toString());

  final zip = ZipEncoder().encode(archive);
  if (zip == null) throw StateError('Không tạo được file Excel');
  return Uint8List.fromList(zip);
}
