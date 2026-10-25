import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/models.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/theme.dart';
import '../../widgets/widgets.dart';

/// Éditeur CMS du site vitrine : page d'accueil (owner) ou fiche d'une salle
/// (owner, admin de la salle — vérifié côté serveur).
///
/// La page est une liste ordonnée de sections : on peut en ajouter, les
/// modifier, les réordonner, les masquer ou les supprimer. Les sections
/// intégrées (liste des salles, horaires…) se déplacent et se masquent
/// seulement, leur contenu vient de l'app.
class ShowcaseEditorScreen extends StatefulWidget {
  final ShowcasePageKind kind;
  final int? gymId;
  final String title;

  const ShowcaseEditorScreen.home({super.key})
    : kind = ShowcasePageKind.home,
      gymId = null,
      title = 'Page d\'accueil';

  const ShowcaseEditorScreen.gym({
    super.key,
    required int this.gymId,
    required String gymName,
  }) : kind = ShowcasePageKind.gym,
       title = gymName;

  @override
  State<ShowcaseEditorScreen> createState() => _ShowcaseEditorScreenState();
}

class _ShowcaseEditorScreenState extends State<ShowcaseEditorScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService.fromEnv();
  late final AuthService _auth = AuthService(_api);
  late final TabController _tabs;

  ShowcasePage? _page;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDirty = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final token = await _auth.loadToken();
    if (token == null) {
      setState(() {
        _isLoading = false;
        _error = 'Non authentifié';
      });
      return;
    }
    final json = await _api.getShowcasePage(token, gymId: widget.gymId);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isDirty = false;
      if (json == null) {
        _error = 'Impossible de charger le contenu';
      } else {
        _page = ShowcasePage.fromJson(widget.kind, json);
      }
    });
  }

  Future<void> _save() async {
    final page = _page;
    if (page == null) return;
    setState(() => _isSaving = true);
    final token = await _auth.loadToken();
    if (token == null) {
      setState(() => _isSaving = false);
      return;
    }
    final ok = await _api.updateShowcasePage(
      token,
      page.toJson(),
      gymId: widget.gymId,
    );
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isDirty = !ok;
    });
    AppSnackBar.show(
      context,
      ok
          ? 'Vitrine mise à jour (visible sous 5 min)'
          : 'Erreur lors de la sauvegarde',
      type: ok ? SnackBarType.success : SnackBarType.error,
    );
  }

  void _update(ShowcasePage page) => setState(() {
    _page = page;
    _isDirty = true;
  });

  void _replaceSection(ShowcaseSection updated) {
    final page = _page!;
    _update(
      page.copyWith(
        sections: [
          for (final s in page.sections) s.id == updated.id ? updated : s,
        ],
      ),
    );
  }

  Future<void> _editSection(
    ShowcaseSection section, {
    bool isNew = false,
  }) async {
    final result = await Navigator.push<ShowcaseSection>(
      context,
      MaterialPageRoute(builder: (_) => _SectionEditScreen(section: section)),
    );
    if (result == null || !mounted) return;
    if (isNew) {
      _update(_page!.copyWith(sections: [..._page!.sections, result]));
    } else {
      _replaceSection(result);
    }
  }

  Future<void> _addSection() async {
    final type = await showModalBottomSheet<ShowcaseSectionType>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Ajouter une section', style: AppTextStyles.h4),
            ),
            for (final t in ShowcaseSectionType.contentTypes)
              ListTile(
                leading: Icon(t.icon, color: context.palette.primary),
                title: Text(t.label),
                subtitle: Text(_typeHint(t)),
                onTap: () => Navigator.pop(ctx, t),
              ),
          ],
        ),
      ),
    );
    if (type == null) return;
    await _editSection(ShowcaseSection.create(type), isNew: true);
  }

  Future<void> _deleteSection(ShowcaseSection section) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la section ?'),
        content: Text(
          section.summary.isEmpty
              ? section.type.label
              : '${section.type.label} — ${section.summary}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: context.palette.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    _update(
      _page!.copyWith(
        sections: _page!.sections.where((s) => s.id != section.id).toList(),
      ),
    );
  }

  Future<void> _resetToDefault() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revenir au contenu par défaut ?'),
        content: const Text(
          'Toutes les sections seront remplacées par le contenu d\'origine. '
          'Rien n\'est enregistré tant que tu ne sauvegardes pas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    _update(
      widget.kind == ShowcasePageKind.home
          ? ShowcasePage.defaultHome()
          : ShowcasePage.defaultGym(),
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
            style: TextButton.styleFrom(foregroundColor: context.palette.error),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirmDiscard();
        if (ok && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vitrine',
                style: AppTextStyles.h4.copyWith(color: onSurface),
              ),
              Text(
                widget.title,
                style: AppTextStyles.caption.copyWith(
                  color: onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          actions: [
            if (_page != null && !_isSaving)
              PopupMenuButton<String>(
                onSelected: (_) => _resetToDefault(),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'reset',
                    child: Text('Revenir au contenu par défaut'),
                  ),
                ],
              ),
            if (_isDirty && !_isSaving)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Sauver'),
                  style: TextButton.styleFrom(
                    foregroundColor: context.palette.primary,
                  ),
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
            labelColor: context.palette.primary,
            unselectedLabelColor: onSurface.withValues(alpha: 0.5),
            indicatorColor: context.palette.primary,
            tabs: const [
              Tab(
                icon: Icon(Icons.view_agenda_outlined, size: 18),
                text: 'Sections',
              ),
              Tab(icon: Icon(Icons.preview_outlined, size: 18), text: 'Aperçu'),
            ],
          ),
        ),
        floatingActionButton: _page == null
            ? null
            : AnimatedBuilder(
                animation: _tabs,
                builder: (context, _) => _tabs.index == 0
                    ? FloatingActionButton.extended(
                        onPressed: _addSection,
                        backgroundColor: context.palette.primaryFill,
                        foregroundColor: context.palette.onPrimary,
                        icon: const Icon(Icons.add),
                        label: const Text('Section'),
                      )
                    : const SizedBox.shrink(),
              ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildError()
            : TabBarView(
                controller: _tabs,
                children: [_buildSectionList(), _buildPreview()],
              ),
      ),
    );
  }

  Widget _buildSectionList() {
    final page = _page!;
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      buildDefaultDragHandles: false,
      header: Column(
        children: [
          _buildHint(),
          if (page.kind == ShowcasePageKind.home) ...[
            const SizedBox(height: 12),
            _HeroEditor(
              page: page,
              onChanged: (eyebrow, tagline) => _update(
                page.copyWith(heroEyebrow: eyebrow, heroTagline: tagline),
              ),
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
      itemCount: page.sections.length,
      onReorder: (oldIndex, newIndex) {
        final sections = [...page.sections];
        if (newIndex > oldIndex) newIndex -= 1;
        sections.insert(newIndex, sections.removeAt(oldIndex));
        _update(page.copyWith(sections: sections));
      },
      itemBuilder: (context, index) {
        final section = page.sections[index];
        return Padding(
          key: ValueKey(section.id),
          padding: const EdgeInsets.only(bottom: 10),
          child: _SectionTile(
            section: section,
            index: index,
            onTap: section.type.isBuiltin ? null : () => _editSection(section),
            onToggleVisible: () =>
                _replaceSection(section.copyWith(visible: !section.visible)),
            onDelete: section.type.isBuiltin
                ? null
                : () => _deleteSection(section),
          ),
        );
      },
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
          Icon(Icons.info_outline, size: 16, color: context.palette.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Glisse ⠿ pour réordonner, l\'œil pour masquer. Les sections '
              '« intégrées » affichent les données de l\'app (salles, horaires…).',
              style: AppTextStyles.caption.copyWith(color: context.palette.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final page = _page!;
    var featureIndex = 0;
    return Theme(
      data: AppTheme.darkTheme,
      child: ColoredBox(
        color: AppColors.darkBackground,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
          children: [
            if (page.kind == ShowcasePageKind.home) ...[
              if (page.heroEyebrow.isNotEmpty)
                Text(
                  page.heroEyebrow,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.barlow(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                    color: context.palette.primary,
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                'TEAM OUSTAD',
                textAlign: TextAlign.center,
                style: GoogleFonts.anton(fontSize: 40, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                page.heroTagline,
                textAlign: TextAlign.center,
                style: GoogleFonts.barlow(
                  fontSize: 16,
                  color: AppColors.darkTextSecondary,
                ),
              ),
            ],
            for (final section in page.visibleSections) ...[
              const SizedBox(height: 28),
              if (section.type.isBuiltin)
                _BuiltinPlaceholder(type: section.type)
              else
                ShowcaseContentSection(
                  key: ValueKey(section.id),
                  section: section,
                  standalone: false,
                  reverse:
                      section.type == ShowcaseSectionType.feature &&
                      (featureIndex++).isOdd,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: context.palette.error),
          const SizedBox(height: 12),
          Text(_error ?? 'Erreur', style: AppTextStyles.body1),
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

String _typeHint(ShowcaseSectionType t) {
  switch (t) {
    case ShowcaseSectionType.markdown:
      return 'Titre + texte libre en markdown';
    case ShowcaseSectionType.feature:
      return 'Sur-titre, titre, texte, puces et icône';
    case ShowcaseSectionType.testimonials:
      return 'Avis de membres en cartes';
    case ShowcaseSectionType.marquee:
      return 'Mots qui défilent sur fond doré';
    case ShowcaseSectionType.categories:
      return 'Tuiles icône + libellé';
    case ShowcaseSectionType.cta:
      return 'Encart doré avec un bouton lien';
    default:
      return '';
  }
}

class _HeroEditor extends StatelessWidget {
  final ShowcasePage page;
  final void Function(String eyebrow, String tagline) onChanged;

  const _HeroEditor({required this.page, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _EditorCard(
      icon: Icons.title_rounded,
      label: 'En-tête de la page',
      children: [
        _Field(
          label: 'Sur-titre',
          initialValue: page.heroEyebrow,
          maxLength: 60,
          onChanged: (v) => onChanged(v, page.heroTagline),
        ),
        _Field(
          label: 'Slogan',
          initialValue: page.heroTagline,
          maxLength: 160,
          onChanged: (v) => onChanged(page.heroEyebrow, v),
        ),
      ],
    );
  }
}

class _SectionTile extends StatelessWidget {
  final ShowcaseSection section;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback onToggleVisible;
  final VoidCallback? onDelete;

  const _SectionTile({
    required this.section,
    required this.index,
    required this.onTap,
    required this.onToggleVisible,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isBuiltin = section.type.isBuiltin;
    final summary = isBuiltin
        ? 'Intégrée — données de l\'app'
        : section.summary;
    return Opacity(
      opacity: section.visible ? 1 : 0.5,
      child: Material(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.drag_indicator,
                      color: onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                Icon(
                  section.type.icon,
                  size: 20,
                  color: isBuiltin
                      ? onSurface.withValues(alpha: 0.5)
                      : context.palette.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.type.label,
                        style: AppTextStyles.body1.copyWith(
                          color: onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (summary.isNotEmpty)
                        Text(
                          summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: section.visible ? 'Masquer' : 'Afficher',
                  icon: Icon(
                    section.visible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: onToggleVisible,
                ),
                if (onDelete != null)
                  IconButton(
                    tooltip: 'Supprimer',
                    icon: const Icon(Icons.delete_outline),
                    color: context.palette.error,
                    onPressed: onDelete,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BuiltinPlaceholder extends StatelessWidget {
  final ShowcaseSectionType type;

  const _BuiltinPlaceholder({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(type.icon, color: AppColors.darkTextTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${type.label} (données de l\'app)',
              style: GoogleFonts.barlow(color: AppColors.darkTextTertiary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Édition d'une section ──────────────────────────────────────────────────

class _SectionEditScreen extends StatefulWidget {
  final ShowcaseSection section;

  const _SectionEditScreen({required this.section});

  @override
  State<_SectionEditScreen> createState() => _SectionEditScreenState();
}

class _SectionEditScreenState extends State<_SectionEditScreen> {
  late final Map<String, dynamic> _data;

  // Les listes sont éditées avec une clé stable par ligne, pour que les
  // champs ne s'échangent pas leur texte quand on supprime une ligne.
  final Map<String, List<_Row>> _lists = {};
  int _nextRowKey = 0;

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.section.data);
    for (final key in ['points', 'words']) {
      if (_data[key] is List) {
        _lists[key] = [
          for (final v in _data[key] as List) _row({'value': v.toString()}),
        ];
      }
    }
    if (_data['items'] is List) {
      _lists['items'] = [
        for (final v in (_data['items'] as List).whereType<Map>())
          _row(Map<String, dynamic>.from(v)),
      ];
    }
  }

  _Row _row(Map<String, dynamic> values) => _Row(_nextRowKey++, values);

  ShowcaseSection _result() {
    final data = Map<String, dynamic>.from(_data);
    for (final e in _lists.entries) {
      data[e.key] = (e.key == 'items')
          ? e.value.map((r) => r.values).toList()
          : e.value
                .map((r) => (r.values['value'] as String? ?? '').trim())
                .where((v) => v.isNotEmpty)
                .toList();
    }
    return widget.section.copyWith(data: data);
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.section.type;
    return Scaffold(
      appBar: AppBar(
        title: Text(type.label),
        actions: [
          IconButton(
            tooltip: 'Aperçu',
            icon: const Icon(Icons.preview_outlined),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => Theme(
                data: AppTheme.darkTheme,
                child: Container(
                  color: AppColors.darkBackground,
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      ShowcaseContentSection(
                        section: _result(),
                        standalone: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () => Navigator.pop(context, _result()),
              style: TextButton.styleFrom(foregroundColor: context.palette.primary),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
        children: _fieldsFor(type),
      ),
    );
  }

  Widget _text(
    String key,
    String label, {
    int maxLength = 160,
    bool multiline = false,
    bool markdown = false,
    String? hint,
  }) {
    return _Field(
      label: label,
      initialValue: (_data[key] as String?) ?? '',
      maxLength: maxLength,
      multiline: multiline,
      monospace: markdown,
      hint: hint,
      onChanged: (v) => _data[key] = v,
    );
  }

  List<Widget> _fieldsFor(ShowcaseSectionType type) {
    switch (type) {
      case ShowcaseSectionType.markdown:
        return [
          _EditorCard(
            icon: type.icon,
            label: 'Contenu',
            children: [
              _text('title', 'Titre (optionnel)'),
              _text(
                'body',
                'Texte (markdown)',
                maxLength: 5000,
                multiline: true,
                markdown: true,
                hint: '**gras**, *italique*, - liste, [lien](https://…)',
              ),
            ],
          ),
        ];
      case ShowcaseSectionType.feature:
        return [
          _EditorCard(
            icon: type.icon,
            label: 'Texte',
            children: [
              _text('eyebrow', 'Sur-titre', maxLength: 40, hint: 'EXPÉRIENCE'),
              _text('title', 'Titre', maxLength: 120),
              _text('body', 'Paragraphe', maxLength: 1000, multiline: true),
              _text(
                'tag',
                'Étiquette sur l\'image',
                maxLength: 40,
                hint: 'STUDIO MUSCULATION',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _EditorCard(
            icon: Icons.image_outlined,
            label: 'Icône de l\'image',
            children: [
              _IconPicker(
                selected: _data['icon'] as String?,
                onSelected: (k) => setState(() => _data['icon'] = k),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _stringList('points', 'Puces', 'Point fort', maxItems: 8),
        ];
      case ShowcaseSectionType.testimonials:
        return [
          _EditorCard(
            icon: type.icon,
            label: 'En-tête',
            children: [
              _text('eyebrow', 'Sur-titre', maxLength: 40),
              _text('title', 'Titre', maxLength: 120),
            ],
          ),
          const SizedBox(height: 12),
          _itemList(
            'Témoignages',
            maxItems: 12,
            fields: const [
              _ItemField('name', 'Nom', 60),
              _ItemField('meta', 'Détail (ex. Membre depuis 1 an)', 60),
              _ItemField('quote', 'Citation', 600, multiline: true),
            ],
          ),
        ];
      case ShowcaseSectionType.marquee:
        return [_stringList('words', 'Mots du bandeau', 'Mot', maxItems: 16)];
      case ShowcaseSectionType.categories:
        return [
          _itemList(
            'Tuiles',
            maxItems: 10,
            fields: const [_ItemField('label', 'Libellé', 30)],
            withIcon: true,
          ),
        ];
      case ShowcaseSectionType.cta:
        return [
          _EditorCard(
            icon: type.icon,
            label: 'Contenu',
            children: [
              _text('eyebrow', 'Sur-titre', maxLength: 40),
              _text('text', 'Texte', maxLength: 200, multiline: true),
              _text('buttonLabel', 'Libellé du bouton', maxLength: 30),
              _text('url', 'Lien du bouton', maxLength: 500, hint: 'https://…'),
            ],
          ),
        ];
      default:
        return const [];
    }
  }

  Widget _stringList(
    String key,
    String label,
    String itemLabel, {
    required int maxItems,
  }) {
    final rows = _lists.putIfAbsent(key, () => []);
    return _EditorCard(
      icon: Icons.list_rounded,
      label: label,
      children: [
        for (final row in rows)
          Row(
            key: ValueKey(row.key),
            children: [
              Expanded(
                child: _Field(
                  label: itemLabel,
                  initialValue: row.values['value'] as String? ?? '',
                  maxLength: 120,
                  onChanged: (v) => row.values['value'] = v,
                ),
              ),
              IconButton(
                tooltip: 'Retirer',
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => setState(() => rows.remove(row)),
              ),
            ],
          ),
        if (rows.length < maxItems)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => rows.add(_row({'value': ''}))),
              icon: const Icon(Icons.add),
              label: Text('Ajouter : ${itemLabel.toLowerCase()}'),
            ),
          ),
      ],
    );
  }

  Widget _itemList(
    String label, {
    required int maxItems,
    required List<_ItemField> fields,
    bool withIcon = false,
  }) {
    final rows = _lists.putIfAbsent('items', () => []);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return _EditorCard(
      icon: Icons.list_rounded,
      label: label,
      children: [
        for (var i = 0; i < rows.length; i++)
          Container(
            key: ValueKey(rows[i].key),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: onSurface.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '#${i + 1}',
                      style: AppTextStyles.caption.copyWith(
                        color: context.palette.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Retirer',
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => setState(() => rows.removeAt(i)),
                    ),
                  ],
                ),
                for (final f in fields)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _Field(
                      label: f.label,
                      initialValue: rows[i].values[f.key] as String? ?? '',
                      maxLength: f.maxLength,
                      multiline: f.multiline,
                      onChanged: (v) => rows[i].values[f.key] = v,
                    ),
                  ),
                if (withIcon)
                  _IconPicker(
                    selected: rows[i].values['icon'] as String?,
                    onSelected: (k) =>
                        setState(() => rows[i].values['icon'] = k),
                  ),
              ],
            ),
          ),
        if (rows.length < maxItems)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(
                () => rows.add(_row({if (withIcon) 'icon': 'fitness'})),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            ),
          ),
      ],
    );
  }
}

class _Row {
  final int key;
  final Map<String, dynamic> values;

  _Row(this.key, this.values);
}

class _ItemField {
  final String key;
  final String label;
  final int maxLength;
  final bool multiline;

  const _ItemField(
    this.key,
    this.label,
    this.maxLength, {
    this.multiline = false,
  });
}

class _EditorCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Widget> children;

  const _EditorCard({
    required this.icon,
    required this.label,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
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
          Row(
            children: [
              Icon(icon, size: 16, color: context.palette.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.overline.copyWith(
                  color: context.palette.primary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String initialValue;
  final int maxLength;
  final bool multiline;
  final bool monospace;
  final String? hint;
  final ValueChanged<String> onChanged;

  const _Field({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.maxLength = 160,
    this.multiline = false,
    this.monospace = false,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        initialValue: initialValue,
        onChanged: onChanged,
        maxLength: maxLength,
        maxLines: multiline ? null : 1,
        minLines: multiline ? (monospace ? 6 : 3) : 1,
        keyboardType: multiline ? TextInputType.multiline : TextInputType.text,
        style: monospace
            ? const TextStyle(fontFamily: 'monospace', fontSize: 13)
            : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          alignLabelWithHint: multiline,
          isDense: true,
        ),
      ),
    );
  }
}

class _IconPicker extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelected;

  const _IconPicker({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final e in showcaseIcons.entries)
            ChoiceChip(
              label: Icon(e.value, size: 18),
              selected: e.key == (selected ?? 'fitness'),
              selectedColor: AppColors.primary.withValues(alpha: 0.25),
              showCheckmark: false,
              onSelected: (_) => onSelected(e.key),
            ),
        ],
      ),
    );
  }
}
