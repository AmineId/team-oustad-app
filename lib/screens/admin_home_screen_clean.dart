import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/responsive_layout.dart';
import 'login_screen.dart';
import 'admin_create_member_screen.dart';
import 'admin_members_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;
  bool _isOwner = false;
  final AuthService _authService = AuthService(ApiService.fromEnv());

  List<Widget> get _pages => _isOwner
      ? [
          const AccueilPage(),
          const GestionPage(),
          const GestionGlobalePage(),
          const ProfilePage(),
        ]
      : [
          const AccueilPage(),
          const GestionPage(),
          const ProfilePage(),
        ];

  List<String> get _titles => _isOwner
      ? [
          'Accueil',
          'Gestion',
          'Gestion Globale',
          'Profile',
        ]
      : [
          'Accueil',
          'Gestion',
          'Profile',
        ];

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final isOwner = await _authService.isOwner();
    setState(() {
      _isOwner = isOwner;
    });
  }

  Future<void> _showQrCode() async {
    // Récupérer l'ID de l'utilisateur depuis le cache
    final profileData = await _authService.getCachedUserProfile();
    if (profileData == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Une erreur est survenue'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: const Color(0xFFe89547),
            onPressed: _showQrCode,
          ),
        ),
      );
      return;
    }

    final userId = profileData['id'] as int;
    final token = await _authService.loadToken();
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Une erreur est survenue'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: const Color(0xFFe89547),
            onPressed: _showQrCode,
          ),
        ),
      );
      return;
    }

    // Afficher le dialog avec loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF2d3748),
        title: const Text(
          'Mon QR Code',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 250,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFe89547),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Chargement du QR code...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Charger le QR code
      final qrImageBytes = await ApiService.fromEnv().getUserQrCode(userId, token);
      
      if (!mounted) return;
      
      // Fermer le dialog de loading
      Navigator.of(context).pop();
      
      if (qrImageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Une erreur est survenue'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: const Color(0xFFe89547),
              onPressed: _showQrCode,
            ),
          ),
        );
        return;
      }

      // Afficher le QR code
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF2d3748),
          title: const Text(
            'Mon QR Code',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.memory(
                  Uint8List.fromList(qrImageBytes),
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                profileData['fullName'] ?? 'Utilisateur',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFe89547).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFe89547).withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  profileData['displayId'] ?? '',
                  style: const TextStyle(
                    color: Color(0xFFe89547),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Présentez ce code à l\'entrée',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Fermer',
                style: TextStyle(color: Color(0xFFe89547), fontSize: 16),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      // Fermer le dialog de loading s'il est encore ouvert
      Navigator.of(context).pop();
      
      // Afficher l'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Une erreur est survenue'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: const Color(0xFFe89547),
            onPressed: _showQrCode,
          ),
        ),
      );
    }
  }


  List<NavigationItem> get _navigationItems => _isOwner
      ? const [
          NavigationItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Accueil',
          ),
          NavigationItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: 'Gestion',
          ),
          NavigationItem(
            icon: Icons.admin_panel_settings_outlined,
            activeIcon: Icons.admin_panel_settings,
            label: 'Gestion Globale',
          ),
          NavigationItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ]
      : const [
          NavigationItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Accueil',
          ),
          NavigationItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: 'Gestion',
          ),
          NavigationItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: _titles[_currentIndex],
      navigationItems: _navigationItems,
      currentIndex: _currentIndex,
      onNavigationChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      body: _pages[_currentIndex],
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_2),
          onPressed: _showQrCode,
          tooltip: 'Mon QR Code',
        ),
      ],
    );
  }
}

// Page Accueil
class AccueilPage extends StatelessWidget {
  const AccueilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1a1f2e),
            const Color(0xFF2d3748),
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 600;
              final isWatch = constraints.maxWidth < 300;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistiques - responsive grid
                  _buildStatsGrid(isDesktop, isWatch),
                  
                  SizedBox(height: isWatch ? 16 : 32),
                  
                  // Actions rapides
                  Text(
                    'Actions rapides',
                    style: TextStyle(
                      fontSize: isWatch ? 14 : (isDesktop ? 24 : 20),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: isWatch ? 8 : 16),
                  _buildQuickActions(isDesktop, isWatch),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(bool isDesktop, bool isWatch) {
    final stats = [
      _StatCard(
        icon: Icons.people,
        title: 'Membres',
        value: '156',
        color: const Color(0xFFe89547),
      ),
      _StatCard(
        icon: Icons.fitness_center,
        title: 'Actifs',
        value: '89',
        color: Colors.green,
      ),
      _StatCard(
        icon: Icons.calendar_today,
        title: 'Aujourd\'hui',
        value: '23',
        color: Colors.blue,
      ),
      _StatCard(
        icon: Icons.trending_up,
        title: 'Revenus',
        value: '12.5K',
        color: Colors.purple,
      ),
    ];

    if (isWatch) {
      // Watch: single column
      return Column(
        children: stats.map((stat) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: stat,
        )).toList(),
      );
    } else if (isDesktop) {
      // Desktop: 4 columns
      return Row(
        children: stats.map((stat) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: stat,
          ),
        )).toList(),
      );
    } else {
      // Mobile: 2x2 grid
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: stats[0]),
              const SizedBox(width: 16),
              Expanded(child: stats[1]),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: stats[2]),
              const SizedBox(width: 16),
              Expanded(child: stats[3]),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildQuickActions(bool isDesktop, bool isWatch) {
    return Builder(
      builder: (context) {
        final actions = [
          _QuickActionButton(
            icon: Icons.person_add,
            title: 'Nouveau membre',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminCreateMemberScreen(),
                ),
              );
            },
          ),
          _QuickActionButton(
            icon: Icons.payment,
            title: 'Enregistrer un paiement',
            onTap: () {
              // TODO: Navigate to payment screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité en développement')),
              );
            },
          ),
          // Scanner only on mobile (not available on desktop)
          if (!isDesktop)
            _QuickActionButton(
              icon: Icons.qr_code_scanner,
              title: 'Scanner une carte',
              onTap: () {
                // TODO: Navigate to QR scanner
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Scanner non disponible')),
                );
              },
            ),
        ];

        if (isDesktop) {
          // Desktop: 2 columns (without scanner)
          return Row(
            children: actions.map((action) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: action,
              ),
            )).toList(),
          );
        } else {
          // Mobile & Watch: single column
          return Column(
            children: actions.map((action) => Padding(
              padding: EdgeInsets.only(bottom: isWatch ? 8 : 12),
              child: action,
            )).toList(),
          );
        }
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWatch = constraints.maxWidth < 150;
        
        return Container(
          padding: EdgeInsets.all(isWatch ? 8 : 16),
          decoration: BoxDecoration(
            color: const Color(0xFF2d3748),
            borderRadius: BorderRadius.circular(isWatch ? 8 : 16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: isWatch
              ? Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 9,
                            ),
                          ),
                          Text(
                            value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: color, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWatch = constraints.maxWidth < 300;
        
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(isWatch ? 8 : 24),
          child: Container(
            padding: EdgeInsets.all(isWatch ? 8 : 16),
            decoration: BoxDecoration(
              color: const Color(0xFF2d3748),
              borderRadius: BorderRadius.circular(isWatch ? 8 : 24),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isWatch ? 8 : 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFe89547).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFFe89547),
                    size: isWatch ? 16 : 24,
                  ),
                ),
                SizedBox(width: isWatch ? 8 : 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isWatch ? 11 : 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white60,
                  size: isWatch ? 12 : 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Page Gestion - Navigation vers la gestion des membres
class GestionPage extends StatelessWidget {
  const GestionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) => const AdminMembersScreen(),
      ),
    );
  }
}

// Page Ajout Membre
class AjoutMembrePage extends StatelessWidget {
  const AjoutMembrePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1a1f2e),
            const Color(0xFF2d3748),
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ajouter un nouveau membre',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: Icon(Icons.person, color: Color(0xFFe89547)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email, color: Color(0xFFe89547)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone, color: Color(0xFFe89547)),
                ),
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fonctionnalité à implémenter')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: const Text(
                    'Enregistrer',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Page Profile
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1a1f2e),
            const Color(0xFF2d3748),
          ],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 600;
            
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 600 : double.infinity),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isDesktop ? 48.0 : 24.0),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: isDesktop ? 120 : 100,
                        height: isDesktop ? 120 : 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFe89547).withValues(alpha: 0.2),
                          border: Border.all(color: const Color(0xFFe89547), width: 3),
                        ),
                        child: Icon(
                          Icons.person,
                          size: isDesktop ? 60 : 50,
                          color: const Color(0xFFe89547),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Administrateur',
                        style: TextStyle(
                          fontSize: isDesktop ? 32 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'admin@gymmanager.com',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white60,
                        ),
                      ),
                      SizedBox(height: isDesktop ? 48 : 32),
                      
                      // Card with options
                      Card(
                        color: const Color(0xFF2d3748),
                        child: Column(
                          children: [
                            _ProfileOption(
                              icon: Icons.edit,
                              title: 'Modifier le profil',
                              onTap: () {},
                            ),
                            const Divider(color: Colors.white24, height: 1),
                            _ProfileOption(
                              icon: Icons.lock,
                              title: 'Changer le mot de passe',
                              onTap: () {},
                            ),
                            const Divider(color: Colors.white24, height: 1),
                            _ProfileOption(
                              icon: Icons.notifications,
                              title: 'Notifications',
                              onTap: () {},
                            ),
                            const Divider(color: Colors.white24, height: 1),
                            _ProfileOption(
                              icon: Icons.help_outline,
                              title: 'Aide & Support',
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isDesktop ? 32 : 24),
                      
                      // Déconnexion
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final apiService = ApiService.fromEnv();
                            final authService = AuthService(apiService);
                            
                            await authService.setBiometricEnabled(false);
                            
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                                (route) => false,
                              );
                            }
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text(
                            'Déconnexion',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(
                              vertical: isDesktop ? 20 : 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Page Gestion Globale (Owner uniquement)
class GestionGlobalePage extends StatefulWidget {
  const GestionGlobalePage({super.key});

  @override
  State<GestionGlobalePage> createState() => _GestionGlobalePageState();
}

class _GestionGlobalePageState extends State<GestionGlobalePage> {
  String _currentView = 'menu'; // 'menu', 'admins', 'gyms', 'admin_details', 'gym_details', 'admin_edit', 'gym_edit', 'gym_hours', 'admin_create', 'gym_create'
  Map<String, dynamic>? _selectedAdmin;
  Map<String, dynamic>? _selectedGym;

  @override
  Widget build(BuildContext context) {
    // Afficher la vue appropriée
    if (_currentView == 'admins') {
      return _AdminsListView(
        onBack: () => setState(() => _currentView = 'menu'),
        onAdminTap: (admin) => setState(() {
          _selectedAdmin = admin;
          _currentView = 'admin_details';
        }),
        onCreate: () => setState(() => _currentView = 'admin_create'),
      );
    } else if (_currentView == 'gyms') {
      return _GymsListView(
        onBack: () => setState(() => _currentView = 'menu'),
        onGymTap: (gym) => setState(() {
          _selectedGym = gym;
          _currentView = 'gym_details';
        }),
        onCreate: () => setState(() => _currentView = 'gym_create'),
      );
    } else if (_currentView == 'admin_details' && _selectedAdmin != null) {
      return _AdminDetailsView(
        admin: _selectedAdmin!,
        onBack: () => setState(() => _currentView = 'admins'),
        onEdit: () => setState(() => _currentView = 'admin_edit'),
      );
    } else if (_currentView == 'gym_details' && _selectedGym != null) {
      return _GymDetailsView(
        gym: _selectedGym!,
        onBack: () => setState(() => _currentView = 'gyms'),
        onEdit: () => setState(() => _currentView = 'gym_edit'),
        onManageHours: () => setState(() => _currentView = 'gym_hours'),
      );
    } else if (_currentView == 'admin_edit' && _selectedAdmin != null) {
      return _AdminEditView(
        admin: _selectedAdmin!,
        onBack: () => setState(() => _currentView = 'admin_details'),
        onSuccess: () => setState(() => _currentView = 'admin_details'),
      );
    } else if (_currentView == 'gym_edit' && _selectedGym != null) {
      return _GymEditView(
        gym: _selectedGym!,
        onBack: () => setState(() => _currentView = 'gym_details'),
        onSuccess: () => setState(() => _currentView = 'gym_details'),
      );
    } else if (_currentView == 'gym_hours' && _selectedGym != null) {
      return _GymOpeningHoursView(
        gym: _selectedGym!,
        onBack: () => setState(() => _currentView = 'gym_details'),
      );
    } else if (_currentView == 'admin_create') {
      return _AdminCreateView(
        onBack: () => setState(() => _currentView = 'admins'),
        onSuccess: () => setState(() => _currentView = 'admins'),
      );
    } else if (_currentView == 'gym_create') {
      return _GymCreateView(
        onBack: () => setState(() => _currentView = 'gyms'),
        onSuccess: () => setState(() => _currentView = 'gyms'),
      );
    }

    // Vue menu par défaut
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1a1f2e),
            const Color(0xFF2d3748),
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gestion Globale',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Administration système',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32),

              // Gestion des Admins
              _buildGlobalOption(
                context,
                icon: Icons.admin_panel_settings,
                title: 'Gestion des Admins',
                description: 'Ajouter, modifier ou supprimer des administrateurs',
                onTap: () => setState(() => _currentView = 'admins'),
              ),
              const SizedBox(height: 16),

              // Gestion des Salles
              _buildGlobalOption(
                context,
                icon: Icons.fitness_center,
                title: 'Gestion des Salles',
                description: 'Créer, modifier ou supprimer des salles de sport',
                onTap: () => setState(() => _currentView = 'gyms'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2d3748),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFe89547).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFe89547).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFe89547),
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white60,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// Vue pour la liste des admins
class _AdminsListView extends StatefulWidget {
  final VoidCallback onBack;
  final Function(Map<String, dynamic>) onAdminTap;
  final VoidCallback onCreate;

  const _AdminsListView({
    required this.onBack,
    required this.onAdminTap,
    required this.onCreate,
  });

  @override
  State<_AdminsListView> createState() => _AdminsListViewState();
}

class _AdminsListViewState extends State<_AdminsListView> {
  final ApiService _apiService = ApiService.fromEnv();
  final AuthService _authService = AuthService(ApiService.fromEnv());
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _filteredAdmins = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAdmins();
    _searchController.addListener(_filterAdmins);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAdmins() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await _authService.loadToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'Token non disponible';
          _isLoading = false;
        });
        return;
      }

      final users = await _apiService.getUsers(token);
      
      if (users != null) {
        setState(() {
          // Ne lister QUE les admins, PAS les owners
          _admins = users
              .where((user) => user['role'] == 'admin' && user['role'] != 'owner')
              .map((user) => user as Map<String, dynamic>)
              .toList();
          _filteredAdmins = _admins;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Impossible de charger les administrateurs';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  void _filterAdmins() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredAdmins = _admins;
      } else {
        _filteredAdmins = _admins.where((admin) {
          final fullName = (admin['fullName'] as String? ?? '').toLowerCase();
          final email = (admin['email'] as String? ?? '').toLowerCase();
          final role = (admin['role'] as String? ?? '').toLowerCase();
          return fullName.contains(query) || 
                 email.contains(query) || 
                 role.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1a1f2e),
            const Color(0xFF2d3748),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header avec bouton retour
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: widget.onBack,
                  ),
                  const Text(
                    'Administrateurs',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add, color: Color(0xFFe89547)),
                    onPressed: widget.onCreate,
                  ),
                ],
              ),
            ),
            
            // Barre de recherche
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Rechercher un administrateur...',
                  hintStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFe89547)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white60),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF2d3748),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Liste des administrateurs
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFe89547),
                      ),
                    )
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadAdmins,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        )
                      : _filteredAdmins.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.admin_panel_settings_outlined,
                                    color: Colors.white60,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchController.text.isNotEmpty
                                        ? 'Aucun administrateur trouvé'
                                        : 'Aucun administrateur',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadAdmins,
                              color: const Color(0xFFe89547),
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _filteredAdmins.length,
                                itemBuilder: (context, index) {
                                  final admin = _filteredAdmins[index];
                                  return _buildAdminCard(admin, () => widget.onAdminTap(admin));
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(Map<String, dynamic> admin, VoidCallback onTap) {
    final fullName = admin['fullName'] as String? ?? 'Sans nom';
    final email = admin['email'] as String? ?? '';
    final role = admin['role'] as String? ?? 'N/A';
    
    final initials = fullName
        .split(' ')
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();

    final roleBadge = role == 'owner' ? 'Propriétaire' : role == 'admin' ? 'Administrateur' : role;
    final roleColor = role == 'owner' ? Colors.purple : const Color(0xFFe89547);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF2d3748),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: roleColor.withValues(alpha: 0.2),
                  border: Border.all(color: roleColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        roleBadge,
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white60, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// Vue pour la liste des salles
class _GymsListView extends StatefulWidget {
  final VoidCallback onBack;
  final Function(Map<String, dynamic>) onGymTap;
  final VoidCallback onCreate;

  const _GymsListView({
    required this.onBack,
    required this.onGymTap,
    required this.onCreate,
  });

  @override
  State<_GymsListView> createState() => _GymsListViewState();
}

class _GymsListViewState extends State<_GymsListView> {
  final ApiService _apiService = ApiService.fromEnv();
  final AuthService _authService = AuthService(ApiService.fromEnv());
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _gyms = [];
  List<Map<String, dynamic>> _filteredGyms = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadGyms();
    _searchController.addListener(_filterGyms);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGyms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await _authService.loadToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'Token non disponible';
          _isLoading = false;
        });
        return;
      }

      final gyms = await _apiService.getGyms(token);
      
      if (gyms != null) {
        setState(() {
          _gyms = gyms.map((gym) => gym as Map<String, dynamic>).toList();
          _filteredGyms = _gyms;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Impossible de charger les salles';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  void _filterGyms() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredGyms = _gyms;
      } else {
        _filteredGyms = _gyms.where((gym) {
          final name = (gym['name'] as String? ?? '').toLowerCase();
          final address = (gym['address'] as String? ?? '').toLowerCase();
          return name.contains(query) || address.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1a1f2e),
            const Color(0xFF2d3748),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header avec bouton retour
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: widget.onBack,
                  ),
                  const Text(
                    'Salles de sport',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add, color: Color(0xFFe89547)),
                    onPressed: widget.onCreate,
                  ),
                ],
              ),
            ),
            
            // Barre de recherche
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Rechercher une salle...',
                  hintStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFe89547)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white60),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF2d3748),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Liste des salles
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFe89547),
                      ),
                    )
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadGyms,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        )
                      : _filteredGyms.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.fitness_center_outlined,
                                    color: Colors.white60,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchController.text.isNotEmpty
                                        ? 'Aucune salle trouvée'
                                        : 'Aucune salle',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadGyms,
                              color: const Color(0xFFe89547),
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _filteredGyms.length,
                                itemBuilder: (context, index) {
                                  final gym = _filteredGyms[index];
                                  return _buildGymCard(gym, () => widget.onGymTap(gym));
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGymCard(Map<String, dynamic> gym, VoidCallback onTap) {
    final name = gym['name'] as String? ?? 'Sans nom';
    final address = gym['address'] as String? ?? '';
    final memberCount = gym['_count']?['users'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF2d3748),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFe89547).withValues(alpha: 0.2),
                  border: Border.all(
                    color: const Color(0xFFe89547),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.fitness_center,
                    color: Color(0xFFe89547),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFe89547).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$memberCount membre${memberCount > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Color(0xFFe89547),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white60, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// Vue détails d'un admin
class _AdminDetailsView extends StatelessWidget {
  final Map<String, dynamic> admin;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  const _AdminDetailsView({
    required this.admin,
    required this.onBack,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final fullName = admin['fullName'] as String? ?? 'Sans nom';
    final email = admin['email'] as String? ?? '';
    final uniqueCode = admin['uniqueCode'] as String? ?? '';
    final gymId = admin['gymId']?.toString() ?? 'N/A';
    final createdAt = admin['createdAt'] as String? ?? '';
    
    // Obtenir les initiales pour l'avatar
    final initials = fullName
        .split(' ')
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1a1f2e),
            const Color(0xFF2d3748),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header avec bouton retour
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: onBack,
                  ),
                  const Text(
                    'Détails Administrateur',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFFe89547)),
                    onPressed: onEdit,
                  ),
                ],
              ),
            ),
            
            // Contenu
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFe89547).withValues(alpha: 0.2),
                        border: Border.all(
                          color: const Color(0xFFe89547),
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Color(0xFFe89547),
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Nom
                    Text(
                      fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    
                    // Badge rôle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFe89547).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Administrateur',
                        style: TextStyle(
                          color: Color(0xFFe89547),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Informations
                    _buildInfoCard(
                      icon: Icons.email,
                      title: 'Email',
                      value: email,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildInfoCard(
                      icon: Icons.qr_code,
                      title: 'Code unique',
                      value: uniqueCode,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildInfoCard(
                      icon: Icons.fitness_center,
                      title: 'ID Salle',
                      value: gymId,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildInfoCard(
                      icon: Icons.calendar_today,
                      title: 'Créé le',
                      value: createdAt.isNotEmpty 
                          ? DateTime.parse(createdAt).toString().split(' ')[0]
                          : 'N/A',
                    ),
                    const SizedBox(height: 32),
                    
                    // Bouton supprimer
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showDeleteConfirmation(context, fullName);
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Supprimer l\'administrateur'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2d3748),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFe89547).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFe89547),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2d3748),
        title: const Text(
          'Confirmer la suppression',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer $name ?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Suppression en développement')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// Vue détails d'une salle
class _GymDetailsView extends StatelessWidget {
  final Map<String, dynamic> gym;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onManageHours;

  const _GymDetailsView({
    required this.gym,
    required this.onBack,
    required this.onEdit,
    required this.onManageHours,
  });

  @override
  Widget build(BuildContext context) {
    final name = gym['name'] as String? ?? 'Sans nom';
    final address = gym['address'] as String? ?? '';
    final phone = gym['phone'] as String? ?? 'N/A';
    final memberCount = gym['_count']?['users'] ?? 0;
    final createdAt = gym['createdAt'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1a1f2e),
            const Color(0xFF2d3748),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header avec bouton retour
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: onBack,
                  ),
                  const Text(
                    'Détails Salle',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFFe89547)),
                    onPressed: onEdit,
                  ),
                ],
              ),
            ),
            
            // Contenu
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Icône
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFe89547).withValues(alpha: 0.2),
                        border: Border.all(
                          color: const Color(0xFFe89547),
                          width: 3,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.fitness_center,
                          color: Color(0xFFe89547),
                          size: 60,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Nom
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    
                    // Badge membres
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFe89547).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$memberCount membre${memberCount > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Color(0xFFe89547),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Informations
                    _buildInfoCard(
                      icon: Icons.location_on,
                      title: 'Adresse',
                      value: address,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildInfoCard(
                      icon: Icons.phone,
                      title: 'Téléphone',
                      value: phone,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildInfoCard(
                      icon: Icons.people,
                      title: 'Nombre de membres',
                      value: memberCount.toString(),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildInfoCard(
                      icon: Icons.calendar_today,
                      title: 'Créée le',
                      value: createdAt.isNotEmpty 
                          ? DateTime.parse(createdAt).toString().split(' ')[0]
                          : 'N/A',
                    ),
                    const SizedBox(height: 32),
                    
                    // Boutons d'action
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onManageHours,
                            icon: const Icon(Icons.schedule),
                            label: const Text('Horaires'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFe89547),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Liste membres en développement')),
                              );
                            },
                            icon: const Icon(Icons.group),
                            label: const Text('Membres'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFe89547),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Bouton supprimer
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showDeleteConfirmation(context, name);
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Supprimer la salle'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2d3748),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFe89547).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFe89547),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2d3748),
        title: const Text(
          'Confirmer la suppression',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la salle "$name" ?\n\nCette action supprimera également tous les membres associés.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Suppression en développement')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2d3748),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFe89547)),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.white60, size: 16),
          ],
        ),
      ),
    );
  }
}

// Vue édition admin
class _AdminEditView extends StatefulWidget {
  final Map<String, dynamic> admin;
  final VoidCallback onBack;
  final VoidCallback onSuccess;

  const _AdminEditView({
    required this.admin,
    required this.onBack,
    required this.onSuccess,
  });

  @override
  State<_AdminEditView> createState() => _AdminEditViewState();
}

class _AdminEditViewState extends State<_AdminEditView> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService.fromEnv();
  final AuthService _authService = AuthService(ApiService.fromEnv());
  
  late TextEditingController _emailController;
  late TextEditingController _fullNameController;
  
  List<Map<String, dynamic>> _gyms = [];
  int? _selectedGymId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.admin['email'] as String?);
    _fullNameController = TextEditingController(text: widget.admin['fullName'] as String?);
    _selectedGymId = widget.admin['gymId'] as int?;
    _loadGyms();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _loadGyms() async {
    try {
      final token = await _authService.loadToken();
      if (token == null) return;

      final gyms = await _apiService.getGyms(token);
      if (gyms != null && mounted) {
        setState(() {
          _gyms = gyms.map((g) => g as Map<String, dynamic>).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement salles: $e')),
        );
      }
    }
  }

  Future<void> _updateAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = await _authService.loadToken();
      if (token == null) throw Exception('Token non disponible');

      final updateData = {
        'email': _emailController.text.trim(),
        'fullName': _fullNameController.text.trim(),
        'gymId': _selectedGymId,
      };

      final response = await _apiService.updateUserProfile(
        widget.admin['id'] as int,
        updateData,
        token,
      );

      if (response != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Administrateur modifié avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSuccess();
      } else {
        throw Exception('Erreur lors de la modification');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1a1f2e),
            const Color(0xFF2d3748),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: widget.onBack,
                  ),
                  const Text(
                    'Modifier administrateur',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenu
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Icône
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFe89547).withValues(alpha: 0.2),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            color: Color(0xFFe89547),
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Nom complet
                      TextFormField(
                        controller: _fullNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Nom complet',
                          labelStyle: const TextStyle(color: Colors.white60),
                          prefixIcon: const Icon(Icons.person, color: Color(0xFFe89547)),
                          filled: true,
                          fillColor: const Color(0xFF2d3748),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le nom complet est requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: const TextStyle(color: Colors.white60),
                          prefixIcon: const Icon(Icons.email, color: Color(0xFFe89547)),
                          filled: true,
                          fillColor: const Color(0xFF2d3748),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'L\'email est requis';
                          }
                          if (!value.contains('@')) {
                            return 'Email invalide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Salle
                      DropdownButtonFormField<int>(
                        initialValue: _selectedGymId,
                        dropdownColor: const Color(0xFF2d3748),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Salle de sport',
                          labelStyle: const TextStyle(color: Colors.white60),
                          prefixIcon: const Icon(Icons.fitness_center, color: Color(0xFFe89547)),
                          filled: true,
                          fillColor: const Color(0xFF2d3748),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _gyms.map((gym) {
                          return DropdownMenuItem<int>(
                            value: gym['id'] as int,
                            child: Text(gym['name'] as String),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedGymId = value);
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Veuillez sélectionner une salle';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Bouton modifier
                      ElevatedButton(
                        onPressed: _isLoading ? null : _updateAdmin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFe89547),
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
                                'Modifier l\'administrateur',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Vue édition salle
class _GymEditView extends StatefulWidget {
  final Map<String, dynamic> gym;
  final VoidCallback onBack;
  final VoidCallback onSuccess;

  const _GymEditView({
    required this.gym,
    required this.onBack,
    required this.onSuccess,
  });

  @override
  State<_GymEditView> createState() => _GymEditViewState();
}

class _GymEditViewState extends State<_GymEditView> {
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
            backgroundColor: Colors.green,
          ),
        );
        widget.onSuccess();
      } else {
        throw Exception('Erreur lors de la modification');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1a1f2e),
            const Color(0xFF2d3748),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: widget.onBack,
                  ),
                  const Text(
                    'Modifier salle',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenu
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Icône
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFe89547).withValues(alpha: 0.2),
                          ),
                          child: const Icon(
                            Icons.fitness_center,
                            color: Color(0xFFe89547),
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Nom de la salle',
                          labelStyle: const TextStyle(color: Colors.white60),
                          prefixIcon: const Icon(Icons.business, color: Color(0xFFe89547)),
                          filled: true,
                          fillColor: const Color(0xFF2d3748),
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
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Adresse',
                          labelStyle: const TextStyle(color: Colors.white60),
                          prefixIcon: const Icon(Icons.location_on, color: Color(0xFFe89547)),
                          filled: true,
                          fillColor: const Color(0xFF2d3748),
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
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Téléphone (optionnel)',
                          labelStyle: const TextStyle(color: Colors.white60),
                          prefixIcon: const Icon(Icons.phone, color: Color(0xFFe89547)),
                          filled: true,
                          fillColor: const Color(0xFF2d3748),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _updateGym,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFe89547),
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
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Vue gestion horaires salle
class _GymOpeningHoursView extends StatefulWidget {
  final Map<String, dynamic> gym;
  final VoidCallback onBack;

  const _GymOpeningHoursView({
    required this.gym,
    required this.onBack,
  });

  @override
  State<_GymOpeningHoursView> createState() => _GymOpeningHoursViewState();
}

class _GymOpeningHoursViewState extends State<_GymOpeningHoursView> {
  final ApiService _apiService = ApiService.fromEnv();
  final AuthService _authService = AuthService(ApiService.fromEnv());
  bool _isLoading = false;

  final List<Map<String, dynamic>> _hoursData = List.generate(7, (index) {
    return {
      'dayOfWeek': index,
      'isClosed': false,
      'openTime': '09:00',
      'closeTime': '18:00',
    };
  });

  final List<String> _dayNames = [
    'Dimanche',
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
  ];

  @override
  void initState() {
    super.initState();
    _loadOpeningHours();
  }

  Future<void> _loadOpeningHours() async {
    setState(() => _isLoading = true);

    try {
      final token = await _authService.loadToken();
      if (token == null) throw Exception('Token non disponible');

      final hours = await _apiService.getOpeningHours(
        widget.gym['id'] as int,
        token,
      );

      if (hours != null && mounted) {
        for (var hour in hours) {
          final dayOfWeek = hour['dayOfWeek'] as int;
          if (dayOfWeek >= 0 && dayOfWeek <= 6) {
            _hoursData[dayOfWeek] = {
              'dayOfWeek': dayOfWeek,
              'isClosed': hour['isClosed'] ?? false,
              'openTime': hour['openTime'] ?? '09:00',
              'closeTime': hour['closeTime'] ?? '18:00',
            };
          }
        }
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveOpeningHours() async {
    setState(() => _isLoading = true);

    try {
      final token = await _authService.loadToken();
      if (token == null) throw Exception('Token non disponible');

      final response = await _apiService.setOpeningHours(
        widget.gym['id'] as int,
        _hoursData,
        token,
      );

      if (response != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Horaires enregistrés avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onBack();
      } else {
        throw Exception('Erreur lors de l\'enregistrement');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<TimeOfDay?> _selectTime(BuildContext context, String initialTime) async {
    final parts = initialTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );

    return await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFe89547),
              onSurface: Colors.white,
              surface: Color(0xFF2d3748),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  String _timeOfDayToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildTimeButton(
    BuildContext context,
    String label,
    String time,
    Function(String) onTimeSelected,
  ) {
    return InkWell(
      onTap: () async {
        final selected = await _selectTime(context, time);
        if (selected != null) {
          onTimeSelected(_timeOfDayToString(selected));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1f2e),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFe89547).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: Color(0xFFe89547),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gymName = widget.gym['name'] as String? ?? 'Sans nom';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1a1f2e),
            const Color(0xFF2d3748),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: widget.onBack,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Horaires d\'ouverture',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          gymName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Contenu
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFe89547),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 7,
                      itemBuilder: (context, index) {
                        final dayData = _hoursData[index];
                        final isClosed = dayData['isClosed'] as bool;

                        return Card(
                          color: const Color(0xFF2d3748),
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _dayNames[index],
                                      style: const TextStyle(
                                        color: Color(0xFFe89547),
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Text(
                                      'Fermé',
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Switch(
                                      value: isClosed,
                                      activeThumbColor: Colors.red,
                                      onChanged: (value) {
                                        setState(() {
                                          _hoursData[index]['isClosed'] = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                if (!isClosed) ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTimeButton(
                                          context,
                                          'Ouverture',
                                          dayData['openTime'] as String,
                                          (time) {
                                            setState(() {
                                              _hoursData[index]['openTime'] = time;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildTimeButton(
                                          context,
                                          'Fermeture',
                                          dayData['closeTime'] as String,
                                          (time) {
                                            setState(() {
                                              _hoursData[index]['closeTime'] = time;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Bouton sauvegarder
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveOpeningHours,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFe89547),
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
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Enregistrer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Vue création admin
class _AdminCreateView extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSuccess;

  const _AdminCreateView({
    required this.onBack,
    required this.onSuccess,
  });

  @override
  State<_AdminCreateView> createState() => _AdminCreateViewState();
}

class _AdminCreateViewState extends State<_AdminCreateView> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService.fromEnv();
  final AuthService _authService = AuthService(ApiService.fromEnv());
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  List<Map<String, dynamic>> _gyms = [];
  int? _selectedGymId;
  bool _sendSetupEmail = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGyms();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadGyms() async {
    try {
      final token = await _authService.loadToken();
      if (token == null) return;

      final gyms = await _apiService.getGyms(token);
      if (gyms != null && mounted) {
        setState(() {
          _gyms = gyms.map((g) => g as Map<String, dynamic>).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement salles: $e')),
        );
      }
    }
  }

  Future<void> _createAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = await _authService.loadToken();
      if (token == null) throw Exception('Token non disponible');

      final response = await _apiService.createAdmin(
        _emailController.text.trim(),
        _fullNameController.text.trim(),
        _selectedGymId!,
        token,
        password: _sendSetupEmail ? null : _passwordController.text.trim(),
      );

      if (response != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Administrateur créé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSuccess();
      } else {
        throw Exception('Erreur lors de la création');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1a1f2e),
            const Color(0xFF2d3748),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: widget.onBack,
                  ),
                  const Text(
                    'Créer un administrateur',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenu
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Icône
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFe89547).withValues(alpha: 0.2),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            color: Color(0xFFe89547),
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Nom complet
                      TextFormField(
                        controller: _fullNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Nom complet',
                          labelStyle: const TextStyle(color: Colors.white60),
                          prefixIcon: const Icon(Icons.person, color: Color(0xFFe89547)),
                          filled: true,
                          fillColor: const Color(0xFF2d3748),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le nom complet est requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: const TextStyle(color: Colors.white60),
                          prefixIcon: const Icon(Icons.email, color: Color(0xFFe89547)),
                          filled: true,
                          fillColor: const Color(0xFF2d3748),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'L\'email est requis';
                          }
                          if (!value.contains('@')) {
                            return 'Email invalide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Salle
                      DropdownButtonFormField<int>(
                        initialValue: _selectedGymId,
                        dropdownColor: const Color(0xFF2d3748),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Salle de sport',
                          labelStyle: const TextStyle(color: Colors.white60),
                          prefixIcon: const Icon(Icons.fitness_center, color: Color(0xFFe89547)),
                          filled: true,
                          fillColor: const Color(0xFF2d3748),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _gyms.map((gym) {
                          return DropdownMenuItem<int>(
                            value: gym['id'] as int,
                            child: Text(gym['name'] as String),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedGymId = value);
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Veuillez sélectionner une salle';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Checkbox email de configuration
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2d3748),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _sendSetupEmail,
                              activeColor: const Color(0xFFe89547),
                              onChanged: (value) {
                                setState(() {
                                  _sendSetupEmail = value ?? true;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Envoyer un email de configuration',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Mot de passe (conditionnel)
                      if (!_sendSetupEmail) ...[
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            labelStyle: const TextStyle(color: Colors.white60),
                            prefixIcon: const Icon(Icons.lock, color: Color(0xFFe89547)),
                            filled: true,
                            fillColor: const Color(0xFF2d3748),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (!_sendSetupEmail && (value == null || value.trim().isEmpty)) {
                              return 'Le mot de passe est requis';
                            }
                            if (!_sendSetupEmail && value!.length < 6) {
                              return 'Le mot de passe doit contenir au moins 6 caractères';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      const SizedBox(height: 16),

                      // Bouton créer
                      ElevatedButton(
                        onPressed: _isLoading ? null : _createAdmin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFe89547),
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
                                'Créer l\'administrateur',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Vue création salle
class _GymCreateView extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSuccess;

  const _GymCreateView({
    required this.onBack,
    required this.onSuccess,
  });

  @override
  State<_GymCreateView> createState() => _GymCreateViewState();
}

class _GymCreateViewState extends State<_GymCreateView> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService.fromEnv();
  final AuthService _authService = AuthService(ApiService.fromEnv());
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _createGym() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = await _authService.loadToken();
      if (token == null) throw Exception('Token non disponible');

      final response = await _apiService.createGym(
        _nameController.text.trim(),
        _addressController.text.trim(),
        token,
        phone: _phoneController.text.trim().isNotEmpty 
            ? _phoneController.text.trim() 
            : null,
      );

      if (response != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Salle créée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSuccess();
      } else {
        throw Exception('Erreur lors de la création');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1a1f2e),
            const Color(0xFF2d3748),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: widget.onBack,
                  ),
                  const Text(
                    'Créer une salle',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenu
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Icône
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFe89547).withValues(alpha: 0.2),
                          ),
                          child: const Icon(
                            Icons.fitness_center,
                            color: Color(0xFFe89547),
                            size: 40,
                          ),
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
                          prefixIcon: const Icon(Icons.business, color: Color(0xFFe89547)),
                          filled: true,
                          fillColor: const Color(0xFF2d3748),
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
                          prefixIcon: const Icon(Icons.location_on, color: Color(0xFFe89547)),
                          filled: true,
                          fillColor: const Color(0xFF2d3748),
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

                      // Téléphone (optionnel)
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Téléphone (optionnel)',
                          labelStyle: const TextStyle(color: Colors.white60),
                          prefixIcon: const Icon(Icons.phone, color: Color(0xFFe89547)),
                          filled: true,
                          fillColor: const Color(0xFF2d3748),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Bouton créer
                      ElevatedButton(
                        onPressed: _isLoading ? null : _createGym,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFe89547),
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
                                'Créer la salle',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
