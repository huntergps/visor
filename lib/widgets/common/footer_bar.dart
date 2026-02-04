import 'package:flutter/material.dart';

import 'config_dialog.dart';

import '../../core/app_colors.dart';
import '../../core/app_sizes.dart';
import '../../core/app_text_styles.dart';

class FooterBar extends StatelessWidget {
  const FooterBar({super.key});

  void _openConfig(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ConfigDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppSizes.isMobile;

    return Container(
      height: isMobile ? 36 : 48,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: AppSizes.paddingBase),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tu supermercado de ',
                style: AppTextStyles.footerText,
              ),
              GestureDetector(
                onLongPress: () => _openConfig(context),
                onDoubleTap: () => _openConfig(context),
                child: Text(
                  'confianza',
                  style: AppTextStyles.custom(
                    fontSize: isMobile ? AppSizes.fontCaption : 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandPrimary,
                  ),
                ),
              ),
              Text(
                ', siempre a tu servicio.',
                style: AppTextStyles.footerText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
