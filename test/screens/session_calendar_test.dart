import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_oustad_app/core/l10n/app_localizations.dart';
import 'package:team_oustad_app/core/theme/app_palette.dart';
import 'package:team_oustad_app/screens/sessions/session_calendar.dart';
import 'package:team_oustad_app/screens/sessions/session_editor_screen.dart';

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
    Locale locale = const Locale('fr'),
  }) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AppPalette.light]),
        locale: locale,
        supportedLocales: const [Locale('fr'), Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
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

  testWidgets('arabe (RTL) : la séance est sous l\'en-tête de son jour', (
    tester,
  ) async {
    await pump(tester, locale: const Locale('ar'));
    await tester.tap(find.byTooltip('عرض الشهر'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('عرض الأسبوع'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final header = tester.getCenter(find.text('${today.day}').first).dx;
    final block = tester.getRect(find.text('18:00'));
    expect(header, inInclusiveRange(block.left, block.right));
  });

  testWidgets('éditeur : 23 h finit à 23:59, jour seul démarre à 9 h', (
    tester,
  ) async {
    final day = today.add(const Duration(days: 1));
    Future<void> editor(DateTime initial) => tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AppPalette.light]),
        home: SessionEditorScreen(
          key: UniqueKey(),
          gymId: 1,
          coaches: const [],
          initialDay: initial,
        ),
      ),
    );
    await editor(day.add(const Duration(hours: 23)));
    expect(find.text('23:00'), findsOneWidget);
    expect(find.text('23:59'), findsOneWidget);
    await editor(day);
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
  });
}
