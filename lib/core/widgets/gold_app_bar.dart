import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
import 'package:gia_pha/core/widgets/ornaments/ornaments.dart';

/// AppBar đỏ son, chữ vàng, viền hồi văn phía dưới.
class GoldAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GoldAppBar({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  static const _stripHeight = 12.0;

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + _stripHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.red,
      foregroundColor: AppColors.goldLight,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: const TextStyle(
        fontFamily: 'serif',
        fontWeight: FontWeight.w700,
        fontSize: 20,
        letterSpacing: 0.5,
        color: AppColors.goldLight,
      ),
      flexibleSpace: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.red, AppColors.redDark],
          ),
        ),
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(_stripHeight),
        child: MeanderStrip(height: _stripHeight),
      ),
    );
  }
}
