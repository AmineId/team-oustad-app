import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/user_utils.dart';
import '../../widgets/common/common_widgets.dart';

/// Gestion des coachs (owner) : liste, création, salles d'affectation.
class AdminCoachesScreen extends StatefulWidget {
  const AdminCoachesScreen({super.key});

  @override
  State<AdminCoachesScreen> createState() => _AdminCoachesScreenState();
}

class _AdminCoachesScreenState extends State<AdminCoachesScreen> {
  final ApiService _apiService = ApiService.fromEnv();
  late final AuthService _authService = AuthService(_apiService);
  late final CoachService _coachService = CoachService(_apiService);

  List<Map<String, dynamic>> _coaches = [];
  List<Map<String, dynamic>> _gyms = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final token = await _authService.loadToken();
    if (token == null) {
      setState(() {
        _error = 'Session expirée';
        _isLoading = false;
      });
      return;
    }
    final results = await Future.wait([
      _coachService.getCoaches(token),
      _apiService.getGyms(token),
    ]);
    if (!mounted) return;
    final coaches = results[0] as List<Map<String, dynamic>>?;
    final gyms = results[1];
    setState(() {
      _coaches = coaches ?? [];
      _gyms = gyms?.whereType<Map<String, dynamic>>().toList() ?? [];
      _error = coaches == null ? 'Impossible de charger les coachs' : null;
      _isLoading = false;
    });
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AdminCreateCoachScreen(gyms: _gyms)),
    );
    if (created == true) _load();
  }

  Future<void> _editGyms(Map<String, dynamic> coach) async {
    final current = CoachService.gymsOf(
      coach,
    ).map((g) => g['id']).whereType<int>().toSet();
    final selected = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _GymPickerSheet(
        title: 'Salles de ${getUserFullName(coach)}',
        gyms: _gyms,
        initial: current,
      ),
    );
    if (selected == null || !mounted) return;
    final token = await _authService.loadToken();
    final coachId = coach['id'];
    if (token == null || coachId is! int) return;
    final ok = await _coachService.updateCoachGyms(
      token,
      coachId,
      selected.toList(),
    );
    if (!mounted) return;
    if (ok) {
      AppSnackBar.success(context, 'Salles du coach mises à jour');
      _load();
    } else {
      AppSnackBar.error(context, 'Échec de la mise à jour des salles');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Coachs')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _gyms.isEmpty ? null : _openCreate,
        icon: const Icon(Icons.person_add),
        label: const Text('Nouveau coach'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                ],
              )
            : _coaches.isEmpty
            ? ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Aucun coach', textAlign: TextAlign.center),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: _coaches.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final coach = _coaches[i];
                  final gymNames = CoachService.gymsOf(
                    coach,
                  ).map((g) => g['name']).whereType<String>().join(' · ');
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: context.palette.primary.withValues(
                          alpha: 0.15,
                        ),
                        child: Icon(
                          Icons.sports,
                          color: context.palette.primary,
                        ),
                      ),
                      title: Text(getUserFullName(coach)),
                      subtitle: Text(
                        gymNames.isEmpty ? 'Aucune salle' : gymNames,
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: const Icon(Icons.edit_location_alt_outlined),
                      onTap: () => _editGyms(coach),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

/// Création d'un coach (owner). Le serveur envoie l'email d'activation.
class AdminCreateCoachScreen extends StatefulWidget {
  final List<Map<String, dynamic>> gyms;

  const AdminCreateCoachScreen({super.key, required this.gyms});

  @override
  State<AdminCreateCoachScreen> createState() => _AdminCreateCoachScreenState();
}

class _AdminCreateCoachScreenState extends State<AdminCreateCoachScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService.fromEnv();
  late final AuthService _authService = AuthService(_apiService);
  late final CoachService _coachService = CoachService(_apiService);

  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final Set<int> _gymIds = {};
  bool _isSaving = false;

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gymIds.isEmpty) {
      AppSnackBar.warning(context, 'Sélectionnez au moins une salle');
      return;
    }
    setState(() => _isSaving = true);
    final token = await _authService.loadToken();
    if (token == null) {
      if (mounted) setState(() => _isSaving = false);
      return;
    }
    final error = await _coachService.createCoach(
      token,
      email: _emailController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      gymIds: _gymIds.toList(),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (error == null) {
      AppSnackBar.success(
        context,
        'Coach créé ! Email de configuration envoyé.',
      );
      Navigator.pop(context, true);
    } else {
      AppSnackBar.error(context, error);
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Champ requis' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau coach')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ModernTextField(
                  controller: _firstNameController,
                  label: 'Prénom',
                  prefixIcon: Icons.person_outline,
                  validator: _required,
                ),
                const SizedBox(height: 16),
                ModernTextField(
                  controller: _lastNameController,
                  label: 'Nom',
                  prefixIcon: Icons.person_outline,
                  validator: _required,
                ),
                const SizedBox(height: 16),
                ModernTextField(
                  controller: _emailController,
                  label: 'Email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      _required(v) ??
                      (v!.contains('@') ? null : 'Email invalide'),
                ),
                const SizedBox(height: 16),
                ModernTextField(
                  controller: _phoneController,
                  label: 'Téléphone (optionnel)',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),
                Text('Salles', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final gym in widget.gyms)
                      if (gym['id'] is int)
                        FilterChip(
                          label: Text(gym['name'] as String? ?? 'Salle'),
                          selected: _gymIds.contains(gym['id']),
                          onSelected: (on) => setState(
                            () => on
                                ? _gymIds.add(gym['id'] as int)
                                : _gymIds.remove(gym['id']),
                          ),
                        ),
                  ],
                ),
                const SizedBox(height: 32),
                ModernButton(
                  text: 'Créer le coach',
                  icon: Icons.check,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GymPickerSheet extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> gyms;
  final Set<int> initial;

  const _GymPickerSheet({
    required this.title,
    required this.gyms,
    required this.initial,
  });

  @override
  State<_GymPickerSheet> createState() => _GymPickerSheetState();
}

class _GymPickerSheetState extends State<_GymPickerSheet> {
  late final Set<int> _selected = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Les membres affectés à ce coach dans une salle retirée '
              'perdront leur coach.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final gym in widget.gyms)
                    if (gym['id'] is int)
                      CheckboxListTile(
                        title: Text(gym['name'] as String? ?? 'Salle'),
                        value: _selected.contains(gym['id']),
                        onChanged: (on) => setState(
                          () => on == true
                              ? _selected.add(gym['id'] as int)
                              : _selected.remove(gym['id']),
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ModernButton(
              text: 'Enregistrer',
              icon: Icons.check,
              onPressed: _selected.isEmpty
                  ? null
                  : () => Navigator.pop(context, _selected),
            ),
          ],
        ),
      ),
    );
  }
}
