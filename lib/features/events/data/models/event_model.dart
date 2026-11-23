import 'package:gia_pha/features/events/domain/entities/custom_event.dart';

class EventModel extends CustomEvent {
  const EventModel({
    required super.id,
    required super.title,
    required super.day,
    required super.month,
    required super.year,
    required super.createdAt,
    super.note,
    super.isLunar,
    super.repeatYearly,
  });

  factory EventModel.fromEntity(CustomEvent e) => EventModel(
        id: e.id,
        title: e.title,
        day: e.day,
        month: e.month,
        year: e.year,
        createdAt: e.createdAt,
        note: e.note,
        isLunar: e.isLunar,
        repeatYearly: e.repeatYearly,
      );

  factory EventModel.fromMap(Map<String, Object?> m) => EventModel(
        id: m['id'] as String,
        title: m['title'] as String,
        note: m['note'] as String?,
        day: m['day'] as int,
        month: m['month'] as int,
        year: m['year'] as int,
        isLunar: (m['is_lunar'] as int? ?? 0) == 1,
        repeatYearly: (m['repeat_yearly'] as int? ?? 1) == 1,
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'note': note,
        'day': day,
        'month': month,
        'year': year,
        'is_lunar': isLunar ? 1 : 0,
        'repeat_yearly': repeatYearly ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };
}
