import 'package:flutter_test/flutter_test.dart';
import 'package:team_oustad_app/core/services/session_service.dart';

void main() {
  test('startOf / endOf convertissent l\'UTC en heure locale', () {
    final s = {
      'startAt': '2026-10-27T08:00:00.000Z',
      'endAt': '2026-10-27T09:00:00.000Z',
    };
    final start = SessionService.startOf(s)!;
    expect(start.isUtc, isFalse);
    expect(start, DateTime.utc(2026, 10, 27, 8).toLocal());
    expect(SessionService.endOf(s)!.difference(start).inMinutes, 60);
    expect(SessionService.startOf({}), isNull);
  });

  test('membersOf ignore les membres désinscrits', () {
    final s = {
      'members': [
        {'memberId': 1, 'status': 'booked'},
        {'memberId': 2, 'status': 'cancelled'},
        {'memberId': 3, 'status': 'checked_in'},
      ],
    };
    expect(SessionService.membersOf(s).map((m) => m['memberId']), [1, 3]);
  });
}
