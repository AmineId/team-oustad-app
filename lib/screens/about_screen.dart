import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';
  String _buildNumber = '';
  String _releaseDate = '';
  List<String> _features = [];
  List<String> _improvements = [];
  List<String> _bugFixes = [];

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    try {
      // Load from package_info_plus
      final packageInfo = await PackageInfo.fromPlatform();
      
      // Load version-metadata.json
      final String metadataString = await rootBundle.loadString('version-metadata.json');
      final metadata = json.decode(metadataString);
      
      setState(() {
        _version = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
        _releaseDate = metadata['release_date'] ?? '';
        
        // Release notes
        final releaseNotes = metadata['release_notes'] as Map<String, dynamic>?;
        if (releaseNotes != null) {
          _features = List<String>.from(releaseNotes['new_features'] ?? []);
          _improvements = List<String>.from(releaseNotes['improvements'] ?? []);
          _bugFixes = List<String>.from(releaseNotes['bug_fixes'] ?? []);
        }
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error loading version info: $e');
      // Fallback to basic info
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'À propos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Logo et nom de l'app
                      Image.asset(
                        'assets/images/logo.png',
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Team Fitness',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFe89547),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Version info
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2d3748),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFe89547).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'Version $_version (Build $_buildNumber)',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      if (_releaseDate.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Publié le $_releaseDate',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 32),
                      
                      // Description
                      Card(
                        color: const Color(0xFF2d3748),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: const Color(0xFFe89547),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Description',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Team Fitness est une application de gestion complète pour votre salle de sport. '
                                'Gérez vos membres, plannings d\'entraînement, présences et bien plus encore.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Release notes sections
                      if (_features.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildReleaseNotesSection(
                          'Nouveautés',
                          Icons.new_releases,
                          Colors.green,
                          _features,
                        ),
                      ],
                      
                      if (_improvements.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildReleaseNotesSection(
                          'Améliorations',
                          Icons.trending_up,
                          Colors.blue,
                          _improvements,
                        ),
                      ],
                      
                      if (_bugFixes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildReleaseNotesSection(
                          'Corrections',
                          Icons.bug_report,
                          Colors.orange,
                          _bugFixes,
                        ),
                      ],
                      
                      const SizedBox(height: 32),
                      
                      // Credits
                      Card(
                        color: const Color(0xFF2d3748),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.code,
                                    color: const Color(0xFFe89547),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Développé par',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Team Oustad © ${DateTime.now().year}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Legal info
                      Text(
                        'Tous droits réservés',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReleaseNotesSection(
    String title,
    IconData icon,
    Color color,
    List<String> items,
  ) {
    return Card(
      color: const Color(0xFF2d3748),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
