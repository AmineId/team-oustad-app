import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_oustad_app/core/services/audit_service.dart';
import 'package:team_oustad_app/screens/audit/audit_entry_screen.dart';

/// Échantillon réel de GET /audit-logs (base de test serveur, données
/// fictives) : suppression, entrée groupée, action système, création avec
/// photo masquée, changement de salle, mot de passe.
List<Map<String, dynamic>> _sample() {
  final body = jsonDecode(
    File('test/fixtures/audit_sample.json').readAsStringSync(),
  );
  return (body['entries'] as List).cast<Map<String, dynamic>>();
}

void main() {
  test('libellés des clés étrangères prioritaires sur l\'id', () {
    final move = _sample().firstWhere(
      (e) =>
          (e['changes'] as Map).containsKey('gymId') && e['action'] == 'update',
    );
    final gym = (move['changes'] as Map)['gymId'] as Map;
    expect(
      AuditService.valueText(gym['from'], gym['fromLabel']),
      'Salle Centre',
    );
    expect(AuditService.valueText(gym['to'], gym['toLabel']), 'Salle Nord');
  });

  test('tableaux et objets JSON : rendu générique tronqué', () {
    expect(AuditService.valueText(<dynamic>[], null), '(aucun)');
    expect(AuditService.valueText(['dos', 'jambes'], null), 'dos, jambes');
    expect(
      AuditService.valueText([
        {'a': 1},
      ], null),
      '1 élément(s)',
    );
    final long = AuditService.valueText({'text': 'x' * 400}, null);
    expect(long.length, 161);
    expect(long.endsWith('…'), isTrue);
  });

  testWidgets('chaque entrée de l\'échantillon s\'affiche sans erreur', (
    tester,
  ) async {
    for (final entry in _sample()) {
      await tester.pumpWidget(
        MaterialApp(home: AuditEntryScreen(entry: entry)),
      );
      expect(tester.takeException(), isNull, reason: 'entrée ${entry['id']}');
      expect(find.textContaining(entry['actorLabel'] as String), findsWidgets);
    }
  });

  testWidgets('entrée groupée : nombre de lignes affiché', (tester) async {
    final bulk = _sample().firstWhere(AuditService.isBulk);
    await tester.pumpWidget(MaterialApp(home: AuditEntryScreen(entry: bulk)));
    expect(find.textContaining('201 lignes'), findsWidgets);
  });

  testWidgets('mot de passe : changement visible, valeur masquée', (
    tester,
  ) async {
    final pwd = _sample().firstWhere(
      (e) => (e['changes'] as Map).containsKey('password'),
    );
    await tester.pumpWidget(MaterialApp(home: AuditEntryScreen(entry: pwd)));
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(find.text('[masqué]'), findsNWidgets(2));
  });
}
