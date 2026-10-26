import 'package:flutter_test/flutter_test.dart';
import 'package:team_oustad_app/core/services/audit_service.dart';

void main() {
  test('libellés FR avec repli sur le nom brut', () {
    expect(AuditService.entityLabel('TrainingSession'), 'Séance');
    expect(AuditService.entityLabel('NouveauModele'), 'NouveauModele');
    expect(AuditService.fieldLabel('sessionsUsed'), 'Séances utilisées');
    expect(AuditService.fieldLabel('champInconnu'), 'champInconnu');
  });

  test('phrase et entrée groupée', () {
    final entry = {'actorLabel': 'Amine I.', 'action': 'update'};
    expect(AuditService.sentenceOf(entry), 'Amine I. a modifié');
    expect(AuditService.isBulk(entry), isFalse);
    expect(
      AuditService.isBulk({
        'entityId': null,
        'changes': {
          '_count': {'from': null, 'to': 201},
        },
      }),
      isTrue,
    );
  });

  test('valueText : libellé figé, booléens, vide, nul', () {
    expect(AuditService.valueText(12, 'Coach Bob'), 'Coach Bob');
    expect(AuditService.valueText(true, null), 'Oui');
    expect(AuditService.valueText('', null), '(vide)');
    expect(AuditService.valueText(null, null), '—');
    expect(AuditService.valueText('[masqué]', null), '[masqué]');
    final date = AuditService.valueText('2026-10-26T13:05:00.000Z', null);
    expect(date, matches(RegExp(r'^\d{2}/\d{2}/2026 \d{2}:\d{2}$')));
  });
}
