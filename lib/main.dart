import 'package:flutter/material.dart';
import 'home/spashpage/splashpage.dart';
import 'services/session_service.dart';
import 'patient/patient_dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Care People',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthenticationWrapper(),
    );
  }
}

// Wrapper to check authentication state
class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  bool _isChecking = true;
  bool _isLoggedIn = false;
  String? _phoneNumber;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final isActive = await SessionService.isSessionActive();
    if (isActive) {
      final phoneNumber = await SessionService.getPhoneNumber();
      setState(() {
        _isLoggedIn = true;
        _phoneNumber = phoneNumber;
        _isChecking = false;
      });
    } else {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      // Show loading screen while checking session
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isLoggedIn && _phoneNumber != null) {
      // Session is active, go directly to dashboard
      return PatientDashboard(phoneNumber: _phoneNumber!);
    }

    // No active session, show splash/login
    return const SplashPage();
  }
}
