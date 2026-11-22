import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gia_pha/core/theme/app_colors.dart';

/// AppBar nền ngà, tiêu đề đỏ thẫm, viền vàng–đỏ mảnh phía dưới.
class GoldAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GoldAppBar({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  static const _lineHeight = 3.0;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + _lineHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.card,
      foregroundColor: AppColors.redDark,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: const TextStyle(
        fontFamily: 'serif',
        fontWeight: FontWeight.w700,
        fontSize: 21,
        color: AppColors.redDark,
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(_lineHeight),
        child: SizedBox(
          height: _lineHeight,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.red, AppColors.gold, AppColors.red],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
