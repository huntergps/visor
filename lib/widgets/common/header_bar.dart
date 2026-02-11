import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_sizes.dart';
import '../../core/app_text_styles.dart';
import '../../providers/visor_provider.dart';
import '../../services/hardware_scanner_service.dart';
import 'login_dialog.dart';

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
    final compact = HardwareScannerService.isAvailable;

    return Builder(
      builder: (context) {
        final provider = context.watch<VisorProvider>();
        final isLoggedIn = provider.authUser != null;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.paddingXSmall,
            vertical: compact ? 4 : 0,
          ),
          child: Row(
            children: [
              // Logo — hide on compact (hardware scanner devices)
              if (!compact) ...[
                Image.asset(
                  'assets/mepriga_logo.png',
                  height: 96,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(width: 96, height: 96);
                  },
                ),
                const SizedBox(width: 8),
              ],
              // Title text
              Expanded(
                child: GestureDetector(
                  onTap: () => _showAboutDialog(context),
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
                      if (!compact)
                        Text(
                          'El encanto de comprar...!',
                          style: AppTextStyles.headerSloganMobile,
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ),
              // Login button
              GestureDetector(
                onTap: () => _handleUserTap(context, provider),
                child: Icon(
                  isLoggedIn ? Icons.person : Icons.person_outline,
                  size: 24,
                  color: isLoggedIn
                      ? AppColors.brandPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleUserTap(BuildContext context, VisorProvider provider) {
    if (provider.authUser != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(provider.authUser!.name),
          content: Text(
            provider.isEditor
                ? 'Editor de imágenes activo'
                : 'Sin permisos de edición',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cerrar'),
            ),
            TextButton(
              onPressed: () {
                provider.logout();
                Navigator.of(ctx).pop();
              },
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => const LoginDialog(),
      );
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/mepriga_logo.png', height: 56),
              const SizedBox(height: 12),
              const Text(
                'TheosVisor',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Versión 1.0.0',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'GalapagosTech',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const Text(
                'www.galapagos.tech',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              const Text(
                '\u00a9 2025 GalapagosTech',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
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
