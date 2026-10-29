import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_mobile/core/networking/orbit_api.dart';

void main() {
  late HttpServer server;
  late OrbitApi api;
  final requests = <String>[];

  setUpAll(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests.add('${request.method} ${request.uri.path} ${request.headers.value(HttpHeaders.authorizationHeader) ?? ''}');
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path == '/health') {
        request.response.write(jsonEncode({'ok': true, 'agent_online': true}));
      } else if (request.uri.path == '/v1/tasks' && request.method == 'GET') {
        request.response.write(jsonEncode([{'id': 'task-1', 'status': 'running'}]));
      } else if (request.uri.path == '/v1/tasks' && request.method == 'POST') {
        final body = jsonDecode(await utf8.decoder.bind(request).join());
        request.response.write(jsonEncode({'id': 'task-2', 'request': body['request'], 'status': 'queued'}));
      } else if (request.uri.path == '/v1/tasks/task-1/stop') {
        request.response.write(jsonEncode({'id': 'task-1', 'status': 'stopped'}));
      } else if (request.uri.path == '/v1/evidence/evidence-1') {
        request.response.headers.contentType = ContentType('image', 'png');
        request.response.add([137, 80, 78, 71]);
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write(jsonEncode({'detail': 'Not found'}));
      }
      await request.response.close();
    });
  });

  setUp(() {
    requests.clear();
    api = OrbitApi('http://127.0.0.1:${server.port}', 'test-token');
  });

  tearDown(() => api.close());

  tearDownAll(() => server.close(force: true));

  test('uses authenticated health, history, submit and stop requests', () async {
    expect((await api.health())['agent_online'], isTrue);
    expect((await api.tasks()).single['status'], 'running');
    expect((await api.submit('Create note: hello'))['status'], 'queued');
    expect((await api.stop('task-1'))['status'], 'stopped');
    expect(requests.where((entry) => entry.contains('Bearer test-token')).length, 3);
    expect(requests.first, startsWith('GET /health '));
  });

  test('retrieves evidence bytes with the bearer token', () async {
    expect(await api.evidence('evidence-1'), [137, 80, 78, 71]);
    expect(requests.single, 'GET /v1/evidence/evidence-1 Bearer test-token');
  });
}
