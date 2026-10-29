import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_oustad_app/core/theme/app_palette.dart';
import 'package:team_oustad_app/screens/sessions/session_calendar.dart';

Map<String, dynamic> _session(
  int id,
  DateTime start,
  int minutes,
  String type,
) => {
  'id': id,
  'type': type,
  'title': '',
  'status': 'scheduled',
  'startAt': start.toUtc().toIso8601String(),
  'endAt': start.add(Duration(minutes: minutes)).toUtc().toIso8601String(),
  'capacity': 4,
  'bookedCount': 1,
  'coach': {'firstName': 'Sara', 'lastName': 'B'},
};

void main() {
  final today = DateUtils.dateOnly(DateTime.now());
  final sessions = [
    _session(1, today.add(const Duration(hours: 9)), 60, 'training'),
    // Chevauchements : trois séances côte à côte.
    _session(
      2,
      today.add(const Duration(hours: 9, minutes: 30)),
      60,
      'private',
    ),
    _session(3, today.add(const Duration(hours: 10)), 30, 'group_class'),
    _session(4, today.add(const Duration(hours: 18)), 90, 'assessment'),
  ];

  Future<void> pump(
    WidgetTester tester, {
    ValueChanged<DateTime>? onSlot,
  }) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AppPalette.light]),
        home: Scaffold(
          body: SessionCalendar(
            loader: (from, to) async => sessions,
            onSessionTap: (_) async => false,
            onSlotTap: onSlot,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('semaine : séances placées, sans débordement', (tester) async {
    await pump(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('18:00'), findsOneWidget);
  });

  testWidgets('créneau vide touché : heure pleine transmise', (tester) async {
    DateTime? slot;
    await pump(tester, onSlot: (d) => slot = d);
    // Colonne du jour, vers 13 h (zone sans séance).
    final column = 40 + (360 - 40) / 7 * (today.weekday - 1) + 10;
    await tester.dragUntilVisible(
      find.text('13h'),
      find.byType(SingleChildScrollView).first,
      const Offset(0, -100),
    );
    await tester.tapAt(
      Offset(column, tester.getCenter(find.text('13h')).dy + 20),
    );
    expect(slot, today.add(const Duration(hours: 13)));
  });

  testWidgets('mois : points sous le jour et liste du jour choisi', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byTooltip('Vue mois'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Coaching individuel'), findsOneWidget);
  });
}
