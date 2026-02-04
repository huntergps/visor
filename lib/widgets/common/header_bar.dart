import 'package:flutter/material.dart';
import '../../core/app_sizes.dart';
import '../../core/app_text_styles.dart';

class HeaderBar extends StatelessWidget {
  const HeaderBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = AppSizes.isMobile;

    if (isMobile) {
      return _buildMobileHeader();
    }
    return _buildDesktopHeader();
  }

  Widget _buildMobileHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.paddingXSmall,
      ),
      child: Row(
        children: [
          // Logo
          Image.asset(
            'assets/mepriga_logo.png',
            height: 96,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox(width: 96, height: 96);
            },
          ),
          const SizedBox(width: 8),
          // Title text
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: AppTextStyles.headerTitleMobile,
                      children: [
                        const TextSpan(text: 'MEGA'),
                        TextSpan(
                          text: ' | ',
                          style: AppTextStyles.headerDividerMobile,
                        ),
                        const TextSpan(text: 'PRIMAVERA'),
                      ],
                    ),
                  ),
                ),
                Text(
                  'El encanto de comprar...!',
                  style: AppTextStyles.headerSloganMobile,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return SizedBox(
      height: 100,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.paddingSmall),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppTextStyles.headerTitle,
                children: [
                  const TextSpan(text: 'MEGA'),
                  TextSpan(
                    text: ' | ',
                    style: AppTextStyles.headerDivider,
                  ),
                  const TextSpan(text: 'PRIMAVERA'),
                  TextSpan(
                    text: '   |   ',
                    style: AppTextStyles.headerDividerSmall,
                  ),
                  TextSpan(
                    text: 'El encanto de comprar...!',
                    style: AppTextStyles.headerSlogan,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
