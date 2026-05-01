import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:async' show TimeoutException;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cliente HTTP con reintentos automáticos, timeouts mejorados y resolución inteligente de IP.
///
/// Características:
/// - Reintentos automáticos (máx 3) con exponential backoff
/// - Timeouts apropiados: 30s normal, 60s uploads
/// - Resolución inteligente de IP del Mac (prioridad: env > localhost > IP)
/// - Logging detallado para debugging
class ApiClient {
  static const String _envUrl = String.fromEnvironment('BACKEND_URL');
  static const String _physicalDeviceIp =
      '192.168.10.162'; // Fallback si no hay env

  // Configuración de reintentos
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(milliseconds: 500);

  // Timeouts (aumentados para evitar fallos en primera request)
  static const Duration _standardTimeout = Duration(seconds: 30);
  static const Duration _uploadTimeout = Duration(seconds: 60);

  static bool get _isIosSimulator =>
      !kIsWeb &&
      Platform.isIOS &&
      Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');

  static String _getHostForPhysicalDevice() {
    // Prioridad de resolución:
    // 1. BACKEND_URL env var (manual override)
    // 2. localhost:8080 (por si el backend está en el mismo Mac en modo bridge)
    // 3. La IP registrada (fallback)
    if (_envUrl.isNotEmpty) {
      _log('Using BACKEND_URL from environment: $_envUrl');
      return _envUrl;
    }
    // Nota: Para iPhone físico, el simulador puede acceder a localhost en el Mac
    // Si esto no funciona, pasa: flutter run --dart-define=BACKEND_URL=http://192.168.10.162:8080
    return _physicalDeviceIp;
  }

  static String get _baseUrl {
    if (_envUrl.isNotEmpty) {
      _log('Using BACKEND_URL from environment: $_envUrl');
      return _envUrl;
    }
    if (kIsWeb) return 'http://localhost:8080';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    if (_isIosSimulator) return 'http://localhost:8080';
    if (Platform.isIOS) {
      final host = _getHostForPhysicalDevice();
      _log('iOS Physical Device - Using host: $host');
      return 'http://$host:8080';
    }
    return 'http://localhost:8080'; // macOS desktop
  }

  static void _log(String message) {
    debugPrint('[ApiClient] $message');
  }

  static Map<String, String> _headers() {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Ejecuta request con reintentos automáticos y exponential backoff
  static Future<http.Response> _executeWithRetry(
    Future<http.Response> Function() request,
    String method,
    String path,
  ) async {
    int attempt = 0;
    while (attempt < _maxRetries) {
      try {
        _log('$method $path (attempt ${attempt + 1}/$_maxRetries)');
        final response = await request();
        _log('$method $path completed with status ${response.statusCode}');
        return response;
      } on TimeoutException catch (_) {
        attempt++;
        if (attempt >= _maxRetries) {
          _log('❌ $method $path - TimeoutException after $attempt attempts');
          rethrow;
        }
        final delay =
            _baseRetryDelay * (1 << (attempt - 1)); // exponential backoff
        _log('⏳ $method $path timeout - retrying in ${delay.inMilliseconds}ms');
        await Future.delayed(delay);
      } catch (e) {
        attempt++;
        if (attempt >= _maxRetries) {
          _log('❌ $method $path - Exception: $e');
          rethrow;
        }
        _log('⚠️  $method $path error (attempt $attempt) - retrying: $e');
        await Future.delayed(_baseRetryDelay * (1 << (attempt - 1)));
      }
    }
    throw Exception('Failed after $_maxRetries attempts');
  }

  static Future<http.Response> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    return _executeWithRetry(
      () async {
        var uri = Uri.parse('$_baseUrl$path');
        if (queryParams != null) {
          uri = uri.replace(queryParameters: queryParams);
        }
        return http.get(uri, headers: _headers()).timeout(_standardTimeout);
      },
      'GET',
      path,
    );
  }

  static Future<http.Response> post(String path, {Object? body}) async {
    return _executeWithRetry(
      () => http
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: _headers(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_standardTimeout),
      'POST',
      path,
    );
  }

  static Future<http.Response> put(String path, {Object? body}) async {
    return _executeWithRetry(
      () => http
          .put(
            Uri.parse('$_baseUrl$path'),
            headers: _headers(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_standardTimeout),
      'PUT',
      path,
    );
  }

  static Future<http.Response> delete(String path) async {
    return _executeWithRetry(
      () => http
          .delete(Uri.parse('$_baseUrl$path'), headers: _headers())
          .timeout(_standardTimeout),
      'DELETE',
      path,
    );
  }

  static Future<http.Response> postMultipart(
    String path, {
    required String filePath,
    required String fieldName,
  }) async {
    return _executeWithRetry(
      () async {
        final session = Supabase.instance.client.auth.currentSession;
        final token = session?.accessToken;

        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$_baseUrl$path'),
        );
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }
        request.files.add(
          await http.MultipartFile.fromPath(fieldName, filePath),
        );

        final streamed = await request.send().timeout(_uploadTimeout);
        return http.Response.fromStream(streamed);
      },
      'POST (multipart)',
      path,
    );
  }
}
