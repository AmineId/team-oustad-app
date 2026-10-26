import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/core.dart';
import '../../widgets/common/common_widgets.dart';

/// Signaler un incident (manager : sa salle ; coach : une de ses salles).
/// Utilisé aussi par le kiosk, où le serveur marque la source « kiosk ».
/// Renvoie `true` au pop si l'incident a été créé.
class IncidentCreateScreen extends StatefulWidget {
  const IncidentCreateScreen({super.key});

  @override
  State<IncidentCreateScreen> createState() => _IncidentCreateScreenState();
}

class _IncidentCreateScreenState extends State<IncidentCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService.fromEnv();
  late final AuthService _authService = AuthService(_apiService);
  late final IncidentService _incidentService = IncidentService(_apiService);
  final _picker = ImagePicker();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = 'equipment';
  String _severity = 'medium';
  Uint8List? _photo;
  String _photoMime = 'image/jpeg';

  /// Salles proposées au coach (`gyms` du profil) ; vide pour le manager,
  /// dont la salle est imposée par le serveur.
  List<Map<String, dynamic>> _gyms = [];
  int? _gymId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadGyms();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadGyms() async {
    if (!await _authService.isCoach()) return;
    final profile = await _authService.getCachedUserProfile();
    var gyms = CoachService.gymsOf(profile ?? {});
    final user = profile?['user'];
    if (gyms.isEmpty && user is Map<String, dynamic>) {
      gyms = CoachService.gymsOf(user);
    }
    if (!mounted) return;
    setState(() {
      _gyms = gyms;
      _gymId = gyms.length == 1 ? gyms.first['id'] as int? : null;
    });
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 75,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final name = picked.name.toLowerCase();
      setState(() {
        _photo = bytes;
        _photoMime = name.endsWith('.png')
            ? 'image/png'
            : name.endsWith('.webp')
            ? 'image/webp'
            : 'image/jpeg';
      });
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Photo indisponible : $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gyms.isNotEmpty && _gymId == null) {
      AppSnackBar.warning(context, 'Choisissez la salle concernée');
      return;
    }
    setState(() => _isSaving = true);
    final token = await _authService.loadToken();
    if (token == null) {
      setState(() => _isSaving = false);
      return;
    }
    final error = await _incidentService.create(
      token,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      severity: _severity,
      gymId: _gymId,
      photo: _photo,
      photoMime: _photoMime,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (error == null) {
      AppSnackBar.success(context, 'Incident signalé au propriétaire');
      Navigator.pop(context, true);
    } else {
      AppSnackBar.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signaler un incident')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_gyms.isNotEmpty) ...[
              DropdownButtonFormField<int>(
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
                onChanged: (v) => setState(() => _gymId = v),
              ),
              const SizedBox(height: 12),
            ],
            ModernTextField(
              controller: _titleController,
              label: 'Titre',
              prefixIcon: Icons.title,
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return 'Champ requis';
                return t.length > 200 ? '200 caractères maximum' : null;
              },
            ),
            const SizedBox(height: 12),
            ModernTextField(
              controller: _descriptionController,
              label: 'Description',
              prefixIcon: Icons.notes,
              maxLines: 5,
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return 'Champ requis';
                return t.length > 5000 ? '5000 caractères maximum' : null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Catégorie'),
              items: [
                for (final e in IncidentService.categories.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 16),
            Text('Gravité', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final e in IncidentService.severities.entries)
                  ChoiceChip(
                    label: Text(e.value),
                    selected: _severity == e.key,
                    onSelected: (_) => setState(() => _severity = e.key),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_photo != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _photo!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  IconButton.filled(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _photo = null),
                  ),
                ],
              )
            else
              Row(
                children: [
                  if (!kIsWeb)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickPhoto(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Photo'),
                      ),
                    ),
                  if (!kIsWeb) const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickPhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Galerie'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            ModernButton(
              text: 'Envoyer au propriétaire',
              icon: Icons.send,
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
