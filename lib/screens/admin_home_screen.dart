import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'admin_create_member_screen.dart';

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
                  profileData['uniqueCode'] ?? '',
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

  void _manageGymsAndAdmins() {
    // TODO: Naviguer vers la page de gestion des salles et admins
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gestion Salles & Admins - À implémenter')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Row(
          children: [
            const SizedBox(width: 8),
            // Bouton QR Code (pour admin et owner)
            IconButton(
              icon: const Icon(Icons.qr_code_2, size: 28),
              onPressed: _showQrCode,
              tooltip: 'Mon QR Code',
            ),
          ],
        ),
        leadingWidth: 70,
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1a1f2e),
        selectedItemColor: const Color(0xFFe89547),
        unselectedItemColor: Colors.white60,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: _isOwner
            ? const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Accueil',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings),
                  label: 'Gestion',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.admin_panel_settings_outlined),
                  activeIcon: Icon(Icons.admin_panel_settings),
                  label: 'Gestion Globale',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ]
            : const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Accueil',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings),
                  label: 'Gestion',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
      ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bienvenue !',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tableau de bord',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 32),
              
              // Statistiques
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.people,
                      title: 'Membres',
                      value: '156',
                      color: const Color(0xFFe89547),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.fitness_center,
                      title: 'Actifs',
                      value: '89',
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.calendar_today,
                      title: 'Aujourd\'hui',
                      value: '23',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.trending_up,
                      title: 'Revenus',
                      value: '12.5K',
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Actions rapides
              const Text(
                'Actions rapides',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _QuickActionButton(
                icon: Icons.person_add,
                title: 'Nouveau membre',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _QuickActionButton(
                icon: Icons.payment,
                title: 'Enregistrer un paiement',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _QuickActionButton(
                icon: Icons.qr_code_scanner,
                title: 'Scanner une carte',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2d3748),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFe89547).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFe89547)),
            ),
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

// Page Gestion - Navigation vers la liste des membres
class GestionPage extends StatelessWidget {
  const GestionPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Import nécessaire pour la navigation
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
              // Bouton Ajouter nouveau membre (jaune, en haut)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminCreateMemberScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add, size: 24),
                  label: const Text(
                    'Ajouter nouveau membre',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFe89547),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Bouton pour aller à la liste des membres
              _QuickActionButton(
                icon: Icons.people,
                title: 'Gérer les membres',
                onTap: () {
                  Navigator.pushNamed(context, '/admin/members');
                },
              ),
              const SizedBox(height: 12),
              
              // Bouton pour aller à la liste des plannings
              _QuickActionButton(
                icon: Icons.calendar_today,
                title: 'Gérer les plannings',
                onTap: () {
                  Navigator.pushNamed(context, '/admin/plannings');
                },
              ),
            ],
          ),
        ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFe89547).withValues(alpha: 0.2),
                  border: Border.all(color: const Color(0xFFe89547), width: 3),
                ),
                child: const Icon(
                  Icons.person,
                  size: 50,
                  color: Color(0xFFe89547),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Administrateur',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'admin@gymmanager.com',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 32),
              
              // Options
              _ProfileOption(
                icon: Icons.settings,
                title: 'Paramètres',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _ProfileOption(
                icon: Icons.lock,
                title: 'Sécurité',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _ProfileOption(
                icon: Icons.help,
                title: 'Aide',
                onTap: () {},
              ),
              const SizedBox(height: 32),
              
              // Déconnexion
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final apiService = ApiService.fromEnv();
                    final authService = AuthService(apiService);
                    
                    // Supprimer les credentials et le token
                    await authService.setBiometricEnabled(false);
                    // TODO: Ajouter une méthode pour supprimer le token
                    
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: const Text(
                    'Déconnexion',
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

// Page Gestion Globale (Owner uniquement)
class GestionGlobalePage extends StatelessWidget {
  const GestionGlobalePage({super.key});

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

              // Gestion des Gérants
              _buildGlobalOption(
                context,
                icon: Icons.supervisor_account,
                title: 'Gestion des Gérants',
                description: 'Ajouter, modifier ou supprimer des gérants',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gestion des Gérants - À implémenter')),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Gestion des Salles
              _buildGlobalOption(
                context,
                icon: Icons.business,
                title: 'Gestion des Salles',
                description: 'Créer, modifier ou supprimer des salles de sport',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gestion des Salles - À implémenter')),
                  );
                },
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
