import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/theme.dart';
import 'gym_rules_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService.fromEnv();
  late final AuthService _authService;
  
  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _waistController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _goalTitleController = TextEditingController();
  final TextEditingController _goalDescriptionController = TextEditingController();
  
  // State
  File? _profileImage;
  String _profession = 'Actif';
  String _fitnessLevel = 'debutant';
  bool _isLoading = false;
  Set<int> _preferredTrainingDays = {}; // 0=Dimanche, 1=Lundi, ..., 6=Samedi
  bool _workoutNotificationsEnabled = true;
  
  // Constants
  final List<String> _professionOptions = ['Actif', 'Etudiant'];
  final Map<String, String> _fitnessLevels = {
    'debutant': 'Débutant',
    'intermediaire': 'Intermédiaire',
    'avance': 'Avancé',
    'expert': 'Expert',
    'athletique': 'Athlétique',
  };
  
  final List<String> _daysOfWeek = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  @override
  void initState() {
    super.initState();
    _authService = AuthService(_apiService);
    _clearOldDataAndInitialize();
  }
  
  Future<void> _clearOldDataAndInitialize() async {
    // Clear old onboarding data to force fresh load from profile
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('onboarding_data');
      await prefs.remove('onboarding_profile_image');
      debugPrint('🗑️ ONBOARDING: Old onboarding data cleared');
      
      // Also refresh the user profile cache to get latest data
      debugPrint('🔄 ONBOARDING: Refreshing user profile cache...');
      await _authService.refreshUserProfile();
      debugPrint('✅ ONBOARDING: User profile cache refreshed');
    } catch (e) {
      debugPrint('⚠️ ONBOARDING: Error clearing old data: $e');
    }
    await _initializeData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
    _weightController.dispose();
    _waistController.dispose();
    _heightController.dispose();
    _goalTitleController.dispose();
    _goalDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      debugPrint('🔍 ONBOARDING: Initializing data...');
      
      // Always load profile data first
      final profileData = await _authService.getCachedUserProfile();
      debugPrint('👤 ONBOARDING: Profile data loaded');
      
      // Then try to load saved onboarding data
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('onboarding_data');
      final imagePath = prefs.getString('onboarding_profile_image');
      
      debugPrint('🔍 ONBOARDING: savedData = ${savedData != null ? "EXISTS" : "NULL"}');
      
      if (savedData != null) {
        final data = jsonDecode(savedData) as Map<String, dynamic>;
        debugPrint('📦 ONBOARDING: Saved data: $data');
        
        setState(() {
          // Load saved data
          _firstNameController.text = data['firstName'] ?? '';
          _lastNameController.text = data['lastName'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _birthDateController.text = data['birthDate'] ?? '';
          _addressController.text = data['address'] ?? '';
          _profession = data['profession'] ?? 'Actif';
          _fitnessLevel = data['fitnessLevel'] ?? 'debutant';
          _weightController.text = data['weight'] ?? '';
          _waistController.text = data['waist'] ?? '';
          _heightController.text = data['height'] ?? '';
          _goalTitleController.text = data['goalTitle'] ?? '';
          _goalDescriptionController.text = data['goalDescription'] ?? '';
          _preferredTrainingDays = (data['preferredTrainingDays'] as List<dynamic>?)?.map((e) => e as int).toSet() ?? {};
          _workoutNotificationsEnabled = data['workoutNotificationsEnabled'] ?? true;
          
          // If profile data exists, fill in missing fields
          if (profileData != null) {
            debugPrint('🔍 ONBOARDING: Checking profile data...');
            debugPrint('🔍 ONBOARDING: phoneNumber in profile = ${profileData['phoneNumber']}');
            debugPrint('🔍 ONBOARDING: Current phone value = "${_phoneController.text}"');
            
            // Always use profile data for firstName, lastName, email, and phone if they're empty or whitespace
            if (_firstNameController.text.trim().isEmpty && profileData['firstName'] != null) {
              _firstNameController.text = profileData['firstName'];
              debugPrint('✅ ONBOARDING: First name filled from profile: ${profileData['firstName']}');
            }
            if (_lastNameController.text.trim().isEmpty && profileData['lastName'] != null) {
              _lastNameController.text = profileData['lastName'];
              debugPrint('✅ ONBOARDING: Last name filled from profile: ${profileData['lastName']}');
            }
            if (_phoneController.text.trim().isEmpty && profileData['phoneNumber'] != null) {
              _phoneController.text = profileData['phoneNumber'];
              debugPrint('✅ ONBOARDING: Phone filled from profile: ${profileData['phoneNumber']}');
            } else {
              debugPrint('⚠️ ONBOARDING: Phone NOT filled - text="${_phoneController.text}", trim().isEmpty=${_phoneController.text.trim().isEmpty}, phoneNumber=${profileData['phoneNumber']}');
            }
            if (_emailController.text.trim().isEmpty) {
              if (profileData['email'] != null) {
                _emailController.text = profileData['email'];
                debugPrint('✅ ONBOARDING: Email filled from profile: ${profileData['email']}');
              } else {
                final memberData = profileData['member'];
                if (memberData != null && memberData['email'] != null) {
                  _emailController.text = memberData['email'];
                  debugPrint('✅ ONBOARDING: Email filled from member: ${memberData['email']}');
                }
              }
            }
            
            // Load birthDate from member data if empty
            if (_birthDateController.text.trim().isEmpty) {
              final memberData = profileData['member'];
              if (memberData != null && memberData['birthDate'] != null) {
                try {
                  final birthDate = DateTime.parse(memberData['birthDate']);
                  _birthDateController.text = _formatDateFrench(birthDate);
                  debugPrint('✅ ONBOARDING: Birth date filled from member: ${_birthDateController.text}');
                } catch (e) {
                  debugPrint('⚠️ ONBOARDING: Error parsing birth date: $e');
                }
              }
            }
            
            // Load profile image from base64 if not already loaded
            if (_profileImage == null && profileData['profileImage'] != null) {
              try {
                final base64String = profileData['profileImage'] as String;
                final cleanBase64 = base64String.replaceFirst(RegExp(r'data:image/[^;]+;base64,'), '');
                final bytes = base64Decode(cleanBase64);
                
                final tempDir = Directory.systemTemp;
                final tempFile = File('${tempDir.path}/profile_temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
                tempFile.writeAsBytesSync(bytes);
                
                _profileImage = tempFile;
                debugPrint('✅ ONBOARDING: Profile image loaded from base64 (saved data path)');
              } catch (e) {
                debugPrint('⚠️ ONBOARDING: Error loading profile image from base64: $e');
              }
            }
          } else {
            debugPrint('❌ ONBOARDING: Profile data is NULL when trying to fill missing fields!');
          }
          
          // Load saved profile image from local path if exists
          if (_profileImage == null && imagePath != null) {
            final imageFile = File(imagePath);
            if (imageFile.existsSync()) {
              _profileImage = imageFile;
              debugPrint('✅ ONBOARDING: Profile image loaded from local path');
            }
          }
        });
      } else {
        // No saved data, prefill from user profile
        debugPrint('👤 ONBOARDING: No saved data, prefilling from profile');
        
        if (profileData != null) {
          debugPrint('👤 ONBOARDING: Profile data details:');
          debugPrint('   - firstName: ${profileData['firstName']}');
          debugPrint('   - lastName: ${profileData['lastName']}');
          debugPrint('   - phoneNumber: ${profileData['phoneNumber']}');
          debugPrint('   - email: ${profileData['email']}');
          debugPrint('   - profileImage: ${profileData['profileImage'] != null ? "EXISTS (base64)" : "NULL"}');
          
          setState(() {
            if (profileData['firstName'] != null) {
              _firstNameController.text = profileData['firstName'];
              debugPrint('✅ ONBOARDING: First name set to: ${profileData['firstName']}');
            }
            if (profileData['lastName'] != null) {
              _lastNameController.text = profileData['lastName'];
              debugPrint('✅ ONBOARDING: Last name set to: ${profileData['lastName']}');
            }
            if (profileData['phoneNumber'] != null) {
              _phoneController.text = profileData['phoneNumber'];
              debugPrint('✅ ONBOARDING: Phone set to: ${profileData['phoneNumber']}');
            } else {
              debugPrint('❌ ONBOARDING: phoneNumber is NULL in profile!');
            }
            if (profileData['email'] != null) {
              _emailController.text = profileData['email'];
              debugPrint('✅ ONBOARDING: Email set to: ${profileData['email']}');
            } else {
              final memberData = profileData['member'];
              if (memberData != null && memberData['email'] != null) {
                _emailController.text = memberData['email'];
                debugPrint('✅ ONBOARDING: Email set from member: ${memberData['email']}');
              }
            }
            
            // Load birthDate from member data
            final memberData = profileData['member'];
            if (memberData != null && memberData['birthDate'] != null) {
              try {
                final birthDate = DateTime.parse(memberData['birthDate']);
                _birthDateController.text = _formatDateFrench(birthDate);
                debugPrint('✅ ONBOARDING: Birth date set to: ${_birthDateController.text}');
              } catch (e) {
                debugPrint('⚠️ ONBOARDING: Error parsing birth date: $e');
              }
            }
            
            // Load profile image from base64 if available
            if (profileData['profileImage'] != null) {
              try {
                final base64String = profileData['profileImage'] as String;
                // Remove data:image/jpeg;base64, prefix if present
                final cleanBase64 = base64String.replaceFirst(RegExp(r'data:image/[^;]+;base64,'), '');
                final bytes = base64Decode(cleanBase64);
                
                // Save to temp file
                final tempDir = Directory.systemTemp;
                final tempFile = File('${tempDir.path}/profile_temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
                tempFile.writeAsBytesSync(bytes);
                
                _profileImage = tempFile;
                debugPrint('✅ ONBOARDING: Profile image loaded from base64');
              } catch (e) {
                debugPrint('⚠️ ONBOARDING: Error loading profile image: $e');
              }
            }
          });
        } else {
          debugPrint('❌ ONBOARDING: Profile data is NULL!');
        }
      }
      
      debugPrint('✅ ONBOARDING: Initialization complete');
    } catch (e) {
      debugPrint('❌ ONBOARDING ERROR: $e');
      debugPrint('❌ ONBOARDING STACK: ${StackTrace.current}');
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'birthDate': _birthDateController.text,
        'address': _addressController.text,
        'profession': _profession,
        'fitnessLevel': _fitnessLevel,
        'weight': _weightController.text,
        'waist': _waistController.text,
        'height': _heightController.text,
        'goalTitle': _goalTitleController.text,
        'goalDescription': _goalDescriptionController.text,
        'preferredTrainingDays': _preferredTrainingDays.toList(),
        'workoutNotificationsEnabled': _workoutNotificationsEnabled,
      };
      await prefs.setString('onboarding_data', jsonEncode(data));
      debugPrint('💾 ONBOARDING: Data saved: phone=${data['phone']}, email=${data['email']}');
    } catch (e) {
      debugPrint('❌ ONBOARDING SAVE ERROR: $e');
    }
  }

  String _formatDateFrench(DateTime date) {
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _selectDate() async {
    // Parse date from French format "21 novembre 2025" if available
    DateTime? initialDate;
    if (_birthDateController.text.isNotEmpty) {
      final months = [
        'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
        'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
      ];
      
      try {
        final parts = _birthDateController.text.split(' ');
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]);
          final monthIndex = months.indexOf(parts[1].toLowerCase());
          final year = int.tryParse(parts[2]);
          
          if (day != null && monthIndex != -1 && year != null) {
            initialDate = DateTime(year, monthIndex + 1, day);
          }
        }
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
    }
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              surface: Theme.of(context).cardTheme.color!,
              onSurface: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        // Format date in French: "21 novembre 2025"
        _birthDateController.text = _formatDateFrench(picked);
      });
      _saveData();
    }
  }

  Future<void> _takePicture() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la capture: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _submitOnboarding() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez prendre une photo de profil'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Save data locally
      await _saveData();
      
      // Also save the profile image path separately
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('onboarding_profile_image', _profileImage!.path);

      if (!mounted) return;
      
      // Navigate to gym rules screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const GymRulesScreen(),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Données validées! Veuillez accepter le règlement'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildGoalChip(BuildContext context, String label, String description) {
    return InkWell(
      onTap: () {
        setState(() {
          // Écrase toujours le contenu existant
          _goalTitleController.text = label;
          _goalDescriptionController.text = description;
        });
        _saveData();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          // Save data before leaving
          await _saveData();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Bienvenue! Configurez votre profil',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
          ),
          automaticallyImplyLeading: false,
        ),
        body: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo section
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _takePicture,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _profileImage == null
                                    ? AppColors.primary.withValues(alpha: 0.2)
                                    : null,
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 3,
                                ),
                                image: _profileImage != null
                                    ? DecorationImage(
                                        image: FileImage(_profileImage!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _profileImage == null
                                  ? const Icon(
                                      Icons.camera_alt,
                                      size: 40,
                                      color: AppColors.primary,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _takePicture,
                            icon: const Icon(
                              Icons.camera_alt,
                              color: AppColors.primary,
                            ),
                            label: Text(
                              _profileImage == null
                                  ? 'Prendre une photo'
                                  : 'Changer la photo',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Personal Information Section
                    Text(
                      'Informations Personnelles',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // First Name
                    TextFormField(
                      controller: _firstNameController,
                      style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                      decoration: InputDecoration(
                        labelText: 'Prénom *',
                        labelStyle: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                        prefixIcon: const Icon(Icons.person, color: AppColors.primary),
                        filled: true,
                        fillColor: Theme.of(context).cardTheme.color,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le prénom est requis';
                        }
                        return null;
                      },
                      onChanged: (_) => _saveData(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Last Name
                    TextFormField(
                      controller: _lastNameController,
                      style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                      decoration: InputDecoration(
                        labelText: 'Nom *',
                        labelStyle: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                        prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                        filled: true,
                        fillColor: Theme.of(context).cardTheme.color,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le nom est requis';
                        }
                        return null;
                      },
                      onChanged: (_) => _saveData(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Email (optional)
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                      decoration: InputDecoration(
                        labelText: 'Email (facultatif)',
                        labelStyle: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                        prefixIcon: const Icon(Icons.email, color: AppColors.primary),
                        filled: true,
                        fillColor: Theme.of(context).cardTheme.color,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        // Email is optional, but if provided, should be valid
                        if (value != null && value.trim().isNotEmpty) {
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                            return 'Veuillez entrer un email valide';
                          }
                        }
                        return null;
                      },
                      onChanged: (_) => _saveData(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone Number
                    TextFormField(
                      controller: _phoneController,
                      style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Numéro de téléphone *',
                        labelStyle: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                        prefixIcon: const Icon(Icons.phone, color: AppColors.primary),
                        filled: true,
                        fillColor: Theme.of(context).cardTheme.color,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le numéro de téléphone est requis';
                        }
                        // Basic phone validation (allow + and digits)
                        if (!RegExp(r'^\+?[0-9\s\-\(\)]+$').hasMatch(value.trim())) {
                          return 'Veuillez entrer un numéro valide';
                        }
                        return null;
                      },
                      onChanged: (_) => _saveData(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Birth Date
                    TextFormField(
                      controller: _birthDateController,
                      readOnly: true,
                      onTap: _selectDate,
                      style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                      decoration: InputDecoration(
                        labelText: 'Date de naissance *',
                        labelStyle: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                        prefixIcon: const Icon(Icons.cake, color: AppColors.primary),
                        suffixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
                        filled: true,
                        fillColor: Theme.of(context).cardTheme.color,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La date de naissance est requise';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Address (optional)
                    TextFormField(
                      controller: _addressController,
                      style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                      decoration: InputDecoration(
                        labelText: 'Adresse (facultatif)',
                        labelStyle: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                        prefixIcon: const Icon(Icons.location_on, color: AppColors.primary),
                        filled: true,
                        fillColor: Theme.of(context).cardTheme.color,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (_) => _saveData(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Profession (Radio buttons)
                    Text(
                      'Activité *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: RadioGroup<String>(
                        groupValue: _profession,
                        onChanged: (value) {
                          setState(() {
                            _profession = value!;
                          });
                          _saveData();
                        },
                        child: Column(
                          children: _professionOptions.map((option) {
                            return RadioListTile<String>(
                              title: Text(
                                option,
                                style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                              ),
                              value: option,
                              fillColor: WidgetStateProperty.all(AppColors.primary),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Measurements Section (Compact)
                    Text(
                      'Mes mensurations',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                            decoration: InputDecoration(
                              labelText: 'Poids (kg)',
                              labelStyle: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                              prefixIcon: const Icon(Icons.monitor_weight, color: AppColors.primary, size: 20),
                              filled: true,
                              fillColor: Theme.of(context).cardTheme.color,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            ),
                            onChanged: (_) => _saveData(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _waistController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                            decoration: InputDecoration(
                              labelText: 'Tour taille (cm)',
                              labelStyle: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                              prefixIcon: const Icon(Icons.straighten, color: AppColors.primary, size: 20),
                              filled: true,
                              fillColor: Theme.of(context).cardTheme.color,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            ),
                            onChanged: (_) => _saveData(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                            decoration: InputDecoration(
                              labelText: 'Taille (cm)',
                              labelStyle: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                              prefixIcon: const Icon(Icons.height, color: AppColors.primary, size: 20),
                              filled: true,
                              fillColor: Theme.of(context).cardTheme.color,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            ),
                            onChanged: (_) => _saveData(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Goals Section - Modern & Intuitive
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.emoji_events,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mes objectifs',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Définissez vos objectifs fitness personnels',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Quick suggestions
                          Text(
                            '💡 Suggestions populaires',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildGoalChip(context, '🎯 Perdre du poids', 'Perdre du poids et me sentir mieux'),
                              _buildGoalChip(context, '💪 Gagner en muscle', 'Développer ma masse musculaire'),
                              _buildGoalChip(context, '🏃 Améliorer endurance', 'Augmenter mon endurance cardio'),
                              _buildGoalChip(context, '🧘 Être plus flexible', 'Améliorer ma souplesse et mobilité'),
                              _buildGoalChip(context, '⚡ Plus d\'énergie', 'Avoir plus d\'énergie au quotidien'),
                              _buildGoalChip(context, '🏆 Me challenger', 'Repousser mes limites'),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Goal Title
                          TextFormField(
                            controller: _goalTitleController,
                            style: TextStyle(
                              color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Titre de mon objectif',
                              hintText: 'Ex: Perdre 10kg en 3 mois',
                              labelStyle: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                              hintStyle: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.5)),
                              prefixIcon: const Icon(Icons.flag, color: AppColors.primary),
                              filled: true,
                              fillColor: Theme.of(context).cardTheme.color,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (_) => _saveData(),
                          ),
                          const SizedBox(height: 16),
                          
                          // Goal Description
                          TextFormField(
                            controller: _goalDescriptionController,
                            maxLines: 4,
                            style: TextStyle(
                              color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Décrivez votre objectif',
                              hintText: 'Pourquoi est-ce important pour vous ?\nComment voulez-vous y arriver ?\nQu\'est-ce qui vous motive ?',
                              labelStyle: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                              hintStyle: TextStyle(
                                color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.5),
                                fontSize: 13,
                              ),
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(bottom: 60),
                                child: Icon(Icons.edit_note, color: AppColors.primary),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).cardTheme.color,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (_) => _saveData(),
                          ),
                          const SizedBox(height: 12),
                          
                          // Motivational message
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: AppColors.success,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Des objectifs clairs vous aideront à rester motivé et suivre vos progrès !',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Fitness Level
                    DropdownButtonFormField<String>(
                      initialValue: _fitnessLevel,
                      dropdownColor: Theme.of(context).cardTheme.color,
                      style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                      decoration: InputDecoration(
                        labelText: 'Niveau sportif *',
                        labelStyle: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                        prefixIcon: const Icon(Icons.fitness_center, color: AppColors.primary),
                        filled: true,
                        fillColor: Theme.of(context).cardTheme.color,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _fitnessLevels.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _fitnessLevel = value!;
                        });
                        _saveData();
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Preferred Training Days Section
                    Text(
                      'Jours préférés d\'entraînement',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sélectionnez les jours où vous préférez vous entraîner',
                      style: TextStyle(
                        fontSize: 14,
                        color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(7, (index) {
                        final dayIndex = (index + 1) % 7; // Convertir: Lundi=1, ..., Dimanche=0
                        final isSelected = _preferredTrainingDays.contains(dayIndex);
                        
                        return FilterChip(
                          label: Text(_daysOfWeek[index]),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _preferredTrainingDays.add(dayIndex);
                              } else {
                                _preferredTrainingDays.remove(dayIndex);
                              }
                            });
                            _saveData();
                          },
                          backgroundColor: Theme.of(context).cardTheme.color,
                          selectedColor: AppColors.primary.withValues(alpha: 0.3),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primary : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : Theme.of(context).dividerColor,
                            width: 1,
                          ),
                        );
                      }),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Workout Notifications Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.notifications_active,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notifications d\'entraînement',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Recevez des rappels pour vos séances',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _workoutNotificationsEnabled,
                            onChanged: (value) {
                              setState(() {
                                _workoutNotificationsEnabled = value;
                              });
                              _saveData();
                            },
                            activeTrackColor: AppColors.primary,
                            inactiveThumbColor: Theme.of(context).brightness == Brightness.dark ? (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary).withValues(alpha: 0.5) : Colors.grey,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitOnboarding,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Theme.of(context).brightness == Brightness.dark ? (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary) : AppColors.primaryDark,
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                                'Suivant',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}









