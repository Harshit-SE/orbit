import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_mobile/core/networking/orbit_api.dart';
import 'package:orbit_mobile/main.dart';

class FakeOrbitApi implements OrbitApiService {
  final remoteTasks = <Map<String, dynamic>>[];
  String? lastRequest;
  bool closed = false;

  @override
  Future<Map<String, dynamic>> health() async => {
        'ok': true,
        'agent_online': true,
      };

  @override
  Future<List<Map<String, dynamic>>> tasks() async => remoteTasks;

  @override
  Future<Map<String, dynamic>> submit(String request) async {
    lastRequest = request;
    final now = DateTime.now().toUtc().toIso8601String();
    final task = <String, dynamic>{
      'id': 'remote-1',
      'title': 'Create note · Phone demo',
      'request': request,
      'status': 'queued',
      'step': 'Waiting for the Windows agent',
      'progress': 0.0,
      'created_at': now,
      'updated_at': now,
      'error': null,
      'result': null,
      'events': [],
      'evidence': [],
    };
    remoteTasks.insert(0, task);
    return task;
  }

  @override
  Future<Map<String, dynamic>> stop(String id) async => {
        'id': id,
        'status': 'stopped',
      };

  @override
  Future<Uint8List> evidence(String id) async => Uint8List.fromList([137, 80, 78, 71]);

  @override
  void close() => closed = true;
}

void main() {
  testWidgets('connects to the API and submits through the task repository', (tester) async {
    final fake = FakeOrbitApi();
    String? configuredUrl;
    String? configuredToken;

    await tester.pumpWidget(OrbitApp(apiFactory: (url, token) {
      configuredUrl = url;
      configuredToken = token;
      return fake;
    }));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'http://127.0.0.1:8765');
    await tester.enterText(find.byType(TextField).last, 'mobile-integration-test-token');
    await tester.ensureVisible(find.text('Connect'));
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    expect(find.text('Windows agent online'), findsOneWidget);
    expect(configuredUrl, 'http://127.0.0.1:8765');
    expect(configuredToken, 'mobile-integration-test-token');

    await tester.tap(find.text('Agent').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byType(TextField), 240, scrollable: find.byType(Scrollable).first);
    await tester.enterText(find.byType(TextField), 'Create note: Phone demo');
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pumpAndSettle();
    expect(fake.lastRequest, 'Create note: Phone demo');

    await tester.tap(find.text('Activity').last);
    await tester.pumpAndSettle();
    expect(find.text('Create note · Phone demo'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(fake.closed, isTrue);
  });
}
