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

  // Defaults from environment variables (with fallbacks)
  String get _defaultProtocol => dotenv.env['VISOR_PROTOCOL'] ?? 'http';
  String get _defaultHost => dotenv.env['VISOR_HOST'] ?? '';
  String get _defaultApiKey => dotenv.env['VISOR_API_KEY'] ?? '';
  static const int _defaultIdleTimeout = 60; // seconds
  static const int _defaultAdsDuration = 5; // seconds

  Future<void> init() async {
    await dotenv.load(fileName: '.env');
    _prefs = await SharedPreferences.getInstance();
  }

  String get protocol => _prefs.getString(_keyProtocol) ?? _defaultProtocol;
  String get host => _prefs.getString(_keyHost) ?? _defaultHost;
  String get apiKey => _prefs.getString(_keyApiKey) ?? _defaultApiKey;
  int get idleTimeout => _prefs.getInt(_keyIdleTimeout) ?? _defaultIdleTimeout;
  int get adsDuration => _prefs.getInt(_keyAdsDuration) ?? _defaultAdsDuration;

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
}
