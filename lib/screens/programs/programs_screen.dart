import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../core/theme/theme.dart';
import '../../widgets/common/common_widgets.dart';
import 'program_assign_screen.dart';
import 'program_detail_screen.dart';
import 'program_editor_screen.dart';

/// Catalogue des programmes (owner, manager, coach). L'owner crée et modifie ;
/// tout le monde peut affecter. Avec [assignToMemberIds], un tap mène
/// directement à l'affectation pour ces membres (depuis une fiche membre).
class ProgramsScreen extends StatefulWidget {
  final List<int>? assignToMemberIds;

  const ProgramsScreen({super.key, this.assignToMemberIds});

  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  final ApiService _apiService = ApiService.fromEnv();
  late final AuthService _authService = AuthService(_apiService);
  late final ProgramService _programService = ProgramService(_apiService);
  final _searchController = TextEditingController();

  List<Map<String, dynamic>>? _programs;
  bool _isLoading = true;
  bool _isOwner = false;

  bool get _picking => widget.assignToMemberIds != null;

  @override
  void initState() {
    super.initState();
    _authService.isOwner().then((v) {
      if (mounted) setState(() => _isOwner = v);
    });
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final token = await _authService.loadToken();
    final programs = token == null
        ? null
        : await _programService.getPrograms(
            token,
            search: _searchController.text.trim(),
          );
    if (!mounted) return;
    setState(() {
      _programs = programs;
      _isLoading = false;
    });
  }

  Future<void> _open(Map<String, dynamic> program) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _picking
            ? ProgramAssignScreen(
                program: program,
                memberIds: widget.assignToMemberIds,
              )
            : ProgramDetailScreen(program: program),
      ),
    );
    if (!mounted) return;
    if (_picking && changed == true) {
      Navigator.pop(context, true);
    } else if (changed == true) {
      _load();
    }
  }

  Future<void> _create() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ProgramEditorScreen()),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final programs = _programs;
    return Scaffold(
      appBar: AppBar(
        title: Text(_picking ? 'Choisir un programme' : 'Programmes'),
      ),
      floatingActionButton: _isOwner && !_picking
          ? FloatingActionButton.extended(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text('Nouveau programme'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: ModernTextField(
              controller: _searchController,
              hint: 'Rechercher un programme…',
              prefixIcon: Icons.search,
              textInputAction: TextInputAction.search,
              onFieldSubmitted: (_) => _load(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (programs == null || programs.isEmpty)
                  ? ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            programs == null
                                ? 'Impossible de charger les programmes'
                                : 'Aucun programme',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: programs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _ProgramTile(
                        program: programs[i],
                        onTap: () => _open(programs[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramTile extends StatelessWidget {
  final Map<String, dynamic> program;
  final VoidCallback onTap;

  const _ProgramTile({required this.program, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final level = ProgramService.levels[program['level']];
    final days = ProgramService.daysOf(program).length;
    final assigned = program['assignmentsCount'] as int? ?? 0;
    final details = [
      ?level,
      '$days jour${days > 1 ? 's' : ''} / semaine',
      if (program['durationWeeks'] is int)
        '${program['durationWeeks']} semaines',
      '$assigned membre${assigned > 1 ? 's' : ''}',
    ].join(' · ');
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: context.palette.primary.withValues(alpha: 0.15),
          child: Icon(Icons.fitness_center, color: context.palette.primary),
        ),
        title: Text(program['title'] as String? ?? 'Programme'),
        subtitle: Text(details),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
