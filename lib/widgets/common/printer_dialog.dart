import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/printer_config.dart';
import '../../services/printer_service.dart';
import '../../services/app_config_service.dart';

class PrinterDialog extends StatefulWidget {
  const PrinterDialog({super.key});

  @override
  State<PrinterDialog> createState() => _PrinterDialogState();
}

class _PrinterDialogState extends State<PrinterDialog> {
  final _addressController = TextEditingController();
  final _portController = TextEditingController();
  final _nameController = TextEditingController();

  PrinterType _selectedType = PrinterType.wifi;
  bool _isTesting = false;
  String? _testResult;

  // Bluetooth devices
  List<BtDevice> _pairedDevices = [];
  bool _loadingDevices = false;
  String? _selectedBluetoothAddress;

  // Label coordinate controllers
  final Map<String, TextEditingController> _coordControllers = {};
  final _offsetXController = TextEditingController(text: '0');
  final _offsetYController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _initCoordControllers();
    _loadValues();
  }

  void _initCoordControllers() {
    final config = AppConfigService();
    for (final key in AppConfigService.labelCoordDefaults.keys) {
      _coordControllers[key] = TextEditingController(
        text: config.getLabelCoord(key).toString(),
      );
    }
  }

  void _loadValues() {
    final config = AppConfigService();
    _selectedType = config.printerType == 'bluetooth'
        ? PrinterType.bluetooth
        : PrinterType.wifi;
    _addressController.text = config.printerAddress;
    _portController.text = config.printerPort.toString();
    _nameController.text = config.printerName;

    if (_selectedType == PrinterType.bluetooth &&
        config.printerAddress.isNotEmpty) {
      _selectedBluetoothAddress = config.printerAddress;
    }

    if (_selectedType == PrinterType.bluetooth) {
      _loadPairedDevices();
    }
  }

  Future<void> _loadPairedDevices() async {
    setState(() => _loadingDevices = true);
    try {
      final devices = await PrinterService().getPairedDevices();
      if (mounted) {
        setState(() {
          _pairedDevices = devices;
          _loadingDevices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingDevices = false);
      }
    }
  }

  Future<void> _save() async {
    final address = _selectedType == PrinterType.bluetooth
        ? _selectedBluetoothAddress ?? ''
        : _addressController.text.trim();

    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese la dirección de la impresora')),
      );
      return;
    }

    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : (_selectedType == PrinterType.bluetooth
            ? _getSelectedDeviceName()
            : address);

    final printerConfig = PrinterConfig(
      name: name,
      type: _selectedType,
      address: address,
      port: int.tryParse(_portController.text) ?? 6101,
    );

    await PrinterService().saveConfig(printerConfig);

    // Save label coordinates
    final config = AppConfigService();
    for (final entry in _coordControllers.entries) {
      final value = int.tryParse(entry.value.text) ??
          AppConfigService.labelCoordDefaults[entry.key] ??
          0;
      await config.setLabelCoord(entry.key, value);
    }

    if (mounted) Navigator.of(context).pop();
  }

  String _getSelectedDeviceName() {
    if (_selectedBluetoothAddress == null) return '';
    for (final d in _pairedDevices) {
      if (d.address == _selectedBluetoothAddress) {
        return d.name.isNotEmpty ? d.name : d.address;
      }
    }
    return _selectedBluetoothAddress!;
  }

  bool _isCalibrating = false;

  Future<void> _calibrate() async {
    final address = _selectedType == PrinterType.bluetooth
        ? _selectedBluetoothAddress ?? ''
        : _addressController.text.trim();
    if (address.isEmpty) return;

    final tempConfig = PrinterConfig(
      name: _nameController.text.trim(),
      type: _selectedType,
      address: address,
      port: int.tryParse(_portController.text) ?? 6101,
    );
    await PrinterService().saveConfig(tempConfig);

    setState(() {
      _isCalibrating = true;
      _testResult = null;
    });
    final error = await PrinterService().calibrate();
    if (mounted) {
      setState(() {
        _isCalibrating = false;
        _testResult = error ?? 'Calibración completada';
      });
    }
  }

  Future<void> _testPrint() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final address = _selectedType == PrinterType.bluetooth
        ? _selectedBluetoothAddress ?? ''
        : _addressController.text.trim();

    if (address.isEmpty) {
      setState(() {
        _isTesting = false;
        _testResult = 'Ingrese la dirección de la impresora';
      });
      return;
    }

    final tempConfig = PrinterConfig(
      name: _nameController.text.trim(),
      type: _selectedType,
      address: address,
      port: int.tryParse(_portController.text) ?? 6101,
    );

    await PrinterService().saveConfig(tempConfig);

    // Save coordinates before printing test
    final config = AppConfigService();
    for (final entry in _coordControllers.entries) {
      final value = int.tryParse(entry.value.text) ??
          AppConfigService.labelCoordDefaults[entry.key] ??
          0;
      await config.setLabelCoord(entry.key, value);
    }

    final error = await PrinterService().printTestLabel();

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testResult = error ?? 'Etiqueta de prueba enviada';
      });
    }
  }

  void _applyOffsetX() {
    final offset = int.tryParse(_offsetXController.text) ?? 0;
    if (offset == 0) return;
    for (final key in AppConfigService.labelCoordDefaults.keys) {
      if (key.endsWith('_x')) {
        final current = int.tryParse(_coordControllers[key]?.text ?? '0') ?? 0;
        _coordControllers[key]?.text = (current + offset).toString();
      }
    }
    _offsetXController.text = '0';
    setState(() {});
  }

  void _applyOffsetY() {
    final offset = int.tryParse(_offsetYController.text) ?? 0;
    if (offset == 0) return;
    for (final key in AppConfigService.labelCoordDefaults.keys) {
      if (key.endsWith('_y')) {
        final current = int.tryParse(_coordControllers[key]?.text ?? '0') ?? 0;
        _coordControllers[key]?.text = (current + offset).toString();
      }
    }
    _offsetYController.text = '0';
    setState(() {});
  }

  Future<void> _resetCoords() async {
    await AppConfigService().resetLabelCoords();
    for (final entry in AppConfigService.labelCoordDefaults.entries) {
      _coordControllers[entry.key]?.text = entry.value.toString();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _addressController.dispose();
    _portController.dispose();
    _nameController.dispose();
    _offsetXController.dispose();
    _offsetYController.dispose();
    for (final c in _coordControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _buildCoordRow(String label, String xKey, String yKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          const Text(' X:', style: TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          SizedBox(
            width: 52,
            child: TextField(
              controller: _coordControllers[xKey],
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          const Text(' Y:', style: TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          SizedBox(
            width: 52,
            child: TextField(
              controller: _coordControllers[yKey],
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelCoords() {
    return ExpansionTile(
      title: const Text(
        'Coordenadas de etiqueta',
        style: TextStyle(fontSize: 14),
      ),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      children: [
        // Global offset controls
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const SizedBox(
                width: 68,
                child: Text('Mover todo', style: TextStyle(fontSize: 12)),
              ),
              const Text('X:', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 4),
              SizedBox(
                width: 48,
                child: TextField(
                  controller: _offsetXController,
                  keyboardType:
                      const TextInputType.numberWithOptions(signed: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[-0-9]')),
                  ],
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  onPressed: _applyOffsetX,
                  icon: const Icon(Icons.check, size: 14),
                  padding: EdgeInsets.zero,
                  tooltip: 'Aplicar a todos los X',
                ),
              ),
              const SizedBox(width: 4),
              const Text('Y:', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 4),
              SizedBox(
                width: 48,
                child: TextField(
                  controller: _offsetYController,
                  keyboardType:
                      const TextInputType.numberWithOptions(signed: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[-0-9]')),
                  ],
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  onPressed: _applyOffsetY,
                  icon: const Icon(Icons.check, size: 14),
                  padding: EdgeInsets.zero,
                  tooltip: 'Aplicar a todos los Y',
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: 4),
        // LT offset
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              const SizedBox(
                width: 100,
                child: Text('Offset (LT)', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 20),
              const SizedBox(width: 4),
              SizedBox(
                width: 52,
                child: TextField(
                  controller: _coordControllers['lt'],
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[-0-9]')),
                  ],
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        _buildCoordRow('Nombre L1', 'name1_x', 'name1_y'),
        _buildCoordRow('Nombre L2', 'name2_x', 'name2_y'),
        _buildCoordRow('Código', 'code_x', 'code_y'),
        _buildCoordRow('Cód. barras', 'barcode_x', 'barcode_y'),
        _buildCoordRow('Presentación', 'presentation_x', 'presentation_y'),
        _buildCoordRow('Precio', 'price_x', 'price_y'),
        _buildCoordRow('IVA', 'iva_x', 'iva_y'),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _resetCoords,
            icon: const Icon(Icons.restore, size: 16),
            label: const Text(
              'Restaurar predeterminados',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type selector (Bluetooth only on Android)
        if (PrinterService().isBluetoothSupported)
          SegmentedButton<PrinterType>(
            segments: const [
              ButtonSegment(
                value: PrinterType.wifi,
                label: Text('WiFi'),
                icon: Icon(Icons.wifi),
              ),
              ButtonSegment(
                value: PrinterType.bluetooth,
                label: Text('Bluetooth'),
                icon: Icon(Icons.bluetooth),
              ),
            ],
            selected: {_selectedType},
            onSelectionChanged: (set) {
              setState(() {
                _selectedType = set.first;
                if (_selectedType == PrinterType.bluetooth &&
                    _pairedDevices.isEmpty) {
                  _loadPairedDevices();
                }
              });
            },
          ),
        const SizedBox(height: 16),

        // WiFi fields
        if (_selectedType == PrinterType.wifi) ...[
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Dirección IP',
              hintText: '192.168.1.100',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _portController,
            decoration: const InputDecoration(
              labelText: 'Puerto TCP',
              hintText: '6101',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],

        // Bluetooth device list
        if (_selectedType == PrinterType.bluetooth) ...[
          if (_loadingDevices)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_pairedDevices.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No se encontraron dispositivos pareados.\n'
                'Paree la impresora desde Ajustes de Bluetooth.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._pairedDevices.map((device) {
              final isSelected =
                  _selectedBluetoothAddress == device.address;
              return ListTile(
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text(
                  device.name.isNotEmpty ? device.name : 'Desconocido',
                ),
                subtitle: Text(device.address),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  setState(() {
                    _selectedBluetoothAddress = device.address;
                    _nameController.text = device.name.isNotEmpty
                        ? device.name
                        : device.address;
                  });
                },
              );
            }),
          TextButton.icon(
            onPressed: _loadPairedDevices,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Actualizar dispositivos'),
          ),
        ],

        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nombre (opcional)',
            hintText: 'Zebra ZQ521',
          ),
        ),

        // Label coordinates (expandable)
        const SizedBox(height: 8),
        _buildLabelCoords(),

        // Test result
        if (_testResult != null) ...[
          const SizedBox(height: 12),
          Text(
            _testResult!,
            style: TextStyle(
              fontSize: 13,
              color: _testResult!.startsWith('Error') ||
                      _testResult!.startsWith('Ingrese')
                  ? Colors.red
                  : Colors.green,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile =
        !Platform.isWindows && !Platform.isLinux && !Platform.isMacOS;

    if (isMobile) {
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Impresora'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              TextButton(
                onPressed: _save,
                child: const Text('Guardar'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildFormContent(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isCalibrating ? null : _calibrate,
                      icon: _isCalibrating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.tune),
                      label: Text(
                        _isCalibrating ? 'Calibrando...' : 'Calibrar',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isTesting ? null : _testPrint,
                      icon: _isTesting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.print),
                      label: Text(
                        _isTesting ? 'Imprimiendo...' : 'Imprimir prueba',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return AlertDialog(
      title: const Text('Impresora'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(child: _buildFormContent()),
      ),
      actions: [
        TextButton(
          onPressed: _isTesting ? null : _testPrint,
          child: Text(_isTesting ? 'Imprimiendo...' : 'Imprimir prueba'),
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
