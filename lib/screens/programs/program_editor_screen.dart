import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../core/theme/theme.dart';
import '../../widgets/common/common_widgets.dart';
import 'program_detail_screen.dart';

/// Création / modification d'un programme (owner). Le programme est envoyé
/// en entier (`days` remplace tout), renvoie `true` au pop si enregistré.
class ProgramEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? program;

  const ProgramEditorScreen({super.key, this.program});

  @override
  State<ProgramEditorScreen> createState() => _ProgramEditorScreenState();
}

class _ProgramEditorScreenState extends State<ProgramEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService.fromEnv();
  late final AuthService _authService = AuthService(_apiService);
  late final ProgramService _programService = ProgramService(_apiService);

  late final _titleController = TextEditingController(
    text: widget.program?['title'] as String? ?? '',
  );
  late final _descriptionController = TextEditingController(
    text: widget.program?['description'] as String? ?? '',
  );
  late final _weeksController = TextEditingController(
    text: widget.program?['durationWeeks']?.toString() ?? '',
  );
  late String? _level = widget.program?['level'] as String?;

  /// dayOfWeek → exercices (`exerciseId`, `exercise`, sets, reps…).
  final Map<int, List<Map<String, dynamic>>> _days = {
    for (var d = 0; d < 7; d++) d: [],
  };
  List<Map<String, dynamic>>? _catalog;
  bool _isSaving = false;

  /// Lundi → dimanche.
  static const _dayOrder = [1, 2, 3, 4, 5, 6, 0];

  @override
  void initState() {
    super.initState();
    final program = widget.program;
    if (program != null) {
      for (final day in ApiService.listFrom(program['days'], 'days')) {
        final d = day['dayOfWeek'];
        if (d is! int || !_days.containsKey(d)) continue;
        _days[d] = ApiService.listFrom(
          day['exercises'],
          'exercises',
        ).map((e) => {...e}).toList();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _weeksController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadCatalog() async {
    if (_catalog != null) return _catalog!;
    final token = await _authService.loadToken();
    final list = token == null ? null : await _apiService.getExercises(token);
    _catalog = list?.whereType<Map<String, dynamic>>().toList() ?? [];
    return _catalog!;
  }

  Future<void> _addExercise(int day) async {
    final catalog = await _loadCatalog();
    if (!mounted) return;
    if (catalog.isEmpty) {
      AppSnackBar.error(context, 'Catalogue d\'exercices indisponible');
      return;
    }
    final exercise = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExercisePickerSheet(catalog: catalog),
    );
    if (exercise == null || !mounted) return;
    final item = await _editDetails({
      'exerciseId': exercise['id'],
      'exercise': exercise,
    });
    if (item != null) setState(() => _days[day]!.add(item));
  }

  /// Dialogue séries / répétitions / repos / notes ; null si annulé.
  Future<Map<String, dynamic>?> _editDetails(Map<String, dynamic> item) {
    final sets = TextEditingController(text: item['sets']?.toString() ?? '');
    final reps = TextEditingController(text: item['reps']?.toString() ?? '');
    final rest = TextEditingController(
      text: item['restTime']?.toString() ?? '',
    );
    final notes = TextEditingController(text: item['notes'] as String? ?? '');
    Widget number(TextEditingController c, String label) => Expanded(
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
      ),
    );
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(programExerciseName(item)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                number(sets, 'Séries'),
                const SizedBox(width: 12),
                number(reps, 'Répétitions'),
              ],
            ),
            Row(children: [number(rest, 'Repos (s)')]),
            TextField(
              controller: notes,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              ...item,
              'sets': int.tryParse(sets.text),
              'reps': int.tryParse(reps.text),
              'restTime': int.tryParse(rest.text),
              'notes': notes.text.trim().isEmpty ? null : notes.text.trim(),
            }),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final data = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'level': _level,
      'durationWeeks': int.tryParse(_weeksController.text),
      'days': [
        for (final d in _dayOrder)
          if (_days[d]!.isNotEmpty)
            {
              'dayOfWeek': d,
              'exercises': [
                for (final (i, e) in _days[d]!.indexed)
                  {
                    'exerciseId': e['exerciseId'],
                    'sets': ?e['sets'],
                    'reps': ?e['reps'],
                    'duration': ?e['duration'],
                    'weight': ?e['weight'],
                    'restTime': ?e['restTime'],
                    'notes': ?e['notes'],
                    'order': i + 1,
                  },
              ],
            },
      ],
    };
    final token = await _authService.loadToken();
    final saved = token == null
        ? null
        : await _programService.saveProgram(
            token,
            data,
            id: widget.program?['id'] as int?,
          );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (saved != null) {
      AppSnackBar.success(context, 'Programme enregistré');
      Navigator.pop(context, true);
    } else {
      AppSnackBar.error(context, 'Échec de l\'enregistrement');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.program == null ? 'Nouveau programme' : 'Modifier'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ModernTextField(
              controller: _titleController,
              label: 'Titre',
              prefixIcon: Icons.title,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
            ),
            const SizedBox(height: 12),
            ModernTextField(
              controller: _descriptionController,
              label: 'Description',
              prefixIcon: Icons.notes,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _level,
                    decoration: const InputDecoration(labelText: 'Niveau'),
                    items: [
                      for (final e in ProgramService.levels.entries)
                        DropdownMenuItem(value: e.key, child: Text(e.value)),
                    ],
                    onChanged: (v) => setState(() => _level = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ModernTextField(
                    controller: _weeksController,
                    label: 'Semaines',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Séances de la semaine', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final d in _dayOrder)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  title: Text(programDayNames[d]!),
                  subtitle: Text(
                    _days[d]!.isEmpty
                        ? 'Repos'
                        : '${_days[d]!.length} exercice(s)',
                  ),
                  initiallyExpanded: _days[d]!.isNotEmpty,
                  children: [
                    ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      // onReorder (et non onReorderItem) : Flutter 3.35 en CI.
                      onReorder: (from, to) => setState(() {
                        final item = _days[d]!.removeAt(from);
                        _days[d]!.insert(to > from ? to - 1 : to, item);
                      }),
                      children: [
                        for (final (i, e) in _days[d]!.indexed)
                          ListTile(
                            key: ObjectKey(e),
                            leading: ReorderableDragStartListener(
                              index: i,
                              child: const Icon(Icons.drag_handle),
                            ),
                            title: Text(programExerciseName(e)),
                            subtitle: Text(programExerciseSummary(e)),
                            onTap: () async {
                              final edited = await _editDetails(e);
                              if (edited != null) {
                                setState(() => _days[d]![i] = edited);
                              }
                            },
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () =>
                                  setState(() => _days[d]!.removeAt(i)),
                            ),
                          ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => _addExercise(d),
                      icon: Icon(Icons.add, color: context.palette.primary),
                      label: const Text('Ajouter un exercice'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            ModernButton(
              text: 'Enregistrer',
              icon: Icons.check,
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExercisePickerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> catalog;

  const _ExercisePickerSheet({required this.catalog});

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final results = widget.catalog
        .where((e) => (e['name'] as String? ?? '').toLowerCase().contains(q))
        .toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Rechercher un exercice…',
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, i) {
                  final e = results[i];
                  return ListTile(
                    title: Text(e['name'] as String? ?? 'Exercice'),
                    subtitle: Text(e['category'] as String? ?? ''),
                    onTap: () => Navigator.pop(context, e),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
