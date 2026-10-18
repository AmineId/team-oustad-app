import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/user_utils.dart';

class AdminAdminsListScreen extends StatefulWidget {
  const AdminAdminsListScreen({super.key});

  @override
  State<AdminAdminsListScreen> createState() => _AdminAdminsListScreenState();
}

class _AdminAdminsListScreenState extends State<AdminAdminsListScreen> {
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
              .where(
                (user) => user['role'] == 'admin' && user['role'] != 'owner',
              )
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
          final fullName = getUserFullName(admin).toLowerCase();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Administrateurs',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create admin screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Création admin en développement')),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Barre de recherche
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un administrateur...',
                    hintStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.primary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.white60,
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Theme.of(context).cardTheme.color,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Liste des administrateurs
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.error,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
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
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredAdmins.length,
                          itemBuilder: (context, index) {
                            final admin = _filteredAdmins[index];
                            return _AdminCard(
                              admin: admin,
                              onTap: () {
                                // TODO: Naviguer vers les détails de l'admin
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Détails de ${getUserFullName(admin)}',
                                    ),
                                  ),
                                );
                              },
                            );
                          },
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

class _AdminCard extends StatelessWidget {
  final Map<String, dynamic> admin;
  final VoidCallback onTap;

  const _AdminCard({required this.admin, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fullName = getUserFullName(admin);
    final email = admin['email'] as String? ?? '';
    final role = admin['role'] as String? ?? 'N/A';

    // Obtenir les initiales pour l'avatar
    final initials = fullName
        .split(' ')
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();

    // Badge de rôle avec couleur
    final roleBadge = role == 'owner'
        ? 'Propriétaire'
        : role == 'admin'
        ? 'Administrateur'
        : role;
    final roleColor = role == 'owner' ? Colors.purple : AppColors.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Avatar
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

              // Infos
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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

              // Icône flèche
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white60,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
