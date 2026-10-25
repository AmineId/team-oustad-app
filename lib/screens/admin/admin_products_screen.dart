import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/models.dart';
import '../../core/services/store_service.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';
import 'admin_create_product_screen.dart';

/// Écran de gestion des produits du store pour admin/owner
class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen>
    with SingleTickerProviderStateMixin {
  late final StoreService _storeService;
  late final AuthService _authService;
  late final TabController _tabController;

  List<StoreProduct> _products = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(ApiService.fromEnv());
    _storeService = StoreService(ApiService.fromEnv());
    _tabController = TabController(length: 3, vsync: this);
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _authService.loadToken();
      final products = await _storeService.getAllProducts(token: token);
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur lors du chargement des produits';
          _isLoading = false;
        });
      }
    }
  }

  List<StoreProduct> get _activeProducts =>
      _products.where((p) => p.isActive).toList();

  List<StoreProduct> get _lowStockProducts =>
      _products.where((p) => p.availableStock <= 5 && p.isActive).toList();

  Future<void> _deleteProduct(StoreProduct product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_outline, color: context.palette.error),
            ),
            const SizedBox(width: 12),
            const Text('Supprimer'),
          ],
        ),
        content: Text('Voulez-vous vraiment supprimer "${product.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && product.displayId != null) {
      try {
        final token = await _authService.loadToken();
        final success = await _storeService.deleteProduct(
          product.displayId!,
          token: token,
        );
        if (success) {
          _loadProducts();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Produit supprimé'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la suppression'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _navigateToCreate() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AdminCreateProductScreen()),
    );
    if (result == true) {
      _loadProducts();
    }
  }

  void _navigateToEdit(StoreProduct product) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminCreateProductScreen(product: product),
      ),
    );
    if (result == true) {
      _loadProducts();
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
          'Gestion des Produits',
          style: AppTextStyles.h2.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.palette.primary,
          unselectedLabelColor: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          indicatorColor: context.palette.primary,
          indicatorWeight: 3,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelPadding: const EdgeInsets.symmetric(horizontal: 12),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 16),
                  const SizedBox(width: 4),
                  Text('Tout (${_products.length})', style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: context.palette.success,
                  ),
                  const SizedBox(width: 4),
                  Text('Actifs (${_activeProducts.length})', style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: context.palette.warning,
                  ),
                  const SizedBox(width: 4),
                  Text('Stock bas (${_lowStockProducts.length})', style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: context.palette.error),
                  const SizedBox(height: 16),
                  Text(_error!),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadProducts,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadProducts,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProductsList(_products),
                  _buildProductsList(_activeProducts),
                  _buildProductsList(_lowStockProducts),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreate,
        backgroundColor: context.palette.primaryFill,
        foregroundColor: context.palette.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau produit'),
      ),
    );
  }

  Widget _buildProductsList(List<StoreProduct> products) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun produit',
              style: AppTextStyles.body1.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez votre premier produit',
              style: AppTextStyles.caption.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) => _ProductCard(
        product: products[index],
        onEdit: () => _navigateToEdit(products[index]),
        onDelete: () => _deleteProduct(products[index]),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final StoreProduct product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priceFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'MAD ', decimalDigits: 2);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 100,
                child: _buildProductImage(isDark),
              ),
            ),
            
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status badge & Category
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: product.isActive
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product.isActive ? 'Actif' : 'Inactif',
                          style: TextStyle(
                            color: product.isActive
                                ? context.palette.success
                                : context.palette.error,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (product.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            product.category!,
                            style: TextStyle(
                              color: context.palette.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Name
                  Text(
                    product.name,
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Description
                  if (product.description != null)
                    Text(
                      product.description!,
                      style: AppTextStyles.caption.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  const SizedBox(height: 8),
                  
                  // Price & Stock
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          priceFormat.format(product.price),
                          style: TextStyle(
                            color: context.palette.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStockBadge(context, isDark),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Actions
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onEdit,
                icon: Icon(Icons.edit_rounded, color: context.palette.primary, size: 20),
                tooltip: 'Modifier',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline_rounded, color: context.palette.error, size: 20),
                tooltip: 'Supprimer',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
    ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark
          ? AppColors.darkSurface
          : AppColors.lightBackground,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 40,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
    );
  }

  Widget _buildProductImage(bool isDark) {
    final mainImage = product.displayImages.isNotEmpty 
        ? product.displayImages.first 
        : null;
    
    if (mainImage == null) {
      return _buildPlaceholder(isDark);
    }
    
    // Vérifier si c'est une image base64
    if (StoreProduct.isBase64Image(mainImage)) {
      try {
        String base64String = mainImage;
        // Retirer le préfixe data:image si présent
        if (base64String.contains(',')) {
          base64String = base64String.split(',').last;
        }
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildPlaceholder(isDark),
        );
      } catch (_) {
        return _buildPlaceholder(isDark);
      }
    }
    
    // Sinon c'est une URL
    return Image.network(
      mainImage,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _buildPlaceholder(isDark),
    );
  }

  Widget _buildStockBadge(BuildContext context, bool isDark) {
    final stock = product.availableStock;
    final Color color;
    final String text;

    if (stock <= 0) {
      color = context.palette.error;
      text = 'Rupture';
    } else if (stock <= 5) {
      color = context.palette.warning;
      text = 'Stock: $stock';
    } else {
      color = context.palette.success;
      text = 'Stock: $stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_outlined, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
