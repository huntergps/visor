import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfigService {
  static final AppConfigService _instance = AppConfigService._internal();
  factory AppConfigService() => _instance;
  AppConfigService._internal();

  late SharedPreferences _prefs;

  // Keys
  static const String _keyProtocol = 'protocol';
  static const String _keyHost = 'host';
  static const String _keyApiKey = 'api_key';
  static const String _keyIdleTimeout = 'idle_timeout';
  static const String _keyAdsDuration = 'ads_duration';
  static const String _keyScannerStyle = 'scanner_style';
  static const String _keyFabPositionRight = 'fab_position_right';
  static const String _keyFabPositionBottom = 'fab_position_bottom';
  static const String _keyPrinterType = 'printer_type';
  static const String _keyPrinterAddress = 'printer_address';
  static const String _keyPrinterPort = 'printer_port';
  static const String _keyPrinterName = 'printer_name';

  // Defaults from environment variables (with fallbacks)
  String get _defaultProtocol => dotenv.env['VISOR_PROTOCOL'] ?? 'http';
  String get _defaultHost => dotenv.env['VISOR_HOST'] ?? '';
  String get _defaultApiKey => dotenv.env['VISOR_API_KEY'] ?? '';
  static const int _defaultIdleTimeout = 60; // seconds
  static const int _defaultAdsDuration = 5; // seconds
  static const String _defaultScannerStyle = 'floating';
  static const double _defaultFabPositionRight = 24.0;
  static const double _defaultFabPositionBottom = 150.0;

  Future<void> init() async {
    await dotenv.load(fileName: '.env');
    _prefs = await SharedPreferences.getInstance();
  }

  String get protocol => _prefs.getString(_keyProtocol) ?? _defaultProtocol;
  String get host => _prefs.getString(_keyHost) ?? _defaultHost;
  String get apiKey => _prefs.getString(_keyApiKey) ?? _defaultApiKey;
  int get idleTimeout => _prefs.getInt(_keyIdleTimeout) ?? _defaultIdleTimeout;
  int get adsDuration => _prefs.getInt(_keyAdsDuration) ?? _defaultAdsDuration;
  String get scannerStyle =>
      _prefs.getString(_keyScannerStyle) ?? _defaultScannerStyle;
  double get fabPositionRight =>
      _prefs.getDouble(_keyFabPositionRight) ?? _defaultFabPositionRight;
  double get fabPositionBottom =>
      _prefs.getDouble(_keyFabPositionBottom) ?? _defaultFabPositionBottom;

  String get printerType => _prefs.getString(_keyPrinterType) ?? '';
  String get printerAddress => _prefs.getString(_keyPrinterAddress) ?? '';
  int get printerPort => _prefs.getInt(_keyPrinterPort) ?? 6101;
  String get printerName => _prefs.getString(_keyPrinterName) ?? '';

  Future<void> setProtocol(String value) async {
    if (value != 'http' && value != 'https') return;
    await _prefs.setString(_keyProtocol, value);
  }

  Future<void> setHost(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    await _prefs.setString(_keyHost, trimmed);
  }

  Future<void> setApiKey(String value) => _prefs.setString(_keyApiKey, value);

  Future<void> setIdleTimeout(int value) async {
    if (value < 1) return;
    await _prefs.setInt(_keyIdleTimeout, value);
  }

  Future<void> setAdsDuration(int value) async {
    if (value < 1) return;
    await _prefs.setInt(_keyAdsDuration, value);
  }

  Future<void> setScannerStyle(String value) async {
    if (value != 'floating' && value != 'inline') return;
    await _prefs.setString(_keyScannerStyle, value);
  }

  Future<void> setFabPositionRight(double value) =>
      _prefs.setDouble(_keyFabPositionRight, value);

  Future<void> setFabPositionBottom(double value) =>
      _prefs.setDouble(_keyFabPositionBottom, value);

  Future<void> setPrinterType(String value) =>
      _prefs.setString(_keyPrinterType, value);

  Future<void> setPrinterAddress(String value) =>
      _prefs.setString(_keyPrinterAddress, value.trim());

  Future<void> setPrinterPort(int value) =>
      _prefs.setInt(_keyPrinterPort, value);

  Future<void> setPrinterName(String value) =>
      _prefs.setString(_keyPrinterName, value.trim());

  bool get hasPrinterConfigured =>
      printerType.isNotEmpty && printerAddress.isNotEmpty;
}
