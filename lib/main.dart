import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/expense_provider.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'services/biometric_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLocked = true;
  bool _isCheckingSecurity = true;

  @override
  void initState() {
    super.initState();
    _checkSecurityOnLaunch();
  }

  Future<void> _checkSecurityOnLaunch() async {
    final bioEnabled = await BiometricService.isBiometricsEnabled();
    final pin = await BiometricService.getPinCode();

    final bool requiresSecurity = bioEnabled || (pin != null && pin.isNotEmpty);

    setState(() {
      _isLocked = requiresSecurity;
      _isCheckingSecurity = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
      ],
      child: MaterialApp(
        title: 'WealthJoy',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: _isCheckingSecurity
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : _isLocked
                ? LockScreen(onUnlocked: () => setState(() => _isLocked = false))
                : const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}