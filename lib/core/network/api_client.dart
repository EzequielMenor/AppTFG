import 'dart:async' show TimeoutException;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api_exception.dart';
import 'cancel_token.dart';
import 'http_response.dart';

/// Cliente HTTP con reintentos automáticos, timeouts mejorados y resolución inteligente de IP.
///
/// Características:
/// - Reintentos automáticos (máx 3) con exponential backoff
/// - Timeouts apropiados: 30s normal, 60s uploads
/// - Resolución inteligente de IP del Mac (prioridad: env > localhost > IP)
/// - Logging detallado para debugging
abstract class ApiClient {
  Future<HttpResponse> get(
    String path, {
    Map<String, String>? queryParams,
    CancelToken? cancelToken,
  });

  Future<HttpResponse> post(String path, {Object? body, CancelToken? cancelToken});

  Future<HttpResponse> put(String path, {Object? body, CancelToken? cancelToken});

  Future<HttpResponse> delete(String path, {CancelToken? cancelToken});

  static final ApiClient _legacyInstance = HttpApiClient();

  static Future<http.Response> getLegacy(
    String path, {
    Map<String, String>? queryParams,
    CancelToken? cancelToken,
  }) async {
    debugPrint('[ApiClient] DEPRECATED static call: ApiClient.getLegacy($path)');
    final response = await _legacyInstance.get(
      path,
      queryParams: queryParams,
      cancelToken: cancelToken,
    );
    return http.Response.bytes(response.bodyBytes, response.statusCode, headers: response.headers);
  }

  static Future<http.Response> postLegacy(
    String path, {
    Object? body,
    CancelToken? cancelToken,
  }) async {
    debugPrint('[ApiClient] DEPRECATED static call: ApiClient.postLegacy($path)');
    final response = await _legacyInstance.post(path, body: body, cancelToken: cancelToken);
    return http.Response.bytes(response.bodyBytes, response.statusCode, headers: response.headers);
  }

  static Future<http.Response> putLegacy(
    String path, {
    Object? body,
    CancelToken? cancelToken,
  }) async {
    debugPrint('[ApiClient] DEPRECATED static call: ApiClient.putLegacy($path)');
    final response = await _legacyInstance.put(path, body: body, cancelToken: cancelToken);
    return http.Response.bytes(response.bodyBytes, response.statusCode, headers: response.headers);
  }

  static Future<http.Response> deleteLegacy(
    String path, {
    CancelToken? cancelToken,
  }) async {
    debugPrint('[ApiClient] DEPRECATED static call: ApiClient.deleteLegacy($path)');
    final response = await _legacyInstance.delete(path, cancelToken: cancelToken);
    return http.Response.bytes(response.bodyBytes, response.statusCode, headers: response.headers);
  }
}

class HttpApiClient implements ApiClient {
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
    CancelToken? cancelToken,
  ) async {
    int attempt = 0;
    while (attempt < _maxRetries) {
      try {
        _log('$method $path (attempt ${attempt + 1}/$_maxRetries)');
        cancelToken?.throwIfCancelled();
        final response = await request();
        cancelToken?.throwIfCancelled();
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
      } on RequestCancelledException {
        rethrow;
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

  @override
  Future<HttpResponse> get(
    String path, {
    Map<String, String>? queryParams,
    CancelToken? cancelToken,
  }) async {
    final response = await _executeWithRetry(
      () async {
        var uri = Uri.parse('$_baseUrl$path');
        if (queryParams != null) {
          uri = uri.replace(queryParameters: queryParams);
        }
        return http.get(uri, headers: _headers()).timeout(_standardTimeout);
      },
      'GET',
      path,
      cancelToken,
    );
    _mapError(response);
    return HttpResponse(
      statusCode: response.statusCode,
      bodyBytes: response.bodyBytes,
      headers: response.headers,
    );
  }

  @override
  Future<HttpResponse> post(
    String path, {
    Object? body,
    CancelToken? cancelToken,
  }) async {
    final response = await _executeWithRetry(
      () => http
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: _headers(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_standardTimeout),
      'POST',
      path,
      cancelToken,
    );
    _mapError(response);
    return HttpResponse(statusCode: response.statusCode, bodyBytes: response.bodyBytes, headers: response.headers);
  }

  @override
  Future<HttpResponse> put(
    String path, {
    Object? body,
    CancelToken? cancelToken,
  }) async {
    final response = await _executeWithRetry(
      () => http
          .put(
            Uri.parse('$_baseUrl$path'),
            headers: _headers(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_standardTimeout),
      'PUT',
      path,
      cancelToken,
    );
    _mapError(response);
    return HttpResponse(statusCode: response.statusCode, bodyBytes: response.bodyBytes, headers: response.headers);
  }

  @override
  Future<HttpResponse> delete(
    String path, {
    CancelToken? cancelToken,
  }) async {
    final response = await _executeWithRetry(
      () => http
          .delete(Uri.parse('$_baseUrl$path'), headers: _headers())
          .timeout(_standardTimeout),
      'DELETE',
      path,
      cancelToken,
    );
    _mapError(response);
    return HttpResponse(statusCode: response.statusCode, bodyBytes: response.bodyBytes, headers: response.headers);
  }

  Future<http.Response> postMultipart(
    String path, {
    required String filePath,
    required String fieldName,
    CancelToken? cancelToken,
  }) async {
    return _executeWithRetry(
      () async {
        cancelToken?.throwIfCancelled();
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
        cancelToken?.throwIfCancelled();
        return http.Response.fromStream(streamed);
      },
      'POST (multipart)',
      path,
      cancelToken,
    );
  }

  dynamic decodeJsonBody(HttpResponse response) {
    try {
      final body = utf8.decode(response.bodyBytes);
      if (body.isEmpty) return null;
      return jsonDecode(body);
    } on FormatException {
      throw const ServerErrorException(500, 'Invalid UTF-8 or malformed JSON response');
    }
  }

  void _mapError(http.Response response) {
    final status = response.statusCode;
    if (status >= 200 && status < 300) return;

    if (status == 403) throw const ForbiddenException();
    if (status == 404) throw const NotFoundException();
    if (status >= 500) throw ServerErrorException(status);
    if (status == 408) throw const ApiTimeoutException();

    throw GenericApiException('Request failed with status code $status', statusCode: status);
  }
}

class ApiClientLegacy {
  static Future<http.Response> get(
    String path, {
    Map<String, String>? queryParams,
    CancelToken? cancelToken,
  }) {
    return ApiClient.getLegacy(path, queryParams: queryParams, cancelToken: cancelToken);
  }

  static Future<http.Response> post(
    String path, {
    Object? body,
    CancelToken? cancelToken,
  }) {
    return ApiClient.postLegacy(path, body: body, cancelToken: cancelToken);
  }

  static Future<http.Response> put(
    String path, {
    Object? body,
    CancelToken? cancelToken,
  }) {
    return ApiClient.putLegacy(path, body: body, cancelToken: cancelToken);
  }

  static Future<http.Response> delete(
    String path, {
    CancelToken? cancelToken,
  }) {
    return ApiClient.deleteLegacy(path, cancelToken: cancelToken);
  }

  static Future<http.Response> postMultipart(
    String path, {
    required String filePath,
    required String fieldName,
    CancelToken? cancelToken,
  }) {
    return (ApiClient._legacyInstance as HttpApiClient).postMultipart(
      path,
      filePath: filePath,
      fieldName: fieldName,
      cancelToken: cancelToken,
    );
  }
}
