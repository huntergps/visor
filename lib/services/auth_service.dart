import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/auth_user.dart';
import 'app_config_service.dart';
import 'http_client_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Future<AuthUser> login(String username, String pin) async {
    final appConfig = AppConfigService();
    final protocol = appConfig.protocol;
    final host = appConfig.host;
    final apiKey = appConfig.apiKey;

    if (host.isEmpty) {
      throw Exception('Servidor no configurado');
    }

    final url = '$protocol://$host/api/erp_dat/v1/_process/visor_auth';
    debugPrint('AuthService: URL=$url, user=$username, apiKey=$apiKey');

    try {
      final response = await HttpClientService().client.get(
        url,
        queryParameters: {
          'param[username]': username.toUpperCase(),
          'param[passwd]': pin,
          'api_key': apiKey,
        },
        options: Options(responseType: ResponseType.plain),
      );

      if (response.statusCode == 200) {
        final trimmed = (response.data?.toString() ?? '').trim();
        debugPrint('AuthService: Response: $trimmed');

        if (trimmed.isEmpty || !trimmed.startsWith('{')) {
          throw Exception('Respuesta del servidor vacía o inválida');
        }

        // Try to parse JSON; server may return malformed JSON on errors
        Map<String, dynamic> json;
        try {
          json = Map<String, dynamic>.from(
            const JsonDecoder().convert(trimmed) as Map,
          );
        } on FormatException {
          // Server returns malformed JSON for some errors — check raw text
          if (trimmed.contains('NO_ENCONTRADO')) {
            throw Exception('Usuario no encontrado');
          }
          throw Exception('Respuesta del servidor inválida');
        }

        // Check for API-level errors in parsed JSON
        if (json['ok'] == false) {
          final error = json['error']?.toString() ?? '';
          if (error == 'NO_ENCONTRADO') {
            throw Exception('Usuario no encontrado');
          }
          throw Exception(error.isNotEmpty ? error : 'Error de autenticación');
        }

        return AuthUser.fromJson(json);
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('AuthService: DioException: ${e.type} - ${e.message}');
      if (e.response != null) {
        debugPrint('AuthService: Status: ${e.response?.statusCode}, Body: ${e.response?.data}');
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Tiempo de espera agotado. Verifique la conexión.');
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Endpoint no encontrado. Verifique la configuración del servidor.');
      }
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw Exception('Credenciales incorrectas');
      }
      throw Exception('Error de conexión: ${e.message}');
    }
  }
}
