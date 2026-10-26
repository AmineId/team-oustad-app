import 'package:flutter_test/flutter_test.dart';
import 'package:team_oustad_app/core/services/api_service.dart';
import 'package:team_oustad_app/core/services/coach_service.dart';

void main() {
  group('ApiService.listFrom', () {
    test('accepte un tableau brut ou un objet enveloppé', () {
      final item = {'id': 1};
      expect(ApiService.listFrom([item], 'coaches'), [item]);
      expect(ApiService.listFrom({'coaches': [item]}, 'coaches'), [item]);
    });

    test('ignore les réponses inattendues', () {
      expect(ApiService.listFrom(null, 'coaches'), isEmpty);
      expect(ApiService.listFrom({'other': []}, 'coaches'), isEmpty);
      expect(ApiService.listFrom([1, 'x'], 'coaches'), isEmpty);
    });
  });

  test("CoachService.gymsOf lit gyms, pas gymId", () {
    final coach = {
      'gymId': 1,
      'gyms': [
        {'id': 1, 'name': 'A'},
        {'id': 2, 'name': 'B'},
      ],
    };
    expect(CoachService.gymsOf(coach).map((g) => g['id']), [1, 2]);
    expect(CoachService.gymsOf({'gymId': 1}), isEmpty);
  });
}
