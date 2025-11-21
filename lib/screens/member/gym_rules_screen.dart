import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/theme.dart';
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

      // Update cgAccepted to true
      final response = await _apiService.updateMemberProfile(
        userId,
        {'cgAccepted': true},
        token,
      );

      if (response == null || response['error'] != null) {
        throw Exception(response?['error'] ?? 'Erreur lors de l\'acceptation');
      }

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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).cardTheme.color!,
            ],
          ),
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
                          child: const Icon(
                            Icons.gavel,
                            color: AppColors.primary,
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
                            color: AppColors.primary,
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
                            ? AppColors.primary 
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
                              activeColor: AppColors.primary,
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
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle, size: 24),
                                  const SizedBox(width: 12),
                                  const Text(
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
                  color: AppColors.primary,
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
          }).toList(),
        ],
      ),
    );
  }
}
