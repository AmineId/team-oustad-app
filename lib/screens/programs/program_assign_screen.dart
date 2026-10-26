import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../core/utils/user_utils.dart';
import '../../widgets/common/common_widgets.dart';

/// Affecte un programme à des membres. Avec [memberIds], les membres sont
/// déjà choisis (fiche membre) ; sinon on choisit parmi les membres visibles
/// selon le rôle : coach → ses membres, manager → sa salle, owner → salle
/// choisie. Renvoie `true` au pop si l'affectation a réussi.
class ProgramAssignScreen extends StatefulWidget {
  final Map<String, dynamic> program;
  final List<int>? memberIds;

  const ProgramAssignScreen({super.key, required this.program, this.memberIds});

  @override
  State<ProgramAssignScreen> createState() => _ProgramAssignScreenState();
}

class _ProgramAssignScreenState extends State<ProgramAssignScreen> {
  final ApiService _apiService = ApiService.fromEnv();
  late final AuthService _authService = AuthService(_apiService);
  late final ProgramService _programService = ProgramService(_apiService);
  late final CoachService _coachService = CoachService(_apiService);

  String? _role;
  List<Map<String, dynamic>> _gyms = [];
  int? _gymId;
  List<Map<String, dynamic>>? _members;
  late final Set<int> _selected = {...?widget.memberIds};
  String _query = '';
  DateTime _startDate = DateUtils.dateOnly(DateTime.now());
  DateTime? _endDate;
  bool _isLoading = false;
  bool _isSaving = false;

  bool get _fixedMembers => widget.memberIds != null;

  @override
  void initState() {
    super.initState();
    if (!_fixedMembers) _init();
  }

  Future<void> _init() async {
    setState(() => _isLoading = true);
    final token = await _authService.loadToken();
    _role = await _authService.getUserType();
    if (token == null) return;
    if (_role == 'owner') {
      final gyms = await _apiService.getGyms(token);
      _gyms = gyms?.whereType<Map<String, dynamic>>().toList() ?? [];
      _gymId = _gyms.isEmpty ? null : _gyms.first['id'] as int?;
    } else if (_role == 'manager') {
      final profile = await _authService.getCachedUserProfile();
      final gymId = profile?['gymId'];
      _gymId = gymId is int ? gymId : null;
    }
    await _loadMembers(token);
  }

  Future<void> _loadMembers([String? token]) async {
    token ??= await _authService.loadToken();
    if (token == null) return;
    if (mounted) setState(() => _isLoading = true);
    List<Map<String, dynamic>>? members;
    if (_role == 'coach') {
      members = await _coachService.getMyMembers(token);
    } else if (_gymId != null) {
      final list = await _apiService.getGymMembers(_gymId!, token);
      members = list?.whereType<Map<String, dynamic>>().toList();
    }
    if (!mounted) return;
    setState(() {
      _members = members;
      _isLoading = false;
    });
  }

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _startDate : (_endDate ?? _startDate),
      firstDate: start ? DateTime(now.year - 1) : _startDate,
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      } else {
        _endDate = picked;
      }
    });
  }

  String _memberName(int id) {
    final m = _members?.firstWhere((m) => m['id'] == id, orElse: () => {});
    return (m == null || m.isEmpty) ? 'Membre #$id' : getUserFullName(m);
  }

  Future<void> _submit() async {
    final programId = widget.program['id'];
    if (_selected.isEmpty || programId is! int) return;
    setState(() => _isSaving = true);
    final token = await _authService.loadToken();
    if (token == null) {
      setState(() => _isSaving = false);
      return;
    }
    final result = await _programService.assign(
      token,
      programId,
      memberIds: _selected.toList(),
      startDate: _startDate,
      endDate: _endDate,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (result.ok) {
      AppSnackBar.success(
        context,
        result.replaced > 0
            ? 'Programme affecté (${result.replaced} ancien(s) programme(s) '
                  'terminé(s))'
            : 'Programme affecté',
      );
      Navigator.pop(context, true);
    } else if (result.rejected.isNotEmpty) {
      final lines = result.rejected.map((r) {
        final id = r['memberId'] as int? ?? 0;
        final reason = ProgramService.rejectReasons[r['reason']] ?? r['reason'];
        return '• ${_memberName(id)} : $reason';
      });
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Affectation refusée'),
          content: Text(
            'Aucun programme n\'a été affecté :\n\n${lines.join('\n')}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      AppSnackBar.error(context, result.error!);
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final members = (_members ?? [])
        .where((m) => getUserFullName(m).toLowerCase().contains(q))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('Affecter « ${widget.program['title'] ?? 'Programme'} »'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ModernButton(
            text: _selected.isEmpty
                ? 'Choisissez des membres'
                : 'Affecter à ${_selected.length} membre(s)',
            icon: Icons.check,
            isLoading: _isSaving,
            onPressed: _selected.isEmpty || _isSaving ? null : _submit,
          ),
        ),
      ),
      body: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('Début'),
            trailing: Text(_formatDate(_startDate)),
            onTap: () => _pickDate(start: true),
          ),
          ListTile(
            leading: const Icon(Icons.event_busy_outlined),
            title: const Text('Fin (optionnelle)'),
            trailing: _endDate == null
                ? const Text('—')
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_formatDate(_endDate!)),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _endDate = null),
                      ),
                    ],
                  ),
            onTap: () => _pickDate(start: false),
          ),
          const Divider(),
          if (_fixedMembers)
            const Expanded(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Le programme actif du membre, s\'il y en a un, sera '
                  'marqué comme terminé.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else ...[
            if (_role == 'owner' && _gyms.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<int>(
                  initialValue: _gymId,
                  decoration: const InputDecoration(labelText: 'Salle'),
                  items: [
                    for (final g in _gyms)
                      if (g['id'] is int)
                        DropdownMenuItem(
                          value: g['id'] as int,
                          child: Text(g['name'] as String? ?? 'Salle'),
                        ),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _gymId = v;
                      _selected.clear();
                    });
                    _loadMembers();
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Rechercher un membre…',
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _members == null
                  ? const Center(
                      child: Text('Impossible de charger les membres'),
                    )
                  : members.isEmpty
                  ? const Center(child: Text('Aucun membre'))
                  : ListView.builder(
                      itemCount: members.length,
                      itemBuilder: (context, i) {
                        final m = members[i];
                        final id = m['id'];
                        if (id is! int) return const SizedBox.shrink();
                        return CheckboxListTile(
                          value: _selected.contains(id),
                          title: Text(getUserFullName(m)),
                          subtitle: Text(m['displayId'] as String? ?? ''),
                          onChanged: (on) => setState(
                            () => on == true
                                ? _selected.add(id)
                                : _selected.remove(id),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
