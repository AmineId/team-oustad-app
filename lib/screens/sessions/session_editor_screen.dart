import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../core/utils/user_utils.dart';
import '../../widgets/common/common_widgets.dart';
import 'session_widgets.dart';

/// Création / modification d'une séance (owner, manager). En création, la
/// séance peut être répétée chaque semaine. Renvoie `true` au pop si
/// enregistré.
class SessionEditorScreen extends StatefulWidget {
  final int gymId;
  final List<Map<String, dynamic>> coaches;
  final Map<String, dynamic>? session;
  final DateTime? initialDay;

  const SessionEditorScreen({
    super.key,
    required this.gymId,
    required this.coaches,
    this.session,
    this.initialDay,
  });

  @override
  State<SessionEditorScreen> createState() => _SessionEditorScreenState();
}

class _SessionEditorScreenState extends State<SessionEditorScreen> {
  final ApiService _apiService = ApiService.fromEnv();
  late final AuthService _authService = AuthService(_apiService);
  late final SessionService _sessionService = SessionService(_apiService);

  late final Map<String, dynamic>? _session = widget.session;
  late int? _coachId = _session?['coachId'] as int?;
  late DateTime _day;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late final _capacityController = TextEditingController(
    text: '${_session?['capacity'] ?? 1}',
  );
  late final _titleController = TextEditingController(
    text: _session?['title'] as String? ?? '',
  );
  late final _notesController = TextEditingController(
    text: _session?['notes'] as String? ?? '',
  );
  bool _repeat = false;
  DateTime? _repeatUntil;
  bool _isSaving = false;

  bool get _editing => _session != null;

  @override
  void initState() {
    super.initState();
    final start = _session == null ? null : SessionService.startOf(_session);
    final end = _session == null ? null : SessionService.endOf(_session);
    final today = DateUtils.dateOnly(DateTime.now());
    final initial = widget.initialDay == null
        ? today
        : DateUtils.dateOnly(widget.initialDay!);
    _day = start == null
        ? (initial.isBefore(today) ? today : initial)
        : DateUtils.dateOnly(start);
    _start = start == null
        ? const TimeOfDay(hour: 9, minute: 0)
        : TimeOfDay.fromDateTime(start);
    _end = end == null
        ? const TimeOfDay(hour: 10, minute: 0)
        : TimeOfDay.fromDateTime(end);
  }

  @override
  void dispose() {
    _capacityController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  DateTime _at(TimeOfDay t) =>
      DateTime(_day.year, _day.month, _day.day, t.hour, t.minute);

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _day = picked);
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        // Garder la durée en décalant la fin.
        final duration = _at(_end).difference(_at(_start));
        _start = picked;
        _end = TimeOfDay.fromDateTime(_at(picked).add(duration));
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _pickUntil() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _repeatUntil ?? _day.add(const Duration(days: 28)),
      firstDate: _day.add(const Duration(days: 7)),
      // Le serveur plafonne une série à 26 occurrences.
      lastDate: _day.add(const Duration(days: 7 * 25)),
    );
    if (picked != null) setState(() => _repeatUntil = picked);
  }

  Future<void> _save() async {
    final capacity = int.tryParse(_capacityController.text);
    if (_coachId == null) {
      AppSnackBar.warning(context, 'Choisissez un coach');
      return;
    }
    if (capacity == null || capacity < 1) {
      AppSnackBar.warning(context, 'Capacité invalide');
      return;
    }
    if (!_at(_end).isAfter(_at(_start))) {
      AppSnackBar.warning(context, 'L\'heure de fin doit suivre le début');
      return;
    }
    if (_repeat && _repeatUntil == null) {
      AppSnackBar.warning(context, 'Choisissez la date de fin de répétition');
      return;
    }
    String scope = 'this';
    if (_editing) {
      final picked = await pickSessionScope(context, _session!, 'Modifier');
      if (picked == null) return;
      scope = picked;
    }
    setState(() => _isSaving = true);
    final token = await _authService.loadToken();
    if (token == null) return;
    final title = _titleController.text.trim();
    final notes = _notesController.text.trim();
    final result = _editing
        ? await _sessionService.update(
            token,
            _session!['id'] as int,
            scope: scope,
            startAt: _at(_start),
            endAt: _at(_end),
            coachId: _coachId,
            capacity: capacity,
            title: title,
            notes: notes,
          )
        : await _sessionService.create(
            token,
            gymId: widget.gymId,
            coachId: _coachId!,
            startAt: _at(_start),
            endAt: _at(_end),
            capacity: capacity,
            title: title.isEmpty ? null : title,
            notes: notes.isEmpty ? null : notes,
            repeatUntil: _repeat
                ? _repeatUntil!.add(const Duration(hours: 23, minutes: 59))
                : null,
          );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (result.ok) {
      final n = result.sessions.length;
      AppSnackBar.success(
        context,
        n > 1 ? '$n séances enregistrées' : 'Séance enregistrée',
      );
      Navigator.pop(context, true);
    } else {
      showSessionError(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Modifier la séance' : 'Nouvelle séance'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<int>(
            initialValue: _coachId,
            decoration: const InputDecoration(labelText: 'Coach'),
            items: [
              for (final c in widget.coaches)
                if (c['id'] is int)
                  DropdownMenuItem(
                    value: c['id'] as int,
                    child: Text(getUserFullName(c)),
                  ),
            ],
            onChanged: (v) => setState(() => _coachId = v),
          ),
          if (widget.coaches.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Aucun coach rattaché à cette salle.'),
            ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('Jour'),
            trailing: Text(sessionDay(_day)),
            onTap: _pickDay,
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Début'),
            trailing: Text(sessionTime(_at(_start))),
            onTap: () => _pickTime(start: true),
          ),
          ListTile(
            leading: const Icon(Icons.schedule_outlined),
            title: const Text('Fin'),
            trailing: Text(sessionTime(_at(_end))),
            onTap: () => _pickTime(start: false),
          ),
          const SizedBox(height: 8),
          ModernTextField(
            controller: _capacityController,
            label: 'Nombre de places',
            prefixIcon: Icons.groups_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          ModernTextField(
            controller: _titleController,
            label: 'Titre (optionnel)',
            prefixIcon: Icons.title,
          ),
          const SizedBox(height: 12),
          ModernTextField(
            controller: _notesController,
            label: 'Notes (optionnel)',
            prefixIcon: Icons.notes,
            maxLines: 2,
          ),
          if (!_editing) ...[
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Répéter chaque semaine'),
              value: _repeat,
              onChanged: (v) => setState(() => _repeat = v),
            ),
            if (_repeat)
              ListTile(
                leading: const Icon(Icons.event_repeat),
                title: const Text('Jusqu\'au'),
                trailing: Text(
                  _repeatUntil == null ? 'Choisir' : sessionDay(_repeatUntil!),
                ),
                onTap: _pickUntil,
              ),
          ],
          const SizedBox(height: 24),
          ModernButton(
            text: 'Enregistrer',
            icon: Icons.check,
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
    );
  }
}
