import 'package:flutter/material.dart';
import '../../services/app_config_service.dart';
import '../../services/image_cache_service.dart';
import '../../services/visor_config_service.dart';

class ConfigDialog extends StatefulWidget {
  const ConfigDialog({super.key});

  @override
  State<ConfigDialog> createState() => _ConfigDialogState();
}

class _ConfigDialogState extends State<ConfigDialog> {
  final _hostController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _timeoutController = TextEditingController();
  final _adsDurationController = TextEditingController();

  String _selectedProtocol = 'http';

  // Static dropdown items - created once
  static const _protocolItems = [
    DropdownMenuItem(value: 'http', child: Text('http')),
    DropdownMenuItem(value: 'https', child: Text('https')),
  ];

  @override
  void initState() {
    super.initState();
    _loadValues();
  }

  void _loadValues() {
    final service = AppConfigService();
    _selectedProtocol = service.protocol;
    _hostController.text = service.host;
    _apiKeyController.text = service.apiKey;
    _timeoutController.text = service.idleTimeout.toString();
    _adsDurationController.text = service.adsDuration.toString();
    // No setState needed in initState - build hasn't run yet
  }

  Future<void> _save() async {
    final service = AppConfigService();
    await service.setProtocol(_selectedProtocol);
    await service.setHost(_hostController.text);
    await service.setApiKey(_apiKeyController.text);
    await service.setIdleTimeout(int.tryParse(_timeoutController.text) ?? 60);
    await service.setAdsDuration(
      int.tryParse(_adsDurationController.text) ?? 5,
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _apiKeyController.dispose();
    _timeoutController.dispose();
    _adsDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configuración'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedProtocol,
              items: _protocolItems,
              onChanged: (v) => setState(() => _selectedProtocol = v!),
              decoration: const InputDecoration(labelText: 'Protocolo'),
            ),
            TextField(
              controller: _hostController,
              decoration: const InputDecoration(labelText: 'Servidor (Host)'),
            ),
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(labelText: 'API Key'),
            ),
            TextField(
              controller: _timeoutController,
              decoration: const InputDecoration(
                labelText: 'Tiempo inactividad (segundos)',
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _adsDurationController,
              decoration: const InputDecoration(
                labelText: 'Tiempo rotación anuncios (segundos)',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            // Test connection / Manual Fetch
            try {
              final sm = ScaffoldMessenger.of(context);

              // 1. Save current form values first so the request uses them
              final service = AppConfigService();
              await service.setProtocol(_selectedProtocol);
              await service.setHost(_hostController.text);
              await service.setApiKey(_apiKeyController.text);

              // 2. Fetch config (this saves to VisorConfigService cache)
              final config = await VisorConfigService().fetchAndSaveConfig();

              // 2. Update UI with fetched values
              if (mounted) {
                setState(() {
                  _timeoutController.text = config.tiempoEspera.toString();
                  _adsDurationController.text = config.tiempoAds.toString();
                });

                sm.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Configuración actualizada.\n'
                      'T. Anuncios: ${config.tiempoAds}s, '
                      'Imágenes: ${config.images.length} (${config.esLink == 1 ? "Enlace" : "Base64"})',
                    ),
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          },
          child: const Text('Actualizar desde Servidor'),
        ),
        TextButton(
          onPressed: () async {
            final sm = ScaffoldMessenger.of(context);
            await ImageCacheService().clearCache();
            VisorConfigService().clearCache();
            sm.showSnackBar(
              const SnackBar(
                content: Text('Cache de imágenes limpiado'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: const Text('Limpiar Cache'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}
