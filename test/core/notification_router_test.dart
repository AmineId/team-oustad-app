import 'package:flutter_test/flutter_test.dart';
import 'package:team_oustad_app/core/services/notification_router.dart';

void main() {
  test('open transmet les données de la notification', () {
    NotificationRouter.open('incident', {'incidentId': '42'});
    expect(NotificationRouter.take(), 'incident');
    expect(NotificationRouter.incidentIdOf(NotificationRouter.data), 42);
    expect(NotificationRouter.incidentIdOf({}), isNull);
  });
}
