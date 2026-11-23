import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';

/// Màu theo giới: nam (rồng) đỏ son, nữ (phụng) vàng kim.
class GenderStyle {
  const GenderStyle({
    required this.fill,
    required this.onFill,
    required this.ring,
    required this.accent,
  });

  final Color fill;
  final Color onFill;
  final Color ring;
  final Color accent;
}

GenderStyle genderStyle(Gender g) => switch (g) {
      Gender.male => const GenderStyle(
          fill: AppColors.red,
          onFill: AppColors.goldLight,
          ring: AppColors.gold,
          accent: AppColors.red,
        ),
      Gender.female => const GenderStyle(
          fill: AppColors.gold,
          onFill: AppColors.redDeep,
          ring: AppColors.red,
          accent: AppColors.goldDark,
        ),
      Gender.other => const GenderStyle(
          fill: AppColors.ink,
          onFill: AppColors.goldLight,
          ring: AppColors.gold,
          accent: AppColors.ink,
        ),
    };

String genderLabel(Gender g) => switch (g) {
      Gender.male => 'Nam',
      Gender.female => 'Nữ',
      Gender.other => 'Khác',
    };

/// Trả về file ảnh đại diện nếu có và còn tồn tại.
File? personPhotoFile(Person p) {
  final path = p.photoPath;
  if (path == null) return null;
  final f = File(path);
  return f.existsSync() ? f : null;
}

/// Ảnh đại diện tròn; chưa có ảnh thì hiện chữ cái đầu của tên gọi.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar(this.person, {super.key, this.radius = 20});

  final Person person;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final style = genderStyle(person.gender);
    final photo = personPhotoFile(person);
    final parts = person.fullName.trim().split(RegExp(r'\s+'));
    final initial = parts.last.isEmpty ? '?' : parts.last[0].toUpperCase();
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: style.fill,
        border: Border.all(color: style.ring, width: radius > 30 ? 3 : 2),
      ),
      child: photo != null
          ? Image.file(
              photo,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              cacheWidth: (radius * 6).round(),
            )
          : Text(
              initial,
              style: TextStyle(
                fontFamily: 'serif',
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.9,
                color: style.onFill,
              ),
            ),
    );
  }
}

/// "Con trưởng", "Con thứ 3"... hoặc null nếu chưa đặt thứ tự.
String? birthOrderLabel(int? order) {
  if (order == null) return null;
  return order == 1 ? 'Con trưởng' : 'Con thứ $order';
}

/// Dòng phụ dưới tên: năm sinh/mất và thứ tự anh em.
String personSubtitle(Person p) {
  final order = birthOrderLabel(p.birthOrder);
  return [
    if (p.lifespan.isNotEmpty) p.lifespan,
    if (order != null) order,
  ].join(' · ');
}
