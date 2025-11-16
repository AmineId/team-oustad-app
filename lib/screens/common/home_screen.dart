import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/responsive_layout.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const AccueilPage(),
    const RecherchePage(),
    const AjoutMembrePage(),
    const ProfilePage(),
  ];

  final List<String> _titles = [
    'Accueil',
    'Recherche',
    'Nouveau membre',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: _titles[_currentIndex],
      navigationItems: const [
        NavigationItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          label: 'Accueil',
        ),
        NavigationItem(
          icon: Icons.search_outlined,
          activeIcon: Icons.search,
          label: 'Recherche',
        ),
        NavigationItem(
          icon: Icons.person_add_outlined,
          activeIcon: Icons.person_add,
          label: 'Ajouter',
        ),
        NavigationItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: 'Profile',
        ),
      ],
      currentIndex: _currentIndex,
      onNavigationChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      body: _pages[_currentIndex],
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

// Page Recherche
class RecherchePage extends StatelessWidget {
  const RecherchePage({super.key});

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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Rechercher un membre...',
                  hintStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFe89547)),
                  filled: true,
                  fillColor: const Color(0xFF2d3748),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Expanded(
                child: Center(
                  child: Text(
                    'Fonctionnalité de recherche\nà implémenter',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 16,
                    ),
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
