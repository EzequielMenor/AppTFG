class HttpResponse {
  final int statusCode;
  final List<int> bodyBytes;
  final Map<String, String> headers;

  const HttpResponse({
    required this.statusCode,
    required this.bodyBytes,
    required this.headers,
  });
}
