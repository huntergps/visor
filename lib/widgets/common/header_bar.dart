import 'package:flutter/material.dart';
import '../../core/app_text_styles.dart';

class HeaderBar extends StatelessWidget {
  const HeaderBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Center(
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
    );
  }
}
