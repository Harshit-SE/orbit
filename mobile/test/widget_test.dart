import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orbit_mobile/main.dart';

void main() {
  testWidgets('navigates across Orbit sections', (tester) async {
    await tester.pumpWidget(const OrbitApp());
    await tester.pumpAndSettle();

    expect(find.text('What can I help with?'), findsOneWidget);
    await tester.tap(find.text('Activity').last);
    await tester.pumpAndSettle();
    expect(find.text('A clear history of what Orbit has done.'), findsOneWidget);

    await tester.tap(find.text('Recordings').last);
    await tester.pumpAndSettle();
    expect(find.text('Private evidence captured during task runs.'), findsOneWidget);

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(find.text('Your connection, permissions and privacy.'), findsOneWidget);
  });

  testWidgets('submits a task to the local activity history', (tester) async {
    await tester.pumpWidget(const OrbitApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byType(TextField),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField), 'Draft a project note');
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Draft a project note'),
      -250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Draft a project note'), findsOneWidget);

    await tester.tap(find.text('Activity').last);
    await tester.pumpAndSettle();
    expect(find.text('Draft a project note'), findsOneWidget);
  });

  testWidgets('Stop marks a running task in history', (tester) async {
    await tester.pumpWidget(const OrbitApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Stop').first);
    await tester.tap(find.text('Stop').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Activity').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Stopped by you'), findsOneWidget);
  });

  testWidgets('Activity filters only show matching tasks', (tester) async {
    await tester.pumpWidget(const OrbitApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Activity').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Completed'));
    await tester.pumpAndSettle();
    expect(find.text('Create a weekly planning note'), findsOneWidget);
    expect(find.text('Research quiet mechanical keyboards'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Needs review'));
    await tester.pumpAndSettle();
    expect(find.text('Summarize project notes'), findsOneWidget);
  });

  testWidgets('approval, evidence, and demo state controls work', (tester) async {
    await tester.pumpWidget(const OrbitApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Approve'), 220, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Reading approved Orbit folder'), findsOneWidget);

    await tester.tap(find.text('Recordings').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create a weekly planning note'));
    await tester.pumpAndSettle();
    expect(find.text('Mock evidence preview'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Show loading'), 250, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Show loading'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Hide loading'), findsOneWidget);
    await tester.tap(find.text('Agent').last);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.drag(find.byType(ListView).first, const Offset(0, 700));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('demo-loading-indicator')), findsOneWidget);
  });

  testWidgets('disconnect requires confirmation and offline is visible', (tester) async {
    await tester.pumpWidget(const OrbitApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Disconnect').first);
    await tester.tap(find.text('Disconnect').first);
    await tester.pumpAndSettle();
    expect(find.text('Disconnect this PC?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Demo mode'), findsOneWidget);

    await tester.ensureVisible(find.text('Disconnect').first);
    await tester.tap(find.text('Disconnect').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Disconnect').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('PC offline'), findsOneWidget);
  });

  testWidgets('error and empty demo states are reachable', (tester) async {
    await tester.pumpWidget(const OrbitApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Show error'), 250, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Show error'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Show empty state'), 250, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Show empty state'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agent').last);
    await tester.pumpAndSettle();
    expect(find.text('A little room to think'), findsOneWidget);
  });
}
