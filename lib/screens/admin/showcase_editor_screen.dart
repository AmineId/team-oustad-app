import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/theme.dart';
import '../../widgets/common/common_widgets.dart';

/// Éditeur markdown de la fiche vitrine — accessible aux owners toujours,
/// aux admins si le flag [canEditShowcase] est actif côté serveur.
class ShowcaseEditorScreen extends StatefulWidget {
  final int gymId;
  final String gymName;

  const ShowcaseEditorScreen({
    super.key,
    required this.gymId,
    required this.gymName,
  });

  @override
  State<ShowcaseEditorScreen> createState() => _ShowcaseEditorScreenState();
}

class _ShowcaseEditorScreenState extends State<ShowcaseEditorScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService.fromEnv();
  final AuthService _auth = AuthService(ApiService.fromEnv());

  late final TabController _tabs;
  final Map<String, TextEditingController> _controllers = {};

  static const _fields = [
    _Field('description', 'Description', Icons.description_outlined),
    _Field('amenities', 'Équipements', Icons.fitness_center_outlined),
    _Field('schedule', 'Horaires', Icons.schedule_outlined),
    _Field('pricing', 'Tarifs', Icons.price_change_outlined),
    _Field('team', 'Équipe', Icons.people_outline),
  ];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDirty = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    for (final f in _fields) {
      _controllers[f.key] = TextEditingController()
        ..addListener(() => setState(() => _isDirty = true));
    }
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    final token = await _auth.loadToken();
    if (token == null) {
      setState(() { _isLoading = false; _error = 'Non authentifié'; });
      return;
    }
    final data = await _api.getShowcaseContent(widget.gymId, token);
    if (!mounted) return;
    if (data != null) {
      for (final f in _fields) {
        _controllers[f.key]!.text = (data[f.key] as String?) ?? '';
      }
    }
    setState(() { _isLoading = false; _isDirty = false; });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final token = await _auth.loadToken();
    if (token == null) {
      setState(() => _isSaving = false);
      return;
    }
    final content = {
      for (final f in _fields) f.key: _controllers[f.key]!.text,
    };
    final ok = await _api.updateShowcaseContent(widget.gymId, token, content);
    if (!mounted) return;
    setState(() { _isSaving = false; _isDirty = !ok; });
    AppSnackBar.show(
      context,
      ok ? 'Vitrine mise à jour ✓' : 'Erreur lors de la sauvegarde',
      type: ok ? SnackBarType.success : SnackBarType.error,
    );
  }

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardTheme.color,
        title: const Text('Modifications non sauvegardées'),
        content: const Text('Quitter sans sauvegarder ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirmDiscard();
        if (ok && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vitrine',
                style: AppTextStyles.h4.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                widget.gymName,
                style: AppTextStyles.caption.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          actions: [
            if (_isDirty && !_isSaving)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Sauver'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ),
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
          bottom: TabBar(
            controller: _tabs,
            labelColor: AppColors.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(icon: Icon(Icons.edit_outlined, size: 18), text: 'Édition'),
              Tab(icon: Icon(Icons.preview_outlined, size: 18), text: 'Aperçu'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _buildEditor(),
                      _buildPreview(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildEditor() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHint(),
        const SizedBox(height: 16),
        for (final f in _fields) ...[
          _buildFieldCard(f),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildFieldCard(_Field field) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkBorder
              : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(field.icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  field.label,
                  style: AppTextStyles.overline.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          TextField(
            controller: _controllers[field.key],
            maxLines: null,
            minLines: 4,
            style: AppTextStyles.body2.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: '# ${field.label}\n\nContenu en **markdown**...',
              hintStyle: AppTextStyles.body2.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                fontSize: 13,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              filled: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final combined = _fields
        .where((f) => _controllers[f.key]!.text.trim().isNotEmpty)
        .map((f) => '## ${f.label}\n\n${_controllers[f.key]!.text.trim()}')
        .join('\n\n---\n\n');

    if (combined.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.preview_outlined, size: 48,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'Aucun contenu à prévisualiser',
              style: AppTextStyles.body2.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    return Markdown(
      data: combined,
      padding: const EdgeInsets.all(20),
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        h2: AppTextStyles.h4.copyWith(color: AppColors.primary),
        p: AppTextStyles.body1.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Supporte le markdown : **gras**, *italique*, ## Titre, - liste',
              style: AppTextStyles.caption.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(_error!, style: AppTextStyles.body1.copyWith(color: AppColors.error)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

class _Field {
  final String key;
  final String label;
  final IconData icon;
  const _Field(this.key, this.label, this.icon);
}
