import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/user_utils.dart';

const _weekdays = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
const _months = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

String sessionTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

const _monthNames = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

/// « lun. »
String sessionWeekday(DateTime d) => _weekdays[d.weekday - 1];

/// « octobre »
String sessionMonth(DateTime d) => _monthNames[d.month - 1];

/// « lun. 27 oct. »
String sessionDay(DateTime d) =>
    '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

/// « lun. 27 oct. · 09:00 – 10:00 »
String sessionSlot(Map<String, dynamic> s) {
  final start = SessionService.startOf(s);
  final end = SessionService.endOf(s);
  if (start == null) return '';
  return '${sessionDay(start)} · ${sessionTime(start)}'
      '${end == null ? '' : ' – ${sessionTime(end)}'}';
}

String sessionCoachName(Map<String, dynamic> s) {
  final coach = s['coach'];
  return coach is Map<String, dynamic>
      ? getUserFullName(coach, defaultValue: 'Coach')
      : 'Coach';
}

IconData sessionTypeIcon(String type) => switch (type) {
  'discovery' => Icons.explore_outlined,
  'group_class' => Icons.groups_outlined,
  'assessment' => Icons.monitor_heart_outlined,
  'private' => Icons.person_outline,
  _ => Icons.fitness_center,
};

/// Couleur d'un type de séance (calendrier).
Color sessionTypeColor(BuildContext context, String type) {
  final palette = context.palette;
  return switch (type) {
    'discovery' => palette.info,
    'group_class' => palette.premium,
    'assessment' => palette.warning,
    'private' => palette.success,
    _ => palette.primary,
  };
}

/// Puces de filtre par type de séance ; [value] null = tous les types.
class SessionTypeFilter extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const SessionTypeFilter({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Tous'),
            selected: value == null,
            onSelected: (_) => onChanged(null),
          ),
          for (final e in SessionService.types.entries) ...[
            const SizedBox(width: 8),
            ChoiceChip(
              avatar: Icon(sessionTypeIcon(e.key), size: 18),
              label: Text(e.value),
              selected: value == e.key,
              onSelected: (_) => onChanged(value == e.key ? null : e.key),
            ),
          ],
        ],
      ),
    );
  }
}

const sessionMemberStatus = {
  'booked': 'Inscrit',
  'checked_in': 'Présent',
  'absent': 'Absent',
  'cancelled': 'Désinscrit',
};

/// Portée d'une modification sur une séance récurrente ; null si annulé.
/// Une séance isolée renvoie directement 'this'.
Future<String?> pickSessionScope(
  BuildContext context,
  Map<String, dynamic> session,
  String action,
) async {
  if (session['seriesId'] == null) return 'this';
  return showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text('$action la séance récurrente'),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, 'this'),
          child: const Text('Cette séance uniquement'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, 'following'),
          child: const Text('Cette séance et les suivantes'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, 'series'),
          child: const Text('Toute la série'),
        ),
      ],
    ),
  );
}

/// Explique une erreur d'écriture (chevauchements, refus d'inscription).
Future<void> showSessionError(
  BuildContext context,
  SessionResult result, {
  String Function(int memberId)? memberName,
}) {
  final lines = <String>[
    for (final c in result.conflicts)
      '• ${sessionSlot(c)} (${c['title'] ?? sessionCoachName(c)})',
    for (final r in result.rejected)
      '• ${memberName?.call(r['memberId'] as int? ?? 0) ?? 'Membre #${r['memberId']}'} : '
          '${SessionService.rejectReasons[r['reason']] ?? r['reason']}',
  ];
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(result.errorMessage ?? 'Erreur'),
      content: lines.isEmpty ? null : Text(lines.join('\n')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Carte d'une séance : horaire, coach, titre, remplissage.
class SessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final VoidCallback? onTap;
  final bool showDay;
  final Widget? badge;

  const SessionCard({
    super.key,
    required this.session,
    this.onTap,
    this.showDay = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final start = SessionService.startOf(session);
    final end = SessionService.endOf(session);
    final cancelled = session['status'] == 'cancelled';
    final booked = session['bookedCount'] as int? ?? 0;
    final capacity = session['capacity'] as int? ?? 0;
    final type = SessionService.typeOf(session);
    final typeLabel = SessionService.types[type]!;
    final title = session['title'] as String?;
    final gym = (session['gym'] as Map<String, dynamic>?)?['name'] as String?;
    final subtitle = [
      if (title != null && title.isNotEmpty) typeLabel,
      sessionCoachName(session),
      ?gym,
      '$booked/$capacity inscrit${booked > 1 ? 's' : ''}',
    ].join(' · ');
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: SizedBox(
          width: 56,
          // Grandes polices : réduire plutôt que déborder.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  start == null ? '--:--' : sessionTime(start),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.palette.primary,
                  ),
                ),
                if (end != null)
                  Text(sessionTime(end), style: const TextStyle(fontSize: 12)),
                Icon(sessionTypeIcon(type), size: 14),
              ],
            ),
          ),
        ),
        title: Text(
          [
            if (showDay && start != null) sessionDay(start),
            (title == null || title.isEmpty) ? typeLabel : title,
          ].join(' · '),
          style: cancelled
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: Text(cancelled ? 'Annulée · $subtitle' : subtitle),
        trailing: badge ?? const Icon(Icons.chevron_right),
      ),
    );
  }
}
