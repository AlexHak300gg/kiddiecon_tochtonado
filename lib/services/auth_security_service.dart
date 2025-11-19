import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class AuthSecurityService {
  static final AuthSecurityService _instance = AuthSecurityService._internal();
  factory AuthSecurityService() => _instance;
  AuthSecurityService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Storage keys
  static const String _pinKey = 'security_pin';
  static const String _pinEnabledKey = 'security_pin_enabled';
  static const String _biometricEnabledKey = 'security_biometric_enabled';
  static const String _biometricTypeKey = 'security_biometric_type';
  static const String _patternEnabledKey = 'security_pattern_enabled';
  static const String _patternKey = 'security_pattern';
  static const String _failedAttemptsKey = 'security_failed_attempts';
  static const String _lastLockoutKey = 'security_last_lockout';
  static const String _setupCompletedKey = 'security_setup_completed';

  // Constants
  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(seconds: 30);
  static const int minPatternLength = 4;

  /// Check if security setup is completed
  Future<bool> get isSetupCompleted async => await _secureStorage.read(key: _setupCompletedKey) != null;

  /// Check if PIN is enabled
  Future<bool> get isPinEnabled async => await _secureStorage.read(key: _pinEnabledKey) == 'true';

  /// Check if biometric is enabled
  Future<bool> get isBiometricEnabled async => await _secureStorage.read(key: _biometricEnabledKey) == 'true';

  /// Check if pattern is enabled
  Future<bool> get isPatternEnabled async => await _secureStorage.read(key: _patternEnabledKey) == 'true';

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      if (kDebugMode) print('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Check if device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      if (kDebugMode) print('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Setup PIN code
  Future<bool> setupPinCode(String pin) async {
    try {
      if (pin.length < 4 || pin.length > 6 || !RegExp(r'^\d+$').hasMatch(pin)) {
        return false;
      }

      final hashedPin = _hashString(pin);
      await _secureStorage.write(key: _pinKey, value: hashedPin);
      await _secureStorage.write(key: _pinEnabledKey, value: 'true');
      return true;
    } catch (e) {
      if (kDebugMode) print('Error setting up PIN: $e');
      return false;
    }
  }

  /// Verify PIN code
  Future<bool> verifyPin(String pin) async {
    try {
      if (!(await isPinEnabled)) return false;
      
      final storedPin = await _secureStorage.read(key: _pinKey);
      if (storedPin == null) return false;

      final hashedPin = _hashString(pin);
      final isValid = hashedPin == storedPin;

      if (isValid) {
        await resetFailedAttempts();
      } else {
        await incrementFailedAttempts();
      }

      return isValid;
    } catch (e) {
      if (kDebugMode) print('Error verifying PIN: $e');
      return false;
    }
  }

  /// Enable/disable biometric authentication
  Future<bool> enableBiometric(bool enable) async {
    try {
      if (enable && !await isBiometricAvailable()) {
        return false;
      }

      await _secureStorage.write(key: _biometricEnabledKey, value: enable.toString());
      
      if (enable) {
        final biometrics = await getAvailableBiometrics();
        if (biometrics.isNotEmpty) {
          await _secureStorage.write(
            key: _biometricTypeKey,
            value: biometrics.first.toString(),
          );
        }
      } else {
        await _secureStorage.delete(key: _biometricTypeKey);
      }

      return true;
    } catch (e) {
      if (kDebugMode) print('Error enabling biometric: $e');
      return false;
    }
  }

  /// Verify biometric authentication
  Future<bool> verifyBiometric() async {
    try {
      if (!(await isBiometricEnabled) || !await isBiometricAvailable()) {
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Пожалуйста, используйте биометрию для входа',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        await resetFailedAttempts();
      } else {
        await incrementFailedAttempts();
      }

      return authenticated;
    } catch (e) {
      if (kDebugMode) print('Error verifying biometric: $e');
      await incrementFailedAttempts();
      return false;
    }
  }

  /// Setup pattern lock
  Future<bool> setupPatternLock(String pattern) async {
    try {
      final patternList = pattern.split(',').map((e) => int.parse(e.trim())).toList();
      
      if (patternList.length < minPatternLength) {
        return false;
      }

      final hashedPattern = _hashString(pattern);
      await _secureStorage.write(key: _patternKey, value: hashedPattern);
      await _secureStorage.write(key: _patternEnabledKey, value: 'true');
      return true;
    } catch (e) {
      if (kDebugMode) print('Error setting up pattern: $e');
      return false;
    }
  }

  /// Verify pattern lock
  Future<bool> verifyPattern(String pattern) async {
    try {
      if (!(await isPatternEnabled)) return false;
      
      final storedPattern = await _secureStorage.read(key: _patternKey);
      if (storedPattern == null) return false;

      final hashedPattern = _hashString(pattern);
      final isValid = hashedPattern == storedPattern;

      if (isValid) {
        await resetFailedAttempts();
      } else {
        await incrementFailedAttempts();
      }

      return isValid;
    } catch (e) {
      if (kDebugMode) print('Error verifying pattern: $e');
      return false;
    }
  }

  /// Check if user is locked out due to failed attempts
  Future<bool> isLockedOut() async {
    try {
      final failedAttempts = await getFailedAttempts();
      final lastLockout = await _secureStorage.read(key: _lastLockoutKey);

      if (failedAttempts >= maxFailedAttempts) {
        if (lastLockout != null) {
          final lockoutTime = DateTime.parse(lastLockout);
          final now = DateTime.now();
          return now.difference(lockoutTime) < lockoutDuration;
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Error checking lockout status: $e');
      return false;
    }
  }

  /// Get remaining lockout time
  Future<Duration?> getRemainingLockoutTime() async {
    try {
      final failedAttempts = await getFailedAttempts();
      final lastLockout = await _secureStorage.read(key: _lastLockoutKey);

      if (failedAttempts >= maxFailedAttempts && lastLockout != null) {
        final lockoutTime = DateTime.parse(lastLockout);
        final now = DateTime.now();
        final elapsed = now.difference(lockoutTime);
        final remaining = lockoutDuration - elapsed;
        return remaining.isNegative ? null : remaining;
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error getting remaining lockout time: $e');
      return null;
    }
  }

  /// Get failed attempts count
  Future<int> getFailedAttempts() async {
    try {
      final attempts = await _secureStorage.read(key: _failedAttemptsKey);
      return attempts != null ? int.parse(attempts) : 0;
    } catch (e) {
      return 0;
    }
  }

  /// Increment failed attempts
  Future<void> incrementFailedAttempts() async {
    try {
      final attempts = await getFailedAttempts();
      final newAttempts = attempts + 1;
      await _secureStorage.write(key: _failedAttemptsKey, value: newAttempts.toString());

      if (newAttempts >= maxFailedAttempts) {
        await _secureStorage.write(
          key: _lastLockoutKey,
          value: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      if (kDebugMode) print('Error incrementing failed attempts: $e');
    }
  }

  /// Reset failed attempts
  Future<void> resetFailedAttempts() async {
    try {
      await _secureStorage.delete(key: _failedAttemptsKey);
      await _secureStorage.delete(key: _lastLockoutKey);
    } catch (e) {
      if (kDebugMode) print('Error resetting failed attempts: $e');
    }
  }

  /// Mark security setup as completed
  Future<void> completeSetup() async {
    try {
      await _secureStorage.write(key: _setupCompletedKey, value: 'true');
    } catch (e) {
      if (kDebugMode) print('Error completing setup: $e');
    }
  }

  /// Clear all security data (for testing or reset)
  Future<void> clearAllSecurityData() async {
    try {
      final keys = [
        _pinKey,
        _pinEnabledKey,
        _biometricEnabledKey,
        _biometricTypeKey,
        _patternEnabledKey,
        _patternKey,
        _failedAttemptsKey,
        _lastLockoutKey,
        _setupCompletedKey,
      ];

      for (final key in keys) {
        await _secureStorage.delete(key: key);
      }
    } catch (e) {
      if (kDebugMode) print('Error clearing security data: $e');
    }
  }

  /// Hash string using SHA-256
  String _hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}