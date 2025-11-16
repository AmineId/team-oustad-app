import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../core/config/app_config.dart';

class ConnectionTestScreen extends StatefulWidget {
  const ConnectionTestScreen({super.key});

  @override
  State<ConnectionTestScreen> createState() => _ConnectionTestScreenState();
}

class _ConnectionTestScreenState extends State<ConnectionTestScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _result;
  bool? _isConnected;

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _result = null;
      _isConnected = null;
    });

    try {
      final connected = await _apiService.testConnection();
      setState(() {
        _isConnected = connected;
        _result = connected
            ? 'Successfully connected to the database!\nURL: ${_apiService.baseUrl}'
            : 'Failed to connect to the database.\nURL: ${_apiService.baseUrl}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _result = 'Error connecting to database:\n${e.toString()}\nURL: ${_apiService.baseUrl}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Connection Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Testing connection...'),
                  ],
                )
              else if (_isConnected == null)
                const Text('Initializing...')
              else
                Column(
                  children: [
                    Icon(
                      _isConnected! ? Icons.check_circle : Icons.error,
                      size: 64,
                      color: _isConnected! ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isConnected! ? 'Connected!' : 'Connection Failed',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: _isConnected! ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _result ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _testConnection,
                icon: const Icon(Icons.refresh),
                label: const Text('Test Connection Again'),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              const Text(
                'Environment Configuration:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildConfigInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigInfo() {
    const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    final config = AppConfig.fromEnvironment(environment);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ENVIRONMENT: $environment'),
          const SizedBox(height: 4),
          Text('API_BASE_URL: ${apiBaseUrl.isEmpty ? "(not set)" : apiBaseUrl}'),
          const SizedBox(height: 4),
          Text('Resolved URL: ${config.apiBaseUrl}'),
          const SizedBox(height: 8),
          const Text(
            'To change environment, build with:\nflutter run --dart-define=ENVIRONMENT=pprod',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}
