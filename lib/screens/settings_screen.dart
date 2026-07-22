import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../services/biometric_service.dart';
import '../services/sound_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<String> _currencies = ['USD', 'ZWG', 'ZAR', 'EUR', 'GBP'];
  bool _biometricsEnabled = false;
  bool _hasPinSet = false;
  bool _isHardwareSupported = false;
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    final bioEnabled = await BiometricService.isBiometricsEnabled();
    final pin = await BiometricService.getPinCode();
    final hardwareSupported = await BiometricService.isBiometricAvailable();
    final sound = await SoundService.isSoundEnabled();

    setState(() {
      _biometricsEnabled = bioEnabled;
      _hasPinSet = pin != null && pin.isNotEmpty;
      _isHardwareSupported = hardwareSupported;
      _soundEnabled = sound;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), backgroundColor: Colors.deepPurple),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Base Currency
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.currency_exchange, color: Colors.deepPurple),
              title: const Text('Base Currency'),
              subtitle: Text(provider.baseCurrency),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showCurrencyPicker(context, provider),
            ),
          ),
          const SizedBox(height: 8),

          // Security Header
          const Padding(
            padding: EdgeInsets.only(left: 4, top: 12, bottom: 6),
            child: Text('Security & Biometrics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
          ),

          // Fingerprint & Face ID Switch
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              secondary: const Icon(Icons.fingerprint, color: Colors.deepPurple),
              title: const Text('Fingerprint / Face ID Login'),
              subtitle: Text(_isHardwareSupported
                  ? 'Use biometric sensor to unlock app'
                  : 'Biometric hardware not detected on device'),
              value: _biometricsEnabled,
              onChanged: _isHardwareSupported
                  ? (val) async {
                      if (val) {
                        final bool authenticated = await BiometricService.authenticate(
                          reason: 'Confirm your Fingerprint or Face ID to enable biometric login',
                        );
                        if (authenticated) {
                          await BiometricService.setBiometricsEnabled(true);
                          setState(() => _biometricsEnabled = true);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Fingerprint / Face ID enabled'), backgroundColor: Colors.green),
                            );
                          }
                        }
                      } else {
                        await BiometricService.setBiometricsEnabled(false);
                        setState(() => _biometricsEnabled = false);
                      }
                    }
                  : null,
            ),
          ),
          const SizedBox(height: 8),

          // PIN Lock
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.lock, color: Colors.deepPurple),
              title: const Text('PIN Lock'),
              subtitle: Text(_hasPinSet ? '4-digit PIN lock configured' : 'Set a 4-digit PIN to secure your app'),
              trailing: _hasPinSet
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      onPressed: () async {
                        await BiometricService.clearPinCode();
                        await _loadSecuritySettings();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('PIN lock removed')),
                          );
                        }
                      },
                    )
                  : const Icon(Icons.chevron_right),
              onTap: () => _showPinSetup(context),
            ),
          ),
          const SizedBox(height: 8),

          // Preferences Header
          const Padding(
            padding: EdgeInsets.only(left: 4, top: 12, bottom: 6),
            child: Text('Preferences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
          ),

          // Theme
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode, color: Colors.deepPurple),
              title: const Text('Dark Mode'),
              subtitle: const Text('System default theme enabled'),
              value: false,
              onChanged: null,
            ),
          ),
          const SizedBox(height: 8),

          // Sound Effects & Audio Tones
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              secondary: const Icon(Icons.volume_up, color: Colors.deepPurple),
              title: const Text('Audio Tones & Sound Effects'),
              subtitle: const Text('Play audio feedback on taps and transactions'),
              value: _soundEnabled,
              onChanged: (val) async {
                await SoundService.setSoundEnabled(val);
                setState(() => _soundEnabled = val);
              },
            ),
          ),
          const SizedBox(height: 8),

          // Backup
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.cloud_upload, color: Colors.deepPurple),
              title: const Text('Backup & Restore'),
              subtitle: const Text('Cloud backup & data export'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Database is stored securely locally. Export CSV on dashboard.')),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          Center(
            child: Column(
              children: [
                Text('Expense Tracker v2.5 (Biometrics Enabled)', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                const SizedBox(height: 4),
                Text('Built with Flutter ❤️', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, ExpenseProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Base Currency'),
        children: _currencies.map((currency) {
          return RadioListTile<String>(
            value: currency,
            groupValue: provider.baseCurrency,
            title: Text(currency),
            onChanged: (value) async {
              if (value != null) {
                await provider.updateBaseCurrency(value);
                if (context.mounted) Navigator.pop(ctx);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  void _showPinSetup(BuildContext context) {
    final pinCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set 4-Digit PIN'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: pinCtrl,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Enter 4-digit PIN', border: OutlineInputBorder()),
                validator: (v) {
                  if (v == null || v.length != 4) return 'PIN must be 4 digits';
                  if (int.tryParse(v) == null) return 'PIN must be numeric';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmCtrl,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm PIN', border: OutlineInputBorder()),
                validator: (v) {
                  if (v != pinCtrl.text) return 'PINs do not match';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await BiometricService.setPinCode(pinCtrl.text);
                await _loadSecuritySettings();
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN lock configured successfully!'), backgroundColor: Colors.green),
                  );
                }
              }
            },
            child: const Text('Set PIN', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
