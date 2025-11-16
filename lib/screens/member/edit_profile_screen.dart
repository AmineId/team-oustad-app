import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? profileData;
  final VoidCallback? onProfileUpdated;

  const EditProfileScreen({
    super.key,
    this.profileData,
    this.onProfileUpdated,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService.fromEnv();
  late final AuthService _authService;
  
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _birthDateController;
  late TextEditingController _addressController;
  
  bool _isLoading = false;
  List<Map<String, dynamic>> _placeSuggestions = [];

  @override
  void initState() {
    super.initState();
    _authService = AuthService(_apiService);
    
    // Initialize controllers with current data
    _fullNameController = TextEditingController(
      text: widget.profileData?['fullName'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.profileData?['email'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.profileData?['phone'] ?? '',
    );
    _birthDateController = TextEditingController(
      text: widget.profileData?['birthDate'] ?? '',
    );
    _addressController = TextEditingController(
      text: widget.profileData?['address'] ?? '',
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
    super.dispose();
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
              primary: Color(0xFFe89547),
              onPrimary: Colors.white,
              surface: Color(0xFF2d3748),
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
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await _authService.loadToken();
      if (token == null) {
        throw Exception('Session expirée');
      }

      final userId = widget.profileData?['id'] as int;
      
      final updateData = {
        'fullName': _fullNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text.isNotEmpty ? _phoneController.text : null,
        'birthDate': _birthDateController.text.isNotEmpty ? _birthDateController.text : null,
        'address': _addressController.text.isNotEmpty ? _addressController.text : null,
      };

      await _apiService.updateUserProfile(userId, updateData, token);
      
      // Refresh profile data
      await _authService.refreshUserProfile();
      
      if (mounted) {
        widget.onProfileUpdated?.call();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✓ Profil mis à jour avec succès',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur: ${e.toString()}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
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

  Future<void> _fetchPlaceSuggestions(String input) async {
    const apiKey = 'AIzaSyCu6rik9wyOBofUQ9m0l8WqrcNGTjZTpUk';
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input)}&key=$apiKey&language=fr',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            _placeSuggestions = List<Map<String, dynamic>>.from(
              data['predictions'].map((prediction) => {
                'description': prediction['description'],
                'place_id': prediction['place_id'],
              }),
            );
          });
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching place suggestions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Modifier le Profil',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1a1f2e),
              const Color(0xFF2d3748),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile picture section
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color(0xFFe89547),
                        child: const Icon(Icons.person, size: 60, color: Colors.white),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1a1f2e),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFe89547),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Color(0xFFe89547),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Form fields
                const Text(
                  'Informations Personnelles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _fullNameController,
                  label: 'Nom complet',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le nom est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'L\'email est requis';
                    }
                    if (!value.contains('@')) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _phoneController,
                  label: 'Téléphone',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _birthDateController,
                  label: 'Date de naissance',
                  icon: Icons.cake,
                  readOnly: true,
                  onTap: _selectDate,
                  suffixIcon: Icons.calendar_today,
                ),
                const SizedBox(height: 16),

                _buildGooglePlacesField(),
                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFe89547),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
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
                            'Enregistrer les modifications',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Cancel button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildGooglePlacesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _addressController,
          onChanged: (value) {
            if (value.length > 2) {
              _fetchPlaceSuggestions(value);
            } else {
              setState(() {
                _placeSuggestions = [];
              });
            }
          },
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Adresse',
            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            prefixIcon: const Icon(Icons.location_on, color: Color(0xFFe89547)),
            filled: true,
            fillColor: const Color(0xFF2d3748),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFe89547),
                width: 2,
              ),
            ),
          ),
        ),
        if (_placeSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2d3748),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _placeSuggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _placeSuggestions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.location_on,
                    color: Color(0xFFe89547),
                    size: 20,
                  ),
                  title: Text(
                    suggestion['description'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _addressController.text = suggestion['description'] ?? '';
                      _placeSuggestions = [];
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    IconData? suffixIcon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        prefixIcon: Icon(icon, color: const Color(0xFFe89547)),
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, color: const Color(0xFFe89547))
            : null,
        filled: true,
        fillColor: const Color(0xFF2d3748),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFe89547),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
      ),
    );
  }
}
