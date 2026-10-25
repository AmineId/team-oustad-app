import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../core/theme/theme.dart';
import '../../widgets/common/common_widgets.dart';
import 'program_assign_screen.dart';
import 'program_editor_screen.dart';

const programDayNames = {
  0: 'Dimanche',
  1: 'Lundi',
  2: 'Mardi',
  3: 'Mercredi',
  4: 'Jeudi',
  5: 'Vendredi',
  6: 'Samedi',
};

/// « 4 × 10 · 60 s repos » pour un exercice de programme.
String programExerciseSummary(Map<String, dynamic> e) {
  final parts = <String>[];
  if (e['sets'] != null && e['reps'] != null) {
    parts.add('${e['sets']} × ${e['reps']}');
  } else if (e['sets'] != null) {
    parts.add('${e['sets']} séries');
  }
  if (e['duration'] != null) parts.add('${e['duration']} min');
  if (e['weight'] != null) parts.add('${e['weight']} kg');
  if (e['restTime'] != null) parts.add('${e['restTime']} s repos');
  return parts.join(' · ');
}

/// Nom d'un exercice de programme (exercice du catalogue imbriqué).
String programExerciseName(Map<String, dynamic> e) =>
    (e['exercise'] as Map<String, dynamic>?)?['name'] as String? ??
    e['name'] as String? ??
    'Exercice';

/// Détail d'un programme. Renvoie `true` au pop si quelque chose a changé.
class ProgramDetailScreen extends StatefulWidget {
  final Map<String, dynamic> program;

  const ProgramDetailScreen({super.key, required this.program});

  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen> {
  final ApiService _apiService = ApiService.fromEnv();
  late final AuthService _authService = AuthService(_apiService);
  late final ProgramService _programService = ProgramService(_apiService);

  late Map<String, dynamic> _program = widget.program;
  bool _isOwner = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _authService.isOwner().then((v) {
      if (mounted) setState(() => _isOwner = v);
    });
  }

  Future<void> _reload() async {
    final token = await _authService.loadToken();
    final id = _program['id'];
    if (token == null || id is! int) return;
    final fresh = await _programService.getProgram(token, id);
    if (fresh != null && mounted) setState(() => _program = fresh);
  }

  Future<void> _edit() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProgramEditorScreen(program: _program)),
    );
    if (saved == true) {
      _changed = true;
      _reload();
    }
  }

  Future<void> _assign() async {
    final assigned = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProgramAssignScreen(program: _program)),
    );
    if (assigned == true) {
      _changed = true;
      _reload();
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le programme ?'),
        content: Text('« ${_program['title']} » sera supprimé.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final token = await _authService.loadToken();
    final id = _program['id'];
    if (token == null || id is! int) return;
    final error = await _programService.deleteProgram(token, id);
    if (!mounted) return;
    if (error == null) {
      AppSnackBar.success(context, 'Programme supprimé');
      Navigator.pop(context, true);
    } else {
      AppSnackBar.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = ProgramService.daysOf(_program);
    final description = _program['description'] as String?;
    final level = ProgramService.levels[_program['level']];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_program['title'] as String? ?? 'Programme'),
          actions: [
            if (_isOwner) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Modifier',
                onPressed: _edit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Supprimer',
                onPressed: _delete,
              ),
            ],
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _assign,
          icon: const Icon(Icons.group_add_outlined),
          label: const Text('Affecter'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            if (level != null || _program['durationWeeks'] is int)
              Wrap(
                spacing: 8,
                children: [
                  if (level != null) Chip(label: Text(level)),
                  if (_program['durationWeeks'] is int)
                    Chip(label: Text('${_program['durationWeeks']} semaines')),
                  Chip(
                    label: Text(
                      '${_program['assignmentsCount'] ?? 0} membre(s) actif(s)',
                    ),
                  ),
                ],
              ),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(description, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 16),
            if (days.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Aucun exercice dans ce programme',
                  textAlign: TextAlign.center,
                ),
              ),
            for (final day in days)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        programDayNames[day['dayOfWeek']] ?? '',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: context.palette.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final e in ApiService.listFrom(
                        day['exercises'],
                        'exercises',
                      ))
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(programExerciseName(e)),
                          subtitle: Text(programExerciseSummary(e)),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
