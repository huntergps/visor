import 'dart:io';

import 'package:flutter/material.dart';
import '../../models/visor_config.dart';
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
  String _scannerStyle = 'floating';

  // Download progress state
  bool _isFetching = false;
  String _fetchStatus = '';

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
    _scannerStyle = service.scannerStyle;
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
    await service.setScannerStyle(_scannerStyle);

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
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Botón escáner flotante'),
              subtitle: Text(
                _scannerStyle == 'floating'
                    ? 'Botón flotante'
                    : 'En barra de búsqueda',
              ),
              value: _scannerStyle == 'floating',
              onChanged: (v) {
                setState(() {
                  _scannerStyle = v ? 'floating' : 'inline';
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            // Download progress indicator
            if (_isFetching) ...[
              LinearProgressIndicator(
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 6),
              Text(
                _fetchStatus,
                style: const TextStyle(fontSize: 12, color: Colors.blue),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    ImageCacheService().cacheDir ?? 'No inicializado',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.folder_open, size: 20),
                  tooltip: 'Abrir carpeta de cache',
                  onPressed: () {
                    final path = ImageCacheService().cacheDir;
                    if (path != null) {
                      Process.run('open', [path]);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isFetching
              ? null
              : () async {
                  // Manual Fetch by groups
                  try {
                    final sm = ScaffoldMessenger.of(context);

                    setState(() {
                      _isFetching = true;
                      _fetchStatus = 'Conectando...';
                    });

                    // 1. Save current form values first so the request uses them
                    final service = AppConfigService();
                    await service.setProtocol(_selectedProtocol);
                    await service.setHost(_hostController.text);
                    await service.setApiKey(_apiKeyController.text);

                    // 2. Fetch config with progress callback
                    final result =
                        await VisorConfigService().fetchAndSaveConfig(
                      onProgress: (current, total) {
                        if (mounted) {
                          setState(() {
                            _fetchStatus =
                                'Descargando imágenes grupo $current/$total...';
                          });
                        }
                      },
                    );
                    final config = result.config;

                    // 3. Update UI with fetched values
                    if (mounted) {
                      setState(() {
                        _isFetching = false;
                        _fetchStatus = '';
                        _timeoutController.text =
                            config.tiempoEspera.toString();
                        _adsDurationController.text =
                            config.tiempoAds.toString();
                      });

                      // Build image info string
                      final String imageInfo;
                      if (result.validImages > 0) {
                        final tipo =
                            config.esLink == 1 ? 'Enlace' : 'Base64';
                        imageInfo =
                            'Imágenes: ${result.validImages}/${result.totalSlots} ($tipo)';
                      } else if (result.totalSlots > 0) {
                        imageInfo =
                            'Imágenes: 0/${result.totalSlots} (usando ${VisorConfig.defaultImages.length} por defecto)';
                      } else {
                        imageInfo =
                            'Imágenes: ${VisorConfig.defaultImages.length} por defecto';
                      }

                      sm.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Configuración actualizada.\n'
                            'T. Anuncios: ${config.tiempoAds}s, '
                            '$imageInfo',
                          ),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  } catch (e, stack) {
                    debugPrint('ConfigDialog: Error fetching config: $e');
                    debugPrint('ConfigDialog: Stack: $stack');
                    if (mounted) {
                      setState(() {
                        _isFetching = false;
                        _fetchStatus = '';
                      });
                    }
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
          child: Text(_isFetching ? 'Descargando...' : 'Actualizar desde Servidor'),
        ),
        TextButton(
          onPressed: () async {
            final sm = ScaffoldMessenger.of(context);
            await ImageCacheService().clearProductCache();
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
