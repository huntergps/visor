import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// HTTP client service using Dio with SSL bypass for internal networks.
class HttpClientService {
  static final HttpClientService _instance = HttpClientService._internal();
  factory HttpClientService() => _instance;
  HttpClientService._internal();

  Dio? _dio;

  /// Get Dio client configured to accept all certificates
  Dio get client {
    _dio ??= _createDio();
    return _dio!;
  }

  /// Creates Dio instance with SSL bypass for internal networks
  Dio _createDio() {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 30),
    ));

    // Bypass SSL certificate verification for internal networks
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient()
        ..badCertificateCallback = (cert, host, port) => true;
      return client;
    };

    return dio;
  }

  /// Close the client
  void close() {
    _dio?.close();
    _dio = null;
  }
}
