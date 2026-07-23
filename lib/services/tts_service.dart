import 'package:flutter_tts/flutter_tts.dart';
import '../database/database_helper.dart';

class TtsService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInitialized = false;

  static Future<void> _initTts() async {
    if (_isInitialized || DatabaseHelper.isTesting) return;
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.48);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _isInitialized = true;
    } catch (_) {}
  }

  /// Speak out loud
  static Future<void> speak(String text) async {
    if (DatabaseHelper.isTesting) return;
    try {
      await _initTts();
      await stop();

      // Clean text by stripping emojis and special markdown formatting for speech
      String cleanText = text
          .replaceAll(RegExp(r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]', unicode: true), '')
          .replaceAll(RegExp(r'[\*\_~]'), '')
          .trim();

      if (cleanText.isNotEmpty) {
        await _flutterTts.speak(cleanText);
      }
    } catch (_) {}
  }

  /// Stop active voice output
  static Future<void> stop() async {
    if (DatabaseHelper.isTesting) return;
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }
}
