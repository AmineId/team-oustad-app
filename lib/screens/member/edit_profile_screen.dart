import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/theme.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? profileData;
  final VoidCallback? onProfileUpdated;

  const EditProfileScreen({
    super.key,
    this.profileData,
    this.onProfileUpdated,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService.fromEnv();
  late final AuthService _authService;
  
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _birthDateController;
  late TextEditingController _addressController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(_apiService);
    
    // Initialize controllers with current data
    _fullNameController = TextEditingController(
      text: widget.profileData?['fullName'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.profileData?['email'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.profileData?['phone'] ?? '',
    );
    _birthDateController = TextEditingController(
      text: widget.profileData?['birthDate'] ?? '',
    );
    _addressController = TextEditingController(
      text: widget.profileData?['address'] ?? '',
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDateController.text.isNotEmpty
          ? DateTime.tryParse(_birthDateController.text) ?? DateTime.now()
          : DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Theme.of(context).brightness == Brightness.dark ? (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary) : AppColors.primaryDark,
              surface: Theme.of(context).cardTheme.color ?? Colors.grey[900]!,
              onSurface: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary) ?? (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _birthDateController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await _authService.loadToken();
      if (token == null) {
        throw Exception('Session expirée');
      }

      final userId = widget.profileData?['id'] as int;
      
      final updateData = {
        'fullName': _fullNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text.isNotEmpty ? _phoneController.text : null,
        'birthDate': _birthDateController.text.isNotEmpty ? _birthDateController.text : null,
        'address': _addressController.text.isNotEmpty ? _addressController.text : null,
      };

      await _apiService.updateUserProfile(userId, updateData, token);
      
      // Refresh profile data
      await _authService.refreshUserProfile();
      
      if (mounted) {
        widget.onProfileUpdated?.call();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ Profil mis à jour avec succès',
              textAlign: TextAlign.center,
              style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary), fontWeight: FontWeight.w500),
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
        
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur: ${e.toString()}',
              textAlign: TextAlign.center,
              style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
            ),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Modifier le Profil',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).cardTheme.color!,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile picture section
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.person, size: 60, color: Theme.of(context).brightness == Brightness.dark ? (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary) : AppColors.primaryDark),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Form fields
                Text(
                  'Informations Personnelles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  ),
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _fullNameController,
                  label: 'Nom complet',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le nom est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'L\'email est requis';
                    }
                    if (!value.contains('@')) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _phoneController,
                  label: 'Téléphone',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _birthDateController,
                  label: 'Date de naissance',
                  icon: Icons.cake,
                  readOnly: true,
                  onTap: _selectDate,
                  suffixIcon: Icons.calendar_today,
                ),
                const SizedBox(height: 16),

                _buildAddressField(),
                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Theme.of(context).brightness == Brightness.dark ? (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary) : AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Theme.of(context).brightness == Brightness.dark ? (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary) : AppColors.primaryDark,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Enregistrer les modifications',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Cancel button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressField() {
    return _buildTextField(
      controller: _addressController,
      label: 'Adresse',
      icon: Icons.location_on,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    IconData? suffixIcon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, color: AppColors.primary)
            : null,
        filled: true,
        fillColor: Theme.of(context).cardTheme.color,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
      ),
    );
  }
}







