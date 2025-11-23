import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _birthDateController;
  late TextEditingController _professionController;
  
  String _selectedFitnessLevel = '';
  
  File? _newProfileImage;
  String? _currentProfileImageBase64;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(_apiService);
    
    // Get member data from profile
    final member = widget.profileData?['member'] as Map<String, dynamic>?;
    
    // Initialize controllers with current data
    _firstNameController = TextEditingController(
      text: member?['firstName'] ?? widget.profileData?['firstName'] ?? '',
    );
    _lastNameController = TextEditingController(
      text: member?['lastName'] ?? widget.profileData?['lastName'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.profileData?['phoneNumber'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.profileData?['email'] ?? '',
    );
    _professionController = TextEditingController(
      text: member?['profession'] ?? '',
    );
    _selectedFitnessLevel = member?['fitnessLevel'] ?? '';
    
    // Format birth date from ISO to French format
    final birthDate = member?['birthDate'];
    if (birthDate != null) {
      try {
        final date = DateTime.parse(birthDate);
        _birthDateController = TextEditingController(
          text: _formatDateFrench(date),
        );
      } catch (e) {
        _birthDateController = TextEditingController();
      }
    } else {
      _birthDateController = TextEditingController();
    }
    
    // Store current profile image
    _currentProfileImageBase64 = member?['profileImage'];
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  String _formatDateFrench(DateTime date) {
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  DateTime? _parseFrenchDate(String frenchDate) {
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    
    try {
      final parts = frenchDate.split(' ');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final monthIndex = months.indexOf(parts[1].toLowerCase());
        final year = int.tryParse(parts[2]);
        
        if (day != null && monthIndex != -1 && year != null) {
          return DateTime(year, monthIndex + 1, day);
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<void> _selectDate() async {
    DateTime? initialDate = DateTime.now();
    if (_birthDateController.text.isNotEmpty) {
      initialDate = _parseFrenchDate(_birthDateController.text) ?? DateTime.now();
    }
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Theme.of(context).brightness == Brightness.dark ? (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary) : AppColors.primaryDark,
              surface: Theme.of(context).cardTheme.color ?? Colors.grey[900]!,
              onSurface: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _birthDateController.text = _formatDateFrench(picked);
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (pickedFile != null) {
        setState(() {
          _newProfileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection: $e'),
          backgroundColor: AppColors.error,
        ),
      );
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
      
      final updateData = <String, dynamic>{
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'phoneNumber': _phoneController.text,
        'email': _emailController.text.isNotEmpty ? _emailController.text : null,
        'profession': _professionController.text.isNotEmpty ? _professionController.text : null,
        'fitnessLevel': _selectedFitnessLevel.isNotEmpty ? _selectedFitnessLevel : null,
      };
      
      // Convert French date to ISO format
      if (_birthDateController.text.isNotEmpty) {
        final date = _parseFrenchDate(_birthDateController.text);
        if (date != null) {
          updateData['birthDate'] = date.toIso8601String().split('T')[0];
        }
      }
      
      // Handle profile image
      if (_newProfileImage != null) {
        final imageBytes = await _newProfileImage!.readAsBytes();
        final base64Image = base64Encode(imageBytes);
        updateData['profileImage'] = 'data:image/jpeg;base64,$base64Image';
      }

      await _apiService.updateMemberProfile(userId, updateData, token);
      
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
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: AppColors.primary,
                          backgroundImage: _newProfileImage != null
                              ? FileImage(_newProfileImage!)
                              : (_currentProfileImageBase64 != null && _currentProfileImageBase64!.isNotEmpty
                                  ? MemoryImage(
                                      base64Decode(
                                        _currentProfileImageBase64!.contains('base64,')
                                            ? _currentProfileImageBase64!.split('base64,')[1]
                                            : _currentProfileImageBase64!,
                                      ),
                                    )
                                  : null) as ImageProvider?,
                          child: (_newProfileImage == null && (_currentProfileImageBase64 == null || _currentProfileImageBase64!.isEmpty))
                              ? Icon(
                                  Icons.person,
                                  size: 60,
                                  color: (Theme.of(context).brightness == Brightness.dark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary),
                                )
                              : null,
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
                ),
                const SizedBox(height: 32),
                
                // Info message
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Touchez la photo pour la modifier',
                          style: TextStyle(
                            fontSize: 13,
                            color: (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

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
                  controller: _firstNameController,
                  label: 'Prénom',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le prénom est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _lastNameController,
                  label: 'Nom',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le nom est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _phoneController,
                  label: 'Téléphone *',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le numéro de téléphone est obligatoire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _emailController,
                  label: 'Email (facultatif)',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
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

                _buildTextField(
                  controller: _professionController,
                  label: 'Profession (facultatif)',
                  icon: Icons.work,
                ),
                const SizedBox(height: 16),

                // Fitness level dropdown
                Text(
                  'Niveau sportif',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary).withValues(alpha: 0.3),
                    ),
                  ),
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedFitnessLevel.isNotEmpty ? _selectedFitnessLevel : null,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.fitness_center,
                        color: AppColors.primary,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    dropdownColor: Theme.of(context).cardTheme.color,
                    style: TextStyle(
                      fontSize: 16,
                      color: (Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary),
                    ),
                    hint: Text(
                      'Sélectionnez votre niveau',
                      style: TextStyle(
                        color: (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(value: '', child: Text('Non renseigné')),
                      DropdownMenuItem(value: 'beginner', child: Text('Débutant')),
                      DropdownMenuItem(value: 'intermediate', child: Text('Intermédiaire')),
                      DropdownMenuItem(value: 'advanced', child: Text('Avancé')),
                      DropdownMenuItem(value: 'expert', child: Text('Expert')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedFitnessLevel = value ?? '';
                      });
                    },
                  ),
                ),
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







