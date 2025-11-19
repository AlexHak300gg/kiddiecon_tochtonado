import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_security_service.dart';
import '../widgets/pin_input_widget.dart';
import '../widgets/pattern_lock_widget.dart';
import 'app_security_wrapper.dart';
import 'enhanced_parent_dashboard_screen.dart';
import 'child_home_screen.dart';

class SetupSecurityScreen extends StatefulWidget {
  final String userRole; // 'parent' or 'child'
  final bool isFirstTime; // true если это первая настройка после регистрации/входа

  const SetupSecurityScreen({
    super.key,
    required this.userRole,
    this.isFirstTime = false,
  });

  @override
  State<SetupSecurityScreen> createState() => _SetupSecurityScreenState();
}

class _SetupSecurityScreenState extends State<SetupSecurityScreen> {
  final AuthSecurityService _authService = AuthSecurityService();
  final PageController _pageController = PageController();

  int _currentStep = 0;
  bool _enableBiometric = false;
  bool _enablePattern = false;
  String _pinCode = '';
  List<int> _pattern = [];

  bool _biometricAvailable = false;
  bool _isLoadingBiometric = true;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await _authService.isBiometricAvailable();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _isLoadingBiometric = false;
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
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildMethodsSelectionStep(),
                    _buildPinSetupStep(),
                    if (_enablePattern) _buildPatternSetupStep(),
                    _buildCompletionStep(),
                  ],
                ),
              ),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Безопасность',
            style: GoogleFonts.nunito(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Настройте методы входа в приложение',
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          // Progress indicator
          Row(
            children: List.generate(
              _getTotalSteps(),
                  (index) => Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    right: index < _getTotalSteps() - 1 ? 8 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: index <= _currentStep
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodsSelectionStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Выберите методы входа',
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'PIN-код обязателен, остальные методы опциональны',
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),

          // PIN (always enabled)
          _buildMethodCard(
            title: 'PIN-код',
            subtitle: '4-6 цифр для входа',
            icon: Icons.pin,
            isEnabled: true,
            isRequired: true,
          ),

          const SizedBox(height: 16),

          // Biometric
          if (!_isLoadingBiometric)
            _buildMethodCard(
              title: 'Биометрия',
              subtitle: _biometricAvailable
                  ? 'Отпечаток пальца или Face ID'
                  : 'Недоступна на этом устройстве',
              icon: Icons.fingerprint,
              isEnabled: _biometricAvailable && _enableBiometric,
              isRequired: false,
              onTap: _biometricAvailable
                  ? () => setState(() => _enableBiometric = !_enableBiometric)
                  : null,
            ),

          if (_isLoadingBiometric)
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          if (!_isLoadingBiometric) ...[
            const SizedBox(height: 16),

            // Pattern
            _buildMethodCard(
              title: 'Графический ключ',
              subtitle: 'Рисуйте паттерн для входа',
              icon: Icons.lock, // Icons.pattern не существует — заменил на lock
              isEnabled: _enablePattern,
              isRequired: false,
              onTap: () => setState(() => _enablePattern = !_enablePattern),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMethodCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isEnabled,
    required bool isRequired,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isEnabled
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isEnabled
                    ? Theme.of(context).primaryColor
                    : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isEnabled
                              ? Colors.black87
                              : Colors.grey[600],
                        ),
                      ),
                      if (isRequired) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Обязательно',
                            style: GoogleFonts.nunito(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null && !isRequired)
              Switch(
                value: isEnabled,
                onChanged: (_) => onTap(),
                activeThumbColor: Theme.of(context).primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinSetupStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          PinInputWidget(
            title: 'Установите PIN-код',
            subtitle: 'Введите 4-6 цифр для входа в приложение',
            length: 6,
            obscureText: true,
            onCompleted: (pin) {
              // Проверяем корректность PIN (4-6 цифр)
              if (pin.length < 4 || pin.length > 6) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PIN должен содержать от 4 до 6 цифр'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }
              setState(() {
                _pinCode = pin;
              });
              _nextStep();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPatternSetupStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          PatternLockWidget(
            title: 'Установите графический ключ',
            subtitle: 'Соедините минимум 4 точки',
            showConfirmPattern: true,
            confirmTitle: 'Подтвердите графический ключ',
            confirmSubtitle: 'Нарисуйте тот же паттерн еще раз',
            onCompleted: (pattern) {
              if (pattern.length < 4) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Паттерн должен содержать минимум 4 точки'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }
              setState(() {
                _pattern = pattern;
              });
              _nextStep();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionStep() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 32), // Add some top spacing
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Настройка завершена!',
              style: GoogleFonts.nunito(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Ваши методы безопасности успешно настроены',
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildSecuritySummary(),
            SizedBox(height: 32), // Add bottom spacing to prevent overflow
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryItem('PIN-код', true),
          if (_enableBiometric) _buildSummaryItem('Биометрия', true),
          if (_enablePattern) _buildSummaryItem('Графический ключ', true),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String method, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.radio_button_unchecked,
            color: enabled ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            method,
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: enabled ? Colors.black87 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Назад',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _canGoNext() ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                _currentStep == _getTotalSteps() - 1 ? 'Готово' : 'Далее',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getTotalSteps() {
    int steps = 2; // Methods selection + PIN
    if (_enablePattern) steps++;
    steps++; // Completion step
    return steps;
  }

  bool _canGoNext() {
    final int pinStepIndex = 1;
    final int patternStepIndex = _enablePattern ? 2 : -1;
    final int completionIndex = _getTotalSteps() - 1;

    if (_currentStep == 0) {
      // На шаге выбора методов — всегда можно идти далее (PIN обязателен)
      return true;
    }

    if (_currentStep == pinStepIndex) {
      // PIN должен быть 4-6 цифр
      return _pinCode.isNotEmpty && _pinCode.length >= 4 && _pinCode.length <= 6;
    }

    if (_enablePattern && _currentStep == patternStepIndex) {
      return _pattern.isNotEmpty && _pattern.length >= 4;
    }

    if (_currentStep == completionIndex) {
      // на шаге завершения — кнопка "Готово" активна
      return true;
    }

    return false;
  }

  void _nextStep() async {
    if (_currentStep == _getTotalSteps() - 1) {
      // Complete setup
      await _completeSetup();
    } else {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeSetup() async {
    try {
      // Setup PIN
      await _authService.setupPinCode(_pinCode);

      // Setup biometric if enabled
      if (_enableBiometric) {
        await _authService.enableBiometric(true);
      }

      // Setup pattern if enabled
      if (_enablePattern) {
        final patternString = _pattern.join(',');
        await _authService.setupPatternLock(patternString);
      }

      // Mark setup as completed
      await _authService.completeSetup();

      // Если это первая настройка после регистрации/входа, отметим это
      if (widget.isFirstTime) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('firstLoginDone', true);

        // Для первого раза переходим сразу на главный экран, минуя повторную аутентификацию
        if (mounted) {
          if (widget.userRole == 'parent') {
            final parentName = prefs.getString('parentName') ?? '';
            final parentKey = prefs.getString('parentKey') ?? '';

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => EnhancedParentDashboardScreen(
                  parentName: parentName,
                  parentKey: parentKey,
                ),
              ),
                  (route) => false,
            );
          } else {
            final childId = prefs.getString('childId') ?? '';
            final parentKey = prefs.getString('parentKey') ?? '';
            final childName = prefs.getString('childName') ?? '';

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => ChildHomeScreen(
                  childId: childId,
                  parentKey: parentKey,
                  childName: childName,
                ),
              ),
                  (route) => false,
            );
          }
        }
      } else {
        // Если это не первая настройка (изменение PIN), переходим через AppSecurityWrapper
        // чтобы пройти проверку безопасности и попасть на нужный экран
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => AppSecurityWrapper()),
                (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка настройки безопасности: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
