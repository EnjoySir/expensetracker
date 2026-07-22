import 'package:flutter/services.dart';
import '../database/database_helper.dart';

class SoundService {
  /// Check if sound effects setting is enabled
  static Future<bool> isSoundEnabled() async {
    if (DatabaseHelper.isTesting) return false;
    final val = await DatabaseHelper().getSetting('sound_effects_enabled');
    return val != 'false'; // Default enabled
  }

  /// Toggle sound effects setting
  static Future<void> setSoundEnabled(bool enabled) async {
    await DatabaseHelper().setSetting('sound_effects_enabled', enabled ? 'true' : 'false');
  }

  /// Play button / keypad click tone
  static Future<void> playClick() async {
    if (!await isSoundEnabled()) return;
    try {
      await SystemSound.play(SystemSoundType.click);
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Play success chime tone when adding a transaction or savings goal
  static Future<void> playSuccess() async {
    if (!await isSoundEnabled()) return;
    try {
      await SystemSound.play(SystemSoundType.click);
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Play delete / removal impact tone
  static Future<void> playDelete() async {
    if (!await isSoundEnabled()) return;
    try {
      await SystemSound.play(SystemSoundType.click);
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Play transfer chime tone when moving funds between wallets
  static Future<void> playTransfer() async {
    if (!await isSoundEnabled()) return;
    try {
      await SystemSound.play(SystemSoundType.click);
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Play security unlock chime tone when unlocking PIN / Biometrics
  static Future<void> playUnlock() async {
    if (!await isSoundEnabled()) return;
    try {
      await SystemSound.play(SystemSoundType.click);
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }
}
