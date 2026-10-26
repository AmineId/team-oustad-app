import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/theme.dart';
import '../../widgets/widgets.dart';

class AdminEditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? profileData;
  final VoidCallback? onProfileUpdated;

  const AdminEditProfileScreen({
    super.key,
    this.profileData,
    this.onProfileUpdated,
  });

  @override
  State<AdminEditProfileScreen> createState() => _AdminEditProfileScreenState();
}

class _AdminEditProfileScreenState extends State<AdminEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService.fromEnv();
  late final AuthService _authService;

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  File? _newProfileImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(_apiService);
    final data = widget.profileData;
    _firstNameController = TextEditingController(
      text: data?['firstName'] as String? ?? '',
    );
    _lastNameController = TextEditingController(
      text: data?['lastName'] as String? ?? '',
    );
    _emailController = TextEditingController(
      text: data?['email'] as String? ?? '',
    );
    _phoneController = TextEditingController(
      text: data?['phoneNumber'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _newProfileImage = File(picked.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final token = await _authService.loadToken();
      final userId = widget.profileData?['id'] as int?;
      if (token == null || userId == null) {
        throw Exception('Session expirée');
      }

      if (_newProfileImage != null) {
        final bytes = await _newProfileImage!.readAsBytes();
        await _apiService.uploadProfileImage(userId, base64Encode(bytes), token);
        ProfilePhotos.invalidate(userId);
      }

      await _apiService.updateUserProfile(
        userId,
        {
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          if (_emailController.text.trim().isNotEmpty)
            'email': _emailController.text.trim(),
          if (_phoneController.text.trim().isNotEmpty)
            'phoneNumber': _phoneController.text.trim(),
        },
        token,
      );

      await _authService.refreshUserProfile();
      widget.onProfileUpdated?.call();

      if (mounted) {
        AppSnackBar.success(context, 'Profil mis à jour');
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) AppSnackBar.error(context, 'Erreur lors de la mise à jour');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildAvatar(Color iconColor) {
    final placeholder = Container(
      color: context.palette.primaryFill,
      child: Icon(Icons.person, size: 52, color: iconColor),
    );
    final picked = _newProfileImage;
    if (picked != null) {
      return ClipOval(
        child: Image.file(picked, width: 104, height: 104, fit: BoxFit.cover),
      );
    }
    return ProfileAvatar(
      userId: ProfilePhotos.userIdOf(widget.profileData),
      size: 104,
      placeholder: placeholder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final textPrimary = isLight
        ? AppColors.lightTextPrimary
        : AppColors.darkTextPrimary;
    final textSecondary = isLight
        ? AppColors.lightTextSecondary
        : AppColors.darkTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : Text(
                    'Sauvegarder',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).padding.bottom + 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      _buildAvatar(textPrimary),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 14,
                            color: isLight
                                ? AppColors.lightTextPrimary
                                : AppColors.darkBackground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Appuyer pour changer la photo',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Informations personnelles',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ModernTextField(
                      controller: _firstNameController,
                      label: 'Prénom',
                      prefixIcon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ModernTextField(
                      controller: _lastNameController,
                      label: 'Nom',
                      prefixIcon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ModernTextField(
                controller: _emailController,
                label: 'Email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              ModernTextField(
                controller: _phoneController,
                label: 'Téléphone',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
