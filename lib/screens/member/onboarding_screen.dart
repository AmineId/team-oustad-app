import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/theme.dart';
import '../member/member_home_screen.dart';

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
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _waistController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  
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
    _loadSavedData();
    _prefillUserName();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
    _weightController.dispose();
    _waistController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _prefillUserName() async {
    try {
      final profileData = await _authService.getCachedUserProfile();
      if (profileData != null && profileData['fullName'] != null) {
        setState(() {
          _fullNameController.text = profileData['fullName'];
        });
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Error prefilling name: $e');
    }
  }

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('onboarding_data');
      if (savedData != null) {
        final data = jsonDecode(savedData) as Map<String, dynamic>;
        setState(() {
          _fullNameController.text = data['fullName'] ?? '';
          _birthDateController.text = data['birthDate'] ?? '';
          _addressController.text = data['address'] ?? '';
          _profession = data['profession'] ?? 'Actif';
          _fitnessLevel = data['fitnessLevel'] ?? 'debutant';
          _weightController.text = data['weight'] ?? '';
          _waistController.text = data['waist'] ?? '';
          _heightController.text = data['height'] ?? '';
          _preferredTrainingDays = (data['preferredTrainingDays'] as List<dynamic>?)?.map((e) => e as int).toSet() ?? {};
          _workoutNotificationsEnabled = data['workoutNotificationsEnabled'] ?? true;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Error loading saved data: $e');
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'fullName': _fullNameController.text,
        'birthDate': _birthDateController.text,
        'address': _addressController.text,
        'profession': _profession,
        'fitnessLevel': _fitnessLevel,
        'weight': _weightController.text,
        'waist': _waistController.text,
        'height': _heightController.text,
        'preferredTrainingDays': _preferredTrainingDays.toList(),
        'workoutNotificationsEnabled': _workoutNotificationsEnabled,
      };
      await prefs.setString('onboarding_data', jsonEncode(data));
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Error saving data: $e');
    }
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
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.darkCard,
              onSurface: Colors.white,
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
      final token = await _authService.loadToken();
      final profileData = await _authService.getCachedUserProfile();
      
      if (token == null || profileData == null) {
        throw Exception('Session expirée');
      }

      final userId = profileData['id'] as int;

      // 1. Update member profile with photo and mark first login as completed
      final imageBytes = await _profileImage!.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      
      final profileUpdateData = {
        'birthDate': _birthDateController.text,
        'phone': profileData['phone'] ?? '',
        'profession': _profession,
        'fitnessLevel': _fitnessLevel,
        'profileImage': 'data:image/jpeg;base64,$base64Image',
        'onboarding': false, // Mark onboarding as completed (false = done)
        'preferredTrainingDays': _preferredTrainingDays.toList(),
        'workoutNotificationsEnabled': _workoutNotificationsEnabled,
      };

      final profileResponse = await _apiService.updateMemberProfile(
        userId,
        profileUpdateData,
        token,
      );

      if (profileResponse == null || profileResponse['error'] != null) {
        throw Exception(profileResponse?['error'] ?? 'Erreur lors de la mise à jour du profil');
      }

      // 2. Create initial measurement
      if (_weightController.text.isNotEmpty || 
          _waistController.text.isNotEmpty || 
          _heightController.text.isNotEmpty) {
        final measurementData = <String, dynamic>{};
        
        if (_weightController.text.isNotEmpty) {
          measurementData['weight'] = double.parse(_weightController.text);
        }
        if (_waistController.text.isNotEmpty) {
          measurementData['waist'] = double.parse(_waistController.text);
        }
        if (_heightController.text.isNotEmpty) {
          measurementData['height'] = double.parse(_heightController.text);
        }

        if (measurementData.isNotEmpty) {
          await _apiService.createMemberMeasurement(
            userId,
            measurementData,
            token,
          );
        }
      }

      // 3. Create initial goal if objectives are filled
      if (_weightController.text.isNotEmpty && _waistController.text.isNotEmpty) {
        final goalData = {
          'title': 'Mon premier objectif',
          'description': 'Suivi de mes mensurations et progression',
          'startWeight': double.parse(_weightController.text),
          'startWaist': double.parse(_waistController.text),
        };

        await _apiService.createMemberGoal(
          userId,
          goalData,
          token,
        );
      }

      // 4. Clear saved data and navigate to home
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('onboarding_data');
      
      // Mark onboarding as completed
      await prefs.setBool('onboarding_completed', true);

      if (!mounted) return;
      
      // Navigate to member home screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MemberHomeScreen(),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil créé avec succès!'),
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
          title: const Text(
            'Bienvenue! Configurez votre profil',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          automaticallyImplyLeading: false,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.darkBackground,
                AppColors.darkSurface,
              ],
            ),
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
                    const Text(
                      'Informations Personnelles',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Full Name
                    TextFormField(
                      controller: _fullNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Nom et Prénom *',
                        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        prefixIcon: const Icon(Icons.person, color: AppColors.primary),
                        filled: true,
                        fillColor: AppColors.darkCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le nom est requis';
                        }
                        if (value.trim().split(' ').length < 2) {
                          return 'Veuillez entrer le nom et prénom complets';
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
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Date de naissance *',
                        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        prefixIcon: const Icon(Icons.cake, color: AppColors.primary),
                        suffixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
                        filled: true,
                        fillColor: AppColors.darkCard,
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
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Adresse (facultatif)',
                        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        prefixIcon: const Icon(Icons.location_on, color: AppColors.primary),
                        filled: true,
                        fillColor: AppColors.darkCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (_) => _saveData(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Profession (Radio buttons)
                    const Text(
                      'Activité *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: _professionOptions.map((option) {
                          return RadioListTile<String>(
                            title: Text(
                              option,
                              style: const TextStyle(color: Colors.white),
                            ),
                            value: option,
                            groupValue: _profession,
                            fillColor: WidgetStateProperty.all(AppColors.primary),
                            onChanged: (value) {
                              setState(() {
                                _profession = value!;
                              });
                              _saveData();
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Objectives Section
                    const Text(
                      'Objectifs',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Weight
                    TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Poids (kg) *',
                        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        prefixIcon: const Icon(Icons.monitor_weight, color: AppColors.primary),
                        filled: true,
                        fillColor: AppColors.darkCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le poids est requis';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Veuillez entrer un nombre valide';
                        }
                        return null;
                      },
                      onChanged: (_) => _saveData(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Waist
                    TextFormField(
                      controller: _waistController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Tour de taille (cm) *',
                        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        prefixIcon: const Icon(Icons.straighten, color: AppColors.primary),
                        filled: true,
                        fillColor: AppColors.darkCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le tour de taille est requis';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Veuillez entrer un nombre valide';
                        }
                        return null;
                      },
                      onChanged: (_) => _saveData(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Height
                    TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Taille (cm) *',
                        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        prefixIcon: const Icon(Icons.height, color: AppColors.primary),
                        filled: true,
                        fillColor: AppColors.darkCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La taille est requise';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Veuillez entrer un nombre valide';
                        }
                        return null;
                      },
                      onChanged: (_) => _saveData(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Fitness Level
                    DropdownButtonFormField<String>(
                      value: _fitnessLevel,
                      dropdownColor: AppColors.darkCard,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Niveau sportif *',
                        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        prefixIcon: const Icon(Icons.fitness_center, color: AppColors.primary),
                        filled: true,
                        fillColor: AppColors.darkCard,
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
                    const Text(
                      'Jours préférés d\'entraînement',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sélectionnez les jours où vous préférez vous entraîner',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.6),
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
                          backgroundColor: AppColors.darkCard,
                          selectedColor: AppColors.primary.withValues(alpha: 0.3),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.7),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.3),
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
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
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
                                const Text(
                                  'Notifications d\'entraînement',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Recevez des rappels pour vos séances',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.6),
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
                            inactiveThumbColor: Colors.white.withValues(alpha: 0.5),
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
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
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



