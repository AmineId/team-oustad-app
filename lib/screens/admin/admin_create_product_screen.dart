import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/models.dart';
import '../../core/services/store_service.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';

/// Écran de création/édition d'un produit store
class AdminCreateProductScreen extends StatefulWidget {
  final StoreProduct? product;

  const AdminCreateProductScreen({super.key, this.product});

  @override
  State<AdminCreateProductScreen> createState() =>
      _AdminCreateProductScreenState();
}

class _AdminCreateProductScreenState extends State<AdminCreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final StoreService _storeService;
  late final AuthService _authService;
  final _imagePicker = ImagePicker();

  // Form controllers
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _categoryController;

  // Form state
  bool _isActive = true;
  List<String> _existingImageUrls = []; // Images déjà uploadées
  final List<Uint8List> _newImagesBytes = []; // Nouvelles images à uploader
  final List<File> _newImageFiles = []; // Fichiers des nouvelles images
  bool _isLoading = false;
  
  static const int _maxImages = 5;

  bool get _isEditing => widget.product != null;
  int get _totalImages => _existingImageUrls.length + _newImagesBytes.length;
  bool get _canAddMoreImages => _totalImages < _maxImages;

  // Catégories prédéfinies
  final List<String> _categories = [
    'Suppléments',
    'Équipement',
    'Vêtements',
    'Accessoires',
    'Nutrition',
    'Boissons',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _authService = AuthService(ApiService.fromEnv());
    _storeService = StoreService(ApiService.fromEnv());

    _nameController = TextEditingController(text: widget.product?.name);
    _descriptionController = TextEditingController(
      text: widget.product?.description,
    );
    _priceController = TextEditingController(
      text: widget.product?.price.toStringAsFixed(2),
    );
    _stockController = TextEditingController(
      text: widget.product?.stock.toString(),
    );
    _categoryController = TextEditingController(
      text: widget.product?.category,
    );

    if (widget.product != null) {
      _isActive = widget.product!.isActive;
      // Charger les images existantes
      if (widget.product!.imageUrls.isNotEmpty) {
        _existingImageUrls = List.from(widget.product!.imageUrls);
      } else if (widget.product!.imageUrl != null) {
        _existingImageUrls = [widget.product!.imageUrl!];
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (!_canAddMoreImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum $_maxImages images autorisées'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ImageSourceSheet(allowMultiple: true),
    );

    if (source == null) return;

    if (source == ImageSource.gallery) {
      // Sélection multiple depuis la galerie
      final remaining = _maxImages - _totalImages;
      final picked = await _imagePicker.pickMultiImage(
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
        limit: remaining,
      );

      for (final image in picked) {
        if (_totalImages >= _maxImages) break;
        final bytes = await image.readAsBytes();
        setState(() {
          _newImageFiles.add(File(image.path));
          _newImagesBytes.add(bytes);
        });
      }
    } else {
      // Photo unique depuis la caméra
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _newImageFiles.add(File(picked.path));
          _newImagesBytes.add(bytes);
        });
      }
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImageFiles.removeAt(index);
      _newImagesBytes.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = await _authService.loadToken();
      final price = double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0;
      final stock = int.tryParse(_stockController.text) ?? 0;
      
      final product = StoreProduct(
        id: widget.product?.id,
        displayId: widget.product?.displayId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        price: price,
        stock: stock,
        isActive: _isActive,
        category: _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        imageUrls: _existingImageUrls,
        gymId: widget.product?.gymId,
      );

      if (_isEditing) {
        await _storeService.updateProduct(
          widget.product!.displayId!,
          name: product.name,
          description: product.description,
          price: product.price,
          stock: product.stock,
          category: product.category,
          isActive: product.isActive,
          imagesBytes: _newImagesBytes.isNotEmpty ? _newImagesBytes : null,
          imageNames: _newImagesBytes.isNotEmpty 
              ? List.generate(_newImagesBytes.length, (i) => 'product_image_$i.jpg')
              : null,
          token: token,
        );
      } else {
        await _storeService.createProduct(
          name: product.name,
          description: product.description,
          price: product.price,
          stock: product.stock,
          category: product.category,
          imagesBytes: _newImagesBytes.isNotEmpty ? _newImagesBytes : null,
          imageNames: _newImagesBytes.isNotEmpty 
              ? List.generate(_newImagesBytes.length, (i) => 'product_image_$i.jpg')
              : null,
          token: token,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Produit modifié' : 'Produit créé'),
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

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isEditing ? 'Modifier le produit' : 'Nouveau produit',
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
              style: TextButton.styleFrom(foregroundColor: context.palette.primary),
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
              'Image du produit',
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
                    controller: _nameController,
                    label: 'Nom du produit',
                    hint: 'Ex: Protéine Whey 1kg',
                    icon: Icons.inventory_2_outlined,
                    required: true,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Décrivez le produit...',
                    icon: Icons.description_rounded,
                    maxLines: 3,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Prix et stock
            _buildSection(
              'Prix & Stock',
              Icons.attach_money_rounded,
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _priceController,
                          label: 'Prix (MAD)',
                          hint: '0.00',
                          icon: Icons.attach_money_rounded,
                          required: true,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*[.,]?\d{0,2}'),
                            ),
                          ],
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _stockController,
                          label: 'Stock',
                          hint: '0',
                          icon: Icons.inventory_outlined,
                          required: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Catégorie
            _buildSection(
              'Catégorie',
              Icons.category_rounded,
              _buildCategorySelector(isDark),
            ),

            const SizedBox(height: 24),

            // Statut
            _buildSection(
              'Statut',
              Icons.toggle_on_rounded,
              _buildStatusToggle(isDark),
            ),

            const SizedBox(height: 100), // Space for FAB
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
            offset: const Offset(0, 4),
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: context.palette.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.bold,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : AppColors.lightBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.palette.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.palette.error),
        ),
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ce champ est requis';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildImagePicker(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compteur d'images
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$_totalImages / $_maxImages images',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                fontSize: 13,
              ),
            ),
            if (_canAddMoreImages)
              TextButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: const Text('Ajouter'),
                style: TextButton.styleFrom(foregroundColor: context.palette.primary),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Grille d'images
        if (_totalImages > 0)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _existingImageUrls.length + _newImagesBytes.length + (_canAddMoreImages ? 1 : 0),
              itemBuilder: (context, index) {
                // Images existantes (depuis le serveur)
                if (index < _existingImageUrls.length) {
                  return _buildImageTile(
                    isDark: isDark,
                    imageUrl: _existingImageUrls[index],
                    onRemove: () => _removeExistingImage(index),
                    isFirst: index == 0,
                  );
                }
                
                // Nouvelles images sélectionnées
                final newIndex = index - _existingImageUrls.length;
                if (newIndex < _newImagesBytes.length) {
                  return _buildImageTile(
                    isDark: isDark,
                    imageBytes: _newImagesBytes[newIndex],
                    onRemove: () => _removeNewImage(newIndex),
                    isFirst: index == 0,
                  );
                }
                
                // Bouton ajouter
                return _buildAddImageButton(isDark);
              },
            ),
          )
        else
          // Placeholder si aucune image
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                  style: BorderStyle.solid,
                ),
              ),
              child: _buildImagePlaceholder(isDark),
            ),
          ),
      ],
    );
  }

  Widget _buildImageTile({
    required bool isDark,
    String? imageUrl,
    Uint8List? imageBytes,
    required VoidCallback onRemove,
    bool isFirst = false,
  }) {
    return Container(
      width: 120,
      height: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 120,
              height: 120,
              child: imageBytes != null
                  ? Image.memory(imageBytes, fit: BoxFit.cover)
                  : imageUrl != null
                      ? _buildNetworkOrBase64Image(imageUrl, isDark)
                      : _buildImagePlaceholder(isDark),
            ),
          ),
          // Badge "principale" pour la première image
          if (isFirst)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Principale',
                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          // Bouton supprimer
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkOrBase64Image(String imageData, bool isDark) {
    // Vérifier si c'est du base64
    if (StoreProduct.isBase64Image(imageData)) {
      try {
        String base64String = imageData;
        if (base64String.contains(',')) {
          base64String = base64String.split(',').last;
        }
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildImagePlaceholder(isDark),
        );
      } catch (_) {
        return _buildImagePlaceholder(isDark);
      }
    }
    
    return Image.network(
      imageData,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _buildImagePlaceholder(isDark),
    );
  }

  Widget _buildAddImageButton(bool isDark) {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 100,
        height: 120,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: context.palette.primary, size: 32),
            const SizedBox(height: 4),
            Text(
              'Ajouter',
              style: TextStyle(color: context.palette.primary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 48,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
        const SizedBox(height: 12),
        Text(
          'Appuyez pour ajouter une image',
          style: TextStyle(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'JPEG, PNG ou WebP • Max 5 Mo',
          style: TextStyle(
            color: isDark
                ? AppColors.darkTextSecondary.withValues(alpha: 0.6)
                : AppColors.lightTextSecondary.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text field pour catégorie personnalisée
        _buildTextField(
          controller: _categoryController,
          label: 'Catégorie',
          hint: 'Sélectionnez ou tapez une catégorie',
          icon: Icons.category_rounded,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        // Chips pour catégories prédéfinies
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((category) {
            final isSelected = _categoryController.text == category;
            return FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _categoryController.text = selected ? category : '';
                });
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: context.palette.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? context.palette.primary
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              backgroundColor: isDark
                  ? AppColors.darkSurface
                  : AppColors.lightBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? context.palette.primary
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatusToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isActive
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _isActive ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              color: _isActive ? context.palette.success : context.palette.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isActive ? 'Produit actif' : 'Produit désactivé',
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  _isActive
                      ? 'Visible dans le store'
                      : 'Masqué du store',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            activeThumbColor: context.palette.success,
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet pour choisir la source de l'image
class _ImageSourceSheet extends StatelessWidget {
  final bool allowMultiple;
  
  const _ImageSourceSheet({this.allowMultiple = true});
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            allowMultiple ? 'Ajouter des images' : 'Choisir une image',
            style: AppTextStyles.h3.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          if (allowMultiple) ...[
            const SizedBox(height: 8),
            Text(
              'Sélectionnez plusieurs images depuis la galerie',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSourceOption(
                  context: context,
                  icon: Icons.photo_library_rounded,
                  label: allowMultiple ? 'Galerie\n(multiple)' : 'Galerie',
                  source: ImageSource.gallery,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSourceOption(
                  context: context,
                  icon: Icons.camera_alt_rounded,
                  label: 'Appareil photo',
                  source: ImageSource.camera,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSourceOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required ImageSource source,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => Navigator.pop(context, source),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: context.palette.primary, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: AppTextStyles.body2.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
