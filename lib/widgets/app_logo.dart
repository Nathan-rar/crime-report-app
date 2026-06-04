import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    this.size = 64,
    this.showLabel = false,
    this.labelColor,
    super.key,
  });

  final double size;
  final bool showLabel;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(size * 0.22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.18),
                  blurRadius: size * 0.18,
                  offset: Offset(0, size * 0.06),
                ),
              ],
            ),
          ),
          Container(
            width: size * 0.68,
            height: size * 0.68,
            decoration: BoxDecoration(
              color: AppColors.deepBlue,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.silver, width: size * 0.035),
            ),
          ),
          Icon(Icons.travel_explore, size: size * 0.48, color: Colors.white),
          Positioned(
            right: size * 0.23,
            top: size * 0.24,
            child: Transform.rotate(
              angle: -0.72,
              child: Container(
                width: size * 0.1,
                height: size * 0.34,
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(size * 0.05),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (!showLabel) {
      return mark;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 12),
        Text(
          'Crime Report',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: labelColor ?? AppColors.navy,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
