import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/theme.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/user_utils.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/responsive/responsive_layout.dart';
import '../auth/login_screen.dart';
import 'subscription_details_screen.dart';
import 'edit_profile_screen.dart';
import '../common/security_settings_screen.dart';
import '../common/about_screen.dart';
import '../common/store_screen.dart';

class MemberHomeScreen extends StatefulWidget {
  const MemberHomeScreen({super.key});

  @override
  State<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends State<MemberHomeScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _quotaData;
  bool _isLoadingQuota = true;
  Map<String, dynamic>? _subscriptionData;
  bool _isLoadingSubscription = true;

  final List<Widget> _pages = [
    MemberDashboardPage(),
    MemberQrCodePage(),
    MemberPlanningPage(),
    MemberProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadSubscription();
    await _loadQuota();
  }

  Future<void> _loadProfileData() async {
    final authService = AuthService(ApiService.fromEnv());
    final data = await authService.getCachedUserProfile();
    if (mounted) {
      setState(() {
        _profileData = data;
      });
    }
  }

  Future<void> _loadSubscription() async {
    try {
      final authService = AuthService(ApiService.fromEnv());
      final apiService = ApiService.fromEnv();
      final token = await authService.loadToken();
      final profile = await authService.getCachedUserProfile();
      final memberId = profile?['id'];

      print('🔍 [SUBSCRIPTION] memberId: $memberId');

      if (token == null || memberId == null) {
        setState(() {
          _isLoadingSubscription = false;
        });
        return;
      }

      // Charger les abonnements du membre
      final subscriptions = await apiService.getMemberSubscriptions(
        memberId,
        token,
      );
      print('📦 [SUBSCRIPTION] subscriptions: $subscriptions');

      if (subscriptions != null && subscriptions.isNotEmpty) {
        // Prendre le premier abonnement actif
        final activeSubscription =
            subscriptions.firstWhere(
                  (sub) => (sub as Map<String, dynamic>)['status'] == 'active',
                  orElse: () => subscriptions.first,
                )
                as Map<String, dynamic>?;

        if (activeSubscription != null) {
          // Charger les détails complets de l'abonnement pour avoir le subscriptionType
          final subscriptionId = activeSubscription['id'];
          print(
            '🔍 [SUBSCRIPTION] Chargement détails pour subscriptionId: $subscriptionId',
          );

          final fullSubscription = await apiService.getSubscriptionById(
            subscriptionId,
            token,
          );
          print('📋 [SUBSCRIPTION] fullSubscription: $fullSubscription');

          if (mounted) {
            setState(() {
              _subscriptionData = fullSubscription ?? activeSubscription;
              _isLoadingSubscription = false;
            });
          }
          print(
            '✅ [SUBSCRIPTION] Abonnement chargé: ${fullSubscription ?? activeSubscription}',
          );
        } else {
          if (mounted) {
            setState(() {
              _isLoadingSubscription = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingSubscription = false;
          });
        }
        print('⚠️ [SUBSCRIPTION] Aucun abonnement trouvé');
      }
    } catch (e) {
      print('❌ [SUBSCRIPTION] Exception: $e');
      if (mounted) {
        setState(() {
          _isLoadingSubscription = false;
        });
      }
    }
  }

  Future<void> _loadQuota() async {
    try {
      final authService = AuthService(ApiService.fromEnv());
      final apiService = ApiService.fromEnv();
      final token = await authService.loadToken();
      // Utiliser l'abonnement chargé au lieu du cache
      final subscription =
          _subscriptionData?['subscription'] as Map<String, dynamic>?;
      final subscriptionId = subscription?['id'];

      print('🔍 [HOME QUOTA] subscription: $subscription');
      print('🔍 [HOME QUOTA] subscriptionId: $subscriptionId');

      if (token == null || subscriptionId == null) {
        setState(() {
          _isLoadingQuota = false;
        });
        return;
      }

      final uri = apiService.baseUri.resolve(
        '/check-in/subscription/$subscriptionId/quota',
      );
      print('🌐 [HOME QUOTA] Requête: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 [HOME QUOTA] Status: ${response.statusCode}');
      print('📦 [HOME QUOTA] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _quotaData = data;
            _isLoadingQuota = false;
          });
        }
        print('✅ [HOME QUOTA] Quota chargé: $data');
      } else {
        if (mounted) {
          setState(() {
            _isLoadingQuota = false;
          });
        }
      }
    } catch (e) {
      print('❌ [HOME QUOTA] Exception: $e');
      debugPrint('Error loading quota: $e');
      if (mounted) {
        setState(() {
          _isLoadingQuota = false;
        });
      }
    }
  }

  Widget? _buildQuotaWidget() {
    print(
      '🎯 [QUOTA WIDGET] _isLoadingQuota: $_isLoadingQuota, _quotaData: $_quotaData',
    );

    // Afficher un placeholder pendant le chargement
    if (_isLoadingQuota || _quotaData == null) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 80, maxHeight: 36),
        child: Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.1),
                AppColors.primary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary.withValues(alpha: 0.5),
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

    // Utiliser subscriptionType.sessionQuota au lieu de sessionQuota
    final subscriptionTypeData =
        _quotaData!['subscriptionType'] as Map<String, dynamic>?;
    final sessionType = subscriptionTypeData?['sessionType'] as String?;
    final sessionQuota = subscriptionTypeData?['sessionQuota'] as int?;
    final sessionsUsed = _quotaData!['sessionsUsed'] as int? ?? 0;
    final sessionsRemaining = (sessionQuota != null && sessionQuota > 0)
        ? sessionQuota - sessionsUsed
        : null;
    final isUnlimited =
        sessionType == 'unlimited' || sessionQuota == null || sessionQuota == 0;

    print(
      '🎯 [QUOTA WIDGET] sessionQuota: $sessionQuota, sessionsUsed: $sessionsUsed, remaining: $sessionsRemaining, unlimited: $isUnlimited',
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 80, maxHeight: 36),
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              (isUnlimited || (sessionsRemaining ?? 0) > 5)
                  ? AppColors.success.withValues(alpha: 0.2)
                  : AppColors.warning.withValues(alpha: 0.2),
              (isUnlimited || (sessionsRemaining ?? 0) > 5)
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (isUnlimited || (sessionsRemaining ?? 0) > 5)
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.warning.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isUnlimited ? Icons.all_inclusive : Icons.fitness_center,
                  color: (isUnlimited || (sessionsRemaining ?? 0) > 5)
                      ? AppColors.success
                      : AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    isUnlimited ? '∞' : '$sessionsRemaining',
                    style: TextStyle(
                      color: (isUnlimited || (sessionsRemaining ?? 0) > 5)
                          ? AppColors.success
                          : AppColors.warning,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.clip,
                    maxLines: 1,
                    textDirection: TextDirection.ltr,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(bool isActive) {
    // Try to get photo from root level first (from /me endpoint)
    String? profileImageBase64 = _profileData?['profileImage'] as String?;

    // Fallback to member.profileImage if not found at root level
    if (profileImageBase64 == null || profileImageBase64.isEmpty) {
      final member = _profileData?['member'] as Map<String, dynamic>?;
      profileImageBase64 = member?['profileImage'] as String?;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: ClipOval(
        child: profileImageBase64 != null && profileImageBase64.isNotEmpty
            ? Image.memory(
                base64Decode(
                  profileImageBase64.contains('base64,')
                      ? profileImageBase64.split('base64,')[1]
                      : profileImageBase64,
                ),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    child: Icon(
                      Icons.person,
                      color: isActive ? AppColors.primary : Colors.grey,
                      size: 20,
                    ),
                  );
                },
              )
            : Container(
                color: AppColors.primary.withValues(alpha: 0.2),
                child: Icon(
                  Icons.person,
                  color: isActive ? AppColors.primary : Colors.grey,
                  size: 20,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final titles = [l10n.home, l10n.myCard, l10n.myPlanning, l10n.myProfile];

    return ResponsiveScaffold(
      title: titles[_currentIndex],
      leading: _currentIndex == 0 ? _buildQuotaWidget() : null,
      navigationItems: [
        NavigationItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          label: l10n.home,
        ),
        NavigationItem(
          icon: Icons.qr_code_2_outlined,
          activeIcon: Icons.qr_code_2,
          label: l10n.myCard,
        ),
        NavigationItem(
          icon: Icons.fitness_center_outlined,
          activeIcon: Icons.fitness_center,
          label: l10n.myPlanning,
        ),
        NavigationItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: l10n.myProfile,
          customWidget: _buildProfileAvatar(false),
          activeCustomWidget: _buildProfileAvatar(true),
        ),
      ],
      currentIndex: _currentIndex,
      onNavigationChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      actions: [
        // Bouton Store stylé
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.2),
                AppColors.primaryLight.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StoreScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.storefront_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Store',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
      body: _pages[_currentIndex],
    );
  }
}

// ==================== MEMBER DASHBOARD PAGE ====================
class MemberDashboardPage extends StatefulWidget {
  const MemberDashboardPage({super.key});

  @override
  State<MemberDashboardPage> createState() => _MemberDashboardPageState();
}

class _MemberDashboardPageState extends State<MemberDashboardPage> {
  final ApiService _apiService = ApiService.fromEnv();
  late final AuthService _authService;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(_apiService);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Fév',
        'Mar',
        'Avr',
        'Mai',
        'Juin',
        'Juil',
        'Août',
        'Sep',
        'Oct',
        'Nov',
        'Déc',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _refreshDashboard() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Get token
      final token = await _authService.loadToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).sessionExpired,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
                ),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Refresh user profile from API
      await _authService.refreshUserProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ ${AppLocalizations.of(context).updatedData}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary),
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        _showErrorWithRetry(l10n.errorOccurred, _refreshDashboard);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: RefreshIndicator(
        onRefresh: _refreshDashboard,
        color: Theme.of(context).colorScheme.primary,
        notificationPredicate: (notification) => !_isRefreshing,
        child: SingleChildScrollView(
          physics: _isRefreshing
              ? NeverScrollableScrollPhysics()
              : AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner carousel - only shows when banners exist
              const BannerCarousel(height: 140),
              const SizedBox(height: 16),

              // Welcome card
              FutureBuilder<Map<String, dynamic>?>(
                future: _authService.getCachedUserProfile(),
                builder: (context, snapshot) {
                  final theme = Theme.of(context);
                  final profileData = snapshot.data;
                  final fullName = profileData != null
                      ? getUserFullName(profileData)
                      : AppLocalizations.of(context).member;

                  // Get subscription info
                  Map<String, dynamic>? subscription;
                  final subscriptions =
                      profileData?['subscriptions'] as List<dynamic>?;
                  if (subscriptions != null && subscriptions.isNotEmpty) {
                    subscription =
                        subscriptions.firstWhere(
                              (sub) =>
                                  (sub as Map<String, dynamic>)['status'] ==
                                  'active',
                              orElse: () => null,
                            )
                            as Map<String, dynamic>?;
                  } else {
                    subscription =
                        profileData?['subscription'] as Map<String, dynamic>?;
                  }

                  final status = subscription?['status'] ?? 'unknown';
                  final expiresAt =
                      subscription?['expiresAt'] ?? subscription?['endDate'];

                  final l10n = AppLocalizations.of(context);
                  String statusText = l10n.statusUnknown;
                  Color statusColor = Colors.grey;
                  IconData statusIcon = Icons.info;

                  if (status == 'active') {
                    statusText = l10n.subscriptionActive;
                    statusColor = theme.colorScheme.onPrimary;
                    statusIcon = Icons.check_circle;
                  } else if (status == 'expired') {
                    statusText = l10n.subscriptionExpired;
                    statusColor = AppColors.error;
                    statusIcon = Icons.cancel;
                  } else if (status == 'cancelled') {
                    statusText = l10n.subscriptionCancelled;
                    statusColor = Colors.orange.shade200;
                    statusIcon = Icons.warning;
                  } else {
                    // No active subscription - new member
                    final l10n = AppLocalizations.of(context);
                    statusText = l10n.welcomeCommunity;
                    statusColor = theme.colorScheme.onPrimary;
                    statusIcon = Icons.waving_hand;
                  }

                  return ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: double.infinity),
                    child: Card(
                      color: theme.colorScheme.primary,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    ).welcomeName(fullName),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                                if (status != 'active' && status != 'unknown')
                                  Icon(
                                    statusIcon,
                                    color: statusColor,
                                    size: 28,
                                  ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                if (status == 'unknown')
                                  Icon(statusIcon, color: statusColor, size: 20)
                                else if (status == 'active')
                                  Icon(
                                    Icons.check_circle,
                                    color: statusColor,
                                    size: 20,
                                  ),
                                if (status == 'unknown' || status == 'active')
                                  SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: statusColor,
                                      fontWeight: status == 'unknown'
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (status == 'active' && expiresAt != null) ...[
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: theme.colorScheme.onPrimary,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '${AppLocalizations.of(context).expiresOn} ${_formatDate(expiresAt)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: theme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (status == 'unknown') ...[
                              SizedBox(height: 12),
                              Text(
                                AppLocalizations.of(context).visitReception,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onPrimary.withValues(
                                    alpha: 0.9,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24),

              // Gym information
              Text(
                l10n.myGym,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
                ),
              ),
              SizedBox(height: 16),
              _buildGymCard(context),
              SizedBox(height: 24),

              // Next workout section
              Text(
                l10n.myNextWorkout,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
                ),
              ),
              SizedBox(height: 16),
              _buildNextWorkoutCard(),
              SizedBox(height: 24),

              // Stats cards
              Text(
                l10n.myStats,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
                ),
              ),
              SizedBox(height: 16),
              FutureBuilder<Map<String, dynamic>?>(
                future: _authService.getCachedUserProfile(),
                builder: (context, snapshot) {
                  final profileData = snapshot.data;
                  Map<String, dynamic>? subscription;
                  final subscriptions =
                      profileData?['subscriptions'] as List<dynamic>?;
                  if (subscriptions != null && subscriptions.isNotEmpty) {
                    subscription =
                        subscriptions.firstWhere(
                              (sub) =>
                                  (sub as Map<String, dynamic>)['status'] ==
                                  'active',
                              orElse: () => null,
                            )
                            as Map<String, dynamic>?;
                  } else {
                    subscription =
                        profileData?['subscription'] as Map<String, dynamic>?;
                  }

                  final hasActiveSubscription =
                      subscription?['status'] == 'active';

                  if (!hasActiveSubscription) {
                    // Show motivational message for new members
                    return ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: double.infinity),
                      child: Card(
                        color: Theme.of(context).cardTheme.color,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.emoji_events,
                                size: 48,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              SizedBox(height: 16),
                              Text(
                                l10n.yourJourneyStarts,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                l10n.statsAppearWhenTraining,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // Show stats for members with active subscription
                  return Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          l10n.visitsThisMonth,
                          '12',
                          Icons.calendar_today,
                          AppColors.info,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          l10n.totalVisits,
                          '148',
                          Icons.fitness_center,
                          AppColors.success,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextWorkoutCard() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadNextWorkout(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: double.infinity),
            child: Card(
              color: Theme.of(context).cardTheme.color,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          // Check subscription status to show appropriate message
          return FutureBuilder<Map<String, dynamic>?>(
            future: _authService.getCachedUserProfile(),
            builder: (context, profileSnapshot) {
              final profileData = profileSnapshot.data;
              Map<String, dynamic>? subscription;
              final subscriptions =
                  profileData?['subscriptions'] as List<dynamic>?;
              if (subscriptions != null && subscriptions.isNotEmpty) {
                subscription =
                    subscriptions.firstWhere(
                          (sub) =>
                              (sub as Map<String, dynamic>)['status'] ==
                              'active',
                          orElse: () => null,
                        )
                        as Map<String, dynamic>?;
              } else {
                subscription =
                    profileData?['subscription'] as Map<String, dynamic>?;
              }

              final hasActiveSubscription = subscription?['status'] == 'active';

              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: double.infinity),
                child: Card(
                  color: Theme.of(context).cardTheme.color,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(
                          hasActiveSubscription
                              ? Icons.fitness_center
                              : Icons.card_membership,
                          size: 48,
                          color: hasActiveSubscription
                              ? (Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary)
                              : Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(height: 12),
                        Text(
                          hasActiveSubscription
                              ? AppLocalizations.of(context).noWorkoutPlanned
                              : AppLocalizations.of(
                                  context,
                                ).startFitnessJourney,
                          style: TextStyle(
                            fontSize: 16,
                            color: hasActiveSubscription
                                ? (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary)
                                : (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          hasActiveSubscription
                              ? AppLocalizations.of(context).coachWillAssign
                              : AppLocalizations.of(context).getSubscription,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                          ),
                        ),
                        if (!hasActiveSubscription) ...[
                          SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Navigate to subscription page or show contact message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(
                                      context,
                                    ).contactReceptionSubscription,
                                    textAlign: TextAlign.center,
                                  ),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            },
                            icon: Icon(Icons.arrow_forward, size: 18),
                            label: Text(
                              AppLocalizations.of(
                                context,
                              ).getSubscriptionButton,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor:
                                  (Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary),
                              padding: EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 24,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }

        final data = snapshot.data!;
        final planning = data['planning'] as Map<String, dynamic>?;
        final day = data['day'] as Map<String, dynamic>?;
        final exercises = day?['exercises'] as List<dynamic>? ?? [];
        final date = day?['date'] as String?;
        final isToday = data['isToday'] as bool? ?? false;

        // Déterminer le statut de l'entraînement
        String workoutStatus;
        Color statusColor;
        IconData statusIcon;

        if (isToday) {
          workoutStatus = AppLocalizations.of(context).today;
          statusColor = AppColors.success;
          statusIcon = Icons.play_circle_outline;
        } else {
          // Formater la date pour afficher "Prochain : DD/MM"
          workoutStatus = AppLocalizations.of(context).nextWorkout;
          statusColor = Theme.of(context).colorScheme.primary;
          statusIcon = Icons.schedule;

          if (date != null) {
            try {
              final parsedDate = DateTime.parse(date);
              final dayName = _getDayName(parsedDate.weekday % 7);
              workoutStatus = '$dayName ${parsedDate.day}/${parsedDate.month}';
            } catch (_) {
              workoutStatus =
                  day?['dayName'] ?? AppLocalizations.of(context).nextWorkout;
            }
          }
        }

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: double.infinity),
          child: Card(
            color: Theme.of(context).cardTheme.color,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(statusIcon, color: statusColor, size: 28),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              planning?['title'] ??
                                  AppLocalizations.of(context).myWorkout,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary),
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: statusColor.withValues(alpha: 0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    workoutStatus,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (exercises.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Divider(color: Theme.of(context).dividerColor),
                    SizedBox(height: 16),

                    // Exercises preview (show first 3)
                    ...exercises.take(3).map((ex) {
                      final exerciseData = ex as Map<String, dynamic>;
                      final exercise =
                          exerciseData['exercise'] as Map<String, dynamic>?;
                      final sets = exerciseData['sets'] as int?;
                      final reps = exerciseData['reps'] as int?;

                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                exercise?['name'] ?? 'Exercice',
                                style: TextStyle(
                                  fontSize: 15,
                                  color:
                                      (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (sets != null && reps != null)
                              Text(
                                '$sets × $reps',
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),

                    if (exercises.length > 3) ...[
                      SizedBox(height: 4),
                      Text(
                        '+${exercises.length - 3} autres exercices',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showNextWorkoutPopup(data),
                        icon: Icon(Icons.visibility, size: 18),
                        label: Text(AppLocalizations.of(context).viewDetails),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor:
                              (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary),
                          padding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 24,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _loadNextWorkout() async {
    try {
      final token = await _authService.loadToken();
      final profileData = await _authService.getCachedUserProfile();

      if (token == null || profileData == null) {
        return null;
      }

      final memberId = profileData['id'] as int;
      final nextDay = await _apiService.getNextPlanningDay(memberId, token);

      return nextDay;
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Error loading next workout: $e');
      return null;
    }
  }

  String _getDayName(int dayOfWeek) {
    final days = [
      'Dimanche',
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
    ];
    return days[dayOfWeek % 7];
  }

  void _showNextWorkoutPopup(Map<String, dynamic> data) {
    final planning = data['planning'] as Map<String, dynamic>?;
    final day = data['day'] as Map<String, dynamic>?;
    final exercises = day?['exercises'] as List<dynamic>? ?? [];
    final date = day?['date'] as String?;
    final isToday = data['isToday'] as bool? ?? false;

    // Déterminer le statut de l'entraînement
    String workoutStatus;
    if (isToday) {
      final l10n = AppLocalizations.of(context);
      workoutStatus = l10n.today;
    } else {
      final l10n = AppLocalizations.of(context);
      workoutStatus = l10n.nextWorkout;
      if (date != null) {
        try {
          final parsedDate = DateTime.parse(date);
          final dayName = _getDayName(parsedDate.weekday % 7);
          workoutStatus = '$dayName ${parsedDate.day}/${parsedDate.month}';
        } catch (_) {
          workoutStatus = day?['dayName'] ?? 'Prochain';
        }
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color!,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.fitness_center,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              planning?['title'] ??
                                  AppLocalizations.of(context).myWorkout,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${exercises.length} exercice${exercises.length > 1 ? 's' : ''} • $workoutStatus',
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color:
                              (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                // Exercises list
                Flexible(
                  child: exercises.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'Aucun exercice prévu',
                              style: TextStyle(
                                color:
                                    (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary)
                                        .withValues(alpha: 0.7),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.all(20),
                          itemCount: exercises.length,
                          itemBuilder: (context, index) {
                            final exerciseData =
                                exercises[index] as Map<String, dynamic>;
                            final exercise =
                                exerciseData['exercise']
                                    as Map<String, dynamic>?;
                            final sets = exerciseData['sets'] as int?;
                            final reps = exerciseData['reps'] as int?;
                            final weightValue = exerciseData['weight'];
                            final weight = weightValue != null
                                ? (weightValue is int
                                      ? weightValue.toDouble()
                                      : weightValue as double?)
                                : null;
                            final notes = exerciseData['notes'] as String?;

                            return Card(
                              color: Theme.of(context).cardTheme.color,
                              margin: EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${index + 1}',
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            exercise?['name'] ?? 'Exercice',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  (Theme.of(
                                                        context,
                                                      ).brightness ==
                                                      Brightness.dark
                                                  ? AppColors.darkTextPrimary
                                                  : AppColors.lightTextPrimary),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (sets != null ||
                                        reps != null ||
                                        weight != null) ...[
                                      SizedBox(height: 12),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 8,
                                        children: [
                                          if (sets != null)
                                            _buildInfoChip(
                                              'Séries',
                                              sets.toString(),
                                              Icons.repeat,
                                            ),
                                          if (reps != null)
                                            _buildInfoChip(
                                              'Reps',
                                              reps.toString(),
                                              Icons.fitness_center,
                                            ),
                                          if (weight != null)
                                            _buildInfoChip(
                                              'Poids',
                                              '${weight}kg',
                                              Icons.monitor_weight,
                                            ),
                                        ],
                                      ),
                                    ],
                                    if (notes != null && notes.isNotEmpty) ...[
                                      SizedBox(height: 12),
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surface
                                              .withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.note,
                                              size: 16,
                                              color:
                                                  (Theme.of(
                                                        context,
                                                      ).brightness ==
                                                      Brightness.dark
                                                  ? AppColors.darkTextSecondary
                                                  : AppColors
                                                        .lightTextSecondary),
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                notes,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      (Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.dark
                                                      ? AppColors
                                                            .darkTextSecondary
                                                      : AppColors
                                                            .lightTextSecondary),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _requestHelp(
                                            exercise?['name'] ?? 'Exercice',
                                          );
                                        },
                                        icon: Icon(
                                          Icons.help_outline,
                                          size: 18,
                                        ),
                                        label: Text(
                                          AppLocalizations.of(
                                            context,
                                          ).askForHelp,
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          side: BorderSide(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 20,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _requestHelp(String exerciseName) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          title: Text(
            l10n.askForHelp,
            style: TextStyle(
              color: (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary),
            ),
          ),
          content: Text(
            l10n.askHelpForExercise(exerciseName),
            style: TextStyle(
              color: (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Confirmer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final token = await _authService.loadToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: Non authentifié'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final success = await _apiService.requestExerciseHelp(
        exerciseName,
        token,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).helpRequestSent(exerciseName),
              ),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          _showErrorWithRetry(
            AppLocalizations.of(context).errorOccurred,
            () => _requestHelp(exerciseName),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorWithRetry(
          AppLocalizations.of(context).errorOccurred,
          () => _requestHelp(exerciseName),
        );
      }
    }
  }

  void _showErrorWithRetry(String message, VoidCallback onRetry) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        action: SnackBarAction(
          label: 'Réessayer',
          textColor: Theme.of(context).colorScheme.primary,
          onPressed: onRetry,
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      color: Theme.of(context).cardTheme.color,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary),
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGymCard(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: AuthService(ApiService.fromEnv()).getCachedUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            color: Theme.of(context).cardTheme.color,
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          );
        }

        final gym = snapshot.data?['gym'] as Map<String, dynamic>?;
        if (gym == null) {
          return Card(
            color: Theme.of(context).cardTheme.color,
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                AppLocalizations.of(context).noGymAssigned,
                style: TextStyle(
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
                ),
              ),
            ),
          );
        }

        return SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).brightness == Brightness.dark
                      ? Color(0xFF2A2D3A)
                      : Color(0xFFF5F5F7),
                  Theme.of(context).brightness == Brightness.dark
                      ? Color(0xFF1F2128)
                      : Color(0xFFFFFFFF),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Color(0xFF3A3D4A).withValues(alpha: 0.5)
                    : Color(0xFFE0E0E0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showGymDetails(context, gym),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withValues(alpha: 0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.fitness_center,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gym['name'] ??
                                      AppLocalizations.of(context).myGymName,
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 15,
                                      color:
                                          (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary),
                                    ),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        gym['address'] ??
                                            AppLocalizations.of(
                                              context,
                                            ).addressUnavailable,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color:
                                              (Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary),
                                          height: 1.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color:
                                (Theme.of(context).brightness == Brightness.dark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary)
                                    .withValues(alpha: 0.6),
                            size: 18,
                          ),
                        ],
                      ),
                      SizedBox(height: 18),

                      Row(
                        children: [
                          Expanded(
                            child: _buildGymInfoChip(
                              Icons.access_time,
                              'Horaires',
                              Theme.of(context).brightness == Brightness.dark
                                  ? Color(0xFF3A8BFF)
                                  : Color(0xFF2196F3),
                              onTap: null,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildGymInfoChip(
                              Icons.navigation,
                              'Navigation',
                              Theme.of(context).brightness == Brightness.dark
                                  ? Color(0xFF4CAF50)
                                  : Color(0xFF2E7D32),
                              onTap: () => _openInGoogleMaps(
                                gym['address'] ?? '',
                                gym['name'],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openInGoogleMaps(String address, String? gymName) async {
    if (address.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).addressUnavailable),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final encodedAddress = Uri.encodeComponent(address);

    // Use geo: URI which allows the user to choose their preferred navigation app
    // This will show a chooser with Google Maps, Waze, and other map apps
    final geoUri = Uri.parse('geo:0,0?q=$encodedAddress');

    try {
      final canLaunch = await canLaunchUrl(geoUri);
      if (canLaunch) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to web URL if no map app is available
        final webUri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
        );
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        _showErrorWithRetry(
          'Une erreur est survenue',
          () => _openInGoogleMaps(address, null),
        );
      }
    }
  }

  Widget _buildGymInfoChip(
    IconData icon,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final chip = Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.4 : 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: chip,
        ),
      );
    }

    return chip;
  }

  void _showGymDetails(BuildContext context, Map<String, dynamic> gym) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => GymDetailsBottomSheet(gym: gym),
    );
  }
}

// ==================== MEMBER QR CODE PAGE ====================
class MemberQrCodePage extends StatefulWidget {
  const MemberQrCodePage({super.key});

  @override
  State<MemberQrCodePage> createState() => _MemberQrCodePageState();
}

class _MemberQrCodePageState extends State<MemberQrCodePage> {
  final AuthService _authService = AuthService(ApiService.fromEnv());
  final ApiService _apiService = ApiService.fromEnv();
  bool _showQrCode = false;
  bool _isLoading = false;
  List<int>? _qrImageBytes;
  Map<String, dynamic>? _profileData;
  bool _hasConnectivity = true;
  bool _isCheckingConnectivity = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _checkConnectivity();
    _tryLoadCachedQr();
  }

  Future<void> _loadProfileData() async {
    final profileData = await _authService.getCachedUserProfile();
    if (mounted) {
      setState(() {
        _profileData = profileData;
      });
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnection = !connectivityResult.contains(
        ConnectivityResult.none,
      );

      if (mounted) {
        setState(() {
          _hasConnectivity = hasConnection;
          _isCheckingConnectivity = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasConnectivity = false;
          _isCheckingConnectivity = false;
        });
      }
    }
  }

  Future<void> _tryLoadCachedQr() async {
    // Try to load QR from cache if no connectivity
    if (!_hasConnectivity) {
      final cachedQr = await _authService.getQrCodeCache();
      if (cachedQr != null && mounted) {
        setState(() {
          _qrImageBytes = cachedQr;
        });
      }
    }
  }

  Future<void> _toggleQrCode() async {
    if (_showQrCode) {
      // Hide QR code
      setState(() {
        _showQrCode = false;
      });
      return;
    }

    // Check connectivity again before loading
    await _checkConnectivity();

    // If no connectivity, try to use cached QR
    if (!_hasConnectivity) {
      final cachedQr = await _authService.getQrCodeCache();
      if (cachedQr != null) {
        setState(() {
          _qrImageBytes = cachedQr;
          _showQrCode = true;
        });
        return;
      } else {
        // No cache and no connectivity
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pas de connexion et aucun QR code en cache'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
    }

    // Show QR code - load it if not already loaded
    if (_qrImageBytes == null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final profileData = await _authService.getCachedUserProfile();
        if (profileData == null) {
          if (!mounted) return;
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorOccurred),
              backgroundColor: AppColors.error,
              action: SnackBarAction(
                label: l10n.retry,
                textColor: Theme.of(context).colorScheme.primary,
                onPressed: _toggleQrCode,
              ),
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        final userId = profileData['id'] as int;
        final token = await _authService.loadToken();
        if (token == null) {
          if (!mounted) return;
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorOccurred),
              backgroundColor: AppColors.error,
              action: SnackBarAction(
                label: l10n.retry,
                textColor: Theme.of(context).colorScheme.primary,
                onPressed: _toggleQrCode,
              ),
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Charger le QR code
        final qrImageBytes = await _apiService.getUserQrCode(userId, token);

        if (!mounted) return;

        if (qrImageBytes == null) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorLoadingQr),
              backgroundColor: AppColors.error,
              action: SnackBarAction(
                label: l10n.retry,
                textColor: Theme.of(context).colorScheme.primary,
                onPressed: _toggleQrCode,
              ),
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Save QR code to cache for offline use
        await _authService.saveQrCodeCache(qrImageBytes);

        setState(() {
          _qrImageBytes = qrImageBytes;
          _showQrCode = true;
          _isLoading = false;
        });
      } catch (e) {
        if (!mounted) return;

        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorLoadingQr),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: l10n.retry,
              textColor: Theme.of(context).colorScheme.primary,
              onPressed: _toggleQrCode,
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      // Already loaded, just show it
      setState(() {
        _showQrCode = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context).myMemberCard,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
                ),
              ),
              SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).scanAtEntrance,
                style: TextStyle(
                  fontSize: 16,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
                ),
              ),

              // Connectivity status indicator
              if (!_isCheckingConnectivity) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        (_hasConnectivity
                                ? AppColors.success
                                : AppColors.warning)
                            .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _hasConnectivity
                          ? AppColors.success
                          : AppColors.warning,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _hasConnectivity ? Icons.wifi : Icons.wifi_off,
                        color: _hasConnectivity
                            ? AppColors.success
                            : AppColors.warning,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        _hasConnectivity ? 'En ligne' : 'Hors ligne',
                        style: TextStyle(
                          color: _hasConnectivity
                              ? AppColors.success
                              : AppColors.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 40),

              // Show QR Code or Button
              if (_isLoading)
                Container(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(height: 20),
                      Text(
                        AppLocalizations.of(context).loadingQrCode,
                        style: TextStyle(
                          color:
                              (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_showQrCode && _qrImageBytes != null)
                Column(
                  children: [
                    // Offline indicator on QR card if applicable
                    if (!_hasConnectivity)
                      Container(
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.info, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.info,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'QR code chargé depuis le cache',
                                style: TextStyle(
                                  color: AppColors.info,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Card(
                      color: Theme.of(context).cardTheme.color,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color:
                                    (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Image.memory(
                                Uint8List.fromList(_qrImageBytes!),
                                width: 250,
                                height: 250,
                                fit: BoxFit.contain,
                              ),
                            ),
                            SizedBox(height: 24),
                            Text(
                              _profileData != null
                                  ? getUserFullName(_profileData!)
                                  : 'Utilisateur',
                              style: TextStyle(
                                color:
                                    (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                _profileData?['displayId'] ?? '',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 3,
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context).presentThisCode,
                              style: TextStyle(
                                color:
                                    (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary)
                                        .withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _toggleQrCode,
                      icon: Icon(Icons.visibility_off, size: 24),
                      label: Text(
                        AppLocalizations.of(context).hideQrCode,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                )
              else
                ElevatedButton.icon(
                  onPressed: _toggleQrCode,
                  icon: Icon(Icons.qr_code_2, size: 32),
                  label: Text(
                    AppLocalizations.of(context).showMyQrCode,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor:
                        (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary),
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),

              if (!_showQrCode && !_isLoading) ...[
                SizedBox(height: 40),
                Text(
                  AppLocalizations.of(context).presentQrToStaff,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== MEMBER SUBSCRIPTION PAGE ====================
class MemberSubscriptionPage extends StatelessWidget {
  const MemberSubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current subscription card
            Card(
              color: Theme.of(context).colorScheme.primary,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context).premiumSubscription,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color:
                                (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            AppLocalizations.of(context).activeStatus,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color:
                                  (Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildSubscriptionDetail(context, 'Type', 'Mensuel'),
                    _buildSubscriptionDetail(context, 'Prix', '50 MAD / mois'),
                    _buildSubscriptionDetail(
                      context,
                      AppLocalizations.of(context).startDate,
                      '1 Nov 2025',
                    ),
                    _buildSubscriptionDetail(
                      context,
                      AppLocalizations.of(context).expirationDate,
                      '31 Déc 2025',
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Payment history
            Text(
              AppLocalizations.of(context).paymentHistory,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary),
              ),
            ),
            SizedBox(height: 16),
            _buildPaymentItem(
              context,
              'Nov 2025',
              '50 MAD',
              '1 Nov 2025',
              true,
            ),
            _buildPaymentItem(
              context,
              'Oct 2025',
              '50 MAD',
              '1 Oct 2025',
              true,
            ),
            _buildPaymentItem(
              context,
              'Sep 2025',
              '50 MAD',
              '1 Sep 2025',
              true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionDetail(
    BuildContext context,
    String label,
    String value,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(
    BuildContext context,
    String month,
    String amount,
    String date,
    bool paid,
  ) {
    return Card(
      color: Theme.of(context).cardTheme.color,
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: paid
                ? Colors.green.withValues(alpha: 0.7)
                : Colors.red.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            paid ? Icons.check_circle : Icons.pending,
            color: paid ? AppColors.success : AppColors.error,
            size: 24,
          ),
        ),
        title: Text(
          month,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: (Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary),
          ),
        ),
        subtitle: Text(
          date,
          style: TextStyle(
            fontSize: 12,
            color: (Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary),
          ),
        ),
        trailing: Text(
          amount,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

// ==================== MEMBER PLANNING PAGE ====================
class MemberPlanningPage extends StatefulWidget {
  const MemberPlanningPage({super.key});

  @override
  State<MemberPlanningPage> createState() => _MemberPlanningPageState();
}

class _MemberPlanningPageState extends State<MemberPlanningPage> {
  final ApiService _apiService = ApiService.fromEnv();
  late final AuthService _authService;
  List<dynamic>? _plannings;
  List<dynamic>? _goals;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  void _showErrorWithRetry(String message, VoidCallback onRetry) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        action: SnackBarAction(
          label: 'Réessayer',
          textColor: Theme.of(context).colorScheme.primary,
          onPressed: onRetry,
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _authService = AuthService(_apiService);
    _loadPlannings();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final token = await _authService.loadToken();
      final profileData = await _authService.getCachedUserProfile();

      if (token == null || profileData == null) {
        return;
      }

      final memberId = profileData['id'] as int;
      final goals = await _apiService.getMemberGoals(memberId, token);

      if (mounted) {
        setState(() {
          _goals = goals;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading goals: $e');
    }
  }

  Future<void> _loadPlannings() async {
    if (_isRefreshing) return; // Prevent multiple refreshes

    setState(() {
      _isLoading = true;
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      final token = await _authService.loadToken();
      final profileData = await _authService.getCachedUserProfile();

      if (token == null || profileData == null) {
        setState(() {
          _errorMessage = AppLocalizations.of(context).sessionExpiredShort;
          _isLoading = false;
          _isRefreshing = false;
        });
        return;
      }

      final memberId = profileData['id'] as int;
      // ignore: avoid_print
      debugPrint('🔍 Loading plannings for member ID: $memberId');

      final response = await _apiService.getMemberPlannings(memberId, token);

      // ignore: avoid_print
      debugPrint('📊 Plannings response: $response');
      // ignore: avoid_print
      debugPrint(
        '📊 Number of plannings: ${(response['plannings'] as List<dynamic>?)?.length ?? 0}',
      );

      setState(() {
        _plannings = response['plannings'] as List<dynamic>?;
        _isLoading = false;
        _isRefreshing = false;
      });

      // Also reload goals when refreshing
      _loadGoals();
    } catch (e) {
      // ignore: avoid_print
      debugPrint('❌ Error loading plannings: $e');
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _loadTodayWorkout() async {
    try {
      final token = await _authService.loadToken();
      final profileData = await _authService.getCachedUserProfile();

      if (token == null || profileData == null) {
        // ignore: avoid_print
        debugPrint('❌ Today workout: No token or profile');
        return null;
      }

      final memberId = profileData['id'] as int;
      // ignore: avoid_print
      debugPrint('🔍 Loading today workout for member ID: $memberId');

      final nextDay = await _apiService.getNextPlanningDay(memberId, token);

      // ignore: avoid_print
      debugPrint('📊 Today workout response: $nextDay');
      // ignore: avoid_print
      debugPrint('📊 Is today: ${nextDay?['isToday']}');

      // Only return if it's today
      if (nextDay != null && nextDay['isToday'] == true) {
        return nextDay;
      }

      // ignore: avoid_print
      debugPrint('ℹ️ No workout for today');
      return null;
    } catch (e) {
      // ignore: avoid_print
      debugPrint('❌ Error loading today workout: $e');
      return null;
    }
  }

  String _formatDateSimple(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateStr.split('T')[0]; // Fallback to simple split
    }
  }

  Widget _buildTodayWorkoutCard(Map<String, dynamic> data) {
    final planning = data['planning'] as Map<String, dynamic>?;
    final day = data['day'] as Map<String, dynamic>?;
    final exercises = day?['exercises'] as List<dynamic>? ?? [];

    return Card(
      color: Theme.of(context).cardTheme.color,
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.play_circle_outline,
                    color: AppColors.success,
                    size: 28,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planning?['title'] ??
                            AppLocalizations.of(context).myWorkout,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary),
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context).today,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Divider(color: Theme.of(context).dividerColor),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  size: 18,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
                ),
                SizedBox(width: 8),
                Text(
                  '${exercises.length} exercice${exercises.length > 1 ? 's' : ''} prévu${exercises.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    color: (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showTodayWorkoutPopup(data),
                icon: Icon(Icons.visibility, size: 18),
                label: Text('Voir les détails'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor:
                      (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTodayWorkoutPopup(Map<String, dynamic> data) {
    final planning = data['planning'] as Map<String, dynamic>?;
    final day = data['day'] as Map<String, dynamic>?;
    final exercises = day?['exercises'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color!,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.fitness_center,
                          color: AppColors.success,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              planning?['title'] ??
                                  AppLocalizations.of(context).myWorkout,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${exercises.length} exercice${exercises.length > 1 ? 's' : ''} • Aujourd\'hui',
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color:
                              (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                // Exercises list
                Flexible(
                  child: exercises.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              AppLocalizations.of(context).noExercisePlanned,
                              style: TextStyle(
                                color:
                                    (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary)
                                        .withValues(alpha: 0.7),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.all(16),
                          itemCount: exercises.length,
                          itemBuilder: (context, index) {
                            final exerciseData =
                                exercises[index] as Map<String, dynamic>;
                            final exercise =
                                exerciseData['exercise']
                                    as Map<String, dynamic>?;
                            final sets = exerciseData['sets'] as int?;
                            final reps = exerciseData['reps'] as int?;
                            final weight = exerciseData['weight'] as num?;
                            final notes = exerciseData['notes'] as String?;

                            return Container(
                              margin: EdgeInsets.only(bottom: 12),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardTheme.color,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          exercise?['name'] ?? 'Exercice',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                (Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? AppColors.darkTextPrimary
                                                : AppColors.lightTextPrimary),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      if (sets != null)
                                        _buildExerciseDetail(
                                          Icons.repeat,
                                          '$sets séries',
                                        ),
                                      if (reps != null)
                                        _buildExerciseDetail(
                                          Icons.fitness_center,
                                          '$reps reps',
                                        ),
                                      if (weight != null && weight > 0)
                                        _buildExerciseDetail(
                                          Icons.monitor_weight,
                                          '$weight kg',
                                        ),
                                    ],
                                  ),
                                  if (notes != null && notes.isNotEmpty) ...[
                                    SizedBox(height: 12),
                                    Container(
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).cardTheme.color,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            size: 16,
                                            color: Colors.blue.shade300,
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              notes,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color:
                                                    (Theme.of(
                                                          context,
                                                        ).brightness ==
                                                        Brightness.dark
                                                    ? AppColors
                                                          .darkTextSecondary
                                                    : AppColors
                                                          .lightTextSecondary),
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _requestHelp(
                                          exercise?['name'] ?? 'Exercice',
                                        );
                                      },
                                      icon: Icon(Icons.help_outline, size: 18),
                                      label: Text(
                                        AppLocalizations.of(
                                          context,
                                        ).requestHelp,
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        side: BorderSide(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isPlanningUpcoming(String startDate) {
    try {
      final start = DateTime.parse(startDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final planningStart = DateTime(start.year, start.month, start.day);

      // Planning is upcoming if start date is in the future
      return planningStart.isAfter(today);
    } catch (e) {
      return false;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.success;
      case 'completed':
        return AppColors.info;
      case 'cancelled':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: RefreshIndicator(
        onRefresh: _loadPlannings,
        color: Theme.of(context).colorScheme.primary,
        notificationPredicate: (notification) => !_isRefreshing,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red.shade300,
                    ),
                    SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadPlannings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: Text(AppLocalizations.of(context).retry),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: EdgeInsets.all(16.0),
                children: [
                  // Goals carousel section
                  if (_goals != null && _goals!.isNotEmpty) ...[
                    Text(
                      AppLocalizations.of(context).myGoals,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary),
                      ),
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: Center(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          // padding: EdgeInsets.symmetric(horizontal: 8),
                          shrinkWrap: true,
                          itemCount: _goals!.length,
                          itemBuilder: (context, index) {
                            final goal = _goals![index] as Map<String, dynamic>;
                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: 0),
                              child: _buildGoalCard(goal, index),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                  ],
                  // Today's workout section
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _loadTodayWorkout(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SizedBox.shrink();
                      }

                      if (snapshot.data != null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🔥 Entraînement du jour',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color:
                                    (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary),
                              ),
                            ),
                            SizedBox(height: 12),
                            _buildTodayWorkoutCard(snapshot.data!),
                            SizedBox(height: 24),
                            Text(
                              AppLocalizations.of(context).myPlannings,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color:
                                    (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary),
                              ),
                            ),
                            SizedBox(height: 12),
                          ],
                        );
                      }

                      return SizedBox.shrink();
                    },
                  ),
                  // All plannings or empty state
                  if (_plannings != null && _plannings!.isNotEmpty)
                    ..._plannings!.map((planning) {
                      final planningData = planning as Map<String, dynamic>;
                      return _buildPlanningCard(planningData);
                    })
                  else
                    // Empty state when no plannings
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fitness_center,
                              size: 80,
                              color:
                                  (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary)
                                      .withValues(alpha: 0.5),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Aucun planning disponible',
                              style: TextStyle(
                                color:
                                    (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Votre coach vous assignera bientôt\nun programme d\'entraînement',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:
                                    (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildPlanningCard(Map<String, dynamic> planning) {
    final title = planning['title'] as String? ?? 'Planning';
    final description = planning['description'] as String?;
    final status = planning['status'] as String? ?? 'active';
    final startDate = planning['startDate'] as String? ?? '';
    final endDate = planning['endDate'] as String? ?? '';
    final coach = planning['coach'] as Map<String, dynamic>?;
    final days = planning['days'] as List<dynamic>? ?? [];

    // Check if planning is in the future (prévu)
    final bool isUpcoming = _isPlanningUpcoming(startDate);

    return Card(
      color: Theme.of(context).cardTheme.color,
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: (Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary),
                    ),
                  ),
                ),
                if (isUpcoming)
                  Container(
                    margin: EdgeInsets.only(right: 8),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warning, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context).upcoming,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            if (description != null) ...[
              SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
                ),
              ),
            ],
            SizedBox(height: 12),

            // Dates
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
                ),
                SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).fromToDates(
                    _formatDateSimple(startDate),
                    _formatDateSimple(endDate),
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
                  ),
                ),
              ],
            ),

            if (coach != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${AppLocalizations.of(context).coach}: ${getUserFullName(coach)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: (Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                    ),
                  ),
                ],
              ),
            ],

            SizedBox(height: 12),

            // Days summary
            Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).trainingDays(days.length),
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color:
                      (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary)
                          .withValues(alpha: 0.8),
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseDetail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: (Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal, int index) {
    final goalTitle = goal['title'] as String? ?? 'Objectif';
    final goalDescription = goal['description'] as String? ?? '';
    final startWeight = goal['startWeight'] as num?;
    final startWaist = goal['startWaist'] as num?;
    final targetWeight = goal['targetWeight'] as num?;
    final targetWaist = goal['targetWaist'] as num?;
    final targetDate = goal['targetDate'] as String?;
    final achievedAt = goal['achievedAt'] as String?;
    final status = goal['status'] as String? ?? 'active';

    // Define ultra-modern gradient colors based on index
    final List<List<Color>> gradients = [
      [Color(0xFF8B5CF6), Color(0xFFEC4899)], // Purple to Pink - Vibrant
      [Color(0xFF06B6D4), Color(0xFF3B82F6)], // Cyan to Blue - Fresh
      [Color(0xFFF59E0B), Color(0xFFEF4444)], // Amber to Red - Energy
      [Color(0xFF10B981), Color(0xFF059669)], // Emerald to Green - Growth
      [Color(0xFFEC4899), Color(0xFF8B5CF6)], // Pink to Purple - Dynamic
    ];

    final gradientColors = gradients[index % gradients.length];

    // Status configuration
    IconData statusIcon;
    String statusText;
    Color statusBgColor;

    switch (status) {
      case 'achieved':
        statusIcon = Icons.stars_rounded;
        statusText = 'Atteint';
        statusBgColor = Color(0xFF10B981);
        break;
      case 'in_progress':
        statusIcon = Icons.trending_up_rounded;
        statusText = 'En cours';
        statusBgColor = Color(0xFFF59E0B);
        break;
      case 'active':
      default:
        statusIcon = Icons.flag_rounded;
        statusText = 'Actif';
        statusBgColor = Color(0xFF3B82F6);
        break;
    }

    return GestureDetector(
      onTap: () => _showGoalDetailsModal(
        goal,
        gradientColors,
        statusIcon,
        statusText,
        statusBgColor,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final cardWidth = screenWidth - (16 * 2); // padding left/right

          return Container(
            width: cardWidth,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles in background
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -25,
                      left: -15,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row: badge + title + icon
                          Row(
                            children: [
                              // Status badge compact
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusBgColor.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      statusIcon,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      statusText,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 12),
                              // Title
                              Expanded(
                                child: Text(
                                  goalTitle,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 8),
                              // Icon
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.fitness_center_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          // Description
                          if (goalDescription.isNotEmpty)
                            Text(
                              goalDescription,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.9),
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          SizedBox(height: 12),
                          // Measurements compact horizontal
                          if (startWeight != null || startWaist != null)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  if (startWeight != null)
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.monitor_weight_rounded,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              '$startWeight',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: 2),
                                            Text(
                                              'kg',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white.withValues(
                                                  alpha: 0.8,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  if (startWeight != null && startWaist != null)
                                    Container(
                                      width: 1,
                                      height: 20,
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  if (startWaist != null)
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.straighten_rounded,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              '$startWaist',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: 2),
                                            Text(
                                              'cm',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white.withValues(
                                                  alpha: 0.8,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          // Target measurements
                          if (targetWeight != null || targetWaist != null) ...[
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  if (targetWeight != null)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.flag_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          '$targetWeight',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 2),
                                        Text(
                                          'kg',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white.withValues(
                                              alpha: 0.8,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (targetWeight != null &&
                                      targetWaist != null)
                                    Container(
                                      width: 1,
                                      height: 16,
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  if (targetWaist != null)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.flag_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          '$targetWaist',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 2),
                                        Text(
                                          'cm',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white.withValues(
                                              alpha: 0.8,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                          // Dates (sans createdAt)
                          if (achievedAt != null || targetDate != null) ...[
                            SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  size: 14,
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    achievedAt != null
                                        ? 'Atteint le ${_formatDateShort(achievedAt)}'
                                        : 'Objectif: ${_formatDateShort(targetDate!)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDateShort(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  void _showGoalDetailsModal(
    Map<String, dynamic> goal,
    List<Color> gradientColors,
    IconData statusIcon,
    String statusText,
    Color statusBgColor,
  ) {
    final goalTitle = goal['title'] as String? ?? 'Objectif';
    final goalDescription = goal['description'] as String? ?? '';
    final startWeight = goal['startWeight'] as num?;
    final startWaist = goal['startWaist'] as num?;
    final targetWeight = goal['targetWeight'] as num?;
    final targetWaist = goal['targetWaist'] as num?;
    final targetDate = goal['targetDate'] as String?;
    final createdAt = goal['createdAt'] as String?;
    final achievedAt = goal['achievedAt'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            // Content
            Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: statusBgColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 16, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.fitness_center_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        SizedBox(height: 20),
                        // Title
                        Text(
                          goalTitle,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 16),
                        // Description
                        if (goalDescription.isNotEmpty) ...[
                          Text(
                            goalDescription,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.95),
                              height: 1.6,
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                        // Dates
                        if (createdAt != null ||
                            targetDate != null ||
                            achievedAt != null) ...[
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (createdAt != null)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Créé le ${_formatDate(createdAt)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (createdAt != null && targetDate != null)
                                  SizedBox(height: 8),
                                if (targetDate != null)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.flag_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Objectif: ${_formatDate(targetDate)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                if ((createdAt != null || targetDate != null) &&
                                    achievedAt != null)
                                  SizedBox(height: 8),
                                if (achievedAt != null)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.stars_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Atteint le ${_formatDate(achievedAt)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                        // Measurements section
                        if (startWeight != null ||
                            startWaist != null ||
                            targetWeight != null ||
                            targetWaist != null) ...[
                          Text(
                            'Mesures',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 12),
                        ],
                        // Start measurements
                        if (startWeight != null || startWaist != null)
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  ).startingMeasurements,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    if (startWeight != null)
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.monitor_weight_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              '$startWeight kg',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (startWaist != null)
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.straighten_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              '$startWaist cm',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
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
                        SizedBox(height: 12),
                        // Target measurements
                        if (targetWeight != null || targetWaist != null)
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  goalTitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    if (targetWeight != null)
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.monitor_weight_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              '$targetWeight kg',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (targetWaist != null)
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.straighten_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              '$targetWaist cm',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
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
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Fév',
        'Mar',
        'Avr',
        'Mai',
        'Jun',
        'Jul',
        'Aoû',
        'Sep',
        'Oct',
        'Nov',
        'Déc',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _requestHelp(String exerciseName) async {
    try {
      final token = await _authService.loadToken();
      final profileData = await _authService.getCachedUserProfile();

      if (token == null || profileData == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).sessionExpiredShort),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final memberName = getUserFullName(profileData);

      // Show confirmation dialog
      if (!mounted) return;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          title: Text(
            'Demander de l\'aide',
            style: TextStyle(
              color: (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary),
            ),
          ),
          content: Text(
            'Voulez-vous notifier les coachs de votre salle pour obtenir de l\'aide avec "$exerciseName" ?',
            style: TextStyle(
              color: (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Confirmer'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Show loading
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Text('Envoi de la demande...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Send help request
      final success = await _apiService.requestExerciseHelp(
        exerciseName,
        token,
        notes: 'Demande d\'aide de $memberName',
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Les coachs ont été notifiés ! Ils viendront vous aider.',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        _showErrorWithRetry(
          'Une erreur est survenue',
          () => _requestHelp(exerciseName),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Error requesting help: $e');
      if (!mounted) return;
      _showErrorWithRetry(
        'Une erreur est survenue',
        () => _requestHelp(exerciseName),
      );
    }
  }
}

// ==================== MEMBER PROFILE PAGE ====================
class MemberProfilePage extends StatefulWidget {
  const MemberProfilePage({super.key});

  @override
  State<MemberProfilePage> createState() => _MemberProfilePageState();
}

class _MemberProfilePageState extends State<MemberProfilePage> {
  final _authService = AuthService(ApiService.fromEnv());
  final _apiService = ApiService.fromEnv();
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _subscriptionData;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isLoadingSubscription = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadSubscription();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    // Try to load from cache first
    final cachedData = await _authService.getCachedUserProfile();

    if (cachedData != null) {
      setState(() {
        _profileData = cachedData;
        _isLoading = false;
      });

      // Check if cache is stale and refresh in background
      final isStale = await _authService.isProfileCacheStale();
      if (isStale) {
        _refreshProfileDataSilently();
      }
    } else {
      // No cache, fetch from API
      await _refreshProfileData();
    }
  }

  Future<void> _refreshProfileData() async {
    if (_isRefreshing) return; // Prevent multiple refreshes

    setState(() => _isRefreshing = true);

    try {
      final freshData = await _authService.refreshUserProfile();

      if (mounted) {
        setState(() {
          if (freshData != null) {
            _profileData = freshData;
          }
          _isLoading = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _refreshProfileDataSilently() async {
    final freshData = await _authService.refreshUserProfile();
    if (mounted && freshData != null) {
      setState(() => _profileData = freshData);
    }
  }

  Future<void> _loadSubscription() async {
    try {
      final token = await _authService.loadToken();
      final profile = await _authService.getCachedUserProfile();
      final memberId = profile?['id'];

      if (token == null || memberId == null) {
        setState(() {
          _isLoadingSubscription = false;
        });
        return;
      }

      // Charger les abonnements du membre
      final subscriptions = await _apiService.getMemberSubscriptions(
        memberId,
        token,
      );

      if (subscriptions != null && subscriptions.isNotEmpty) {
        // Prendre le premier abonnement actif
        final activeSubscription =
            subscriptions.firstWhere(
                  (sub) => (sub as Map<String, dynamic>)['status'] == 'active',
                  orElse: () => subscriptions.first,
                )
                as Map<String, dynamic>?;

        if (activeSubscription != null) {
          // Charger les détails complets
          final subscriptionId = activeSubscription['id'];
          final fullSubscription = await _apiService.getSubscriptionById(
            subscriptionId,
            token,
          );

          if (mounted) {
            setState(() {
              _subscriptionData = fullSubscription ?? activeSubscription;
              _isLoadingSubscription = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoadingSubscription = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingSubscription = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSubscription = false;
        });
      }
    }
  }

  void _navigateToEditProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          profileData: _profileData,
          onProfileUpdated: _refreshProfileDataSilently,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
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
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    // Extract data from cache
    final fullName = _profileData != null
        ? getUserFullName(_profileData!)
        : 'Utilisateur';
    final email = _profileData?['email'] ?? 'email@exemple.com';
    final phoneNumber = _profileData?['phoneNumber'] ?? '';
    final joinedAt = _profileData?['joinedAt'] ?? 'N/A';

    // Extract member data
    final member = _profileData?['member'] as Map<String, dynamic>?;
    final firstName = member?['firstName'] ?? '';
    final lastName = member?['lastName'] ?? '';
    final birthDate = member?['birthDate'] as String?;
    final profession = member?['profession'] ?? '';
    final fitnessLevel = member?['fitnessLevel'] ?? '';
    final profileImageBase64 =
        _profileData?['profileImage'] as String? ??
        member?['profileImage'] as String?;

    // Format birth date
    String formattedBirthDate = AppLocalizations.of(context).notSpecified;
    if (birthDate != null && birthDate.isNotEmpty) {
      try {
        final date = DateTime.parse(birthDate);
        final l10n = AppLocalizations.of(context);
        formattedBirthDate =
            '${date.day} ${l10n.getMonthName(date.month)} ${date.year}';
      } catch (e) {
        formattedBirthDate = birthDate;
      }
    }

    // Format fitness level
    final l10n = AppLocalizations.of(context);
    final fitnessLevelLabels = {
      'debutant': l10n.fitnessBeginner,
      'intermediaire': l10n.fitnessIntermediate,
      'avance': l10n.fitnessAdvanced,
      'expert': l10n.fitnessExpert,
      'athletique': l10n.fitnessAthletic,
    };
    final formattedFitnessLevel =
        fitnessLevelLabels[fitnessLevel] ?? fitnessLevel;

    // Handle both 'subscription' (singular) and 'subscriptions' (plural array)
    Map<String, dynamic>? subscription;
    final subscriptions = _profileData?['subscriptions'] as List<dynamic>?;
    if (subscriptions != null && subscriptions.isNotEmpty) {
      // Get the first active subscription or just the first one
      subscription =
          subscriptions.firstWhere(
                (sub) => (sub as Map<String, dynamic>)['status'] == 'active',
                orElse: () => subscriptions.first,
              )
              as Map<String, dynamic>;
    } else {
      subscription = _profileData?['subscription'] as Map<String, dynamic>?;
    }

    return Container(
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
      child: RefreshIndicator(
        onRefresh: _refreshProfileData,
        color: Theme.of(context).colorScheme.primary,
        notificationPredicate: (notification) => !_isRefreshing,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header - Full width, clickable
              SizedBox(
                width: double.infinity,
                child: InkWell(
                  onTap: () => _navigateToEditProfile(context),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).cardTheme.color!,
                          Theme.of(
                            context,
                          ).cardTheme.color!.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              backgroundImage:
                                  profileImageBase64 != null &&
                                      profileImageBase64.isNotEmpty
                                  ? MemoryImage(
                                      base64Decode(
                                        profileImageBase64.contains('base64,')
                                            ? profileImageBase64.split(
                                                'base64,',
                                              )[1]
                                            : profileImageBase64,
                                      ),
                                    )
                                  : null,
                              child:
                                  (profileImageBase64 == null ||
                                      profileImageBase64.isEmpty)
                                  ? Icon(
                                      Icons.person,
                                      size: 50,
                                      color:
                                          (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).scaffoldBackgroundColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Text(
                          '$firstName $lastName'.trim().isNotEmpty
                              ? '$firstName $lastName'
                              : fullName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color:
                                (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary),
                          ),
                        ),
                        SizedBox(height: 8),
                        if (email.isNotEmpty && email != 'email@exemple.com')
                          Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.email,
                                  size: 14,
                                  color:
                                      (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (phoneNumber.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: 14,
                                  color:
                                      (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  phoneNumber,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context).memberSince(joinedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                (Theme.of(context).brightness == Brightness.dark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary)
                                    .withValues(alpha: 0.7),
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                AppLocalizations.of(context).editProfile,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Subscription section
              Text(
                AppLocalizations.of(context).mySubscription,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
                ),
              ),
              SizedBox(height: 12),

              // Check if user has a subscription
              if (_isLoadingSubscription)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
              else if (_subscriptionData != null)
                Builder(
                  builder: (context) {
                    final data = _subscriptionData!;
                    print('📋 [SUBSCRIPTION CARD] data: $data');

                    final sub = data['subscription'] as Map<String, dynamic>?;
                    final subscriptionTypeData =
                        sub?['SubscriptionType'] as Map<String, dynamic>?;
                    print('📋 [SUBSCRIPTION CARD] sub: $sub');
                    print(
                      '📋 [SUBSCRIPTION CARD] subscriptionTypeData: $subscriptionTypeData',
                    );

                    final subscriptionTypeName =
                        subscriptionTypeData?['name'] ?? 'Abonnement';
                    final monthlyPrice =
                        subscriptionTypeData?['monthlyPrice'] ?? 0;
                    final durationMonths =
                        subscriptionTypeData?['durationMonths'] ?? 1;
                    final subscriptionStatus = sub?['status'] ?? 'unknown';
                    final startDate = sub?['startDate'] ?? 'N/A';
                    final expiresAt =
                        sub?['endDate'] ?? sub?['expiresAt'] ?? 'N/A';

                    print(
                      '📋 [SUBSCRIPTION CARD] name: $subscriptionTypeName, price: $monthlyPrice, duration: $durationMonths',
                    );
                    print(
                      '📋 [SUBSCRIPTION CARD] status: $subscriptionStatus, start: $startDate, expires: $expiresAt',
                    );

                    // Formater les dates
                    String formatDate(String dateStr) {
                      if (dateStr == 'N/A') return 'N/A';
                      try {
                        final date = DateTime.parse(dateStr);
                        final months = [
                          'janvier',
                          'février',
                          'mars',
                          'avril',
                          'mai',
                          'juin',
                          'juillet',
                          'août',
                          'septembre',
                          'octobre',
                          'novembre',
                          'décembre',
                        ];
                        return '${date.day} ${months[date.month - 1]} ${date.year}';
                      } catch (e) {
                        return dateStr;
                      }
                    }

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubscriptionDetailsScreen(
                              subscriptionData: _subscriptionData,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        color: Theme.of(context).colorScheme.primary,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      subscriptionTypeName,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: subscriptionStatus == 'active'
                                          ? AppColors.success
                                          : AppColors.error,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      subscriptionStatus.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              _buildSubscriptionDetail(
                                context,
                                'Type',
                                durationMonths == 12 ? 'Annuel' : 'Mensuel',
                              ),
                              _buildSubscriptionDetail(
                                context,
                                'Prix',
                                '$monthlyPrice MAD / mois',
                              ),
                              _buildSubscriptionDetail(
                                context,
                                'Date de début',
                                formatDate(startDate),
                              ),
                              _buildSubscriptionDetail(
                                context,
                                'Expire le',
                                formatDate(expiresAt),
                              ),
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Voir les détails',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          (Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? AppColors.darkTextSecondary
                                                  : AppColors
                                                        .lightTextSecondary)
                                              .withValues(alpha: 1.0),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color:
                                        (Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.lightTextSecondary)
                                            .withValues(alpha: 1.0),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )
              else
                Card(
                  color: Theme.of(context).cardTheme.color,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.card_membership_outlined,
                          size: 64,
                          color:
                              (Theme.of(context).brightness == Brightness.dark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary)
                                  .withValues(alpha: 0.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context).noActiveSubscription,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context).subscribeForFeatures,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 24),

              // Personal Information Section
              Text(
                AppLocalizations.of(context).personalInfo,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
                ),
              ),
              SizedBox(height: 12),
              Card(
                color: Theme.of(context).cardTheme.color,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      if (formattedBirthDate !=
                          AppLocalizations.of(context).notSpecified)
                        _buildInfoRow(
                          context,
                          Icons.cake,
                          AppLocalizations.of(context).birthDate,
                          formattedBirthDate,
                          isLast:
                              (profession.isEmpty || profession == 'Actif') &&
                              formattedFitnessLevel.isEmpty,
                        ),
                      if (profession.isNotEmpty && profession != 'Actif')
                        _buildInfoRow(
                          context,
                          Icons.work,
                          AppLocalizations.of(context).profession,
                          profession,
                          isLast: formattedFitnessLevel.isEmpty,
                        ),
                      if (formattedFitnessLevel.isNotEmpty)
                        _buildInfoRow(
                          context,
                          Icons.fitness_center,
                          AppLocalizations.of(context).fitnessLevel,
                          formattedFitnessLevel,
                          isLast: true,
                        ),
                      // Show message if no info available
                      if (formattedBirthDate ==
                              AppLocalizations.of(context).notSpecified &&
                          (profession.isEmpty || profession == 'Actif') &&
                          formattedFitnessLevel.isEmpty)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 48,
                                  color:
                                      (Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary)
                                          .withValues(alpha: 0.5),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Aucune information personnelle renseignée',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Settings options
              Text(
                AppLocalizations.of(context).parameters,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
                ),
              ),
              SizedBox(height: 12),
              _buildSettingsItem(
                context,
                AppLocalizations.of(context).parameters,
                Icons.settings,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SecuritySettingsPage(),
                    ),
                  );
                },
              ),
              _buildSettingsItem(
                context,
                AppLocalizations.of(context).about,
                Icons.info_outline,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AboutScreen()),
                  );
                },
              ),
              _buildSettingsItem(
                context,
                AppLocalizations.of(context).helpSupport,
                Icons.help_outline,
                () {},
              ),
              SizedBox(height: 16),

              // Logout button
              Card(
                color: AppColors.error,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.logout,
                    color: (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary),
                  ),
                  title: Text(
                    AppLocalizations.of(context).disconnect,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: (Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary),
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary),
                    size: 16,
                  ),
                  onTap: () async {
                    // Vider le cache du profil mais garder les credentials pour biométrie
                    await _authService.clearProfileCache();
                    await _authService.clearAll();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionDetail(
    BuildContext context,
    String label,
    String value,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color:
                (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary)
                    .withValues(alpha: 0.2),
          ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      color: Theme.of(context).cardTheme.color,
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: (Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color:
              (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary)
                  .withValues(alpha: 0.8),
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}
