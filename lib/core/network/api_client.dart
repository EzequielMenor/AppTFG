import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cliente HTTP centralizado que inyecta automáticamente el JWT de Supabase
/// en cada petición al backend de Spring Boot.
class ApiClient {
  static const String _baseUrl = 'https://6e276db315298c.lhr.life';

  static Map<String, String> _headers() {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    var uri = Uri.parse('$_baseUrl$path');
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }
    return http.get(uri, headers: _headers());
  }

  static Future<http.Response> post(String path, {Object? body}) async {
    return http.post(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Future<http.Response> put(String path, {Object? body}) async {
    return http.put(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Future<http.Response> delete(String path) async {
    return http.delete(Uri.parse('$_baseUrl$path'), headers: _headers());
  }

  static Future<http.Response> postMultipart(
    String path, {
    required String filePath,
    required String fieldName,
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;

    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl$path'));
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }
}
