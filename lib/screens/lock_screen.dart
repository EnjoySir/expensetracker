import 'package:flutter/material.dart';
import '../services/biometric_service.dart';
import '../services/sound_service.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _enteredPin = '';
  String? _expectedPin;
  bool _biometricsEnabled = false;

  @override
  void initState() {
    super.initState();
    _initLockState();
  }

  Future<void> _initLockState() async {
    final pin = await BiometricService.getPinCode();
    final bioEnabled = await BiometricService.isBiometricsEnabled();
    setState(() {
      _expectedPin = pin;
      _biometricsEnabled = bioEnabled;
    });

    if (_biometricsEnabled) {
      _triggerBiometricAuth();
    }
  }

  Future<void> _triggerBiometricAuth() async {
    final bool success = await BiometricService.authenticate(
      reason: 'Use Fingerprint or Face ID to unlock Expense Tracker',
    );
    if (success && mounted) {
      await SoundService.playUnlock();
      widget.onUnlocked();
    }
  }

  void _onKeyPress(String val) {
    SoundService.playClick();
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += val;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    SoundService.playClick();
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _verifyPin() async {
    if (_expectedPin != null && _enteredPin == _expectedPin) {
      await SoundService.playUnlock();
      widget.onUnlocked();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect PIN. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade900,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const CircleAvatar(
              radius: 36,
              backgroundColor: Colors.white24,
              child: Icon(Icons.lock_rounded, size: 36, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Expense Tracker Security',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter PIN or use Fingerprint / Face ID',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final bool isFilled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? Colors.greenAccent : Colors.white24,
                    border: Border.all(color: Colors.white54, width: 1.5),
                  ),
                );
              }),
            ),
            const Spacer(),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['1', '2', '3'].map((n) => _buildKey(n)).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['4', '5', '6'].map((n) => _buildKey(n)).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['7', '8', '9'].map((n) => _buildKey(n)).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: _triggerBiometricAuth,
                        icon: const Icon(Icons.fingerprint, color: Colors.greenAccent, size: 32),
                        tooltip: 'Fingerprint / Face ID',
                      ),
                      _buildKey('0'),
                      IconButton(
                        onPressed: _onBackspace,
                        icon: const Icon(Icons.backspace_outlined, color: Colors.white70, size: 26),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String val) {
    return InkWell(
      onTap: () => _onKeyPress(val),
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.12),
        ),
        child: Center(
          child: Text(
            val,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
