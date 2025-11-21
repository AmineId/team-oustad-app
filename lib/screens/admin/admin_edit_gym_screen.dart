import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/theme.dart';

class AdminEditGymScreen extends StatefulWidget {
  final Map<String, dynamic> gym;
  
  const AdminEditGymScreen({super.key, required this.gym});

  @override
  State<AdminEditGymScreen> createState() => _AdminEditGymScreenState();
}

class _AdminEditGymScreenState extends State<AdminEditGymScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService.fromEnv();
  final AuthService _authService = AuthService(ApiService.fromEnv());
  
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.gym['name'] as String?);
    _addressController = TextEditingController(text: widget.gym['address'] as String?);
    _phoneController = TextEditingController(text: widget.gym['phone'] as String? ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateGym() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = await _authService.loadToken();
      if (token == null) throw Exception('Token non disponible');

      final response = await _apiService.updateGym(
        widget.gym['id'] as int,
        token,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty 
            ? _phoneController.text.trim() 
            : null,
      );

      if (response != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Salle modifiée avec succès !'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Erreur lors de la modification');
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Modifier salle',
          style: TextStyle(color: theme.appBarTheme.titleTextStyle?.color),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.cardTheme.color!,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icône
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Nom de la salle
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nom de la salle',
                      labelStyle: const TextStyle(color: Colors.white60),
                      prefixIcon: const Icon(Icons.business, color: AppColors.primary),
                      filled: true,
                      fillColor: theme.cardTheme.color,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le nom de la salle est requis';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Adresse
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Adresse',
                      labelStyle: const TextStyle(color: Colors.white60),
                      prefixIcon: const Icon(Icons.location_on, color: AppColors.primary),
                      filled: true,
                      fillColor: theme.cardTheme.color,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'L\'adresse est requise';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Téléphone
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Téléphone (optionnel)',
                      labelStyle: const TextStyle(color: Colors.white60),
                      prefixIcon: const Icon(Icons.phone, color: AppColors.primary),
                      filled: true,
                      fillColor: theme.cardTheme.color,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bouton modifier
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updateGym,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Modifier la salle',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
