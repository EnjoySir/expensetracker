import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../database/database_helper.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Check if hardware supports biometrics (Fingerprint / Face ID)
  static Future<bool> isBiometricAvailable() async {
    try {
      if (DatabaseHelper.isTesting) return true;
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Get list of available biometrics (Fingerprint, Face, Iris)
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      if (DatabaseHelper.isTesting) return [BiometricType.fingerprint, BiometricType.face];
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return [];
    }
  }

  /// Trigger Biometric Verification Prompt (Fingerprint / Face ID)
  static Future<bool> authenticate({String reason = 'Authenticate to access Expense Tracker'}) async {
    try {
      if (DatabaseHelper.isTesting) return true;
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException catch (e) {
      print('Biometric auth error: $e');
      return false;
    }
  }

  /// Settings Helpers for Biometric Preferences
  static Future<bool> isBiometricsEnabled() async {
    final val = await DatabaseHelper().getSetting('biometrics_enabled');
    return val == 'true';
  }

  static Future<void> setBiometricsEnabled(bool enabled) async {
    await DatabaseHelper().setSetting('biometrics_enabled', enabled ? 'true' : 'false');
  }

  static Future<String?> getPinCode() async {
    return await DatabaseHelper().getSetting('app_pin_code');
  }

  static Future<void> setPinCode(String pin) async {
    await DatabaseHelper().setSetting('app_pin_code', pin);
  }

  static Future<void> clearPinCode() async {
    await DatabaseHelper().setSetting('app_pin_code', '');
  }
}
