import 'package:flutter/material.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
import 'package:gia_pha/core/widgets/ornaments/motif_data.dart';
import 'package:gia_pha/core/widgets/ornaments/motif_painter.dart';
import 'package:gia_pha/core/widgets/ornaments/ornaments.dart';

/// Biểu ngữ "rồng phụng chầu": rồng bên trái, phụng bên phải.
/// Giữa là [title] + [subtitle], hoặc một câu [quote] nếu có.
class DragonPhoenixBanner extends StatelessWidget {
  const DragonPhoenixBanner({
    super.key,
    this.title = '',
    this.subtitle = '',
    this.quote,
  });

  final String title;
  final String subtitle;
  final String? quote;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 124,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.redDark, AppColors.red, AppColors.redDark],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(
                painter: CloudPatternPainter(color: Color(0x2EF6DE94), cell: 60),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
              child: Row(
                children: [
                  const SizedBox(
                    width: 100,
                    child: MotifView(motif: dragonMotif, color: AppColors.goldLight),
                  ),
                  Expanded(child: _center()),
                  const SizedBox(
                    width: 100,
                    child: MotifView(
                      motif: phoenixMotif,
                      color: AppColors.goldLight,
                      flipX: true,
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MeanderStrip(height: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _center() {
    if (quote != null) {
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            quote!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'serif',
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              fontSize: 17,
              height: 1.3,
              color: AppColors.goldLight,
            ),
          ),
        ),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'serif',
              fontWeight: FontWeight.w700,
              fontSize: 24,
              letterSpacing: 3,
              color: AppColors.goldLight,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12.5, color: AppColors.gold),
        ),
      ],
    );
  }
}
