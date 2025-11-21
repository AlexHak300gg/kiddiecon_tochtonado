import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_security_service.dart';
import '../widgets/pin_input_widget.dart';
import '../widgets/pattern_lock_widget.dart';

class SecurityLockScreen extends StatefulWidget {
  final String userRole; // 'parent' or 'child'
  final VoidCallback? onUnlockSuccess;

  const SecurityLockScreen({
    super.key,
    required this.userRole,
    this.onUnlockSuccess,
  });

  @override
  State<SecurityLockScreen> createState() => _SecurityLockScreenState();
}

class _SecurityLockScreenState extends State<SecurityLockScreen>
    with TickerProviderStateMixin {
  final AuthSecurityService _authService = AuthSecurityService();
  
  int _currentMethod = 0; // 0: PIN, 1: Biometric, 2: Pattern
  List<String> _availableMethods = [];
  bool _isLockedOut = false;
  Duration? _remainingLockoutTime;
  Timer? _lockoutTimer;
  
  bool _isAuthenticating = false;
  String _errorMessage = '';
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAvailableMethods();
    _checkLockoutStatus();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initializeAvailableMethods() async {
    final methods = <String>[];
    
    if (await _authService.isPinEnabled) {
      methods.add('PIN');
    }
    
    if (await _authService.isBiometricEnabled && await _authService.isBiometricAvailable()) {
      methods.add('Биометрия');
    }
    
    if (await _authService.isPatternEnabled) {
      methods.add('Паттерн');
    }
    
    setState(() {
      _availableMethods = methods;
      // Set initial method - prioritize biometric if available
      if (methods.contains('Биометрия')) {
        _currentMethod = methods.indexOf('Биометрия');
      } else {
        _currentMethod = 0;
      }
    });
    
    // Auto-trigger biometric if it's the first method
    if (methods.isNotEmpty && methods[_currentMethod] == 'Биометрия') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _authenticateWithBiometric();
      });
    }
  }

  Future<void> _checkLockoutStatus() async {
    final lockedOut = await _authService.isLockedOut();
    final remainingTime = await _authService.getRemainingLockoutTime();
    
    setState(() {
      _isLockedOut = lockedOut;
      _remainingLockoutTime = remainingTime;
    });
    
    if (_isLockedOut && _remainingLockoutTime != null) {
      _startLockoutTimer();
    }
  }

  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final remainingTime = await _authService.getRemainingLockoutTime();
      
      if (remainingTime == null) {
        timer.cancel();
        setState(() {
          _isLockedOut = false;
          _remainingLockoutTime = null;
        });
      } else {
        setState(() {
          _remainingLockoutTime = remainingTime;
        });
      }
    });
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
              Theme.of(context).primaryColor.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (_isLockedOut) ...[
                Expanded(child: _buildLockoutWidget()),
              ] else ...[
                if (_availableMethods.length > 1) _buildMethodSelector(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildCurrentMethodWidget(),
                  ),
                ),
                _buildFooter(),
              ],
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
          // App logo/icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'KiddieCoin',
            style: GoogleFonts.nunito(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getGreetingMessage(),
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Доброе утро!';
    if (hour < 17) return 'Добрый день!';
    if (hour < 22) return 'Добрый вечер!';
    return 'Доброй ночи!';
  }

  Widget _buildMethodSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
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
      child: Row(
        children: List.generate(
          _availableMethods.length,
          (index) => Expanded(
            child: GestureDetector(
              onTap: () => _switchMethod(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _currentMethod == index
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getMethodIcon(_availableMethods[index]),
                      color: _currentMethod == index
                          ? Theme.of(context).primaryColor
                          : Colors.grey[600],
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _availableMethods[index],
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _currentMethod == index
                            ? Theme.of(context).primaryColor
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getMethodIcon(String method) {
    switch (method) {
      case 'PIN':
        return Icons.pin;
      case 'Биометрия':
        return Icons.fingerprint;
      case 'Паттерн':
        return Icons.pattern;
      default:
        return Icons.lock;
    }
  }

  Widget _buildCurrentMethodWidget() {
    if (_availableMethods.isEmpty) {
      return _buildErrorWidget('Нет доступных методов аутентификации');
    }

    final currentMethod = _availableMethods[_currentMethod];
    
    switch (currentMethod) {
      case 'PIN':
        return _buildPinWidget();
      case 'Биометрия':
        return _buildBiometricWidget();
      case 'Паттерн':
        return _buildPatternWidget();
      default:
        return _buildErrorWidget('Неизвестный метод аутентификации');
    }
  }

  Widget _buildPinWidget() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_errorMessage.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[600], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: GoogleFonts.nunito(
                          color: Colors.red[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Expanded(
              child: PinInputWidget(
                title: 'Введите PIN-код',
                subtitle: 'Используйте установленный PIN-код для входа',
                length: 6,
                obscureText: true,
                onCompleted: _authenticateWithPin,
                onChanged: (_) {
                  if (_errorMessage.isNotEmpty) {
                    setState(() {
                      _errorMessage = '';
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricWidget() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fingerprint,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _isAuthenticating ? 'Проверка биометрии...' : 'Используйте биометрию',
              style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Приложите палец или используйте Face ID',
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (_isAuthenticating) ...[
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
            ],
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[600], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: GoogleFonts.nunito(
                          color: Colors.red[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isAuthenticating ? null : _authenticateWithBiometric,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Повторить',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternWidget() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_errorMessage.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[600], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: GoogleFonts.nunito(
                          color: Colors.red[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Expanded(
              child: PatternLockWidget(
                title: 'Нарисуйте паттерн',
                subtitle: 'Используйте установленный графический ключ',
                onCompleted: _authenticateWithPattern,
                onChanged: (_) {
                  if (_errorMessage.isNotEmpty) {
                    setState(() {
                      _errorMessage = '';
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockoutWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_clock,
                size: 80,
                color: Colors.orange[600],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Вход временно заблокирован',
              style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Слишком много неудачных попыток',
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
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
                  Text(
                    'До разблокировки:',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDuration(_remainingLockoutTime ?? Duration.zero),
                    style: GoogleFonts.nunito(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.nunito(
                fontSize: 18,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextButton(
            onPressed: _showForgotPinDialog,
            child: Text(
              'Забыли PIN-код?',
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_availableMethods.length > 1)
            Text(
              'Используйте другой метод входа',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  void _switchMethod(int index) {
    setState(() {
      _currentMethod = index;
      _errorMessage = '';
      _isAuthenticating = false;
    });
    
    _fadeController.reset();
    _fadeController.forward();
    
    // Auto-trigger biometric if switching to it
    if (_availableMethods[index] == 'Биометрия') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _authenticateWithBiometric();
      });
    }
  }

  Future<void> _authenticateWithPin(String pin) async {
    setState(() {
      _isAuthenticating = true;
      _errorMessage = '';
    });

    try {
      final success = await _authService.verifyPin(pin);
      
      if (success) {
        await _onAuthenticationSuccess();
      } else {
        setState(() {
          _errorMessage = 'Неверный PIN-код';
          _isAuthenticating = false;
        });
        await _checkLockoutStatus();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка проверки PIN-кода';
        _isAuthenticating = false;
      });
    }
  }

  Future<void> _authenticateWithBiometric() async {
    setState(() {
      _isAuthenticating = true;
      _errorMessage = '';
    });

    try {
      final success = await _authService.verifyBiometric();
      
      if (success) {
        await _onAuthenticationSuccess();
      } else {
        setState(() {
          _errorMessage = 'Биометрия не распознана';
          _isAuthenticating = false;
        });
        await _checkLockoutStatus();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка биометрической аутентификации';
        _isAuthenticating = false;
      });
    }
  }

  Future<void> _authenticateWithPattern(List<int> pattern) async {
    setState(() {
      _isAuthenticating = true;
      _errorMessage = '';
    });

    try {
      final patternString = pattern.join(',');
      final success = await _authService.verifyPattern(patternString);
      
      if (success) {
        await _onAuthenticationSuccess();
      } else {
        setState(() {
          _errorMessage = 'Неверный графический ключ';
          _isAuthenticating = false;
        });
        await _checkLockoutStatus();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка проверки графического ключа';
        _isAuthenticating = false;
      });
    }
  }

  Future<void> _onAuthenticationSuccess() async {
    if (mounted) {
      widget.onUnlockSuccess?.call();
    }
  }

  void _showForgotPinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Сброс PIN-кода',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Для сброса PIN-кода потребуется повторная аутентификация через Firebase. Продолжить?',
          style: GoogleFonts.nunito(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Отмена',
              style: GoogleFonts.nunito(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetPinThroughFirebase();
            },
            child: Text(
              'Продолжить',
              style: GoogleFonts.nunito(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPinThroughFirebase() async {
    // TODO: Implement Firebase re-authentication flow
    // This would typically involve:
    // 1. Navigate to re-authentication screen
    // 2. Verify user credentials through Firebase
    // 3. Clear security data
    // 4. Redirect to setup screen
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Функция сброса PIN будет доступна в следующем обновлении'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}