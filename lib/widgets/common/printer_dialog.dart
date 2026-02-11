import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bluetooth_classic/models/device.dart';

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
  List<Device> _pairedDevices = [];
  bool _loadingDevices = false;
  String? _selectedBluetoothAddress;

  @override
  void initState() {
    super.initState();
    _loadValues();
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
    if (mounted) Navigator.of(context).pop();
  }

  String _getSelectedDeviceName() {
    if (_selectedBluetoothAddress == null) return '';
    for (final d in _pairedDevices) {
      if (d.address == _selectedBluetoothAddress) {
        return d.name ?? d.address;
      }
    }
    return _selectedBluetoothAddress!;
  }

  Future<void> _testPrint() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    // Save current values temporarily for the test
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
    final error = await PrinterService().printTestLabel();

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testResult = error ?? 'Etiqueta de prueba enviada';
      });
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _portController.dispose();
    _nameController.dispose();
    super.dispose();
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
              final isSelected = _selectedBluetoothAddress == device.address;
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? Theme.of(context).colorScheme.primary : null,
                ),
                title: Text(device.name ?? 'Desconocido'),
                subtitle: Text(device.address),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  setState(() {
                    _selectedBluetoothAddress = device.address;
                    _nameController.text = device.name ?? device.address;
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
              FilledButton.icon(
                onPressed: _isTesting ? null : _testPrint,
                icon: _isTesting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.print),
                label: Text(
                    _isTesting ? 'Imprimiendo...' : 'Imprimir prueba'),
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
