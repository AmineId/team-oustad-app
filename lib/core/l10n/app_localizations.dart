import 'package:flutter/material.dart';

/// Simple localization delegate for the app
/// This provides translations for French, English, and Arabic
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Translation keys and values
  static final Map<String, Map<String, String>> _localizedValues = {
    'fr': {
      'home': 'Accueil',
      'my_card': 'Ma Carte',
      'my_planning': 'Mon Planning',
      'my_profile': 'Mon Profil',
      'welcome': 'Bienvenue !',
      'language': 'Langue',
      'select_language': 'Sélectionner la langue',
      'french': 'Français',
      'english': 'English',
      'arabic': 'العربية',
      'language_changed': 'Langue changée en',
      'dashboard': 'Tableau de bord',
      'members': 'Membres',
      'active': 'Actifs',
      'today': 'Aujourd\'hui',
      'revenue': 'Revenus',
      'quick_actions': 'Actions rapides',
      'new_member': 'Nouveau membre',
      'record_payment': 'Enregistrer un paiement',
      'scan_card': 'Scanner une carte',
      'search': 'Recherche',
      'search_member_hint': 'Rechercher un membre...',
      'add_new_member_title': 'Ajouter un nouveau membre',
      'full_name': 'Nom complet',
      'email': 'Email',
      'phone': 'Téléphone',
      'save': 'Enregistrer',
      'administrator': 'Administrateur',
      'settings': 'Paramètres',
      'security': 'Sécurité',
      'help': 'Aide',
      'logout': 'Déconnexion',
      'add': 'Ajouter',
      'profile': 'Profil',
      'store': 'Boutique',
      'management': 'Gestion',
      'global_management': 'Gestion Globale',
      'welcome_community': 'Bienvenue dans notre communauté !',
      'welcome_name': 'Bienvenue, {name} !',
      'visit_reception':
          'Rendez-vous à la réception pour activer votre abonnement',
      'my_gym': 'Ma Salle de Sport',
      'my_next_workout': 'Mon Prochain Entraînement',
      'start_fitness_journey': 'Commencez votre parcours fitness',
      'get_subscription':
          'Obtenez un abonnement pour accéder à votre programme personnalisé',
      'get_subscription_button': 'Obtenir un abonnement',
      'updated_data': 'Données mises à jour',
      'subscription_expired': 'Abonnement expiré',
      'subscription_cancelled': 'Abonnement annulé',
      'expires_on': 'Expire le:',
      'my_stats': 'Mes Statistiques',
      'no_workout_planned': 'Aucun entraînement prévu',
      'coach_will_assign': 'Votre coach vous assignera bientôt un programme',
      'session_expired': 'Session expirée, veuillez vous reconnecter',
      'session_expired_short': 'Session expirée',
      'welcome_login': 'Bienvenue\nConnectez-vous',
      'login': 'Connexion',
      'sign_in_biometric': 'Se connecter avec la biométrie',
      'or_use_password': 'ou utilisez votre mot de passe',
      'email_or_phone': 'Email ou Numéro de téléphone',
      'password': 'Mot de passe',
      'forgot_password': 'Mot de passe oublié ?',
      'sign_in': 'Se connecter',
      'first_login': 'Première connexion',
      'checking_connection': 'Vérification de la connexion...',
      'offline_mode': 'Mode hors ligne',
      'db_connection_failed':
          'Connexion à la base de données impossible.\nL\'app fonctionne en mode limité.',
      'invalid_credentials': 'Identifiants incorrects',
      'fill_email_password':
          'Veuillez saisir votre email/téléphone et mot de passe',
      'gym_management': 'Gestion de votre salle de sport',
      'error_occurred': 'Une erreur est survenue',
      'status_unknown': 'Statut inconnu',
      'subscription_active': 'Votre abonnement est actif',
      'your_journey_starts': 'Votre parcours commence ici !',
      'stats_appear_when_training':
          'Vos statistiques apparaîtront ici dès que vous commencerez vos entraînements',
      'visits_this_month': 'Visites ce mois',
      'total_visits': 'Total visites',
      'contact_reception_subscription':
          'Contactez la réception pour choisir votre abonnement',
      'next_workout': 'Prochain entraînement',
      'my_workout': 'Mon Entraînement',
      'view_details': 'Voir les détails',
      'no_exercise_planned': 'Aucun exercice prévu',
      'ask_for_help': 'Demander de l\'aide',
      'ask_help_for_exercise':
          'Voulez-vous demander de l\'aide pour l\'exercice "{exercise}" ?',
      'help_request_sent': '✅ Demande d\'aide envoyée pour {exercise}',
      'choose_subscription': 'Choisir un abonnement',
      'personal_info': 'Informations personnelles',
      'birth_date': 'Date de naissance',
      'fitness_level': 'Niveau sportif',
      'parameters': 'Paramètres',
      'about': 'À propos',
      'help_support': 'Aide & Support',
      'disconnect': 'Se déconnecter',
      'retry': 'Réessayer',
      'my_member_card': 'Ma Carte Membre',
      'scan_at_entrance': 'Scannez ce code à l\'entrée',
      'loading_qr_code': 'Chargement du QR code...',
      'present_this_code': 'Présentez ce code à l\'entrée',
      'no_gym_assigned': 'Aucune salle assignée',
      'my_gym_name': 'Ma Salle',
      'address_unavailable': 'Adresse non disponible',
      'error_loading_gym':
          'Erreur lors du chargement des informations de la salle',
      'error_loading_qr': 'Erreur lors du chargement du QR code',
      'error_loading_subscription':
          'Erreur lors du chargement de l\'abonnement',
      'error_loading_workout': 'Erreur lors du chargement de l\'entraînement',
      'hide_qr_code': 'Masquer le QR Code',
      'whatsapp_scan_qr': 'Scanner QR',
      'whatsapp_phone_number': 'Numéro de téléphone',
      'whatsapp_get_code': 'Obtenir le code',
      'whatsapp_pairing_code': 'Code d\'appairage',
      'whatsapp_phone_helper': 'Format international, ex : 212600123456',
      'whatsapp_enter_phone': 'Entrez votre numéro pour recevoir le code sur WhatsApp',
      'my_plannings': 'Mes Plannings',
      'starting_measurements': 'Mesures de départ',
      'member_since': 'Membre depuis: {date}',
      'edit_profile': 'Modifier le profil',
      'my_subscription': 'Mon Abonnement',
      'my_goals': '🎯 Mes Objectifs',
      'member': 'Membre',
      'show_my_qr_code': 'Afficher mon QR Code',
      'present_qr_to_staff':
          'Présentez votre QR code au personnel\npour enregistrer votre présence',
      'premium_subscription': 'Abonnement Premium',
      'start_date': 'Date de début',
      'expiration_date': 'Date d\'expiration',
      'payment_history': 'Historique des Paiements',
      'no_active_subscription': 'Aucun abonnement actif',
      'subscribe_for_features':
          'Souscrivez à un abonnement pour accéder à toutes les fonctionnalités.',
      'feature_coming_soon': 'Fonctionnalité à venir',
      'profession': 'Profession',
      'not_specified': 'Non renseignée',
      'upcoming': 'Prévu',
      'coach': 'Coach',
      'training_days': '{count} jour{plural} d\'entraînement',
      'from_to_dates': 'Du {start} au {end}',
      'month_january': 'janvier',
      'month_february': 'février',
      'month_march': 'mars',
      'month_april': 'avril',
      'month_may': 'mai',
      'month_june': 'juin',
      'month_july': 'juillet',
      'month_august': 'août',
      'month_september': 'septembre',
      'month_october': 'octobre',
      'month_november': 'novembre',
      'month_december': 'décembre',
      'fitness_beginner': 'Débutant',
      'fitness_intermediate': 'Intermédiaire',
      'fitness_advanced': 'Avancé',
      'fitness_expert': 'Expert',
      'fitness_athletic': 'Athlétique',
      'request_help': 'Demander aide',
      'premium_subscription_type': 'Abonnement Premium',
      'standard_subscription_type': 'Abonnement Standard',
      'cancel': 'Annuler',
      'confirm': 'Confirmer',
      'active_status': 'ACTIF',
      'owner_role': 'Propriétaire',
      'manager_role': 'Manager',
      'coach_role': 'Coach',
      'coach_my_members': 'Mes membres',
      'coach_no_members': 'Aucun membre ne vous est encore affecté.',
    },
    'en': {
      'home': 'Home',
      'my_card': 'My Card',
      'my_planning': 'My Schedule',
      'my_profile': 'My Profile',
      'welcome': 'Welcome!',
      'language': 'Language',
      'select_language': 'Select Language',
      'french': 'Français',
      'english': 'English',
      'arabic': 'العربية',
      'language_changed': 'Language changed to',
      'dashboard': 'Dashboard',
      'members': 'Members',
      'active': 'Active',
      'today': 'Today',
      'revenue': 'Revenue',
      'quick_actions': 'Quick Actions',
      'new_member': 'New Member',
      'record_payment': 'Record Payment',
      'scan_card': 'Scan Card',
      'search': 'Search',
      'search_member_hint': 'Search for a member...',
      'add_new_member_title': 'Add New Member',
      'full_name': 'Full Name',
      'email': 'Email',
      'phone': 'Phone',
      'save': 'Save',
      'administrator': 'Administrator',
      'settings': 'Settings',
      'security': 'Security',
      'help': 'Help',
      'logout': 'Logout',
      'add': 'Add',
      'profile': 'Profile',
      'store': 'Store',
      'management': 'Management',
      'global_management': 'Global Management',
      'welcome_community': 'Welcome to our community!',
      'welcome_name': 'Welcome, {name}!',
      'visit_reception': 'Visit the reception to activate your subscription',
      'my_gym': 'My Gym',
      'my_next_workout': 'My Next Workout',
      'start_fitness_journey': 'Start your fitness journey',
      'get_subscription':
          'Get a subscription to access your personalized program',
      'get_subscription_button': 'Get a subscription',
      'updated_data': 'Updated data',
      'subscription_expired': 'Subscription expired',
      'subscription_cancelled': 'Subscription cancelled',
      'expires_on': 'Expires on:',
      'my_stats': 'My Statistics',
      'no_workout_planned': 'No workout planned',
      'coach_will_assign': 'Your coach will assign you a program soon',
      'session_expired': 'Session expired, please log in again',
      'session_expired_short': 'Session expired',
      'welcome_login': 'Welcome\nSign In',
      'login': 'Login',
      'sign_in_biometric': 'Sign in with biometrics',
      'or_use_password': 'or use your password',
      'email_or_phone': 'Email or Phone Number',
      'password': 'Password',
      'forgot_password': 'Forgot password?',
      'sign_in': 'Sign In',
      'first_login': 'First Login',
      'checking_connection': 'Checking connection...',
      'offline_mode': 'Offline Mode',
      'db_connection_failed':
          'Database connection failed.\nThe app is running in limited mode.',
      'invalid_credentials': 'Invalid credentials',
      'fill_email_password': 'Please enter your email/phone and password',
      'gym_management': 'Manage your gym',
      'error_occurred': 'An error occurred',
      'status_unknown': 'Unknown status',
      'subscription_active': 'Your subscription is active',
      'your_journey_starts': 'Your journey starts here!',
      'stats_appear_when_training':
          'Your statistics will appear here once you start training',
      'visits_this_month': 'Visits this month',
      'total_visits': 'Total visits',
      'contact_reception_subscription':
          'Contact reception to choose your subscription',
      'next_workout': 'Next workout',
      'my_workout': 'My Workout',
      'view_details': 'View details',
      'no_exercise_planned': 'No exercise planned',
      'ask_for_help': 'Ask for help',
      'ask_help_for_exercise':
          'Do you want to ask for help with the exercise "{exercise}"?',
      'help_request_sent': '✅ Help request sent for {exercise}',
      'choose_subscription': 'Choose a subscription',
      'personal_info': 'Personal information',
      'birth_date': 'Date of birth',
      'fitness_level': 'Fitness level',
      'parameters': 'Settings',
      'about': 'About',
      'help_support': 'Help & Support',
      'disconnect': 'Sign out',
      'retry': 'Retry',
      'my_member_card': 'My Member Card',
      'scan_at_entrance': 'Scan this code at the entrance',
      'loading_qr_code': 'Loading QR code...',
      'present_this_code': 'Present this code at the entrance',
      'no_gym_assigned': 'No gym assigned',
      'my_gym_name': 'My Gym',
      'address_unavailable': 'Address unavailable',
      'error_loading_gym': 'Error loading gym information',
      'error_loading_qr': 'Error loading QR code',
      'error_loading_subscription': 'Error loading subscription',
      'error_loading_workout': 'Error loading workout',
      'hide_qr_code': 'Hide QR Code',
      'whatsapp_scan_qr': 'Scan QR',
      'whatsapp_phone_number': 'Phone number',
      'whatsapp_get_code': 'Get code',
      'whatsapp_pairing_code': 'Pairing code',
      'whatsapp_phone_helper': 'International format, e.g. 212600123456',
      'whatsapp_enter_phone': 'Enter your number to receive the code on WhatsApp',
      'my_plannings': 'My Schedules',
      'starting_measurements': 'Starting measurements',
      'member_since': 'Member since: {date}',
      'edit_profile': 'Edit profile',
      'my_subscription': 'My Subscription',
      'my_goals': '🎯 My Goals',
      'member': 'Member',
      'show_my_qr_code': 'Show my QR Code',
      'present_qr_to_staff': 'Present your QR code to staff\nto check in',
      'premium_subscription': 'Premium Subscription',
      'start_date': 'Start date',
      'expiration_date': 'Expiration date',
      'payment_history': 'Payment History',
      'no_active_subscription': 'No active subscription',
      'subscribe_for_features': 'Subscribe to access all features.',
      'feature_coming_soon': 'Feature coming soon',
      'profession': 'Profession',
      'not_specified': 'Not specified',
      'upcoming': 'Upcoming',
      'coach': 'Coach',
      'training_days': '{count} training day{plural}',
      'from_to_dates': 'From {start} to {end}',
      'month_january': 'January',
      'month_february': 'February',
      'month_march': 'March',
      'month_april': 'April',
      'month_may': 'May',
      'month_june': 'June',
      'month_july': 'July',
      'month_august': 'August',
      'month_september': 'September',
      'month_october': 'October',
      'month_november': 'November',
      'month_december': 'December',
      'fitness_beginner': 'Beginner',
      'fitness_intermediate': 'Intermediate',
      'fitness_advanced': 'Advanced',
      'fitness_expert': 'Expert',
      'fitness_athletic': 'Athletic',
      'request_help': 'Request help',
      'premium_subscription_type': 'Premium Subscription',
      'standard_subscription_type': 'Standard Subscription',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'active_status': 'ACTIVE',
      'owner_role': 'Owner',
      'manager_role': 'Manager',
      'coach_role': 'Coach',
      'coach_my_members': 'My members',
      'coach_no_members': 'No members are assigned to you yet.',
    },
    'ar': {
      'home': 'الرئيسية',
      'my_card': 'بطاقتي',
      'my_planning': 'جدولي',
      'my_profile': 'ملفي الشخصي',
      'welcome': 'مرحباً!',
      'language': 'اللغة',
      'select_language': 'اختر اللغة',
      'french': 'Français',
      'english': 'English',
      'arabic': 'العربية',
      'language_changed': 'تم تغيير اللغة إلى',
      'dashboard': 'لوحة القيادة',
      'members': 'الأعضاء',
      'active': 'نشط',
      'today': 'اليوم',
      'revenue': 'الإيرادات',
      'quick_actions': 'إجراءات سريعة',
      'new_member': 'عضو جديد',
      'record_payment': 'تسجيل دفعة',
      'scan_card': 'مسح البطاقة',
      'search': 'بحث',
      'search_member_hint': 'البحث عن عضو...',
      'add_new_member_title': 'إضافة عضو جديد',
      'full_name': 'الاسم الكامل',
      'email': 'البريد الإلكتروني',
      'phone': 'الهاتف',
      'save': 'حفظ',
      'administrator': 'مسؤول',
      'settings': 'الإعدادات',
      'security': 'الأمان',
      'help': 'مساعدة',
      'logout': 'تسجيل الخروج',
      'add': 'إضافة',
      'profile': 'الملف الشخصي',
      'store': 'المتجر',
      'management': 'الإدارة',
      'global_management': 'الإدارة الشاملة',
      'welcome_community': 'مرحباً بك في مجتمعنا!',
      'welcome_name': 'مرحباً، {name}!',
      'visit_reception': 'قم بزيارة الاستقبال لتفعيل اشتراكك',
      'my_gym': 'صالة الرياضة الخاصة بي',
      'my_next_workout': 'تمريني القادم',
      'start_fitness_journey': 'ابدأ رحلتك الرياضية',
      'get_subscription': 'احصل على اشتراك للوصول إلى برنامجك المخصص',
      'get_subscription_button': 'احصل على اشتراك',
      'updated_data': 'تم تحديث البيانات',
      'subscription_expired': 'انتهى الاشتراك',
      'subscription_cancelled': 'تم إلغاء الاشتراك',
      'expires_on': 'ينتهي في:',
      'my_stats': 'إحصائياتي',
      'no_workout_planned': 'لم يتم تحديد تمرين',
      'coach_will_assign': 'سيقوم مدربك بتعيين برنامج لك قريباً',
      'session_expired': 'انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى',
      'session_expired_short': 'انتهت الجلسة',
      'welcome_login': 'مرحباً\nتسجيل الدخول',
      'login': 'تسجيل الدخول',
      'sign_in_biometric': 'تسجيل الدخول باستخدام البصمة',
      'or_use_password': 'أو استخدم كلمة المرور',
      'email_or_phone': 'البريد الإلكتروني أو رقم الهاتف',
      'password': 'كلمة المرور',
      'forgot_password': 'هل نسيت كلمة المرور؟',
      'sign_in': 'تسجيل الدخول',
      'first_login': 'أول تسجيل دخول',
      'checking_connection': 'جاري التحقق من الاتصال...',
      'offline_mode': 'وضع غير متصل',
      'db_connection_failed':
          'فشل الاتصال بقاعدة البيانات.\nالتطبيق يعمل في وضع محدود.',
      'invalid_credentials': 'بيانات الاعتماد غير صحيحة',
      'fill_email_password': 'يرجى إدخال البريد الإلكتروني/الهاتف وكلمة المرور',
      'gym_management': 'إدارة صالة الرياضة الخالة بك',
      'error_occurred': 'حدث خطأ',
      'status_unknown': 'حالة غير معروفة',
      'subscription_active': 'اشتراكك نشط',
      'your_journey_starts': 'تبدأ رحلتك هنا!',
      'stats_appear_when_training':
          'ستظهر إحصائياتك هنا بمجرد أن تبدأ تدريباتك',
      'visits_this_month': 'الزيارات هذا الشهر',
      'total_visits': 'إجمالي الزيارات',
      'contact_reception_subscription': 'اتصل بالاستقبال لاختيار اشتراكك',
      'next_workout': 'التمرين القادم',
      'my_workout': 'تمريني',
      'view_details': 'عرض التفاصيل',
      'no_exercise_planned': 'لا توجد تمارين مخططة',
      'ask_for_help': 'اطلب المساعدة',
      'ask_help_for_exercise': 'هل تريد طلب المساعدة في التمرين "{exercise}"؟',
      'help_request_sent': '✅ تم إرسال طلب المساعدة لـ {exercise}',
      'choose_subscription': 'اختر الاشتراك',
      'personal_info': 'المعلومات الشخصية',
      'birth_date': 'تاريخ الميلاد',
      'fitness_level': 'المستوى الرياضي',
      'parameters': 'الإعدادات',
      'about': 'حول',
      'help_support': 'المساعدة والدعم',
      'disconnect': 'تسجيل الخروج',
      'retry': 'إعادة المحاولة',
      'my_member_card': 'بطاقة العضوية',
      'scan_at_entrance': 'امسح هذا الرمز عند المدخل',
      'loading_qr_code': 'جارٍ تحميل رمز الاستجابة السريعة...',
      'present_this_code': 'قدم هذا الرمز عند المدخل',
      'no_gym_assigned': 'لم يتم تعيين صالة رياضية',
      'my_gym_name': 'صالتي الرياضية',
      'address_unavailable': 'العنوان غير متوفر',
      'error_loading_gym': 'خطأ في تحميل معلومات الصالة الرياضية',
      'error_loading_qr': 'خطأ في تحميل رمز الاستجابة السريعة',
      'error_loading_subscription': 'خطأ في تحميل الاشتراك',
      'error_loading_workout': 'خطأ في تحميل التمرين',
      'hide_qr_code': 'إخفاء رمز الاستجابة السريعة',
      'whatsapp_scan_qr': 'مسح QR',
      'whatsapp_phone_number': 'رقم الهاتف',
      'whatsapp_get_code': 'الحصول على الرمز',
      'whatsapp_pairing_code': 'رمز الإقران',
      'whatsapp_phone_helper': 'الصيغة الدولية، مثل 212600123456',
      'whatsapp_enter_phone': 'أدخل رقمك لتلقي الرمز على واتساب',
      'my_plannings': 'جداولي',
      'starting_measurements': 'القياسات الأولية',
      'member_since': 'عضو منذ: {date}',
      'edit_profile': 'تعديل الملف الشخصي',
      'my_subscription': 'اشتراكي',
      'my_goals': '🎯 أهدافي',
      'member': 'عضو',
      'show_my_qr_code': 'عرض رمز الاستجابة السريعة',
      'present_qr_to_staff': 'قدم رمز الاستجابة السريعة للموظفين\nلتسجيل حضورك',
      'premium_subscription': 'اشتراك مميز',
      'start_date': 'تاريخ البداية',
      'expiration_date': 'تاريخ الانتهاء',
      'payment_history': 'سجل الدفع',
      'no_active_subscription': 'لا يوجد اشتراك نشط',
      'subscribe_for_features': 'اشترك للوصول إلى جميع الميزات.',
      'feature_coming_soon': 'ميزة قادمة قريباً',
      'profession': 'المهنة',
      'not_specified': 'غير محدد',
      'upcoming': 'قادم',
      'coach': 'مدرب',
      'training_days': '{count} يوم تدريب',
      'from_to_dates': 'من {start} إلى {end}',
      'month_january': 'يناير',
      'month_february': 'فبراير',
      'month_march': 'مارس',
      'month_april': 'أبريل',
      'month_may': 'مايو',
      'month_june': 'يونيو',
      'month_july': 'يوليو',
      'month_august': 'أغسطس',
      'month_september': 'سبتمبر',
      'month_october': 'أكتوبر',
      'month_november': 'نوفمبر',
      'month_december': 'ديسمبر',
      'fitness_beginner': 'مبتدئ',
      'fitness_intermediate': 'متوسط',
      'fitness_advanced': 'متقدم',
      'fitness_expert': 'خبير',
      'fitness_athletic': 'رياضي',
      'request_help': 'طلب مساعدة',
      'premium_subscription_type': 'اشتراك مميز',
      'standard_subscription_type': 'اشتراك قياسي',
      'cancel': 'إلغاء',
      'confirm': 'تأكيد',
      'active_status': 'نشط',
      'owner_role': 'المالك',
      'manager_role': 'مدير',
      'coach_role': 'مدرب',
      'coach_my_members': 'أعضائي',
      'coach_no_members': 'لم يتم تعيين أي عضو لك بعد.',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Convenience getters for common translations
  String get home => translate('home');
  String get myCard => translate('my_card');
  String get myPlanning => translate('my_planning');
  String get myProfile => translate('my_profile');
  String get welcome => translate('welcome');
  String get language => translate('language');
  String get selectLanguage => translate('select_language');
  String get french => translate('french');
  String get english => translate('english');
  String get arabic => translate('arabic');
  String get languageChanged => translate('language_changed');
  String get dashboard => translate('dashboard');
  String get members => translate('members');
  String get active => translate('active');
  String get today => translate('today');
  String get revenue => translate('revenue');
  String get quickActions => translate('quick_actions');
  String get newMember => translate('new_member');
  String get recordPayment => translate('record_payment');
  String get scanCard => translate('scan_card');
  String get search => translate('search');
  String get searchMemberHint => translate('search_member_hint');
  String get addNewMemberTitle => translate('add_new_member_title');
  String get fullName => translate('full_name');
  String get email => translate('email');
  String get phone => translate('phone');
  String get save => translate('save');
  String get administrator => translate('administrator');
  String get settings => translate('settings');
  String get security => translate('security');
  String get help => translate('help');
  String get logout => translate('logout');
  String get add => translate('add');
  String get profile => translate('profile');
  String get store => translate('store');
  String get management => translate('management');
  String get globalManagement => translate('global_management');
  String get welcomeCommunity => translate('welcome_community');
  String welcomeName(String name) =>
      translate('welcome_name').replaceAll('{name}', name);
  String get visitReception => translate('visit_reception');
  String get myGym => translate('my_gym');
  String get myNextWorkout => translate('my_next_workout');
  String get startFitnessJourney => translate('start_fitness_journey');
  String get getSubscription => translate('get_subscription');
  String get getSubscriptionButton => translate('get_subscription_button');
  String get updatedData => translate('updated_data');
  String get subscriptionExpired => translate('subscription_expired');
  String get subscriptionCancelled => translate('subscription_cancelled');
  String get expiresOn => translate('expires_on');
  String get myStats => translate('my_stats');
  String get noWorkoutPlanned => translate('no_workout_planned');
  String get coachWillAssign => translate('coach_will_assign');
  String get sessionExpired => translate('session_expired');
  String get sessionExpiredShort => translate('session_expired_short');
  String get welcomeLogin => translate('welcome_login');
  String get login => translate('login');
  String get signInBiometric => translate('sign_in_biometric');
  String get orUsePassword => translate('or_use_password');
  String get emailOrPhone => translate('email_or_phone');
  String get password => translate('password');
  String get forgotPassword => translate('forgot_password');
  String get signIn => translate('sign_in');
  String get firstLogin => translate('first_login');
  String get checkingConnection => translate('checking_connection');
  String get offlineMode => translate('offline_mode');
  String get dbConnectionFailed => translate('db_connection_failed');
  String get invalidCredentials => translate('invalid_credentials');
  String get fillEmailPassword => translate('fill_email_password');
  String get gymManagement => translate('gym_management');
  String get errorOccurred => translate('error_occurred');
  String get statusUnknown => translate('status_unknown');
  String get subscriptionActive => translate('subscription_active');
  String get yourJourneyStarts => translate('your_journey_starts');
  String get statsAppearWhenTraining => translate('stats_appear_when_training');
  String get visitsThisMonth => translate('visits_this_month');
  String get totalVisits => translate('total_visits');
  String get contactReceptionSubscription =>
      translate('contact_reception_subscription');
  String get nextWorkout => translate('next_workout');
  String get myWorkout => translate('my_workout');
  String get viewDetails => translate('view_details');
  String get noExercisePlanned => translate('no_exercise_planned');
  String get askForHelp => translate('ask_for_help');
  String askHelpForExercise(String exercise) =>
      translate('ask_help_for_exercise').replaceAll('{exercise}', exercise);
  String helpRequestSent(String exercise) =>
      translate('help_request_sent').replaceAll('{exercise}', exercise);
  String get chooseSubscription => translate('choose_subscription');
  String get personalInfo => translate('personal_info');
  String get birthDate => translate('birth_date');
  String get fitnessLevel => translate('fitness_level');
  String get parameters => translate('parameters');
  String get about => translate('about');
  String get helpSupport => translate('help_support');
  String get disconnect => translate('disconnect');
  String get retry => translate('retry');
  String get myMemberCard => translate('my_member_card');
  String get scanAtEntrance => translate('scan_at_entrance');
  String get loadingQrCode => translate('loading_qr_code');
  String get presentThisCode => translate('present_this_code');
  String get noGymAssigned => translate('no_gym_assigned');
  String get myGymName => translate('my_gym_name');
  String get addressUnavailable => translate('address_unavailable');
  String get errorLoadingGym => translate('error_loading_gym');
  String get errorLoadingQr => translate('error_loading_qr');
  String get errorLoadingSubscription =>
      translate('error_loading_subscription');
  String get errorLoadingWorkout => translate('error_loading_workout');
  String get hideQrCode => translate('hide_qr_code');
  String get whatsappScanQr => translate('whatsapp_scan_qr');
  String get whatsappPhoneNumber => translate('whatsapp_phone_number');
  String get whatsappGetCode => translate('whatsapp_get_code');
  String get whatsappPairingCode => translate('whatsapp_pairing_code');
  String get whatsappPhoneHelper => translate('whatsapp_phone_helper');
  String get whatsappEnterPhone => translate('whatsapp_enter_phone');
  String get myPlannings => translate('my_plannings');
  String get startingMeasurements => translate('starting_measurements');
  String memberSince(String date) =>
      translate('member_since').replaceAll('{date}', date);
  String get editProfile => translate('edit_profile');
  String get mySubscription => translate('my_subscription');
  String get myGoals => translate('my_goals');
  String get member => translate('member');
  String get showMyQrCode => translate('show_my_qr_code');
  String get presentQrToStaff => translate('present_qr_to_staff');
  String get premiumSubscription => translate('premium_subscription');
  String get startDate => translate('start_date');
  String get expirationDate => translate('expiration_date');
  String get paymentHistory => translate('payment_history');
  String get noActiveSubscription => translate('no_active_subscription');
  String get subscribeForFeatures => translate('subscribe_for_features');
  String get featureComingSoon => translate('feature_coming_soon');
  String get profession => translate('profession');
  String get notSpecified => translate('not_specified');
  String get upcoming => translate('upcoming');
  String get coach => translate('coach');
  String trainingDays(int count) {
    final plural = count > 1 ? 's' : '';
    return translate(
      'training_days',
    ).replaceAll('{count}', count.toString()).replaceAll('{plural}', plural);
  }

  String fromToDates(String start, String end) => translate(
    'from_to_dates',
  ).replaceAll('{start}', start).replaceAll('{end}', end);

  // Month names
  String getMonthName(int month) {
    final monthKeys = [
      'month_january',
      'month_february',
      'month_march',
      'month_april',
      'month_may',
      'month_june',
      'month_july',
      'month_august',
      'month_september',
      'month_october',
      'month_november',
      'month_december',
    ];
    if (month >= 1 && month <= 12) {
      return translate(monthKeys[month - 1]);
    }
    return month.toString();
  }

  // Fitness levels
  String get fitnessBeginner => translate('fitness_beginner');
  String get fitnessIntermediate => translate('fitness_intermediate');
  String get fitnessAdvanced => translate('fitness_advanced');
  String get fitnessExpert => translate('fitness_expert');
  String get fitnessAthletic => translate('fitness_athletic');
  String get requestHelp => translate('request_help');
  String get premiumSubscriptionType => translate('premium_subscription_type');
  String get standardSubscriptionType =>
      translate('standard_subscription_type');
  String get cancel => translate('cancel');
  String get confirm => translate('confirm');
  String get activeStatus => translate('active_status');
  String get ownerRole => translate('owner_role');
  String get managerRole => translate('manager_role');
  String get coachRole => translate('coach_role');
  String get coachMyMembers => translate('coach_my_members');
  String get coachNoMembers => translate('coach_no_members');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['fr', 'en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    debugPrint('AppLocalizationsDelegate: load called for $locale');
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => true;
}
