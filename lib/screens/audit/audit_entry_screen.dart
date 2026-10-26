import 'package:flutter/material.dart';

import '../../core/core.dart';
import 'audit_log_screen.dart';

/// Détail d'une entrée d'historique : auteur, objet, et changements champ
/// par champ (avant → après ; création = valeurs créées, suppression =
/// valeurs supprimées).
class AuditEntryScreen extends StatelessWidget {
  final Map<String, dynamic> entry;

  const AuditEntryScreen({super.key, required this.entry});

  static const _roles = {
    'owner': 'Propriétaire',
    'manager': 'Manager',
    'coach': 'Coach',
    'member': 'Membre',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = entry['action'] as String?;
    final (icon, color) = auditActionStyle(context, action);
    final entity = AuditService.entityLabel(entry['entity'] as String?);
    final label = entry['label'] as String?;
    final gym = (entry['gym'] as Map<String, dynamic>?)?['name'] as String?;
    final role = entry['actorRole'] ?? (entry['actor'] as Map?)?['role'];
    final changes = (entry['changes'] as Map?)?.cast<String, dynamic>() ?? {};
    final fields = changes.keys.where((k) => k != '_count').toList()..sort();
    final count = (changes['_count'] as Map?)?['to'];

    final details = <(String, String)>[
      ('Date', AuditService.valueText(entry['createdAt'], null)),
      (
        'Auteur',
        '${entry['actorLabel'] ?? 'Anonyme'}'
            '${role == null ? '' : ' (${_roles[role] ?? role})'}',
      ),
      ('Objet', entity),
      if (entry['entityDisplayId'] != null || entry['entityId'] != null)
        ('Identifiant', '${entry['entityDisplayId'] ?? entry['entityId']}'),
      if (gym != null) ('Salle', gym),
      if (entry['source'] != null) ('Origine', '${entry['source']}'),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(AuditService.actions[action] ?? 'Détail')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${AuditService.sentenceOf(entry)} $entity'
                  '${label == null || label.isEmpty ? '' : ' · $label'}',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (final (k, v) in details)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 96,
                            child: Text(k, style: theme.textTheme.bodySmall),
                          ),
                          Expanded(child: Text(v)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (count != null)
            Text(
              'Opération groupée : $count lignes concernées.',
              style: theme.textTheme.bodyMedium,
            ),
          if (fields.isNotEmpty) ...[
            Text(switch (action) {
              'create' => 'Valeurs créées',
              'delete' => 'Valeurs supprimées',
              _ => 'Changements',
            }, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final f in fields)
              _ChangeRow(field: f, change: changes[f], action: action),
          ] else if (count == null)
            Text('Aucun détail', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  final String field;
  final Object? change;
  final String? action;

  const _ChangeRow({required this.field, required this.change, this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = change is Map ? change as Map : const {};
    final from = AuditService.valueText(c['from'], c['fromLabel']);
    final to = AuditService.valueText(c['to'], c['toLabel']);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AuditService.fieldLabel(field),
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            switch (action) {
              'create' => Text(to),
              'delete' => Text(
                from,
                style: const TextStyle(decoration: TextDecoration.lineThrough),
              ),
              _ => Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(
                    from,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const Icon(Icons.arrow_forward, size: 16),
                  Text(to, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            },
          ],
        ),
      ),
    );
  }
}
