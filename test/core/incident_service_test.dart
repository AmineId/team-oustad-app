import 'package:flutter_test/flutter_test.dart';
import 'package:team_oustad_app/core/services/incident_service.dart';

void main() {
  test('libellés couvrant toutes les valeurs du contrat serveur', () {
    expect(IncidentService.categories.keys, [
      'equipment',
      'safety',
      'hygiene',
      'member',
      'other',
    ]);
    expect(IncidentService.severities.keys, [
      'low',
      'medium',
      'high',
      'critical',
    ]);
    expect(IncidentService.statuses.keys, [
      'open',
      'in_progress',
      'resolved',
      'closed',
    ]);
  });
}
