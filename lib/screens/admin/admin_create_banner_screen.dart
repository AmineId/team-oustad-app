import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/models/models.dart';
import '../../core/services/banner_service.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Écran de création/édition de bannière
class AdminCreateBannerScreen extends StatefulWidget {
  final BannerModel? banner;

  const AdminCreateBannerScreen({super.key, this.banner});

  @override
  State<AdminCreateBannerScreen> createState() =>
      _AdminCreateBannerScreenState();
}

class _AdminCreateBannerScreenState extends State<AdminCreateBannerScreen> {
  final _formKey = GlobalKey<FormState>();
  late final BannerService _bannerService;
  late final AuthService _authService;
  final _imagePicker = ImagePicker();

  // Form controllers
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _actionUrlController;

  // Form state
  BannerType _selectedType = BannerType.event;
  BannerActionType _selectedActionType = BannerActionType.none;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  int _priority = 0;
  bool _isActive = true;
  String? _imageBase64;
  File? _imageFile;
  bool _isLoading = false;
  Color _backgroundColor = const Color(0xFF6366F1); // Indigo par défaut
  Color _textColor = Colors.white;

  bool get _isEditing => widget.banner != null;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(ApiService.fromEnv());
    _bannerService = BannerService(ApiService.fromEnv());

    _titleController = TextEditingController(text: widget.banner?.title);
    _descriptionController = TextEditingController(
      text: widget.banner?.description,
    );
    _imageUrlController = TextEditingController(text: widget.banner?.imageUrl);
    _actionUrlController = TextEditingController(
      text: widget.banner?.action?.data,
    );

    if (widget.banner != null) {
      _selectedType = widget.banner!.type;
      _selectedActionType =
          widget.banner!.action?.type ?? BannerActionType.none;
      _startDate = widget.banner!.startDate;
      _endDate = widget.banner!.endDate;
      _priority = widget.banner!.priority;
      _isActive = widget.banner!.isActive;
      _imageBase64 = widget.banner!.imageBase64;
      // Restaurer les couleurs
      if (widget.banner!.backgroundColor != null) {
        _backgroundColor =
            _parseColor(widget.banner!.backgroundColor!) ?? _backgroundColor;
      }
      if (widget.banner!.textColor != null) {
        _textColor = _parseColor(widget.banner!.textColor!) ?? _textColor;
      }
    }
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) return null;
    try {
      String hex = colorString.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return null;
    }
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _actionUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ImageSourceSheet(),
    );

    if (source == null) return;

    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 600,
      imageQuality: 85,
    );

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageFile = File(picked.path);
        _imageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        _imageUrlController.clear();
      });
    }
  }

  Future<void> _selectDate(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Theme.of(context).cardTheme.color!,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Aussi sélectionner l'heure
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
      );

      final dateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time?.hour ?? 0,
        time?.minute ?? 0,
      );

      setState(() {
        if (isStart) {
          _startDate = dateTime;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 7));
          }
        } else {
          _endDate = dateTime;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = await _authService.loadToken();
      final banner = BannerModel(
        id: widget.banner?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        imageBase64: _imageBase64,
        type: _selectedType,
        startDate: _startDate,
        endDate: _endDate,
        action: _selectedActionType != BannerActionType.none
            ? BannerAction(
                type: _selectedActionType,
                data: _actionUrlController.text.trim().isEmpty
                    ? null
                    : _actionUrlController.text.trim(),
              )
            : null,
        priority: _priority,
        isActive: _isActive,
        backgroundColor: _colorToHex(_backgroundColor),
        textColor: _colorToHex(_textColor),
      );

      if (_isEditing) {
        await _bannerService.updateBanner(
          widget.banner!.id!,
          banner,
          token: token,
        );
      } else {
        await _bannerService.createBanner(banner, token: token);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Bannière modifiée' : 'Bannière créée'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMM yyyy HH:mm', 'fr_FR');

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isEditing ? 'Modifier la bannière' : 'Nouvelle bannière',
          style: AppTextStyles.h2.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: Text(_isEditing ? 'Enregistrer' : 'Créer'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image picker
            _buildSection(
              'Image',
              Icons.image_rounded,
              _buildImagePicker(isDark),
            ),

            const SizedBox(height: 24),

            // Info basiques
            _buildSection(
              'Informations',
              Icons.info_outline_rounded,
              Column(
                children: [
                  _buildTextField(
                    controller: _titleController,
                    label: 'Titre',
                    hint: 'Ex: Offre spéciale été',
                    icon: Icons.title_rounded,
                    required: true,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Ex: Profitez de -30% sur tous les abonnements',
                    icon: Icons.description_rounded,
                    maxLines: 3,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Type
            _buildSection(
              'Type',
              Icons.category_rounded,
              _buildTypeSelector(isDark),
            ),

            const SizedBox(height: 24),

            // Dates
            _buildSection(
              'Période',
              Icons.date_range_rounded,
              Column(
                children: [
                  _buildDateButton(
                    label: 'Date de début',
                    date: _startDate,
                    dateFormat: dateFormat,
                    onTap: () => _selectDate(true),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildDateButton(
                    label: 'Date de fin',
                    date: _endDate,
                    dateFormat: dateFormat,
                    onTap: () => _selectDate(false),
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action
            _buildSection(
              'Action au clic',
              Icons.touch_app_rounded,
              Column(
                children: [
                  _buildActionTypeSelector(isDark),
                  if (_selectedActionType != BannerActionType.none) ...[
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _actionUrlController,
                      label: _selectedActionType == BannerActionType.externalUrl
                          ? 'URL externe'
                          : 'Route de navigation',
                      hint: _selectedActionType == BannerActionType.externalUrl
                          ? 'https://...'
                          : '/screen-name',
                      icon: Icons.link_rounded,
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Options avancées
            _buildSection(
              'Options',
              Icons.tune_rounded,
              Column(
                children: [
                  // Priorité
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Priorité d\'affichage',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (_priority > 0) setState(() => _priority--);
                        },
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: AppColors.primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_priority',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _priority++),
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Actif
                  SwitchListTile(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    title: Text(
                      'Bannière active',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    subtitle: Text(
                      _isActive
                          ? 'Visible selon les dates'
                          : 'Masquée même pendant la période',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Couleurs
            _buildSection(
              'Couleurs',
              Icons.palette_rounded,
              Column(
                children: [
                  // Couleur de fond
                  _buildColorPicker(
                    label: 'Couleur de fond',
                    color: _backgroundColor,
                    onColorChanged: (color) =>
                        setState(() => _backgroundColor = color),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  // Couleur du texte
                  _buildColorPicker(
                    label: 'Couleur du texte',
                    color: _textColor,
                    onColorChanged: (color) =>
                        setState(() => _textColor = color),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  // Aperçu
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aperçu du texte',
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Voici à quoi ressemblera votre bannière',
                          style: TextStyle(
                            color: _textColor.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100), // Espace pour le FAB
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTextStyles.h3.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildImagePicker(bool isDark) {
    final hasImage =
        _imageFile != null ||
        _imageBase64 != null ||
        _imageUrlController.text.isNotEmpty;

    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_imageFile != null)
                          Image.file(_imageFile!, fit: BoxFit.cover)
                        else if (_imageBase64 != null)
                          Image.memory(
                            base64Decode(_imageBase64!.split(',').last),
                            fit: BoxFit.cover,
                          )
                        else if (_imageUrlController.text.isNotEmpty)
                          Image.network(
                            _imageUrlController.text,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildImagePlaceholder(),
                          ),
                        Container(
                          color: Colors.black.withValues(alpha: 0.3),
                          child: const Center(
                            child: Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ],
                    )
                  : _buildImagePlaceholder(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'OU',
          style: TextStyle(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _imageUrlController,
          label: 'URL de l\'image',
          hint: 'https://...',
          icon: Icons.link_rounded,
          isDark: isDark,
          onChanged: (_) => setState(() {
            _imageFile = null;
            _imageBase64 = null;
          }),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_rounded,
            size: 48,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajouter une image',
            style: TextStyle(
              color: AppColors.primary.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool required = false,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      style: TextStyle(
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : AppColors.lightBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      validator: required
          ? (v) => v?.trim().isEmpty == true ? 'Champ requis' : null
          : null,
    );
  }

  Widget _buildTypeSelector(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: BannerType.values.map((type) {
        final isSelected = _selectedType == type;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? type.color.withValues(alpha: 0.2)
                  : isDark
                  ? AppColors.darkSurface
                  : AppColors.lightBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? type.color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  type.icon,
                  size: 18,
                  color: isSelected
                      ? type.color
                      : isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  type.displayName,
                  style: TextStyle(
                    color: isSelected
                        ? type.color
                        : isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionTypeSelector(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: BannerActionType.values.map((type) {
        final isSelected = _selectedActionType == type;
        return GestureDetector(
          onTap: () => setState(() => _selectedActionType = type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : isDark
                  ? AppColors.darkSurface
                  : AppColors.lightBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Text(
              type.displayName,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primary
                    : isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime date,
    required DateFormat dateFormat,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(date),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageSourceSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Choisir une source',
            style: AppTextStyles.h3.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSourceButton(
                context,
                Icons.camera_alt_rounded,
                'Caméra',
                ImageSource.camera,
                isDark,
              ),
              _buildSourceButton(
                context,
                Icons.photo_library_rounded,
                'Galerie',
                ImageSource.gallery,
                isDark,
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSourceButton(
    BuildContext context,
    IconData icon,
    String label,
    ImageSource source,
    bool isDark,
  ) {
    return InkWell(
      onTap: () => Navigator.pop(context, source),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Extension pour le sélecteur de couleur
extension _ColorPickerExtension on _AdminCreateBannerScreenState {
  Widget _buildColorPicker({
    required String label,
    required Color color,
    required ValueChanged<Color> onColorChanged,
    required bool isDark,
  }) {
    // Couleurs prédéfinies
    final presetColors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFEC4899), // Rose
      const Color(0xFFEF4444), // Rouge
      const Color(0xFFF97316), // Orange
      const Color(0xFFEAB308), // Jaune
      const Color(0xFF22C55E), // Vert
      const Color(0xFF14B8A6), // Teal
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF3B82F6), // Bleu
      const Color(0xFF1F2937), // Gris foncé
      const Color(0xFFFFFFFF), // Blanc
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presetColors.map((presetColor) {
            final isSelected = color.toARGB32() == presetColor.toARGB32();
            return GestureDetector(
              onTap: () => onColorChanged(presetColor),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: presetColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (presetColor == Colors.white
                              ? Colors.grey.shade300
                              : Colors.transparent),
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: presetColor.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
