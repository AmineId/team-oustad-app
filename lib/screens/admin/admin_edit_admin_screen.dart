import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AdminEditAdminScreen extends StatefulWidget {
  final Map<String, dynamic> admin;
  
  const AdminEditAdminScreen({super.key, required this.admin});

  @override
  State<AdminEditAdminScreen> createState() => _AdminEditAdminScreenState();
}

class _AdminEditAdminScreenState extends State<AdminEditAdminScreen> {
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
        Navigator.pop(context, true);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Modifier administrateur',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1a1f2e),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
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
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icône
                  Container(
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
                    value: _selectedGymId,
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
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
