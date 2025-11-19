import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_security_service.dart';
import 'role_selection_screen.dart';
import 'security_lock_screen.dart';
import 'setup_security_screen.dart';
import 'preim_screen.dart';
import 'enhanced_parent_dashboard_screen.dart';
import 'child_home_screen.dart';

class AppSecurityWrapper extends StatefulWidget {
  const AppSecurityWrapper({super.key});

  @override
  State<AppSecurityWrapper> createState() => _AppSecurityWrapperState();
}

class _AppSecurityWrapperState extends State<AppSecurityWrapper> {
  String? _userRole;
  bool _isLoading = true;
  bool _needsSecuritySetup = false;
  bool _needsAuthentication = false;

  @override
  void initState() {
    super.initState();
    _checkSecurityStatus();
  }

  Future<void> _checkSecurityStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userRole = prefs.getString('userRole');
      final firstLoginDone = prefs.getBool('firstLoginDone') ?? false;
      final authService = AuthSecurityService();

      setState(() {
        _userRole = userRole;
        _isLoading = false;
      });

      if (userRole != null) {
        // Если первый вход/регистрация завершён, но security не настроена
        if (firstLoginDone && !(await authService.isSetupCompleted)) {
          setState(() {
            _needsSecuritySetup = true;
          });
        } else if (await authService.isSetupCompleted) {
          // Если security уже настроена, требуем аутентификацию
          setState(() {
            _needsAuthentication = true;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_userRole == null) {
      return const RoleSelectionScreen();
    }

    if (_needsSecuritySetup) {
      return SetupSecurityScreen(
        userRole: _userRole!,
        isFirstTime: true,
      );
    }

    if (_needsAuthentication) {
      return SecurityLockScreen(
        userRole: _userRole!,
        onUnlockSuccess: () async {
          // После успешной аутентификации, переходим на соответствующий главный экран
          final prefs = await SharedPreferences.getInstance();
          
          if (_userRole == 'parent') {
            final parentName = prefs.getString('parentName') ?? '';
            final parentKey = prefs.getString('parentKey') ?? '';
            
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => EnhancedParentDashboardScreen(
                  parentName: parentName,
                  parentKey: parentKey,
                ),
              ),
            );
          } else {
            final childId = prefs.getString('childId') ?? '';
            final parentKey = prefs.getString('parentKey') ?? '';
            final childName = prefs.getString('childName') ?? '';
            
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ChildHomeScreen(
                  childId: childId,
                  parentKey: parentKey,
                  childName: childName,
                ),
              ),
            );
          }
        },
      );
    }

    // Если userRole установлена, но security ещё не настроена и первый вход не был
    // то показываем PreimScreen для регистрации/входа
    return PreimScreen(role: _userRole!);
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: const SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 24),
                Text(
                  'Загрузка...',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}