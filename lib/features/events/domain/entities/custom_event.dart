/// Ngày kỷ niệm do người dùng tự nhập (dương hoặc âm lịch).
class CustomEvent {
  const CustomEvent({
    required this.id,
    required this.title,
    required this.day,
    required this.month,
    required this.year,
    required this.createdAt,
    this.note,
    this.isLunar = false,
    this.repeatYearly = true,
  });

  final String id;
  final String title;
  final String? note;

  /// Ngày/tháng/năm theo lịch được chọn ([isLunar]). Với sự kiện lặp lại hằng năm,
  /// [year] là năm gốc (để tính "lần thứ N").
  final int day;
  final int month;
  final int year;
  final bool isLunar;
  final bool repeatYearly;
  final DateTime createdAt;
}
