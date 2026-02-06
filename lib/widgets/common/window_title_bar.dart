import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/app_colors.dart';
import '../../providers/visor_provider.dart';
import 'login_dialog.dart';

class WindowTitleBar extends StatelessWidget {
  const WindowTitleBar({super.key});

  static const double _height = 36;

  @override
  Widget build(BuildContext context) {
    if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: _height,
      child: Row(
        children: [
          // Draggable area fills remaining space
          const Expanded(child: DragToMoveArea(child: SizedBox.expand())),
          // User/login button
          _UserButton(),
          // About button
          _WindowButton(
            icon: Icons.info_outline,
            onPressed: () => _showAboutDialog(context),
          ),
          // Window control buttons
          _WindowButton(
            icon: Icons.remove,
            onPressed: () => windowManager.minimize(),
          ),
          _MaximizeButton(),
          _WindowButton(
            icon: Icons.close,
            onPressed: () => windowManager.close(),
            hoverColor: Colors.red,
            hoverIconColor: Colors.white,
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    const detailStyle = TextStyle(fontSize: 13, color: AppColors.textSecondary);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/mega_primavera_logo.png', height: 64),
              const SizedBox(height: 16),
              const Text(
                'Visor de Precios',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Versión 1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Desarrollador',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Elmer Salazar A.',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text('GalapagosTech', style: detailStyle),
              const SizedBox(height: 4),
              const Text('www.galapagos.tech', style: detailStyle),
              const SizedBox(height: 4),
              const Text('admin@galapagos.tech', style: detailStyle),
              const SizedBox(height: 4),
              const Text('esalazargps@gmail.com', style: detailStyle),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                '\u00a9 2025 GalapagosTech. Todos los derechos reservados.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
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
}

class _MaximizeButton extends StatefulWidget {
  @override
  State<_MaximizeButton> createState() => _MaximizeButtonState();
}

class _MaximizeButtonState extends State<_MaximizeButton> with WindowListener {
  bool _isMaximized = true;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _updateMaximized();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _updateMaximized() async {
    final maximized = await windowManager.isMaximized();
    if (mounted) setState(() => _isMaximized = maximized);
  }

  @override
  void onWindowMaximize() => setState(() => _isMaximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _isMaximized = false);

  @override
  Widget build(BuildContext context) {
    return _WindowButton(
      icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
      onPressed: () async {
        if (_isMaximized) {
          await windowManager.unmaximize();
        } else {
          await windowManager.maximize();
        }
      },
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? hoverColor;
  final Color? hoverIconColor;

  const _WindowButton({
    required this.icon,
    required this.onPressed,
    this.hoverColor,
    this.hoverIconColor,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isHoverStyled = _hovering && widget.hoverColor != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: WindowTitleBar._height,
          color: isHoverStyled
              ? widget.hoverColor
              : _hovering
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.transparent,
          child: Icon(
            widget.icon,
            size: 16,
            color: isHoverStyled
                ? widget.hoverIconColor ?? Colors.white
                : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

class _UserButton extends StatefulWidget {
  @override
  State<_UserButton> createState() => _UserButtonState();
}

class _UserButtonState extends State<_UserButton> {
  bool _hovering = false;

  void _handleTap() {
    final provider = context.read<VisorProvider>();

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VisorProvider>();
    final isLoggedIn = provider.authUser != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          height: WindowTitleBar._height,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          color: _hovering
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.transparent,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLoggedIn ? Icons.person : Icons.person_outline,
                size: 16,
                color: isLoggedIn
                    ? AppColors.brandPrimary
                    : Colors.grey.shade600,
              ),
              if (isLoggedIn) ...[
                const SizedBox(width: 4),
                Text(
                  provider.authUser!.name,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
