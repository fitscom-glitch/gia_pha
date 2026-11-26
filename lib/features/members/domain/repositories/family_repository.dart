import 'package:gia_pha/features/members/domain/entities/family_data.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/members/domain/entities/relationship.dart';

/// Hợp đồng truy cập dữ liệu gia phả. Bản cài đặt nằm ở tầng data.
abstract interface class FamilyRepository {
  Future<FamilyData> loadFamily();

  /// Lưu (thêm hoặc cập nhật) một người, kèm quan hệ mới nếu có, trong cùng 1 giao dịch.
  Future<void> savePerson(Person person, {Relationship? relationship});

  /// Thay toàn bộ quan hệ cha/mẹ của [childId] bằng [parents] (mỗi phần tử là một
  /// quan hệ parentChild với personBId = [childId]), trong cùng 1 giao dịch.
  Future<void> replaceParents(String childId, List<Relationship> parents);

  Future<void> deletePerson(String id);

  /// Đặt "con thứ mấy" = 1..n theo đúng thứ tự của [orderedIds].
  Future<void> setBirthOrders(List<String> orderedIds);
}
