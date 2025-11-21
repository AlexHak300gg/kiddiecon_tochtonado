import 'package:flutter/material.dart';
import '../services/auth_security_service.dart';

class SecurityTestScreen extends StatefulWidget {
  const SecurityTestScreen({super.key});

  @override
  State<SecurityTestScreen> createState() => _SecurityTestScreenState();
}

class _SecurityTestScreenState extends State<SecurityTestScreen> {
  final AuthSecurityService _authService = AuthSecurityService();
  String _status = 'Testing security service...';

  @override
  void initState() {
    super.initState();
    _testSecurityService();
  }

  Future<void> _testSecurityService() async {
    setState(() {
      _status = 'Testing biometric availability...';
    });

    final biometricAvailable = await _authService.isBiometricAvailable();
    final availableBiometrics = await _authService.getAvailableBiometrics();
    final setupCompleted = await _authService.isSetupCompleted;
    final pinEnabled = await _authService.isPinEnabled;
    final biometricEnabled = await _authService.isBiometricEnabled;
    final patternEnabled = await _authService.isPatternEnabled;

    setState(() {
      _status = '''
Security Service Test Results:
- Setup Completed: $setupCompleted
- PIN Enabled: $pinEnabled
- Biometric Enabled: $biometricEnabled
- Pattern Enabled: $patternEnabled
- Biometric Available: $biometricAvailable
- Available Biometrics: $availableBiometrics
      ''';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Test'),
        actions: [
          IconButton(
            onPressed: () async {
              await _authService.clearAllSecurityData();
              _testSecurityService();
            },
            icon: const Icon(Icons.clear),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            _status,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          ),
        ),
      ),
    );
  }
}