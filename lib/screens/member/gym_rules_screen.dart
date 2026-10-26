import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/theme.dart';
import '../../widgets/common/profile_avatar.dart';
import 'member_home_screen.dart';

class GymRulesScreen extends StatefulWidget {
  const GymRulesScreen({super.key});

  @override
  State<GymRulesScreen> createState() => _GymRulesScreenState();
}

class _GymRulesScreenState extends State<GymRulesScreen> {
  final ApiService _apiService = ApiService.fromEnv();
  late final AuthService _authService;
  bool _isAccepted = false;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _authService = AuthService(_apiService);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String? _convertFrenchDateToISO(String? frenchDate) {
    if (frenchDate == null || frenchDate.isEmpty) return null;
    
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
          final date = DateTime(year, monthIndex + 1, day);
          return date.toIso8601String().split('T')[0]; // Format: yyyy-MM-dd
        }
      }
    } catch (e) {
      debugPrint('Error converting date: $e');
    }
    
    return frenchDate; // Return as-is if conversion fails
  }

  static const _measurementDoneKey = 'onboarding_measurement_done';
  static const _goalDoneKey = 'onboarding_goal_done';

  void _throwIfError(Map<String, dynamic>? result, String fallback) {
    if (result == null || result['error'] != null) {
      throw Exception(result?['error'] ?? fallback);
    }
  }

  Future<void> _acceptRules() async {
    if (!_isAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez accepter le règlement pour continuer'),
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

      // Load saved onboarding data
      final prefs = await SharedPreferences.getInstance();
      final savedDataJson = prefs.getString('onboarding_data');
      final imagePath = prefs.getString('onboarding_profile_image');
      
      if (savedDataJson == null || imagePath == null) {
        throw Exception('Données d\'onboarding manquantes');
      }

      final savedData = jsonDecode(savedDataJson) as Map<String, dynamic>;
      final imageFile = File(imagePath);
      
      if (!await imageFile.exists()) {
        throw Exception('Photo de profil manquante');
      }

      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      String? text(String key) {
        final v = (savedData[key] as String?)?.trim();
        return v == null || v.isEmpty ? null : v;
      }

      // « 72,5 » comme « 72.5 » ; une saisie illisible n'est pas envoyée.
      double? number(String key) =>
          double.tryParse(text(key)?.replaceAll(',', '.') ?? '');

      // Tout le formulaire est enregistré. L'onboarding n'est clôturé qu'à
      // la fin (étape 5) : si une étape échoue, le membre peut réessayer,
      // et les étapes de création déjà faites ne sont pas rejouées.

      // 1. Identité, contact et adresse sur le User (PUT /users/:id) : la
      //    route /members/:id/profile les ignore.
      await _apiService.updateUserProfile(userId, {
        'firstName': ?text('firstName'),
        'lastName': ?text('lastName'),
        'phoneNumber': ?text('phone'),
        'email': ?text('email'),
        'address': ?text('address'),
      }, token);

      // 2. Profil membre : naissance, profession, niveau, taille, photo,
      //    préférences d'entraînement.
      final profileResponse = await _apiService.updateMemberProfile(userId, {
        'birthDate': _convertFrenchDateToISO(savedData['birthDate']),
        'profession': savedData['profession'],
        'fitnessLevel': savedData['fitnessLevel'],
        'height': ?number('height'),
        'profileImage': 'data:image/jpeg;base64,$base64Image',
        'preferredTrainingDays': savedData['preferredTrainingDays'],
        'workoutNotificationsEnabled': savedData['workoutNotificationsEnabled'],
      }, token);
      _throwIfError(profileResponse, 'Erreur lors de la mise à jour du profil');

      final weight = number('weight');
      final waist = number('waist');

      // 3. Mesure initiale (poids, tour de taille)
      if ((weight != null || waist != null) &&
          !(prefs.getBool(_measurementDoneKey) ?? false)) {
        final measurement = await _apiService.createMemberMeasurement(userId, {
          'weight': ?weight,
          'waist': ?waist,
        }, token);
        _throwIfError(measurement, 'Erreur lors de l\'enregistrement des mesures');
        await prefs.setBool(_measurementDoneKey, true);
      }

      // 4. Objectif initial
      final goalTitle = text('goalTitle');
      if (goalTitle != null && !(prefs.getBool(_goalDoneKey) ?? false)) {
        final goal = await _apiService.createMemberGoal(userId, {
          'title': goalTitle,
          'description': text('goalDescription') ?? '',
          'startWeight': ?weight,
          'startWaist': ?waist,
        }, token);
        _throwIfError(goal, 'Erreur lors de l\'enregistrement de l\'objectif');
        await prefs.setBool(_goalDoneKey, true);
      }

      // 5. Règlement accepté, onboarding terminé
      final done = await _apiService.updateMemberProfile(userId, {
        'onboarding': false,
        'cgAccepted': true,
      }, token);
      _throwIfError(done, 'Erreur lors de la validation du règlement');
      await prefs.remove(_measurementDoneKey);
      await prefs.remove(_goalDoneKey);

      // Le profil affiché ensuite doit refléter ce qui vient d'être saisi.
      ProfilePhotos.invalidate(userId);
      await _authService.refreshUserProfile();

      // 4. Clear saved onboarding data
      await prefs.remove('onboarding_data');
      await prefs.remove('onboarding_profile_image');
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
          content: Text('Bienvenue! Profitez de votre salle de sport 💪'),
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.gavel,
                            color: context.palette.primary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Règlement Intérieur',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'النظام الداخلي',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Club name
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'فريق الأستاذ',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Team Oustad',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary).withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Arabic rules
                    _buildLanguageSection(
                      title: 'النظام الداخلي',
                      language: 'ar',
                      rules: [
                        'أداء الواجب الشهري في وقته',
                        'احترام 4 حصص أسبوعياً',
                        'احترام أوقات العمل',
                        'وجوب إحضار حذاء إضافي خاص بالقاعة الرياضية',
                        'نظافة اللباس الرياضي واجب جماعي',
                        'ممنوع إدخال المأكولات و المشروبات',
                        'ممنوع التلفظ بالكلام الفاحش أو المسيء',
                        'المرجو التوجه إلى المسؤول في حالة الخلاف أو الشكوى',
                        'استعمال الآلات و الأوزان بصفة صحيحة',
                        'استعمال الآلات و الأوزان بصفة جماعية',
                        'إرجاع الأوزان إلى أماكنها بعد الانتهاء من استعمالها',
                        'رمي الأوزان في الأماكن المخصصة لها ممنوع',
                        'الدوش في حدود 5 دقائق',
                        'اتباع إرشادات المدرب داخل القاعة',
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(
                            Icons.fitness_center,
                            color: context.palette.primary,
                            size: 24,
                          ),
                        ),
                        Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // French rules
                    _buildLanguageSection(
                      title: 'Règlement Intérieur',
                      language: 'fr',
                      rules: [
                        'Payer la cotisation mensuelle à temps',
                        'Respecter 4 séances par semaine',
                        'Respecter les horaires d\'ouverture',
                        'Obligation d\'apporter des chaussures de sport réservées à la salle',
                        'La propreté de la tenue de sport est un devoir collectif',
                        'Il est interdit d\'introduire de la nourriture et des boissons',
                        'Il est interdit de proférer des paroles grossières ou injurieuses',
                        'Veuillez vous adresser au responsable en cas de conflit ou de réclamation',
                        'Utiliser les machines et les poids de manière correcte',
                        'Utiliser les machines et les poids de façon collective',
                        'Remettre les poids à leur place après utilisation',
                        'Il est interdit de jeter les poids',
                        'La douche est limitée à 5 minutes',
                        'Suivre les consignes de l\'entraîneur à l\'intérieur de la salle',
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Acceptance checkbox
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isAccepted 
                            ? context.palette.primary 
                            : Theme.of(context).dividerColor,
                          width: 2,
                        ),
                        boxShadow: _isAccepted
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Transform.scale(
                            scale: 1.3,
                            child: Checkbox(
                              value: _isAccepted,
                              onChanged: (value) {
                                setState(() {
                                  _isAccepted = value ?? false;
                                });
                              },
                              activeColor: context.palette.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'J\'accepte le règlement intérieur',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'أوافق على النظام الداخلي',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Accept button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _acceptRules,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isAccepted ? AppColors.primary : Colors.grey,
                          foregroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: _isAccepted ? 4 : 0,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    'Commencer',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSection({
    required String title,
    required String language,
    required List<String> rules,
  }) {
    final isArabic = language == 'ar';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isArabic) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '🇫🇷',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.palette.primary,
                ),
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              ),
              if (isArabic) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '🇲🇦',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          ...rules.asMap().entries.map((entry) {
            final index = entry.key;
            final rule = entry.value;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.8),
                          AppColors.primary.withValues(alpha: 0.4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rule,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
