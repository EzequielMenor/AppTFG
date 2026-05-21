import 'package:flutter_test/flutter_test.dart';
import 'package:gym_analytics_mobile/core/network/api_client.dart';

void main() {
  group('HttpApiClient.resolveBaseUrl', () {
    test('uses localhost for iOS when no BACKEND_URL is provided', () {
      final baseUrl = HttpApiClient.resolveBaseUrl(
        isWeb: false,
        isAndroid: false,
        isIos: true,
        envUrl: '',
      );

      expect(baseUrl, 'http://localhost:8080');
    });

    test('prefers BACKEND_URL over platform defaults', () {
      final baseUrl = HttpApiClient.resolveBaseUrl(
        isWeb: false,
        isAndroid: false,
        isIos: true,
        envUrl: 'http://192.168.10.81:8080',
      );

      expect(baseUrl, 'http://192.168.10.81:8080');
    });
  });
}
