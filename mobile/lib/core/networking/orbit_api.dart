import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

abstract interface class OrbitApiService {
  Future<Map<String, dynamic>> health();
  Future<List<Map<String, dynamic>>> tasks();
  Future<Map<String, dynamic>> submit(String request);
  Future<Map<String, dynamic>> stop(String id);
  Future<Uint8List> evidence(String id);
  void close();
}

class OrbitApi implements OrbitApiService {
  OrbitApi(String baseUrl, this.token)
    : baseUri = Uri.parse(baseUrl.trim().replaceAll(RegExp(r'/+$'), ''));

  final Uri baseUri;
  final String token;
  final HttpClient _client = HttpClient()..connectionTimeout = const Duration(seconds: 5);

  @override
  Future<Map<String, dynamic>> health() async => _map(await _request('GET', '/health', auth: false));

  @override
  Future<List<Map<String, dynamic>>> tasks() async {
    final value = await _request('GET', '/v1/tasks');
    return (value as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<Map<String, dynamic>> submit(String request) async =>
      _map(await _request('POST', '/v1/tasks', body: {'request': request}));

  @override
  Future<Map<String, dynamic>> stop(String id) async =>
      _map(await _request('POST', '/v1/tasks/${Uri.encodeComponent(id)}/stop'));

  @override
  Future<Uint8List> evidence(String id) async {
    final uri = baseUri.resolve('/v1/evidence/${Uri.encodeComponent(id)}');
    final request = await _client.getUrl(uri);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Evidence request failed (${response.statusCode})', uri: uri);
    }
    return (await response.fold<BytesBuilder>(BytesBuilder(), (builder, chunk) => builder..add(chunk))).takeBytes();
  }

  Future<dynamic> _request(String method, String path, {Object? body, bool auth = true}) async {
    final uri = baseUri.resolve(path);
    final request = await _client.openUrl(method, uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (auth) request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final response = await request.close();
    final payload = await response.transform(utf8.decoder).join();
    dynamic decoded;
    if (payload.isNotEmpty) {
      try {
        decoded = jsonDecode(payload);
      } on FormatException {
        decoded = payload;
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = decoded is Map ? decoded['detail'] : null;
      throw HttpException(detail?.toString() ?? 'Request failed (${response.statusCode})', uri: uri);
    }
    return decoded;
  }

  Map<String, dynamic> _map(dynamic value) => Map<String, dynamic>.from(value as Map);

  @override
  void close() => _client.close(force: true);
}
